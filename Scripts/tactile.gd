class_name Tactile
extends CanvasLayer
## Contrôles tactiles (mobile) : un joystick flottant à gauche, 3 boutons à droite.
## Rien n'est affiché sur un appareil sans écran tactile, ni après l'appui d'une touche du clavier.
## Principe : on fabrique de VRAIS événements d'action (move_left, attack...) :
## le reste du jeu (joueur, dialogues, choix) ne voit aucune différence avec le clavier.

const RAYON_STICK := 34.0       # distance max de la manette (pixels de l'écran 400x224)
const ZONE_MORTE := 0.25        # en dessous, on ne bouge pas
const BOUTONS := {              # nom -> [action, centre, rayon, texte]
	"A": ["attack", Vector2(-40, -42), 22.0, "A"],
	"B": ["run", Vector2(-84, -26), 17.0, "B"],
	"R": ["reset", Vector2(-24, 26), 11.0, "R"],
}

var _dessin: Control
var _stick_doigt := -1          # index du doigt qui tient le joystick (-1 = aucun)
var _stick_centre := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _doigts_boutons := {}       # index du doigt -> nom du bouton
var _etat_actions := {}         # action -> appuyée ou non (pour ne pas envoyer deux fois le même événement)
var _forces := {}               # action -> dernière force envoyée


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dessin = Control.new()
	_dessin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dessin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dessin.draw.connect(_dessiner)
	add_child(_dessin)
	visible = DisplayServer.is_touchscreen_available()


func _exit_tree() -> void:
	# on relâche tout si la couche disparaît (changement de scène)
	for action in _etat_actions.keys():
		_envoyer(action, false)


func _input(event: InputEvent) -> void:
	# un joueur qui utilise le clavier ne veut pas voir les boutons
	if event is InputEventKey and event.pressed and visible:
		visible = false
		_tout_relacher()
		return
	if event is InputEventScreenTouch:
		visible = true
		if event.pressed:
			_appui(event.index, event.position)
		else:
			_relache(event.index)
	elif event is InputEventScreenDrag:
		if event.index == _stick_doigt:
			_stick_pos = _limiter(event.position - _stick_centre)
			_appliquer_stick()
			_dessin.queue_redraw()


## Position réelle d'un bouton (les valeurs de BOUTONS sont relatives au coin bas-droit).
func _centre_bouton(nom: String) -> Vector2:
	var taille := get_viewport().get_visible_rect().size
	var b: Array = BOUTONS[nom]
	var c: Vector2 = b[1]
	# le bouton R (recommencer) est en haut à droite, A et B en bas à droite
	if nom == "R":
		return Vector2(taille.x + c.x, c.y)
	return taille + c


func _appui(doigt: int, pos: Vector2) -> void:
	# 1) un bouton ?
	for nom in BOUTONS.keys():
		var rayon: float = BOUTONS[nom][2] + 6.0   # un peu de marge pour les gros doigts
		if pos.distance_to(_centre_bouton(nom)) <= rayon:
			_doigts_boutons[doigt] = nom
			_envoyer(BOUTONS[nom][0], true)
			_dessin.queue_redraw()
			return
	# 2) sinon, moitié gauche de l'écran = joystick flottant (centré où le doigt se pose)
	if _stick_doigt == -1 and pos.x < get_viewport().get_visible_rect().size.x * 0.5:
		_stick_doigt = doigt
		_stick_centre = pos
		_stick_pos = Vector2.ZERO
		_dessin.queue_redraw()
	# 3) un appui ailleurs sert à avancer un dialogue : on simule « attack » le temps d'un appui
	elif Etat.en_dialogue:
		_impulsion("attack")


func _relache(doigt: int) -> void:
	if doigt == _stick_doigt:
		_stick_doigt = -1
		_stick_pos = Vector2.ZERO
		_appliquer_stick()
	elif _doigts_boutons.has(doigt):
		_envoyer(BOUTONS[_doigts_boutons[doigt]][0], false)
		_doigts_boutons.erase(doigt)
	_dessin.queue_redraw()


func _tout_relacher() -> void:
	_stick_doigt = -1
	_stick_pos = Vector2.ZERO
	_appliquer_stick()
	for doigt in _doigts_boutons.keys():
		_envoyer(BOUTONS[_doigts_boutons[doigt]][0], false)
	_doigts_boutons.clear()
	_dessin.queue_redraw()


func _limiter(v: Vector2) -> Vector2:
	return v.limit_length(RAYON_STICK)


## Traduit la position de la manette en 4 actions de déplacement (force analogique).
func _appliquer_stick() -> void:
	var v := _stick_pos / RAYON_STICK
	_envoyer("move_left", v.x < -ZONE_MORTE, -v.x)
	_envoyer("move_right", v.x > ZONE_MORTE, v.x)
	_envoyer("move_up", v.y < -ZONE_MORTE, -v.y)
	_envoyer("move_down", v.y > ZONE_MORTE, v.y)


## Envoie un événement d'action seulement si l'état change (ou si la force change).
func _envoyer(action: String, appuyee: bool, force: float = 1.0) -> void:
	var etait: bool = _etat_actions.get(action, false)
	if not appuyee and not etait:
		return
	if appuyee and etait and is_equal_approx(float(_forces.get(action, 1.0)), force):
		return
	_etat_actions[action] = appuyee
	_forces[action] = force
	var e := InputEventAction.new()
	e.action = action
	e.pressed = appuyee
	e.strength = clampf(force, 0.0, 1.0) if appuyee else 0.0
	Input.parse_input_event(e)


## Un appui bref (pour avancer un dialogue sans bouton).
func _impulsion(action: String) -> void:
	_envoyer(action, true)
	await get_tree().create_timer(0.08).timeout
	_envoyer(action, false)


func _dessiner() -> void:
	if not visible:
		return
	# joystick (seulement quand un doigt le tient)
	if _stick_doigt != -1:
		_dessin.draw_circle(_stick_centre, RAYON_STICK, Color(1, 1, 1, 0.10))
		_dessin.draw_arc(_stick_centre, RAYON_STICK, 0, TAU, 32, Color(1, 1, 1, 0.35), 1.5)
		_dessin.draw_circle(_stick_centre + _stick_pos, 12.0, Color(1, 1, 1, 0.35))
	# boutons
	for nom in BOUTONS.keys():
		var b: Array = BOUTONS[nom]
		var c := _centre_bouton(nom)
		var enfonce := _doigts_boutons.values().has(nom)
		var fond := Color(1, 0.85, 0.3, 0.45) if enfonce else Color(1, 1, 1, 0.16)
		_dessin.draw_circle(c, b[2], fond)
		_dessin.draw_arc(c, b[2], 0, TAU, 28, Color(1, 1, 1, 0.45), 1.5)
		var police := ThemeDB.fallback_font
		var t: String = b[3]
		var taille_t := int(b[2] * 0.9)
		var l := police.get_string_size(t, HORIZONTAL_ALIGNMENT_CENTER, -1, taille_t)
		_dessin.draw_string(police, c + Vector2(-l.x * 0.5, taille_t * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, taille_t, Color(1, 1, 1, 0.8))
