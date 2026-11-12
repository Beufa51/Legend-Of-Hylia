extends Node2D
# Gère la caméra : écran fixe par salle, avec glissement quand le joueur
# passe dans une salle voisine.

const TAILLE_SALLE := Vector2i(400, 224)
const DUREE_GLISSEMENT := 0.6  # secondes
# Musique du donjon (pack Ninja Adventure, libre de droits). Autres choix : "12 - Temple.ogg", "30 - Ruins.ogg", "32 - Manor.ogg"
const MUSIQUE := "res://Assets/Ninja_adventure/Audio/Musics/21 - Dungeon.ogg"
const VOLUME_MUSIQUE_DB := -8.0
# Jingles (pack Ninja Adventure) : une énigme résolue / une plume récupérée
const JINGLE_ENIGME := "res://Assets/Ninja_adventure/Audio/Jingles/Success2.wav"
const JINGLE_PLUME := "res://Assets/Ninja_adventure/Audio/Jingles/LevelUp2.wav"

@onready var joueur: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var salle_actuelle := Vector2i.ZERO  # case de la grille où se trouve la caméra
var en_transition := false


func _ready() -> void:
	_lancer_musique()
	_creer_messages()
	Etat.drapeau_change.connect(_jouer_jingle)
	salle_actuelle = _salle_du_joueur()
	camera.position = _centre_salle(salle_actuelle)
	Etat.salle_courante = salle_actuelle
	_modulation = CanvasModulate.new()
	add_child(_modulation)
	_regler_obscurite(salle_actuelle)
	Etat.secousse.connect(_secouer)


func _process(_delta: float) -> void:
	if en_transition:
		return
	var nouvelle := _salle_du_joueur()
	if nouvelle != salle_actuelle:
		_glisser_vers(nouvelle)


# Dans quelle case de la grille se trouve le joueur ?
func _salle_du_joueur() -> Vector2i:
	return Vector2i(
		floori(joueur.position.x / TAILLE_SALLE.x),
		floori(joueur.position.y / TAILLE_SALLE.y))


func _centre_salle(salle: Vector2i) -> Vector2:
	return Vector2(salle * TAILLE_SALLE) + Vector2(TAILLE_SALLE) / 2.0


# Fait glisser la caméra vers la nouvelle salle ; le joueur est figé pendant ce temps.
func _glisser_vers(salle: Vector2i) -> void:
	en_transition = true
	salle_actuelle = salle
	Etat.salle_courante = salle
	_regler_obscurite(salle)
	_montrer_indice(salle)
	joueur.set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(camera, "position", _centre_salle(salle), DUREE_GLISSEMENT)
	await tween.finished
	joueur.set_physics_process(true)
	en_transition = false


# Indice d'une salle (export `indice` de Room) : affiché une seule fois, à la première visite.
var _indices_vus := {}


func _montrer_indice(salle: Vector2i) -> void:
	for enfant in get_children():
		if enfant is Room and enfant.grille == salle and enfant.indice != "" and not _indices_vus.has(salle):
			_indices_vus[salle] = true
			Etat.annoncer(enfant.indice)


# Joue la musique en boucle (volume baissé pour ne pas couvrir les futurs bruitages).
func _lancer_musique() -> void:
	var flux = load(MUSIQUE)
	if flux == null:
		push_warning("Musique introuvable : " + MUSIQUE)
		return
	flux.loop = true
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = VOLUME_MUSIQUE_DB
	add_child(lecteur)
	lecteur.play()


# Touche R : recommence la salle où l'on est (les blocs reviennent à leur place).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		for enfant in get_children():
			if enfant is Room and enfant.grille == salle_actuelle:
				enfant.reinitialiser()


# Petit texte en bas de l'écran pour les messages (Etat.annoncer).
var _etiquette: Label
var _tween_message: Tween


func _creer_messages() -> void:
	var calque := CanvasLayer.new()
	add_child(calque)
	_etiquette = Label.new()
	_etiquette.position = Vector2(0, 205)
	_etiquette.size = Vector2(400, 16)
	_etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_etiquette.add_theme_font_size_override("font_size", 10)
	_etiquette.add_theme_color_override("font_outline_color", Color.BLACK)
	_etiquette.add_theme_constant_override("outline_size", 4)
	_etiquette.modulate.a = 0.0
	calque.add_child(_etiquette)
	Etat.message.connect(_afficher_message)
	# Rappel des touches au début
	await get_tree().create_timer(0.8).timeout
	Etat.annoncer(Noms.VILLAGE + " — Flèches/ZQSD : bouger    Espace/J : lance    R : recommencer la salle")
	await get_tree().create_timer(5.5).timeout
	if not Etat.est("vestibule_cristal"):
		Etat.annoncer("Frappe le cristal bleu avec ta lance pour ouvrir la porte")


func _afficher_message(texte: String) -> void:
	_etiquette.text = texte
	if _tween_message:
		_tween_message.kill()
	_etiquette.modulate.a = 1.0
	_tween_message = create_tween()
	_tween_message.tween_interval(4.0)
	_tween_message.tween_property(_etiquette, "modulate:a", 0.0, 0.8)


# Un son à chaque drapeau levé : jingle "plume" si le drapeau commence par "plume", sinon jingle "énigme".
func _jouer_jingle(nom: String) -> void:
	var flux = load(JINGLE_PLUME if nom.begins_with("plume") else JINGLE_ENIGME)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -2.0
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)


# --- Salles sombres -------------------------------------------------------------
var _modulation: CanvasModulate   # teinte globale : sombre dans une salle sombre, blanche sinon
const COULEUR_NUIT := Color(0.05, 0.055, 0.11)   # plus sombre = plus noir (1,1,1 = pas de nuit)


# Assombrit l'écran si la salle est `sombre` (et allume la lumière du joueur).
func _regler_obscurite(salle: Vector2i) -> void:
	var noir := false
	for enfant in get_children():
		if enfant is Room and enfant.grille == salle:
			noir = enfant.sombre
	var tween := create_tween()
	tween.tween_property(_modulation, "color", COULEUR_NUIT if noir else Color.WHITE, 0.4)
	joueur.regler_lumiere(noir)


# Petite secousse de l'écran (une porte s'ouvre).
func _secouer() -> void:
	var tween := create_tween()
	for i in 6:
		tween.tween_property(camera, "offset", Vector2(randf_range(-3, 3), randf_range(-2, 2)), 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
