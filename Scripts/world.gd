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
	Etat.repere.connect(_raccompagner)


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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1 and OS.is_debug_build():
		_basculer_menu_dev()
		return
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
	# Écran noir pour les fondus (sous le texte, pour que le message reste lisible)
	_fondu = ColorRect.new()
	_fondu.color = Color.BLACK
	_fondu.size = Vector2(TAILLE_SALLE)
	_fondu.modulate.a = 0.0
	_fondu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	calque.add_child(_fondu)
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
	Etat.annoncer(Noms.VILLAGE + " — Flèches/ZQSD : bouger   Maj/K : courir   Espace/J : lance   R : recommencer")
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
	var flux = load(JINGLE_PLUME if (nom.begins_with("plume") or nom.begins_with("fragment")) else JINGLE_ENIGME)
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


# --- Repéré par une sentinelle ---------------------------------------------------
const SON_ALERTE := "res://Assets/Ninja_adventure/Audio/Sounds/Alert/Alert.wav"
var _fondu: ColorRect
var _raccompagnement := false


# Un garde ramène le joueur à l'entrée de la plume : alerte, fondu au noir, retour, la salle est remise à zéro.
func _raccompagner(retour: Vector2) -> void:
	if _raccompagnement:
		return
	_raccompagnement = true
	en_transition = true
	joueur.set_physics_process(false)
	var salle_reperee := salle_actuelle
	var flux = load(SON_ALERTE)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)
	Etat.annoncer("Repéré ! Un garde te raccompagne à l'entrée de la plume.")
	await get_tree().create_timer(0.7).timeout
	var tween := create_tween()
	tween.tween_property(_fondu, "modulate:a", 1.0, 0.4)
	await tween.finished
	joueur.position = retour
	joueur.velocity = Vector2.ZERO
	for enfant in get_children():
		if enfant is Room and enfant.grille == salle_reperee:
			enfant.reinitialiser()
	salle_actuelle = _salle_du_joueur()
	Etat.salle_courante = salle_actuelle
	camera.position = _centre_salle(salle_actuelle)
	_regler_obscurite(salle_actuelle)
	await get_tree().create_timer(0.4).timeout
	tween = create_tween()
	tween.tween_property(_fondu, "modulate:a", 0.0, 0.4)
	await tween.finished
	joueur.set_physics_process(true)
	en_transition = false
	_raccompagnement = false


# --- Mode développeur (touche F1, seulement quand on lance le jeu depuis Godot) -------------
# Un menu avec un bouton par salle : on y est téléporté directement, pour tester sans tout refaire.
var _menu_dev: Control


func _basculer_menu_dev() -> void:
	if _menu_dev == null:
		_creer_menu_dev()
	_menu_dev.visible = not _menu_dev.visible
	joueur.set_physics_process(not _menu_dev.visible and not en_transition)


func _creer_menu_dev() -> void:
	var calque := CanvasLayer.new()
	calque.layer = 10
	add_child(calque)
	var panneau := PanelContainer.new()
	panneau.position = Vector2(8, 8)
	calque.add_child(panneau)
	var boite := VBoxContainer.new()
	panneau.add_child(boite)
	var titre := Label.new()
	titre.text = "MODE DÉVELOPPEUR (F1 pour fermer) : aller dans la salle..."
	titre.add_theme_font_size_override("font_size", 8)
	boite.add_child(titre)
	var grille := GridContainer.new()
	grille.columns = 4
	boite.add_child(grille)
	for enfant in get_children():
		if enfant is Room:
			var bouton := Button.new()
			bouton.text = enfant.name
			bouton.add_theme_font_size_override("font_size", 8)
			bouton.focus_mode = Control.FOCUS_NONE
			bouton.pressed.connect(_teleporter.bind(enfant))
			grille.add_child(bouton)
	_menu_dev = panneau


func _teleporter(salle: Room) -> void:
	_menu_dev.visible = false
	joueur.position = salle.point_arrivee()
	joueur.velocity = Vector2.ZERO
	salle_actuelle = _salle_du_joueur()
	Etat.salle_courante = salle_actuelle
	camera.position = _centre_salle(salle_actuelle)
	_regler_obscurite(salle_actuelle)
	_montrer_indice(salle_actuelle)
	joueur.set_physics_process(true)
	Etat.annoncer("[dev] " + salle.name)
