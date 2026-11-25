class_name Pause
extends CanvasLayer
## MENU PAUSE (créé par world.gd). Ouvert par l'action « pause » : Échap ou P au clavier, Start à la manette, bouton « II » à l'écran tactile.
## Le jeu est gelé (get_tree().paused) ; ce menu, lui, continue de tourner (process_mode = ALWAYS).
## Pages : le menu (Reprendre / Carte / Commandes / Quitter), la carte (carte.gd) et la liste des commandes.
## Navigation : haut/bas (flèches, ZQSD, stick, croix), valider = Espace/J/Entrée/A, retour = Échap/B ; la souris et le doigt marchent aussi.

enum Page { FERMEE, MENU, CARTE, COMMANDES }

const SON_CHOIX := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Move2.wav"
const SON_VALIDER := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Accept.wav"
const SON_RETOUR := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Cancel.wav"
const OR := Color(0.98, 0.84, 0.4)
const DELAI_STICK := 180   # millisecondes entre deux déplacements quand on pousse le stick (sinon il défile trop vite)

const COMMANDES := [
	["Se déplacer", "flèches ou ZQSD", "stick ou croix"],
	["Lance : frapper, parler", "Espace ou J", "A ou X"],
	["Courir", "Maj ou K", "B, RB ou gâchette"],
	["Recommencer la salle", "R", "Y"],
	["Pause", "Échap ou P", "Start"],
]

var _monde: Node
var _page := Page.FERMEE
var _choix := 0
var _ids: Array[String] = []        # les entrées du menu (« reprendre », « carte »...)
var _labels: Array[Label] = []
var _textes: Array[String] = []     # le texte de chaque entrée, sans la flèche
var _fond: ColorRect
var _menu: Panel
var _commandes: Panel
var _carte: Carte
var _dernier_stick := 0
var _fermeture := false


static func creer(monde: Node) -> Pause:
	var p := Pause.new()
	p._monde = monde
	return p


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_fond = ColorRect.new()
	_fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fond)
	_creer_menu()
	_creer_commandes()
	_carte = Carte.new()
	_carte.visible = false
	add_child(_carte)


func _exit_tree() -> void:
	Etat.en_pause = false   # (changement de scène pendant la pause)
	if is_inside_tree() and get_tree().paused:
		get_tree().paused = false


# --- Construction ------------------------------------------------------------------------------------

func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.16, 0.96)
	style.set_border_width_all(2)
	style.border_color = OR
	style.set_corner_radius_all(3)
	return style


func _etiquette(parent: Control, pos: Vector2, taille: Vector2, texte: String, couleur: Color, corps := 11) -> Label:
	var e := Label.new()
	e.position = pos
	e.size = taille
	e.text = texte
	e.add_theme_font_size_override("font_size", corps)
	e.add_theme_color_override("font_color", couleur)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(e)
	return e


func _creer_menu() -> void:
	_ids = ["reprendre", "carte", "commandes"]
	_textes = ["Reprendre", "Carte", "Commandes"]
	if not OS.has_feature("web"):   # (dans un navigateur on ferme l'onglet : pas de bouton Quitter)
		_ids.append("quitter")
		_textes.append("Quitter le jeu")
	var hauteur := 52 + _ids.size() * 22
	_menu = Panel.new()
	_menu.size = Vector2(150, hauteur)
	_menu.position = Vector2(125, (224 - hauteur) / 2)
	_menu.add_theme_stylebox_override("panel", _style())
	add_child(_menu)
	var titre := _etiquette(_menu, Vector2(0, 8), Vector2(150, 16), "PAUSE", OR, 12)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in _ids.size():
		var l := _etiquette(_menu, Vector2(16, 34 + i * 22), Vector2(120, 18), _textes[i], Color.WHITE, 11)
		l.mouse_filter = Control.MOUSE_FILTER_STOP   # cliquable / touchable
		l.gui_input.connect(_clic_entree.bind(i))
		_labels.append(l)
	var aide := _etiquette(_menu, Vector2(0, hauteur - 18), Vector2(150, 14), "Échap / Start : reprendre", Color(0.6, 0.62, 0.75), 8)
	aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_maj_choix()


func _creer_commandes() -> void:
	_commandes = Panel.new()
	_commandes.position = Vector2(14, 26)
	_commandes.size = Vector2(372, 172)
	_commandes.add_theme_stylebox_override("panel", _style())
	_commandes.visible = false
	add_child(_commandes)
	var titre := _etiquette(_commandes, Vector2(0, 8), Vector2(372, 16), "COMMANDES", OR, 12)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_etiquette(_commandes, Vector2(130, 30), Vector2(110, 14), "Clavier", OR, 9)
	_etiquette(_commandes, Vector2(262, 30), Vector2(100, 14), "Manette", OR, 9)
	for i in COMMANDES.size():
		var y := 50 + i * 20
		_etiquette(_commandes, Vector2(14, y), Vector2(116, 16), COMMANDES[i][0], Color.WHITE, 10)
		_etiquette(_commandes, Vector2(130, y), Vector2(130, 16), COMMANDES[i][1], Color(0.85, 0.88, 1.0), 10)
		_etiquette(_commandes, Vector2(262, y), Vector2(104, 16), COMMANDES[i][2], Color(0.85, 0.88, 1.0), 10)
	var tactile := _etiquette(_commandes, Vector2(0, 152), Vector2(372, 14), "Sur écran tactile : joystick à gauche, boutons A, B, R et II à droite.", Color(0.6, 0.62, 0.75), 8)
	tactile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


# --- Ouvrir / fermer / changer de page -----------------------------------------------------------------

func _peut_ouvrir() -> bool:
	if _monde == null or _monde.en_transition or Etat.en_dialogue:
		return false
	if _monde._menu_dev != null and _monde._menu_dev.visible:   # menu développeur (F1) ouvert
		return false
	for enfant in _monde.get_children():
		if enfant is EditeurDecor and enfant.actif:   # éditeur de décor (F2) : Échap lui sert déjà
			return false
	return true


func ouvrir() -> void:
	if _page != Page.FERMEE or _fermeture or not _peut_ouvrir():
		return
	Etat.en_pause = true
	get_tree().paused = true
	visible = true
	_choix = 0
	_maj_choix()
	_aller(Page.MENU)
	_son(SON_VALIDER)


func fermer() -> void:
	if _page == Page.FERMEE or _fermeture:
		return
	_fermeture = true
	_page = Page.FERMEE
	visible = false
	_son(SON_RETOUR)
	# Petit délai avant de relancer le jeu : la touche qui ferme le menu (Espace = lance) ne doit pas frapper aussitôt.
	await get_tree().create_timer(0.12).timeout
	get_tree().paused = false
	Etat.en_pause = false
	_fermeture = false


func _aller(page: Page) -> void:
	_page = page
	_menu.visible = page == Page.MENU
	_commandes.visible = page == Page.COMMANDES
	_carte.visible = page == Page.CARTE
	_fond.color = Color(0, 0, 0, 0.93) if page == Page.CARTE else Color(0, 0, 0, 0.62)
	if page == Page.CARTE:
		_carte.ouvrir(_monde)


func _maj_choix() -> void:
	for i in _labels.size():
		_labels[i].text = ("▶ " if i == _choix else "    ") + _textes[i]
		_labels[i].add_theme_color_override("font_color", OR if i == _choix else Color.WHITE)


func _valider() -> void:
	match _ids[_choix]:
		"reprendre":
			fermer()
		"carte":
			_aller(Page.CARTE)
			_son(SON_VALIDER)
		"commandes":
			_aller(Page.COMMANDES)
			_son(SON_VALIDER)
		"quitter":
			Etat.sauver()
			get_tree().quit()


func _retour() -> void:
	if _page == Page.MENU:
		fermer()
	else:
		_aller(Page.MENU)
		_son(SON_RETOUR)


func _clic_entree(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_choix = i
		_maj_choix()
		_valider()


# --- Entrées -------------------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _page == Page.FERMEE:
		if event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			ouvrir()
		return
	# page ouverte : on garde toutes les touches pour le menu
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventAction:
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_retour()
		return
	if _page == Page.MENU:
		var bas := event.is_action_pressed("move_down") or event.is_action_pressed("ui_down")
		var haut := event.is_action_pressed("move_up") or event.is_action_pressed("ui_up")
		if (bas or haut) and _stick_ok(event):
			_choix = posmod(_choix + (1 if bas else -1), _ids.size())
			_maj_choix()
			_son(SON_CHOIX)
		elif event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
			_valider()
	elif event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		_retour()   # carte, commandes : un appui revient au menu


# Un clic / un appui sur une page sans bouton (carte, commandes) revient au menu.
func _input(event: InputEvent) -> void:
	if _page in [Page.CARTE, Page.COMMANDES] and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_retour()


# Le stick envoie des dizaines d'événements par seconde : on limite la vitesse de défilement (touches et croix : aucune limite).
func _stick_ok(event: InputEvent) -> bool:
	if not event is InputEventJoypadMotion:
		return true
	var maintenant := Time.get_ticks_msec()
	if maintenant - _dernier_stick < DELAI_STICK:
		return false
	_dernier_stick = maintenant
	return true


func _son(chemin: String) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -12.0
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
