class_name Pause
extends CanvasLayer
## MENU PAUSE (créé par world.gd). Ouvert par l'action « pause » : Échap ou P au clavier, Start à la manette, bouton « II » à l'écran tactile.
## Le jeu est gelé (get_tree().paused) ; ce menu, lui, continue de tourner (process_mode = ALWAYS).
## Entrées : Reprendre / Recommencer l'énigme et Un indice (ailes du donjon seulement) / Sauvegarder / Charger / Carte / Options / Quitter.
## SAUVEGARDER écrit une sauvegarde MANUELLE (fichier à part) ; CHARGER la recharge (après confirmation). La sauvegarde automatique continue à côté.
## OPTIONS : volume général, volume de la musique (reglages.gd), puis les pages Commandes et Crédits (credits.gd).
## Navigation : haut/bas (flèches, ZQSD, stick, croix), gauche/droite pour les volumes, valider = Espace/J/Entrée/A, retour = Échap/B ; la souris et le doigt marchent aussi.

enum Page { FERMEE, MENU, CARTE, COMMANDES, CONFIRMER, OPTIONS, CREDITS }

const SON_CHOIX := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Move2.wav"
const SON_VALIDER := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Accept.wav"
const SON_RETOUR := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Cancel.wav"
const OR := Color(0.98, 0.84, 0.4)
const GRIS := Color(0.5, 0.52, 0.62)
const TEXTE_AIDE := "Échap / Start : reprendre"
const DELAI_STICK := 180   # millisecondes entre deux déplacements quand on pousse le stick (sinon il défile trop vite)
const VITESSE_CREDITS := 11.0   # pixels par seconde : les crédits défilent doucement tout seuls

const COMMANDES := [
	["Se déplacer", "flèches ou ZQSD", "stick ou croix"],
	["Lance : frapper, parler", "Espace ou J", "A ou X"],
	["Courir", "Maj ou K", "B, RB ou gâchette"],
	["Recommencer la salle", "R", "Y"],
	["Pause", "Échap ou P", "Start"],
]
# Les lignes de la page Options : [identifiant, texte]. « general » et « musique » sont des curseurs de volume.
const LIGNES_OPTIONS := [["general", "Volume général"], ["musique", "Musique"], ["commandes", "Commandes"], ["credits", "Crédits"]]

var _monde: Node
var _page := Page.FERMEE
var _choix := 0
var _ids: Array[String] = []        # les entrées du menu (« reprendre », « carte »...)
var _textes: Array[String] = []     # le texte de chaque entrée, sans la flèche
var _labels: Array[Label] = []
var _fond: ColorRect
var _menu: Panel
var _aide: Label                    # ligne du bas du menu : rappel des touches, ou message (« Partie sauvegardée ! »)
var _commandes: Panel
var _confirmation: Panel
var _conf_labels: Array[Label] = []
var _conf := 0                      # 0 = Non, 1 = Oui
var _options: Panel
var _opt := 0                       # ligne choisie dans la page Options
var _opt_noms: Array[Label] = []
var _opt_segments: Array = []       # pour chaque curseur : ses 10 petits rectangles
var _credits: Panel
var _credits_texte: Label
var _defil := 0.0
var _carte: Carte
var _dernier_stick := 0
var _fermeture := false
var _numero_info := 0               # pour n'effacer un message que s'il n'a pas été remplacé entre-temps


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
	_creer_options()
	_creer_commandes()
	_creer_credits()
	_creer_confirmation()
	_carte = Carte.new()
	_carte.visible = false
	add_child(_carte)


func _exit_tree() -> void:
	Etat.en_pause = false   # (changement de scène pendant la pause)
	if is_inside_tree() and get_tree().paused:
		get_tree().paused = false


func _process(delta: float) -> void:
	if _page == Page.CREDITS:   # les crédits défilent tout seuls
		_defiler(VITESSE_CREDITS * delta)


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


func _ajouter(id: String, texte: String) -> void:
	_ids.append(id)
	_textes.append(texte)


func _creer_menu() -> void:
	_ajouter("reprendre", "Reprendre")
	if _monde.donjon and _monde.cote in ["gauche", "droite"]:   # (sans objet au village)
		_ajouter("recommencer", "Recommencer l'énigme")   # = la touche R / le bouton Y
		_ajouter("indice", "Un indice")                    # = l'anneau doré, tout de suite
	_ajouter("sauver", "Sauvegarder")
	_ajouter("charger", "Charger")
	_ajouter("carte", "Carte")
	_ajouter("options", "Options")
	if not OS.has_feature("web"):   # (dans un navigateur on ferme l'onglet : pas de bouton Quitter)
		_ajouter("quitter", "Quitter le jeu")
	var hauteur := 52 + _ids.size() * 19
	_menu = Panel.new()
	_menu.size = Vector2(176, hauteur)
	_menu.position = Vector2(112, (224 - hauteur) / 2)
	_menu.add_theme_stylebox_override("panel", _style())
	add_child(_menu)
	var titre := _etiquette(_menu, Vector2(0, 6), Vector2(176, 16), "PAUSE", OR, 12)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in _ids.size():
		var l := _etiquette(_menu, Vector2(14, 28 + i * 19), Vector2(150, 18), _textes[i], Color.WHITE, 11)
		l.mouse_filter = Control.MOUSE_FILTER_STOP   # cliquable / touchable
		l.gui_input.connect(_clic_entree.bind(i))
		_labels.append(l)
	_aide = _etiquette(_menu, Vector2(0, hauteur - 18), Vector2(176, 14), TEXTE_AIDE, Color(0.6, 0.62, 0.75), 8)
	_aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_maj_choix()


# Page Options : deux curseurs de volume (10 crans) puis deux sous-pages.
func _creer_options() -> void:
	_options = Panel.new()
	_options.size = Vector2(280, 150)
	_options.position = Vector2(60, 37)
	_options.add_theme_stylebox_override("panel", _style())
	_options.visible = false
	add_child(_options)
	var titre := _etiquette(_options, Vector2(0, 6), Vector2(280, 16), "OPTIONS", OR, 12)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in LIGNES_OPTIONS.size():
		var y := 34 + i * 25
		var nom := _etiquette(_options, Vector2(14, y), Vector2(120, 18), LIGNES_OPTIONS[i][1], Color.WHITE, 11)
		nom.mouse_filter = Control.MOUSE_FILTER_STOP
		nom.gui_input.connect(_clic_option.bind(i, 0))
		_opt_noms.append(nom)
		if i < 2:   # curseur : « − » [10 crans] « + »
			var moins := _etiquette(_options, Vector2(138, y), Vector2(14, 18), "−", OR, 13)
			moins.mouse_filter = Control.MOUSE_FILTER_STOP
			moins.gui_input.connect(_clic_option.bind(i, -1))
			var plus := _etiquette(_options, Vector2(258, y), Vector2(14, 18), "+", OR, 13)
			plus.mouse_filter = Control.MOUSE_FILTER_STOP
			plus.gui_input.connect(_clic_option.bind(i, 1))
			var crans := []
			for k in Reglages.NIVEAU_MAX:
				var c := ColorRect.new()
				c.position = Vector2(153 + k * 10, y + 4)
				c.size = Vector2(8, 10)
				c.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_options.add_child(c)
				crans.append(c)
			_opt_segments.append(crans)
	var aide := _etiquette(_options, Vector2(0, 132), Vector2(280, 14), "◀ ▶ : régler    Échap / B : retour", Color(0.6, 0.62, 0.75), 8)
	aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_maj_options()


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


# Page Crédits : le texte de credits.gd défile dans une fenêtre (tout seul, ou avec haut / bas).
func _creer_credits() -> void:
	_credits = Panel.new()
	_credits.position = Vector2(40, 14)
	_credits.size = Vector2(320, 196)
	_credits.add_theme_stylebox_override("panel", _style())
	_credits.visible = false
	add_child(_credits)
	var titre := _etiquette(_credits, Vector2(0, 6), Vector2(320, 16), "CRÉDITS", OR, 12)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var zone := Control.new()
	zone.position = Vector2(12, 28)
	zone.size = Vector2(296, 144)
	zone.clip_contents = true
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_credits.add_child(zone)
	_credits_texte = _etiquette(zone, Vector2.ZERO, Vector2(296, 10), Credits.texte(), Color(0.88, 0.9, 1.0), 10)
	_credits_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credits_texte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var aide := _etiquette(_credits, Vector2(0, 176), Vector2(320, 14), "◀ ▶ : défiler    Échap / B : retour", Color(0.6, 0.62, 0.75), 8)
	aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


# Petite fenêtre « Charger la sauvegarde ? » avec Non / Oui (Non est choisi au départ : on ne perd rien par erreur).
func _creer_confirmation() -> void:
	_confirmation = Panel.new()
	_confirmation.size = Vector2(250, 92)
	_confirmation.position = Vector2(75, 66)
	_confirmation.add_theme_stylebox_override("panel", _style())
	_confirmation.visible = false
	add_child(_confirmation)
	var question := _etiquette(_confirmation, Vector2(10, 8), Vector2(230, 40), "Charger la sauvegarde ? Ce qui a été fait depuis sera perdu.", Color.WHITE, 10)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in 2:
		var l := _etiquette(_confirmation, Vector2(40 + i * 100, 58), Vector2(80, 18), "Non" if i == 0 else "Oui", Color.WHITE, 11)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		l.gui_input.connect(_clic_confirmation.bind(i))
		_conf_labels.append(l)
	_maj_confirmation()


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
	_aller(Page.MENU)
	_maj_choix()
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
	_menu.visible = page == Page.MENU or page == Page.CONFIRMER
	_options.visible = page == Page.OPTIONS
	_commandes.visible = page == Page.COMMANDES
	_credits.visible = page == Page.CREDITS
	_confirmation.visible = page == Page.CONFIRMER
	_carte.visible = page == Page.CARTE
	_fond.color = Color(0, 0, 0, 0.93) if page == Page.CARTE else Color(0, 0, 0, 0.62)
	if page == Page.CARTE:
		_carte.ouvrir(_monde)
	if page == Page.CONFIRMER:
		_conf = 0
		_maj_confirmation()
	if page == Page.MENU:
		_maj_choix()
	if page == Page.OPTIONS:
		_maj_options()
	if page == Page.CREDITS:
		_defil = 0.0
		_defiler(0.0)


func _maj_choix() -> void:
	for i in _labels.size():
		_labels[i].text = ("▶ " if i == _choix else "    ") + _textes[i]
		var couleur := OR if i == _choix else Color.WHITE
		if _ids[i] == "charger" and not Etat.a_sauvegarde_manuelle():
			couleur = Color(0.78, 0.65, 0.3) if i == _choix else GRIS   # pas de sauvegarde manuelle : grisé
		_labels[i].add_theme_color_override("font_color", couleur)


func _maj_confirmation() -> void:
	for i in _conf_labels.size():
		_conf_labels[i].text = ("▶ " if i == _conf else "") + ("Non" if i == 0 else "Oui")
		_conf_labels[i].add_theme_color_override("font_color", OR if i == _conf else Color.WHITE)


# Options : la flèche devant la ligne choisie, et les crans allumés selon le volume.
func _maj_options() -> void:
	for i in LIGNES_OPTIONS.size():
		_opt_noms[i].text = ("▶ " if i == _opt else "    ") + LIGNES_OPTIONS[i][1]
		_opt_noms[i].add_theme_color_override("font_color", OR if i == _opt else Color.WHITE)
	for i in _opt_segments.size():
		var niveau := Reglages.niveau(LIGNES_OPTIONS[i][0])
		for k in _opt_segments[i].size():
			_opt_segments[i][k].color = OR if k < niveau else Color(0.22, 0.24, 0.36)


# Change un volume de `pas` crans (la ligne n'est un curseur que pour « general » et « musique »).
func _regler_volume(i: int, pas: int) -> void:
	if i > 1:
		return
	var avant := Reglages.niveau(LIGNES_OPTIONS[i][0])
	var apres := Reglages.changer(LIGNES_OPTIONS[i][0], pas)
	_maj_options()
	if apres != avant:
		_son(SON_CHOIX)   # (petit bruit pour entendre le nouveau volume général)


# Fait défiler les crédits de `dy` pixels (jamais plus loin que le bout du texte).
func _defiler(dy: float) -> void:
	var haut := maxf(_credits_texte.get_minimum_size().y - 144.0 + 10.0, 0.0)
	_defil = clampf(_defil + dy, 0.0, haut)
	_credits_texte.position.y = -_defil


# Un message à la place du rappel des touches (disparaît après 2 s).
func _info(texte: String) -> void:
	_numero_info += 1
	var mon_numero := _numero_info
	_aide.text = texte
	_aide.add_theme_color_override("font_color", OR)
	await get_tree().create_timer(2.0).timeout
	if mon_numero == _numero_info:
		_aide.text = TEXTE_AIDE
		_aide.add_theme_color_override("font_color", Color(0.6, 0.62, 0.75))


func _valider() -> void:
	match _ids[_choix]:
		"reprendre":
			fermer()
		"recommencer":
			await fermer()   # on relance le jeu d'abord, puis la salle est recommencée comme avec la touche R
			_monde.recommencer_salle()
		"indice":
			await fermer()   # idem : le jeu repart, puis l'anneau doré pulse sur ce qu'il faut frapper / ouvrir
			_monde.demander_indice()
		"sauver":
			if _monde.sauvegarder_partie():
				_son(SON_VALIDER)
				_info("Partie sauvegardée !")
				_maj_choix()   # « Charger » n'est plus grisé
			else:
				_son(SON_RETOUR)
				_info("Sauvegarde impossible.")
		"charger":
			if Etat.a_sauvegarde_manuelle():
				_aller(Page.CONFIRMER)
				_son(SON_VALIDER)
			else:
				_son(SON_RETOUR)
				_info("Aucune sauvegarde manuelle.")
		"carte":
			_aller(Page.CARTE)
			_son(SON_VALIDER)
		"options":
			_opt = 0
			_aller(Page.OPTIONS)
			_son(SON_VALIDER)
		"quitter":
			Etat.sauver()
			get_tree().quit()


func _valider_option() -> void:
	match LIGNES_OPTIONS[_opt][0]:
		"commandes":
			_aller(Page.COMMANDES)
			_son(SON_VALIDER)
		"credits":
			_aller(Page.CREDITS)
			_son(SON_VALIDER)
		_:
			_regler_volume(_opt, 1)   # valider sur un curseur = un cran de plus


func _valider_confirmation() -> void:
	if _conf == 1:
		await fermer()
		_monde.charger_partie()
	else:
		_retour()


func _retour() -> void:
	match _page:
		Page.MENU:
			fermer()
		Page.COMMANDES, Page.CREDITS:
			_aller(Page.OPTIONS)
			_son(SON_RETOUR)
		_:   # carte, options, confirmation : retour au menu
			_aller(Page.MENU)
			_son(SON_RETOUR)


func _clic_entree(event: InputEvent, i: int) -> void:
	if _page == Page.MENU and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_choix = i
		_maj_choix()
		_valider()


func _clic_option(event: InputEvent, i: int, pas: int) -> void:
	if _page != Page.OPTIONS or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	_opt = i
	if pas != 0:
		_regler_volume(i, pas)
	elif i > 1:
		_valider_option()
	_maj_options()


func _clic_confirmation(event: InputEvent, i: int) -> void:
	if _page == Page.CONFIRMER and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_conf = i
		_maj_confirmation()
		_valider_confirmation()


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
	var bas := event.is_action_pressed("move_down") or event.is_action_pressed("ui_down")
	var haut := event.is_action_pressed("move_up") or event.is_action_pressed("ui_up")
	var droite := event.is_action_pressed("move_right") or event.is_action_pressed("ui_right")
	var gauche := event.is_action_pressed("move_left") or event.is_action_pressed("ui_left")
	var valide := event.is_action_pressed("attack") or event.is_action_pressed("ui_accept")
	match _page:
		Page.MENU:
			if (bas or haut) and _stick_ok(event):
				_choix = posmod(_choix + (1 if bas else -1), _ids.size())
				_maj_choix()
				_son(SON_CHOIX)
			elif valide:
				_valider()
		Page.OPTIONS:
			if (bas or haut) and _stick_ok(event):
				_opt = posmod(_opt + (1 if bas else -1), LIGNES_OPTIONS.size())
				_maj_options()
				_son(SON_CHOIX)
			elif (droite or gauche) and _stick_ok(event):
				_regler_volume(_opt, 1 if droite else -1)
			elif valide:
				_valider_option()
		Page.CREDITS:
			if bas or droite:
				_defiler(16.0)
			elif haut or gauche:
				_defiler(-16.0)
			elif valide:
				_retour()
		Page.CONFIRMER:
			if (bas or haut or droite or gauche) and _stick_ok(event):
				_conf = 1 - _conf
				_maj_confirmation()
				_son(SON_CHOIX)
			elif valide:
				_valider_confirmation()
		_:
			if valide:
				_retour()   # carte, commandes : un appui revient


# Un clic / un appui sur une page sans bouton (carte, commandes, crédits) revient en arrière.
func _input(event: InputEvent) -> void:
	if _page in [Page.CARTE, Page.COMMANDES, Page.CREDITS] and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
