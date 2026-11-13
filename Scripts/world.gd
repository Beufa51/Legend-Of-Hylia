extends Node2D
# Gère la caméra : écran fixe par salle, avec glissement quand le joueur
# passe dans une salle voisine.

const TAILLE_SALLE := Vector2i(400, 224)
const DUREE_GLISSEMENT := 0.6  # secondes
# Musique du donjon (pack Ninja Adventure, libre de droits). Autres choix : "12 - Temple.ogg", "30 - Ruins.ogg", "32 - Manor.ogg"
# Scène qui utilise ce script : le donjon (world.tscn) ou l'extérieur (village.tscn), réglé dans la scène
@export var musique := "res://Assets/Ninja_adventure/Audio/Musics/21 - Dungeon.ogg"
@export var donjon := true   # faux à l'extérieur : pas de plumes à l'écran, pas de sortie du donjon
# Quelle aile du donjon : "gauche" (world.tscn) ou "droite" (aile_droite.tscn). L'aile droite est le
# MIROIR de la gauche : l'épine part vers l'ouest (grille x négative) et ses drapeaux ont d'autres noms
# (plumeD1..plumeD4, fragment_droite) : voir _plume().
@export var cote := "gauche"
# Scènes du jeu, pour les passages "@nom:Ecran" (voir _changer_de_scene)
const SCENES := {
	"donjon": "res://Scenes/world.tscn",
	"aile_droite": "res://Scenes/aile_droite.tscn",
	"village": "res://Scenes/village.tscn",
	"corps": "res://Scenes/corps.tscn",
}
const VOLUME_MUSIQUE_DB := -8.0
# Jingles (pack Ninja Adventure) : une énigme résolue / une plume récupérée
const JINGLE_ENIGME := "res://Assets/Ninja_adventure/Audio/Jingles/Success2.wav"
const JINGLE_PLUME := "res://Assets/Ninja_adventure/Audio/Jingles/LevelUp2.wav"

@onready var joueur: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var salle_actuelle := Vector2i.ZERO  # case de la grille où se trouve la caméra
var en_transition := false


func _ready() -> void:
	if Etat.position_sauvee != Vector2.ZERO and Etat.scene_sauvee == scene_file_path:
		joueur.position = _position_reprise()   # partie sauvegardée : on reprend là où on était
	if Etat.arrivee_ecran != "":   # on arrive d'une autre scène (village <-> donjon)
		for e in get_children():
			if e is Ecran and e.name == Etat.arrivee_ecran:
				joueur.position = e.position + Vector2(Etat.arrivee_case * Ecran.TUILE) + Vector2(8, 3)
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
	Etat.chute.connect(_raccompagner.bind("chute"))
	Etat.pique.connect(_raccompagner.bind("pics"))
	Etat.stele_touchee.connect(_ceremonie_stele)
	Etat.passage.connect(func(ecran, case): _passer_porte(ecran, case, Etat.passage_texte))
	Etat.drapeau_change.connect(_sur_drapeau)
	_creer_hud()
	add_child(Dialogue.new())   # boîte de dialogue des habitants
	if not donjon:
		var ambiance := Ambiance.new()   # vent, feuilles, nuages, papillons, oiseaux (extérieur seulement)
		ambiance.camera = camera
		add_child(ambiance)
		_ambiance = ambiance
		_regler_obscurite(salle_actuelle)   # (si on reprend la partie dans une maison)
	Etat.memoriser_position(joueur.position)   # la sauvegarde retient la scène où l'on est
	if Etat.arrivee_ecran != "":   # fondu d'arrivée + message
		if Etat.arrivee_direction != "":
			joueur.direction = Etat.arrivee_direction
			joueur.sprite.play("repos_" + joueur.direction)
			Etat.arrivee_direction = ""
		var texte := Etat.arrivee_texte
		Etat.arrivee_ecran = ""
		Etat.arrivee_texte = ""
		_fondu.modulate.a = 1.0
		create_tween().tween_property(_fondu, "modulate:a", 0.0, 0.8)
		if texte != "":
			get_tree().create_timer(1.0).timeout.connect(func(): Etat.annoncer(texte))


# Où reprendre la partie ? On cherche l'écran par son NOM (la grille a pu changer depuis la sauvegarde) ;
# si la case est devenue bloquée, on prend le point d'arrivée de l'écran ; si l'écran n'existe plus, un écran de repli.
func _position_reprise() -> Vector2:
	var ecrans := {}
	for e in get_children():
		if e is Ecran:
			ecrans[e.name] = e
	if Etat.ecran_sauve == "":
		return Etat.position_sauvee   # (donjons : grille inchangée)
	if ecrans.has(Etat.ecran_sauve):
		var e: Ecran = ecrans[Etat.ecran_sauve]
		var p: Vector2 = e.position + Etat.decalage_sauve
		var dedans := Rect2(Vector2.ZERO, Vector2(Ecran.TAILLE_SALLE)).has_point(Etat.decalage_sauve)
		if dedans and not e.position_bloquee(p):
			return p
		return e.point_arrivee()
	for nom in ["InterieurHeros" if not Etat.est("capitaine_vu") else "PlaceDuCoq", "PlaceDuCoq"]:
		if ecrans.has(nom):
			return ecrans[nom].point_arrivee()
	return Etat.position_sauvee


func _process(_delta: float) -> void:
	if en_transition:
		return
	var nouvelle := _salle_du_joueur()
	if donjon and nouvelle == SORTIE_DONJON and Etat.est("fragment_" + cote):
		if not Etat.est("vue_aerienne_" + cote):
			_vue_aerienne(cote)   # on sort du donjon avec l'aile : vue du ciel
		else:
			_ramener("@village:" + _temple(), Vector2i(12, 7), "")   # sorties suivantes : on retourne directement au village
		return
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
	Etat.memoriser_position(joueur.position)   # sauvegarde : on reprendra à l'entrée de cette salle
	joueur.set_physics_process(true)
	en_transition = false


# Indice d'une salle (export `indice` de Room) : affiché une seule fois, à la première visite.
var _indices_vus := {}


func _montrer_indice(salle: Vector2i) -> void:
	for enfant in get_children():
		if enfant is Ecran and enfant.grille == salle and enfant.indice != "" and not _indices_vus.has(salle):
			_indices_vus[salle] = true
			Etat.annoncer(enfant.indice)


# Joue la musique en boucle (volume baissé pour ne pas couvrir les futurs bruitages).
const MUSIQUE_INTERIEUR := "res://Assets/Ninja_adventure/Audio/Musics/27 - Chill.ogg"
var _piste_courante := ""


# Passe à une autre musique en fondu (rien si c'est déjà celle qui joue).
func _changer_musique(chemin: String) -> void:
	if _musique == null or chemin == _piste_courante or not ResourceLoader.exists(chemin):
		return
	_piste_courante = chemin
	var flux = load(chemin)
	flux.loop = true
	var t := create_tween()
	t.tween_property(_musique, "volume_db", -40.0, 0.4)
	await t.finished
	if chemin != _piste_courante:
		return   # on a déjà changé d'avis entre-temps
	_musique.stream = flux
	_musique.play()
	create_tween().tween_property(_musique, "volume_db", VOLUME_MUSIQUE_DB, 0.6)


func _lancer_musique() -> void:
	var flux = load(musique)
	if flux == null:
		push_warning("Musique introuvable : " + musique)
		return
	flux.loop = true
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = VOLUME_MUSIQUE_DB
	add_child(lecteur)
	lecteur.play()
	_musique = lecteur
	_piste_courante = musique


# Touche R : recommence la salle où l'on est (les blocs reviennent à leur place).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1 and OS.is_debug_build():
		_basculer_menu_dev()
		return
	if event.is_action_pressed("reset") and not en_transition and not Etat.en_dialogue:
		for enfant in get_children():
			if enfant is Ecran and enfant.grille == salle_actuelle:
				if enfant is Room and enfant.recommence_au_debut() and enfant.retour != Vector2.ZERO:
					_raccompagner(enfant.retour, "recommencer")   # glace, reflet : on peut être coincé -> retour au début
				else:
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
	Etat.annoncer((Noms.VILLAGE if not donjon else "L'Épreuve de la Garde") + " — Flèches/ZQSD : bouger   Maj/K : courir   Espace/J : lance   R : recommencer")
	await get_tree().create_timer(5.5).timeout
	if cote == "gauche" and donjon and not Etat.est("vestibule_cristal") and salle_actuelle == Vector2i(0, 1):   # seulement si on est encore au vestibule
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
var _ambiance: Ambiance
var _modulation: CanvasModulate   # teinte globale : sombre dans une salle sombre, blanche sinon
const COULEUR_NUIT := Color(0.05, 0.055, 0.11)   # plus sombre = plus noir (1,1,1 = pas de nuit)


# Assombrit l'écran si la salle est `sombre` (et allume la lumière du joueur).
func _regler_obscurite(salle: Vector2i) -> void:
	var noir := false
	var dedans := false
	var piste := musique
	for enfant in get_children():
		if enfant is Ecran and enfant.grille == salle:
			noir = enfant.sombre
			dedans = enfant.interieur
			if enfant.musique_ecran != "":
				piste = enfant.musique_ecran
			elif dedans and not donjon:
				piste = MUSIQUE_INTERIEUR
	_changer_musique(piste)
	if _ambiance:   # pas de vent ni de feuilles dans une maison
		_ambiance.visible = not dedans
		_ambiance.process_mode = Node.PROCESS_MODE_DISABLED if dedans else Node.PROCESS_MODE_INHERIT
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
const SON_CHUTE := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Whoosh.wav"
const SON_PIQUE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Hit1.wav"
var _fondu: ColorRect
var _raccompagnement := false


# Un garde ramène le joueur à l'entrée de la plume : alerte, fondu au noir, retour, la salle est remise à zéro.
# `raison` : "garde" (repéré par une sentinelle), "chute" (tombé dans un trou), "pics" (marché sur des pics sortis),
# "recommencer" (touche R dans une salle de glace).
func _raccompagner(retour: Vector2, raison := "garde") -> void:
	var chute := raison == "chute"
	if _raccompagnement:
		return
	_raccompagnement = true
	en_transition = true
	joueur.set_physics_process(false)
	joueur.velocity = Vector2.ZERO
	var salle_reperee := salle_actuelle
	if chute:
		_jouer_son(SON_CHUTE, -4.0)
		var t_chute := create_tween()
		t_chute.tween_property(joueur.sprite, "scale", Vector2(0.1, 0.1), 0.5)
		t_chute.parallel().tween_property(joueur.sprite, "rotation", 3.0, 0.5)
		Etat.annoncer("Tu es tombé ! Retour au début de la salle.")
	var flux = load(SON_ALERTE) if raison == "garde" else null
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)
	if raison == "garde":
		Etat.annoncer("Repéré ! Un garde te raccompagne au début de la salle.")
	elif raison == "recommencer":
		Etat.annoncer("Tu recommences la salle.")
	elif raison == "pics":
		_jouer_son(SON_PIQUE, -2.0)
		joueur.sprite.modulate = Color(1.0, 0.4, 0.4)
		Etat.annoncer("Aïe, les pics ! Retour au début de la salle. Passe quand ils sont rentrés.")
	await get_tree().create_timer(0.7).timeout
	var tween := create_tween()
	tween.tween_property(_fondu, "modulate:a", 1.0, 0.4)
	await tween.finished
	joueur.arreter_glissade()
	joueur.position = retour
	joueur.velocity = Vector2.ZERO
	joueur.sprite.scale = Vector2.ONE
	joueur.sprite.rotation = 0.0
	joueur.sprite.modulate = Color.WHITE
	for enfant in get_children():
		if enfant is Ecran and enfant.grille == salle_reperee:
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
	bouton_cine.text = "Vue aérienne aile " + cote
	bouton_cine.add_theme_font_size_override("font_size", 8)
	bouton_cine.focus_mode = Control.FOCUS_NONE
	bouton_cine.pressed.connect(_dev_cinematique)
	boite.add_child(bouton_cine)
	var bouton_stele := Button.new()
	bouton_stele.text = "Test stèle : donner les 2 fragments (forêt remise)"
	bouton_stele.add_theme_font_size_override("font_size", 8)
	bouton_stele.focus_mode = Control.FOCUS_NONE
	bouton_stele.pressed.connect(_dev_test_stele)
	boite.add_child(bouton_stele)
	var bouton_vieille := Button.new()
	bouton_vieille.text = "Simuler une vieille sauvegarde (village)"
	bouton_vieille.add_theme_font_size_override("font_size", 8)
	bouton_vieille.focus_mode = Control.FOCUS_NONE
	bouton_vieille.pressed.connect(func():
		Etat.simuler_ancienne_sauvegarde()
		Etat.charger()
		get_tree().change_scene_to_file("res://Scenes/demarrage.tscn"))
	boite.add_child(bouton_vieille)
	var bouton_effacer := Button.new()
	bouton_effacer.text = "Effacer la sauvegarde (nouvelle partie)"
	bouton_effacer.add_theme_font_size_override("font_size", 8)
	bouton_effacer.focus_mode = Control.FOCUS_NONE
	bouton_effacer.pressed.connect(_dev_nouvelle_partie)
	boite.add_child(bouton_effacer)
	for lieu in [["village", "Aller au village"], ["donjon", "Aller à l'aile gauche"], ["aile_droite", "Aller à l'aile droite"], ["corps", "Aller au Gardien (fin)"]]:
		if SCENES[lieu[0]] == scene_file_path:
			continue
		var bouton_scene := Button.new()
		bouton_scene.text = lieu[1]
		bouton_scene.add_theme_font_size_override("font_size", 8)
		bouton_scene.focus_mode = Control.FOCUS_NONE
		bouton_scene.pressed.connect(_dev_changer_scene.bind(SCENES[lieu[0]]))
		boite.add_child(bouton_scene)
	for enfant in get_children():
		if enfant is Ecran:
			var bouton := Button.new()
			bouton.text = enfant.name
			bouton.add_theme_font_size_override("font_size", 8)
			bouton.focus_mode = Control.FOCUS_NONE
			bouton.pressed.connect(_teleporter.bind(enfant))
			grille.add_child(bouton)
	_menu_dev = panneau


# Passe du village au donjon (ou l'inverse). `cible` = "@donjon:Ecran" ou "@village:Ecran" ; le joueur arrive dans cet écran, à cette case.
func _changer_de_scene(cible: String, case: Vector2i, texte: String) -> void:
	var morceaux := cible.substr(1).split(":")
	Etat.arrivee_ecran = morceaux[1]
	Etat.arrivee_case = case
	Etat.arrivee_texte = texte
	Etat.position_sauvee = Vector2.ZERO   # la position sera mémorisée à l'arrivée
	get_tree().change_scene_to_file(SCENES.get(morceaux[0], SCENES["village"]))


# Mode développeur : les deux fragments sont donnés, la forêt du parvis est remise, et on va devant la stèle.
func _dev_test_stele() -> void:
	Etat.noter("fragment_gauche")
	Etat.noter("fragment_droite")
	Etat.drapeaux.erase("corps_revele")
	Etat.sauver()
	_changer_de_scene("@village:Parvis", Vector2i(12, 8), "Monte vers la stèle avec les deux ailes du blason.")


func _dev_nouvelle_partie() -> void:
	Etat.effacer()
	get_tree().change_scene_to_file("res://Scenes/demarrage.tscn")


func _dev_changer_scene(chemin: String) -> void:
	get_tree().change_scene_to_file(chemin)


func _dev_cinematique() -> void:
	_menu_dev.visible = false
	_vue_aerienne(cote)


func _teleporter(salle: Ecran) -> void:
	_menu_dev.visible = false
	joueur.arreter_glissade()
	joueur.position = salle.point_arrivee()
	joueur.velocity = Vector2.ZERO
	salle_actuelle = _salle_du_joueur()
	Etat.salle_courante = salle_actuelle
	camera.position = _centre_salle(salle_actuelle)
	_regler_obscurite(salle_actuelle)
	_montrer_indice(salle_actuelle)
	joueur.set_physics_process(true)
	Etat.memoriser_position(joueur.position)
	Etat.annoncer("[dev] " + salle.name)


# --- Fin d'aile : retour à l'entrée, puis VUE AÉRIENNE en sortant du donjon ---------------
# 1) On ramasse le fragment : une force ramène le joueur à l'Entrée, la grande porte du sud du
#    vestibule s'ouvre (porte H, drapeau fragment_gauche).
# 2) Quand le joueur SORT par cette porte, la caméra s'envole : vu du ciel, le plan des salles
#    qu'il a parcourues dessine une aile. L'aile pivote et rejoint le corps du donjon
#    (le grand blason de pierre, pas encore construit), puis devient l'aile rouge du blason.
# Images : Assets/Gemini/embleme/blason_*.png, fabriquées par Outils/fabriquer_objets.py.
# Le plan vu du ciel est fabriqué EN CODE à partir des plans (`layout`) des salles : si on
# modifie le donjon, la vue aérienne suit toute seule.
const DOSSIER_BLASON := "res://Assets/Gemini/embleme/"
const CENTRE_BLASON := Vector2(200, 112)   # centre du blason à l'écran (l'écran fait 400x224)
const TAILLE_BLASON := Vector2(244, 132)   # taille de blason_socle.png
# Racine de chaque aile dans l'image (affichée par fabriquer_objets.py) = point où l'aile s'accroche au corps
const PIVOTS := {"gauche": Vector2(98, 61), "droite": Vector2(146, 61)}
const SORTIE_DONJON := Vector2i(0, 2)      # l'écran sous le vestibule = dehors
const SON_ENVOL := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Launch.wav"
const SON_REVELATION := "res://Assets/Ninja_adventure/Audio/Jingles/Secret1.wav"
const SON_PIVOT := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Whoosh.wav"
const SON_EMBOITE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact5.wav"
const JINGLE_BLASON := "res://Assets/Ninja_adventure/Audio/Jingles/Secret2.wav"
# Couleurs du plan vu du ciel
const CIEL_HERBE := Color(0.149, 0.259, 0.173)
const CIEL_SOL := Color(0.808, 0.761, 0.643)
const CIEL_MUR := Color(0.282, 0.259, 0.329)
const ECHELLE_AILE := Vector2(0.5, 1.15)   # forme finale du plan pour épouser l'empreinte de l'aile (x = épine, y = plumes)
const CIEL_OR := Color(0.980, 0.784, 0.314)
var _musique: AudioStreamPlayer


# RETOUR RAPIDE : après une plume (1 à 4), une force ramène le joueur dans l'épine, devant la porte
# qui vient de s'ouvrir ; après le fragment, à l'Entrée. Plus besoin de refaire le chemin à vide.
func _sur_drapeau(nom: String) -> void:
	_maj_hud()
	if not donjon:
		return
	if nom == "fragment_" + cote:
		await get_tree().create_timer(1.8).timeout   # laisser le temps au jingle et au message
		_ramener("Entree", Vector2i(12, 9), "Une force t'a ramené à l'entrée. La grande porte du vestibule est ouverte : sors du donjon !")
		return
	for n in range(1, 5):
		if nom == _plume(n):
			await get_tree().create_timer(1.8).timeout
			_ramener("Epine%d" % n, Vector2i(12, 6), "Une force t'a ramené dans l'épine de l'aile. La porte de " + ("l'est" if cote == "gauche" else "l'ouest") + " est ouverte !")


# Nom du drapeau de la plume n de CETTE aile : "plume1" (aile gauche), "plumeD1" (aile droite).
func _plume(n: int) -> String:
	return ("plume%d" if cote == "gauche" else "plumeD%d") % n


# L'écran du village devant le temple de cette aile.
func _temple() -> String:
	return "TempleGauche" if cote == "gauche" else "TempleDroit"


# Fondu au noir, le joueur est posé dans la salle `nom_salle`, sur la case `case`.
const SON_PORTE := "res://Assets/Sons/porte.wav"   # fabriqué par Outils/fabriquer_sons.py


# Passage d'une porte (maison, temple) : on pousse la porte (bruit + un pas vers l'intérieur ou l'extérieur), puis fondu et arrivée juste derrière la porte, dans le bon sens.
func _passer_porte(nom: String, case: Vector2i, texte: String) -> void:
	if en_transition:
		return
	var depart: Ecran = null
	var arrivee: Ecran = null
	for e in get_children():
		if e is Ecran:
			if e.grille == salle_actuelle:
				depart = e
			if e.name == nom:
				arrivee = e
	var pas := Vector2.ZERO
	if nom.begins_with("@donjon") or nom.begins_with("@aile_droite") or nom.begins_with("@corps"):
		pas = Vector2.UP
	elif arrivee != null and depart != null and arrivee.interieur != depart.interieur:
		pas = Vector2.UP if arrivee.interieur else Vector2.DOWN
	if pas != Vector2.ZERO:
		var dir := "haut" if pas == Vector2.UP else "bas"
		en_transition = true
		joueur.set_physics_process(false)
		joueur.velocity = Vector2.ZERO
		if pas == Vector2.UP and depart != null and not depart.interieur:   # la porte s'ouvre devant le héros
			var local := joueur.position - depart.position
			depart.ouvrir_porte(Vector2i(floori(local.x / Ecran.TUILE), floori(local.y / Ecran.TUILE)), 1.0)
			await get_tree().create_timer(0.25).timeout
		joueur.set_physics_process(false)
		joueur.velocity = Vector2.ZERO
		joueur.direction = dir
		joueur.sprite.play("marche_" + dir)
		joueur._jouer_son(SON_PORTE, -3.0)
		var t := create_tween().set_parallel(true)
		t.tween_property(joueur, "position", joueur.position + pas * 12.0, 0.35)
		if pas == Vector2.UP and arrivee != null and arrivee.interieur:
			t.tween_property(joueur, "modulate:a", 0.0, 0.3).set_delay(0.1)   # il entre dans l'ombre de la porte
		await t.finished
		joueur.modulate.a = 1.0
		en_transition = false
		Etat.arrivee_direction = dir
	await _ramener(nom, case, texte)
	if pas == Vector2.DOWN and arrivee != null and not arrivee.interieur:   # on sort : la porte est ouverte derrière le héros
		arrivee.ouvrir_porte(case + Vector2i(0, -1), 0.8)
	if pas != Vector2.ZERO and not nom.begins_with("@"):
		joueur.direction = Etat.arrivee_direction
		joueur.sprite.play("repos_" + joueur.direction)
		Etat.arrivee_direction = ""


func _ramener(nom_salle: String, case: Vector2i, texte: String) -> void:
	if en_transition:
		await get_tree().create_timer(0.8).timeout   # une autre transition se termine
		if en_transition:
			return
	en_transition = true
	joueur.set_physics_process(false)
	var t := create_tween()
	t.tween_property(_fondu, "modulate:a", 1.0, 0.6)
	await t.finished
	if nom_salle.begins_with("@"):   # "@donjon:Vestibule" / "@village:TempleGauche" : autre scène
		_changer_de_scene(nom_salle, case, texte)
		return
	for enfant in get_children():
		if enfant is Ecran and enfant.name == nom_salle:
			joueur.arreter_glissade()
			joueur.position = enfant.position + Vector2(case * Ecran.TUILE) + Vector2(8, 3)
	joueur.velocity = Vector2.ZERO
	_placer_camera()
	_montrer_indice(salle_actuelle)
	Etat.memoriser_position(joueur.position)
	await get_tree().create_timer(0.4).timeout
	t = create_tween()
	t.tween_property(_fondu, "modulate:a", 0.0, 0.6)
	await t.finished
	joueur.set_physics_process(true)
	en_transition = false
	if texte != "":
		Etat.annoncer(texte)


# Caméra et obscurité calées sur la salle où se trouve le joueur (sans glissement).
func _placer_camera() -> void:
	salle_actuelle = _salle_du_joueur()
	Etat.salle_courante = salle_actuelle
	camera.position = _centre_salle(salle_actuelle)
	_regler_obscurite(salle_actuelle)


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


func _sprite(texture: Texture2D, pos: Vector2, parent: Node) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = false
	s.position = pos
	parent.add_child(s)
	return s


# Fabrique le plan du donjon vu du ciel : 1 pixel par case, sol clair, murs sombres (seulement
# les murs proches d'un sol, pour que la FORME des salles se voie), transparent autour.
# Renvoie {"carte": texture, "contour": texture (lisere doré de la silhouette), "coin": case (0,0) de la grille sur l'image}.
func _plan_vu_du_ciel() -> Dictionary:
	var salles: Array[Room] = []
	var bas := Vector2i(1000, 1000)    # plus petite case de la grille
	var haut := Vector2i(-1000, -1000) # plus grande case de la grille
	for enfant in get_children():
		if enfant is Room:   # (chaque aile est dans sa propre scène : toutes les salles en font partie)
			salles.append(enfant)
			bas = Vector2i(mini(bas.x, enfant.grille.x), mini(bas.y, enfant.grille.y))
			haut = Vector2i(maxi(haut.x, enfant.grille.x), maxi(haut.y, enfant.grille.y))
	var cases := Vector2i(25, 14)   # cases par salle
	var marge := 4
	var taille := (haut - bas + Vector2i.ONE) * cases + Vector2i(marge, marge) * 2
	# 1 = sol, 2 = mur
	var plan := PackedByteArray()
	plan.resize(taille.x * taille.y)
	for salle in salles:
		var base := (salle.grille - bas) * cases + Vector2i(marge, marge)
		for y in salle.layout.size():
			for x in salle.layout[y].length():
				if not "#R".contains(salle.layout[y][x]):
					plan[(base.y + y) * taille.x + base.x + x] = 1
	for y in taille.y:
		for x in taille.x:
			if plan[y * taille.x + x] == 0 and _voisin(plan, taille, x, y, 2, 1):
				plan[y * taille.x + x] = 2
	var carte := Image.create(taille.x, taille.y, false, Image.FORMAT_RGBA8)
	var contour := Image.create(taille.x, taille.y, false, Image.FORMAT_RGBA8)
	for y in taille.y:
		for x in taille.x:
			var v := plan[y * taille.x + x]
			if v == 1:
				carte.set_pixel(x, y, CIEL_SOL)
			elif v == 2:
				carte.set_pixel(x, y, CIEL_MUR)
			elif _voisin(plan, taille, x, y, 1, 2):   # le reste est transparent (on voit l'herbe dessous)
				contour.set_pixel(x, y, CIEL_OR)
	return {
		"carte": ImageTexture.create_from_image(carte),
		"contour": ImageTexture.create_from_image(contour),
		"coin": Vector2(-bas * cases + Vector2i(marge, marge)),
		"taille": Vector2(taille),
	}


# Y a-t-il une case de valeur `valeur` à moins de `rayon` cases de (x, y) ?
func _voisin(plan: PackedByteArray, taille: Vector2i, x: int, y: int, rayon: int, valeur: int) -> bool:
	for dy in range(-rayon, rayon + 1):
		for dx in range(-rayon, rayon + 1):
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and ny >= 0 and nx < taille.x and ny < taille.y and plan[ny * taille.x + nx] == valeur:
				return true
	return false


func _vue_aerienne(aile_vue: String) -> void:
	if en_transition:
		return
	en_transition = true
	Etat.noter("vue_aerienne_" + aile_vue)
	_hud.visible = false
	joueur.set_physics_process(false)
	joueur.velocity = Vector2.ZERO
	var droite := aile_vue == "droite"

	# 1) Fondu au noir ; pendant ce temps, on fabrique le plan vu du ciel
	_jouer_son(SON_ENVOL)
	var t := create_tween()
	t.tween_property(_fondu, "modulate:a", 1.0, 0.6)
	if _musique:
		t.parallel().tween_property(_musique, "volume_db", -40.0, 0.6)
	await t.finished
	var plan := _plan_vu_du_ciel()
	var calque := CanvasLayer.new()
	calque.layer = 2
	add_child(calque)
	var herbe := ColorRect.new()
	herbe.color = CIEL_HERBE
	herbe.size = Vector2(TAILLE_SALLE)
	calque.add_child(herbe)
	# Le corps du donjon (le grand blason de pierre), invisible au début
	var origine := CENTRE_BLASON - TAILLE_BLASON / 2.0
	var socle := _sprite(_texture(DOSSIER_BLASON + "blason_socle.png"), origine, calque)
	socle.modulate.a = 0.0
	if Etat.est("fragment_" + ("gauche" if droite else "droite")):
		_sprite(_texture(DOSSIER_BLASON + "blason_aile_" + ("gauche" if droite else "droite") + ".png"), Vector2.ZERO, socle)
	# Le plan de l'aile : son point d'accroche (pivot) = le centre de l'Entrée (racine de l'aile)
	var racine: Vector2 = plan["coin"] + Vector2(12.5, 7)
	var carte := _sprite(plan["carte"], Vector2.ZERO, calque)
	carte.offset = -racine
	var zoom := 1.6
	carte.scale = Vector2(zoom, zoom)
	carte.position = Vector2(TAILLE_SALLE) / 2.0 + (racine - plan["taille"] / 2.0) * zoom   # plan centré à l'écran
	var lisere := _sprite(plan["contour"], Vector2.ZERO, carte)
	lisere.offset = -racine
	lisere.modulate.a = 0.0
	# Le joueur : un point qui clignote, à la sortie du vestibule
	var point := ColorRect.new()
	point.color = Color(1.0, 0.25, 0.2)
	point.size = Vector2(2, 2)
	point.position = plan["coin"] + Vector2(11.5, 14 + 13) - racine
	carte.add_child(point)
	var clignote := create_tween().set_loops()
	clignote.tween_property(point, "modulate:a", 0.2, 0.3)
	clignote.tween_property(point, "modulate:a", 1.0, 0.3)
	# L'aile du blason (rouge), qui remplacera le plan une fois emboîtée
	var pivot: Vector2 = PIVOTS[aile_vue]
	var aile := _sprite(_texture(DOSSIER_BLASON + "blason_aile_" + aile_vue + ".png"), origine, calque)
	aile.modulate.a = 0.0
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.95, 0.8)
	flash.size = Vector2(TAILLE_SALLE)
	flash.modulate.a = 0.0
	calque.add_child(flash)

	# 2) Vu du ciel : on découvre le plan des salles parcourues
	t = create_tween()
	t.tween_property(_fondu, "modulate:a", 0.0, 1.0)
	await t.finished
	Etat.annoncer("Vu du ciel, les salles que tu as parcourues dessinent...")
	await get_tree().create_timer(2.6).timeout
	_jouer_son(SON_REVELATION)
	t = create_tween()
	t.tween_property(lisere, "modulate:a", 1.0, 0.5)
	Etat.annoncer("... une AILE ! L'entrée en est la racine, chaque plume en est une plume.")
	var pulse := create_tween().set_loops()
	pulse.tween_property(lisere, "modulate", Color(1.5, 1.4, 1.0), 0.5)
	pulse.tween_property(lisere, "modulate", Color(1, 1, 1), 0.5)
	await get_tree().create_timer(3.2).timeout

	# 3) On prend de la hauteur : le corps du donjon apparaît, l'aile s'en approche (encore à la verticale)
	var accroche := origine + pivot   # où la racine de l'aile s'emboîte sur le corps
	var petit := 0.62
	t = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(carte, "scale", Vector2(petit, petit), 1.6)
	t.parallel().tween_property(carte, "position", accroche + Vector2(18 if droite else -18, 22), 1.6)
	t.parallel().tween_property(socle, "modulate:a", 1.0, 1.6)
	Etat.annoncer("... et elle doit rejoindre le corps du donjon.")
	await t.finished
	await get_tree().create_timer(0.6).timeout

	# 4) L'aile pivote d'un quart de tour autour de sa racine et s'emboîte
	_jouer_son(SON_PIVOT)
	t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(carte, "rotation", PI / 2 if droite else -PI / 2, 1.2)
	# en pivotant, le plan prend la forme de l'aile du blason (plus court le long de l'épine, plumes plus longues)
	t.parallel().tween_property(carte, "scale", ECHELLE_AILE, 1.2)
	t.parallel().tween_property(carte, "position", accroche, 1.2)
	await t.finished

	# 5) Clac ! Éclair, secousse : le plan devient l'aile rouge du blason
	clignote.kill()
	pulse.kill()
	_jouer_son(SON_EMBOITE)
	_jouer_son(JINGLE_BLASON, -2.0)
	flash.modulate.a = 0.85
	t = create_tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.6)
	t.parallel().tween_property(carte, "modulate:a", 0.0, 0.8)
	t.parallel().tween_property(aile, "modulate:a", 1.0, 0.8)
	var secousse := create_tween()
	for i in 6:
		secousse.tween_property(calque, "offset", Vector2(randf_range(-3, 3), randf_range(-2, 2)), 0.04)
	secousse.tween_property(calque, "offset", Vector2.ZERO, 0.05)
	var autre := "gauche" if droite else "droite"
	if Etat.est("fragment_" + autre):
		Etat.annoncer("Les deux ailes ont rejoint le corps du donjon ! L'épreuve finale t'attend.")
	else:
		Etat.annoncer("L'aile " + aile_vue + " a rejoint le corps du donjon ! Il manque encore l'aile " + autre + ".")
	await get_tree().create_timer(4.5).timeout

	# 6) Fondu au noir, retour dans le vestibule (le corps du donjon n'est pas encore construit)
	t = create_tween()
	t.tween_property(_fondu, "modulate:a", 1.0, 0.6)
	await t.finished
	calque.queue_free()
	# Retour au village, devant le temple (la scène change : la musique et l'état sont rechargés)
	_changer_de_scene("@village:" + _temple(), Vector2i(12, 7), "Tu ressors du temple, l'aile à la main. Retourne voir le capitaine Aubrac !")


# --- HUD : les 5 plumes de l'aile, en haut à gauche ------------------------------------
# Une plume grise = pas encore obtenue ; dorée = obtenue. Le fragment d'aile s'ajoute à côté.
var _hud: CanvasLayer
var _icones_plumes: Array[Sprite2D] = []
var _icone_fragment: Sprite2D
const TEINTE_MANQUANTE := Color(0.12, 0.12, 0.18, 0.75)


func _creer_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 3
	add_child(_hud)
	var plume := _texture("res://Assets/Gemini/tuiles/plume_doree.png")
	for i in 5:
		var icone := _sprite(plume, Vector2(4 + i * 11, 3), _hud)
		_icones_plumes.append(icone)
	_icone_fragment = _sprite(_texture("res://Assets/Gemini/tuiles/fragment_aile.png"), Vector2(62, 1), _hud)
	if cote == "droite":   # l'aile droite = l'aile gauche dans un miroir
		_icone_fragment.flip_h = true
	_hud.visible = donjon and cote in ["gauche", "droite"]   # les plumes ne s'affichent que dans les ailes du donjon
	_maj_hud()


func _maj_hud() -> void:
	for i in 5:
		_icones_plumes[i].modulate = Color.WHITE if Etat.est(_plume(i + 1)) else TEINTE_MANQUANTE
	# plume 5 = le fragment (la plume 5 n'a pas de plume dorée : sa récompense est le fragment)
	if Etat.est("fragment_" + cote):
		_icones_plumes[4].modulate = Color.WHITE
	_icone_fragment.visible = Etat.est("fragment_" + cote)


# --- La STÈLE DU COQ (parvis) : les deux ailes s'y emboîtent, la forêt s'écarte, le corps du coq apparaît ---------
# Lancée par le passage "$stele" (ecran.gd), seulement quand le joueur MONTE vers la stèle.
# 1) les deux fragments volent du joueur vers la stèle ; 2) la terre tremble, la FORÊT S'ÉCARTE devant le héros et le
# corps du coq apparaît ; 3) vue MODE 7 (mode7.gd) : les bâtiments des deux ailes se soulèvent, pivotent et s'emboîtent
# sur le bâtiment du corps ; de haut, ils dessinent le coq ; 4) on revient au parvis, rechargé avec son plan « révélé ».
const STELE_CASE := Vector2i(12, 5)          # case de la stèle sur l'écran Parvis
const SON_GRONDEMENT := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact.wav"


func _ceremonie_stele() -> void:
	if en_transition or joueur.direction != "haut":
		return
	if Etat.est("corps_revele"):
		Etat.annoncer("La stèle porte les deux ailes du coq. Le corps du coq t'attend.")
		return
	if not (Etat.est("fragment_gauche") and Etat.est("fragment_droite")):
		var manque := 2 - int(Etat.est("fragment_gauche")) - int(Etat.est("fragment_droite"))
		Etat.annoncer("Un coq est gravé dans la pierre, ses deux ailes creusées en creux. Il en manque %d..." % manque)
		return
	en_transition = true
	joueur.set_physics_process(false)
	joueur.velocity = Vector2.ZERO
	var parvis: Ecran = null
	for e in get_children():
		if e is Ecran and e.name == "Parvis":
			parvis = e
	var stele := (parvis.position if parvis else Vector2.ZERO) + Vector2(STELE_CASE * Ecran.TUILE) + Vector2(8, -6)
	Etat.annoncer("Tu poses les deux ailes du blason dans la stèle...")
	if _musique:
		create_tween().tween_property(_musique, "volume_db", -30.0, 1.0)
	# 1) Les deux ailes s'envolent vers leurs empreintes
	var aile := _texture("res://Assets/Gemini/tuiles/fragment_aile.png")
	var ailes: Array[Sprite2D] = []
	var t := create_tween().set_parallel()
	for cote_aile in [-1, 1]:
		var sprite := Sprite2D.new()
		sprite.texture = aile
		sprite.flip_h = cote_aile > 0
		sprite.z_index = 5
		sprite.position = joueur.position + Vector2(cote_aile * 10, -14)
		add_child(sprite)
		ailes.append(sprite)
		t.tween_property(sprite, "position", stele + Vector2(cote_aile * 5, 0), 1.2).set_trans(Tween.TRANS_SINE)
		t.tween_property(sprite, "scale", Vector2(0.4, 0.4), 1.2)
	await t.finished
	for sprite in ailes:
		sprite.queue_free()
	_jouer_son(SON_EMBOITE)
	_jouer_son(JINGLE_BLASON, -2.0)
	# 2) La terre tremble... et la forêt s'écarte devant le héros : le corps du coq apparaît derrière
	Etat.annoncer("Clac ! La stèle s'illumine... la terre se met à trembler !")
	for i in 3:
		_jouer_son(SON_GRONDEMENT, -6.0)
		_secouer()
		await get_tree().create_timer(0.45).timeout
	if parvis is Exterieur:
		_jouer_son(SON_ENVOL, -4.0)
		parvis.ecarter_foret(Rect2i(7, 0, 12, 4), (STELE_CASE.x + 0.5) * Ecran.TUILE)   # arbres des colonnes 7-18, rangées 0-3
		parvis.faire_apparaitre("Z", Vector2i(8, 0))
		Etat.annoncer("La forêt s'écarte devant toi... Derrière, un immense bâtiment : le CORPS DU COQ !")
		for i in 4:
			_secouer()
			await get_tree().create_timer(0.6).timeout
		await get_tree().create_timer(1.2).timeout
	t = create_tween()
	t.tween_property(_fondu, "modulate:a", 1.0, 0.6)
	await t.finished
	# 3) Vue mode 7 : les deux ailes rejoignent le corps du coq
	var vue := Mode7.new()
	add_child(vue)
	_hud.visible = false
	t = create_tween()
	t.tween_property(_fondu, "modulate:a", 0.0, 0.8)
	await vue.jouer()
	t = create_tween()
	t.tween_property(_fondu, "modulate:a", 1.0, 0.8)
	await t.finished
	# 4) On revient au parvis : la forêt a disparu, le corps du coq se dresse
	Etat.noter("corps_revele")
	_changer_de_scene("@village:Parvis", Vector2i(12, 7), "La forêt s'est écartée : le CORPS DU COQ se dresse devant toi !")
