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
	Etat.drapeau_change.connect(_sur_drapeau)


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
	_musique = lecteur


# Touche R : recommence la salle où l'on est (les blocs reviennent à leur place).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1 and OS.is_debug_build():
		_basculer_menu_dev()
		return
	if event.is_action_pressed("reset") and not en_transition:
		for enfant in get_children():
			if enfant is Room and enfant.grille == salle_actuelle:
				enfant.reinitialiser()


# Petit texte en bas de l'écran pour les messages (Etat.annoncer).
var _etiquette: Label
var _tween_message: Tween


func _creer_messages() -> void:
	var calque := CanvasLayer.new()
	calque.layer = 3   # au-dessus de la cinématique (calque 2) : le fondu et les messages restent visibles
	add_child(calque)
	# Écran noir pour les fondus (sous le texte, pour que le message reste lisible)
	_fondu = ColorRect.new()
	_fondu.color = Color.BLACK
	_fondu.size = Vector2(TAILLE_SALLE)
	_fondu.modulate.a = 0.0
	_fondu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	calque.add_child(_fondu)
	_etiquette = Label.new()
	# Zone de 2 lignes en bas de l'écran : un message trop long passe à la ligne au lieu d'être coupé
	_etiquette.position = Vector2(8, 192)
	_etiquette.size = Vector2(384, 30)
	_etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_etiquette.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_etiquette.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	if not Etat.est("vestibule_cristal") and salle_actuelle == Vector2i(0, 1):   # seulement si on est encore au vestibule
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
	var bouton_cine := Button.new()
	bouton_cine.text = "Cinématique aile gauche"
	bouton_cine.add_theme_font_size_override("font_size", 8)
	bouton_cine.focus_mode = Control.FOCUS_NONE
	bouton_cine.pressed.connect(_dev_cinematique)
	boite.add_child(bouton_cine)
	for enfant in get_children():
		if enfant is Room:
			var bouton := Button.new()
			bouton.text = enfant.name
			bouton.add_theme_font_size_override("font_size", 8)
			bouton.focus_mode = Control.FOCUS_NONE
			bouton.pressed.connect(_teleporter.bind(enfant))
			grille.add_child(bouton)
	_menu_dev = panneau


func _dev_cinematique() -> void:
	_menu_dev.visible = false
	_cinematique_aile("gauche")


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


# --- Cinématique de fin d'aile ----------------------------------------------------------
# Quand on ramasse un fragment d'aile, le grand blason apparaît : le coq en pierre, ses ailes
# vides. Le fragment arrive À LA VERTICALE (comme l'aile qu'on vient de parcourir : la racine
# en bas, les plumes dressées), pivote d'un quart de tour autour de sa racine et s'emboîte.
# Images : Assets/Gemini/embleme/blason_*.png, fabriquées par Outils/fabriquer_objets.py.
const DOSSIER_BLASON := "res://Assets/Gemini/embleme/"
const CENTRE_BLASON := Vector2(200, 112)   # centre du blason à l'écran (l'écran fait 400x224)
const TAILLE_BLASON := Vector2(244, 132)   # taille de blason_socle.png
# Racine de chaque aile dans l'image (affichée par fabriquer_objets.py) = point autour duquel elle pivote
const PIVOTS := {"gauche": Vector2(98, 61), "droite": Vector2(146, 61)}
const SON_APPARITION := "res://Assets/Ninja_adventure/Audio/Sounds/Magic & Skill/Spirit.wav"
const SON_PIVOT := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Whoosh.wav"
const SON_EMBOITE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact5.wav"
const JINGLE_BLASON := "res://Assets/Ninja_adventure/Audio/Jingles/Secret2.wav"
var _musique: AudioStreamPlayer


func _sur_drapeau(nom: String) -> void:
	if nom == "fragment_gauche":
		await get_tree().create_timer(1.6).timeout   # laisser le temps au jingle et au message
		_cinematique_aile("gauche")


# Charge une image ; si Godot ne l'a pas encore importée, la lit directement dans le fichier.
func _texture(chemin: String) -> Texture2D:
	var tex = load(chemin) if ResourceLoader.exists(chemin) else null
	if tex == null:
		var img := Image.load_from_file(ProjectSettings.globalize_path(chemin))
		if img != null:
			tex = ImageTexture.create_from_image(img)
	return tex


func _jouer_son(chemin: String, volume_db := 0.0) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = volume_db
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)


func _cinematique_aile(cote: String) -> void:
	if en_transition:
		return
	en_transition = true
	joueur.set_physics_process(false)
	joueur.velocity = Vector2.ZERO
	var droite := cote == "droite"
	var origine := CENTRE_BLASON - TAILLE_BLASON / 2.0   # coin haut-gauche du blason à l'écran
	var pivot: Vector2 = PIVOTS[cote]

	# 1) La scène s'assombrit, la musique se tait
	var calque := CanvasLayer.new()
	calque.layer = 2
	add_child(calque)
	var fond := ColorRect.new()
	fond.color = Color(0.03, 0.03, 0.08)
	fond.size = Vector2(TAILLE_SALLE)
	fond.modulate.a = 0.0
	calque.add_child(fond)
	# Halo doré derrière le blason (dégradé rond, en mode "ajout de lumière")
	var halo := Sprite2D.new()
	var degrade := Gradient.new()
	degrade.set_color(0, Color(1.0, 0.75, 0.35, 0.55))
	degrade.set_color(1, Color(1.0, 0.75, 0.35, 0.0))
	var tex_halo := GradientTexture2D.new()
	tex_halo.gradient = degrade
	tex_halo.width = 256
	tex_halo.height = 160
	tex_halo.fill = GradientTexture2D.FILL_RADIAL
	tex_halo.fill_from = Vector2(0.5, 0.5)
	tex_halo.fill_to = Vector2(1.0, 0.5)
	halo.texture = tex_halo
	halo.position = CENTRE_BLASON
	var additif := CanvasItemMaterial.new()
	additif.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = additif
	halo.modulate.a = 0.0
	calque.add_child(halo)
	# Le blason de pierre (avec les ailes déjà gagnées, en rouge)
	var socle := Sprite2D.new()
	socle.texture = _texture(DOSSIER_BLASON + "blason_socle.png")
	socle.centered = false
	socle.position = origine
	socle.modulate.a = 0.0
	calque.add_child(socle)
	var autre := "gauche" if droite else "droite"
	if Etat.est("fragment_" + autre):
		var deja := Sprite2D.new()
		deja.texture = _texture(DOSSIER_BLASON + "blason_aile_" + autre + ".png")
		deja.centered = false
		socle.add_child(deja)
	# Le fragment : son origine est la racine de l'aile, pour pivoter autour d'elle
	var aile := Sprite2D.new()
	aile.texture = _texture(DOSSIER_BLASON + "blason_aile_" + cote + ".png")
	aile.centered = false
	aile.offset = -pivot
	aile.rotation = -PI / 2 if droite else PI / 2   # à la verticale : plumes vers le haut
	aile.position = Vector2(CENTRE_BLASON.x, 260)   # sous l'écran
	aile.scale = Vector2(0.5, 0.5)
	aile.modulate = Color(1.6, 1.4, 0.9, 0.0)        # éclatant pendant le vol
	calque.add_child(aile)
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.95, 0.8)
	flash.size = Vector2(TAILLE_SALLE)
	flash.modulate.a = 0.0
	calque.add_child(flash)

	var t := create_tween()
	t.tween_property(fond, "modulate:a", 0.94, 0.7)
	if _musique:
		t.parallel().tween_property(_musique, "volume_db", -40.0, 0.7)
	t.tween_property(socle, "modulate:a", 1.0, 0.9)
	t.parallel().tween_property(halo, "modulate:a", 0.5, 0.9)
	await t.finished
	Etat.annoncer("Le grand blason de la Garde...")
	await get_tree().create_timer(1.0).timeout

	# 2) L'aile monte à la verticale jusqu'à sa place
	_jouer_son(SON_APPARITION)
	t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(aile, "modulate:a", 1.0, 0.4)
	t.parallel().tween_property(aile, "position", origine + pivot, 1.4)
	t.parallel().tween_property(aile, "scale", Vector2.ONE, 1.4)
	await t.finished
	await get_tree().create_timer(0.5).timeout

	# 3) Elle pivote d'un quart de tour autour de sa racine... et s'emboîte (léger dépassement)
	_jouer_son(SON_PIVOT)
	t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(aile, "rotation", 0.0, 1.1)
	await t.finished

	# 4) Clac ! Éclair, secousse, l'aile reprend sa couleur
	_jouer_son(SON_EMBOITE)
	_jouer_son(JINGLE_BLASON, -2.0)
	flash.modulate.a = 0.8
	t = create_tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.5)
	t.parallel().tween_property(aile, "modulate", Color.WHITE, 0.8)
	t.parallel().tween_property(halo, "modulate:a", 1.0, 0.3)
	t.tween_property(halo, "modulate:a", 0.6, 0.8)
	var secousse := create_tween()
	for i in 6:
		secousse.tween_property(calque, "offset", Vector2(randf_range(-3, 3), randf_range(-2, 2)), 0.04)
	secousse.tween_property(calque, "offset", Vector2.ZERO, 0.05)
	if Etat.est("fragment_" + autre):
		Etat.annoncer("Les deux ailes ont rejoint le blason ! L'épreuve finale t'attend.")
	else:
		Etat.annoncer("L'aile " + cote + " a rejoint le grand blason ! Il manque encore l'aile " + autre + ".")
	await get_tree().create_timer(4.0).timeout

	# 5) Fondu au noir, retour à l'entrée du donjon
	t = create_tween()
	t.tween_property(_fondu, "modulate:a", 1.0, 0.6)
	await t.finished
	calque.queue_free()
	for enfant in get_children():
		if enfant is Room and enfant.name == "Entree":
			joueur.position = enfant.point_arrivee()
	salle_actuelle = _salle_du_joueur()
	Etat.salle_courante = salle_actuelle
	camera.position = _centre_salle(salle_actuelle)
	_regler_obscurite(salle_actuelle)
	await get_tree().create_timer(0.4).timeout
	t = create_tween()
	t.tween_property(_fondu, "modulate:a", 0.0, 0.6)
	if _musique:
		t.parallel().tween_property(_musique, "volume_db", VOLUME_MUSIQUE_DB, 1.5)
	await t.finished
	joueur.set_physics_process(true)
	en_transition = false
