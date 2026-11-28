extends Node2D
class_name Decoration
# MODE DÉCORATION de la maison du héros : ouvert par un coup de lance sur la malle (malle_deco.gd), créé dans l'intérieur.
# Le héros est figé ; un curseur doré se promène sur les cases de la pièce.
#   Flèches / stick : déplacer le curseur      Espace / J / A : prendre le meuble sous le curseur, ou poser celui qu'on tient
#   Maj / K / B : sortir de la malle le décor suivant      R / Y : ranger dans la malle (celui qu'on tient, ou celui sous le curseur)
#   Échap / Start : fini (un meuble tenu retourne à sa place, sinon dans la malle)
# Souris / doigt : toucher une case = y aller + prendre/poser ; toucher une icône de la barre = prendre ce décor ; clic droit = ranger.
# Un meuble se pose sur le sol libre, jamais sur la porte, le joueur, un habitant ni une « case vitale » (voir interieur.gd::peut_poser).

const SON_POSER := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Accept.wav"
const SON_PRENDRE := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Move2.wav"
const SON_NON := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Cancel.wav"
const OR := Color(0.98, 0.84, 0.4)
const DELAI_1 := 0.28   # secondes avant que le curseur se répète quand on garde la flèche enfoncée
const DELAI_2 := 0.09

var _interieur: Interieur
var _curseur := Vector2i(12, 7)
var _main := -1                    # décor tenu (index dans Etat.decors), -1 = main vide
var _origine := Vector2i(-1, -1)   # d'où vient le meuble tenu (pour l'y remettre si on quitte)
var _fantome: Sprite2D
var _repete := 0.0
var _direction_tenue := Vector2i.ZERO
var _ui: CanvasLayer
var _barre: Panel
var _icones: Array = []            # [TextureRect, index du décor]
var _info: Label
var _fini := false


static func creer(interieur: Interieur) -> Decoration:
	var d := Decoration.new()
	d._interieur = interieur
	return d


func _ready() -> void:
	z_index = 20
	Etat.en_dialogue = true
	Etat.en_menu = true
	var joueur := get_tree().get_first_node_in_group("joueur")
	if joueur:
		joueur.set_physics_process(false)
		joueur.sprite.play("repos_" + joueur.direction)
		_curseur = Vector2i(((joueur.global_position - _interieur.position) / Ecran.TUILE).floor()) + Vector2i(0, -1)
	_fantome = Sprite2D.new()
	_fantome.centered = false
	_fantome.visible = false
	add_child(_fantome)
	_creer_ui()
	_jouer(SON_PRENDRE)
	# on commence la main pleine si un décor attend dans la malle
	_suivant()


# --- Interface (bandeau d'aide en haut, barre des décors en bas) ---------------------------------------

func _creer_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 5
	add_child(_ui)
	var haut := Panel.new()
	haut.position = Vector2(4, 4)
	haut.size = Vector2(392, 29)
	haut.add_theme_stylebox_override("panel", _style())
	_ui.add_child(haut)
	var aide := _label(Vector2(6, 1), Vector2(380, 26), 8, Color.WHITE)
	aide.text = "Flèches : bouger   Espace : prendre / poser   Maj : décor suivant de la malle\nR : ranger dans la malle   Échap : fini"
	haut.add_child(aide)
	_barre = Panel.new()
	_barre.add_theme_stylebox_override("panel", _style())
	_ui.add_child(_barre)
	_info = _label(Vector2(6, 2), Vector2(380, 12), 8, OR)
	_barre.add_child(_info)
	_maj_barre()


func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.16, 0.9)
	style.set_border_width_all(1)
	style.border_color = OR
	style.set_corner_radius_all(3)
	return style


func _label(pos: Vector2, taille: Vector2, police: int, couleur: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = taille
	l.add_theme_font_size_override("font_size", police)
	l.add_theme_color_override("font_color", couleur)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# Une icône par décor possédé : brillante s'il attend dans la malle, pâle s'il est déjà posé, cadre doré pour celui qu'on tient.
func _maj_barre() -> void:
	for i in _icones:
		i[0].get_parent().queue_free()
	_icones.clear()
	var n := Etat.decors.size()
	var par_rangee := 18
	var rangees := maxi(ceili(n / float(par_rangee)), 1)
	_barre.size = Vector2(392, 18 + rangees * 21)
	_barre.position = Vector2(4, 224 - 4 - _barre.size.y)
	for i in n:
		var d: Dictionary = Etat.decors[i]
		var case := Panel.new()
		case.position = Vector2(6 + (i % par_rangee) * 21, 15 + (i / par_rangee) * 21)
		case.size = Vector2(19, 19)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.16, 0.28, 0.9)
		style.set_border_width_all(1)
		style.border_color = OR if i == _main else Color(0.3, 0.32, 0.45)
		case.add_theme_stylebox_override("panel", style)
		case.gui_input.connect(_clic_icone.bind(i))
		_barre.add_child(case)
		var icone := TextureRect.new()
		icone.texture = _interieur._image(Decors.CATALOGUE[d["id"]]["image"])
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.position = Vector2(2, 2)
		icone.size = Vector2(15, 15)
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icone.modulate = Color(1, 1, 1, 0.4) if d["x"] >= 0 and i != _main else Color.WHITE
		case.add_child(icone)
		_icones.append([icone, i])
	var dans_malle := 0
	for d in Etat.decors:
		if d["x"] < 0:
			dans_malle += 1
	if _main >= 0:
		_info.text = "En main : %s" % Decors.CATALOGUE[Etat.decors[_main]["id"]]["nom"]
	elif n == 0:
		_info.text = "Aucun décor. Rosine en vend au village est !"
	else:
		_info.text = "Dans la malle : %d   (achète d'autres décors chez Rosine)" % dans_malle


# --- Le curseur et le meuble tenu ----------------------------------------------------------------------

func _process(delta: float) -> void:
	if _fini:
		return
	var dir := Vector2i(int(Input.get_axis("move_left", "move_right")), int(Input.get_axis("move_up", "move_down")))
	if dir != Vector2i.ZERO and dir.x != 0 and dir.y != 0:
		dir.y = 0   # une seule direction à la fois
	if dir != _direction_tenue:
		_direction_tenue = dir
		_repete = DELAI_1
		if dir != Vector2i.ZERO:
			_bouger(dir)
	elif dir != Vector2i.ZERO:
		_repete -= delta
		if _repete <= 0.0:
			_repete = DELAI_2
			_bouger(dir)
	queue_redraw()
	_maj_fantome()


func _bouger(dir: Vector2i) -> void:
	_curseur = (_curseur + dir).clamp(Vector2i(0, 0), Vector2i(24, 13))


func _emprise_main() -> Vector2i:
	return Decors.CATALOGUE[Etat.decors[_main]["id"]]["emprise"] if _main >= 0 else Vector2i.ONE


func _maj_fantome() -> void:
	if _main < 0:
		_fantome.visible = false
		return
	var def: Dictionary = Decors.CATALOGUE[Etat.decors[_main]["id"]]
	_fantome.texture = _interieur._image(def["image"])
	var emprise: Vector2i = def["emprise"]
	var taille := Vector2(_fantome.texture.get_size())
	_fantome.position = (Vector2((_curseur.x + emprise.x / 2.0) * Ecran.TUILE, (_curseur.y + emprise.y) * Ecran.TUILE) - Vector2(taille.x / 2.0, taille.y)).round()
	var ok := _interieur.peut_poser(_main, _curseur)
	var pulse := 0.65 + 0.2 * sin(Time.get_ticks_msec() / 160.0)
	_fantome.modulate = Color(0.8, 1.0, 0.8, pulse) if ok else Color(1.0, 0.45, 0.45, pulse)
	_fantome.visible = true


func _draw() -> void:
	var emprise := _emprise_main()
	var coin := _curseur
	if _main < 0:   # main vide : on encadre le meuble survolé (s'il y en a un)
		var i := _interieur.decor_en(_curseur)
		if i >= 0:
			emprise = Decors.CATALOGUE[Etat.decors[i]["id"]]["emprise"]
			coin = Vector2i(Etat.decors[i]["x"], Etat.decors[i]["y"])
	var couleur := OR
	if _main >= 0 and not _interieur.peut_poser(_main, _curseur):
		couleur = Color(1, 0.4, 0.4)
	couleur.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 140.0)
	var r := Rect2(Vector2(coin * Ecran.TUILE), Vector2(emprise * Ecran.TUILE))
	draw_rect(r.grow(1), couleur, false, 1.0)
	draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2)), Color(couleur, 0.12), true)


# --- Actions ---------------------------------------------------------------------------------------------

# Espace : poser ce qu'on tient, sinon prendre ce qui est sous le curseur.
func _action() -> void:
	if _main >= 0:
		if _interieur.peut_poser(_main, _curseur):
			Etat.decors[_main]["x"] = _curseur.x
			Etat.decors[_main]["y"] = _curseur.y
			_main = -1
			_origine = Vector2i(-1, -1)
			_appliquer()
			_jouer(SON_POSER)
			_bouffee(_curseur)
		else:
			_jouer(SON_NON)
		return
	var i := _interieur.decor_en(_curseur)
	if i >= 0:
		_prendre(i)
	else:
		_suivant()


func _prendre(i: int) -> void:
	if _main >= 0:   # on tenait déjà quelque chose : il retourne d'où il vient (ou dans la malle)
		_relacher()
	var d: Dictionary = Etat.decors[i]
	_origine = Vector2i(d["x"], d["y"])
	if d["x"] >= 0:
		_curseur = _origine
	d["x"] = -1
	d["y"] = -1
	_main = i
	_appliquer()
	_jouer(SON_PRENDRE)


# Maj : prendre dans la malle le décor suivant (celui qu'on tenait y retourne).
func _suivant() -> void:
	var depart := _main
	if _main >= 0:
		_relacher()
	var n := Etat.decors.size()
	for k in range(1, n + 1):
		var i := posmod(depart + k, n)
		if Etat.decors[i]["x"] < 0:
			_main = i
			_origine = Vector2i(-1, -1)
			_appliquer()
			_jouer(SON_PRENDRE)
			return
	_appliquer()


# R : ranger dans la malle.
func _ranger() -> void:
	if _main >= 0:
		_main = -1
		_origine = Vector2i(-1, -1)
	else:
		var i := _interieur.decor_en(_curseur)
		if i < 0:
			_jouer(SON_NON)
			return
		Etat.decors[i]["x"] = -1
		Etat.decors[i]["y"] = -1
	_appliquer()
	_jouer(SON_PRENDRE)


# Le meuble tenu retourne à sa place d'origine si elle est encore libre ; sinon il reste dans la malle.
func _relacher() -> void:
	if _main >= 0 and _origine.x >= 0 and _interieur.peut_poser(_main, _origine):
		Etat.decors[_main]["x"] = _origine.x
		Etat.decors[_main]["y"] = _origine.y
	_main = -1
	_origine = Vector2i(-1, -1)


func _appliquer() -> void:
	_interieur.poser_decors()
	_maj_barre()


# Petit nuage de poussière quand un meuble se pose.
func _bouffee(case: Vector2i) -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(case * Ecran.TUILE) + Vector2(_emprise_pose(case)) * Ecran.TUILE * Vector2(0.5, 1.0)
	p.amount = 10
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.5
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 24.0
	p.gravity = Vector2(0, 20)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.85, 0.78, 0.65, 0.7)
	_interieur.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _emprise_pose(case: Vector2i) -> Vector2i:
	var i := _interieur.decor_en(case)
	return Decors.CATALOGUE[Etat.decors[i]["id"]]["emprise"] if i >= 0 else Vector2i.ONE


func _fermer() -> void:
	if _fini:
		return
	_fini = true
	_relacher()
	_interieur.poser_decors()
	Etat.sauver()
	_jouer(SON_PRENDRE)
	_ui.visible = false
	_fantome.visible = false
	queue_redraw()
	# petit délai : la touche qui ferme ne doit pas donner un coup de lance
	await get_tree().create_timer(0.15).timeout
	Etat.en_dialogue = false
	Etat.en_menu = false
	var joueur := get_tree().get_first_node_in_group("joueur")
	if joueur:
		joueur.set_physics_process(true)
	queue_free()


func _exit_tree() -> void:
	if not _fini:   # (écran détruit pendant le mode : on rend la main au joueur)
		Etat.en_dialogue = false
		Etat.en_menu = false


# --- Entrées -------------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _fini:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_fermer()
	elif event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_action()
	elif event.is_action_pressed("run"):
		get_viewport().set_input_as_handled()
		_suivant()
	elif event.is_action_pressed("reset"):
		get_viewport().set_input_as_handled()
		_ranger()
	elif event is InputEventMouseButton and event.pressed:
		var ecran_pos: Vector2 = event.position
		if _barre.get_global_rect().has_point(ecran_pos):
			return   # (la barre gère ses propres clics)
		var case := Vector2i((get_global_mouse_position() - _interieur.position) / Ecran.TUILE)
		var emprise := _emprise_main()
		_curseur = (case - (emprise - Vector2i.ONE) / 2).clamp(Vector2i(0, 0), Vector2i(24, 13))
		get_viewport().set_input_as_handled()
		if event.button_index == MOUSE_BUTTON_LEFT:
			_action()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_ranger()


func _clic_icone(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not _fini:
		if i == _main:
			_ranger()
		else:
			_prendre(i)


func _jouer(chemin: String) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -10.0
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
