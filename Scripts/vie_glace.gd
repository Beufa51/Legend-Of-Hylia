extends Node2D
class_name VieGlace
# VIE D'UNE SALLE DE GLACE (posée par room.gd dans toute salle qui contient de la glace `i`) :
# - GIVRE (neige + petits glaçons) sur le haut des faces de mur, avec des gouttes qui tombent ;
# - CONGÈRES de neige au pied des murs, aux deux bouts du quai ;
# - ÉTINCELLES de givre qui scintillent sur la glace ; BUÉE froide qui dérive lentement.
# Aucune collision, tout est léger (sprites, tweens, CPUParticles2D). Images : Outils/traiter_glace_decor.py.

const TUILE := 16
var _salle: Node2D
var _bouts := []        # points d'où tombent les gouttes (pointes des stalactites)
var _attente := 2.0
var _brumes := []


func initialiser(salle: Node2D) -> void:
	_salle = salle
	var plan: PackedStringArray = salle.layout
	var glace := []
	for y in plan.size():
		for x in plan[y].length():
			if plan[y][x] == "i":
				glace.append(Vector2i(x, y))
	if glace.is_empty():
		return
	_poser_stalactites(plan)
	_poser_congeres(plan)
	_poser_etincelles(glace)
	_poser_brume(glace)


func _est_glace(plan: PackedStringArray, x: int, y: int) -> bool:
	return y >= 0 and y < plan.size() and x >= 0 and x < plan[y].length() and "ikco".contains(plan[y][x])


# GIVRE : une bande de neige et de petits glaçons sur le haut de chaque face de mur qui borde la salle (planche Gemini glace_decor2)
func _poser_stalactites(plan: PackedStringArray) -> void:
	var tex: Texture2D = _salle._image("givre_mur")
	if tex == null:
		return
	for y in range(1, plan.size() - 1):
		for x in plan[y].length():
			# une face de mur : un mur avec du sol ou de la glace juste en dessous
			if plan[y][x] != "#" or "#D".contains(plan[y + 1][x]):
				continue
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.region_enabled = true
			s.region_rect = Rect2((x % 3) * TUILE, 0, TUILE, tex.get_height())   # les cases voisines se suivent : bande continue
			s.position = Vector2(x * TUILE, y * TUILE - 2)
			add_child(s)
			if (x * 7 + y) % 4 == 0:
				_bouts.append(s.position + Vector2(8, tex.get_height() - 2))   # un glaçon d'où tombe parfois une goutte


# Congères : tas de neige au pied des murs de côté, aux deux bouts du quai (sans collision)
func _poser_congeres(plan: PackedStringArray) -> void:
	var tex: Texture2D = _salle._image("congere_coin")
	if tex == null:
		return
	var y := plan.size() - 3   # rangée du quai
	for gauche in [true, false]:
		var x := 2 if gauche else plan[y].length() - 3
		if plan[y][x] == "#":
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.flip_h = not gauche
		s.position = Vector2(x * TUILE - (14 if gauche else 0), y * TUILE - 8)
		add_child(s)


# Étincelles de givre : petits points blancs qui apparaissent et s'éteignent au hasard sur la glace
func _poser_etincelles(glace: Array) -> void:
	var mini := Vector2(9999, 9999)
	var maxi := Vector2(-1, -1)
	for c in glace:
		mini = mini.min(Vector2(c * TUILE))
		maxi = maxi.max(Vector2(c * TUILE + Vector2i(TUILE, TUILE)))
	var p := CPUParticles2D.new()
	p.amount = clampi(glace.size() / 4, 6, 18)
	p.lifetime = 1.4
	p.preprocess = 1.4
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = (maxi - mini) / 2.0
	p.position = (mini + maxi) / 2.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	var courbe := Curve.new()   # grandit puis disparaît : un scintillement
	courbe.add_point(Vector2(0, 0))
	courbe.add_point(Vector2(0.3, 1))
	courbe.add_point(Vector2(1, 0))
	p.scale_amount_curve = courbe
	p.color = Color(0.95, 1.0, 1.0, 0.85)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	add_child(p)


# Buée froide : 3 grandes taches très pâles qui dérivent lentement au-dessus de la glace
func _poser_brume(glace: Array) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.95, 1.0, 0.10))
	g.set_color(1, Color(0.85, 0.95, 1.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 96
	tex.height = 40
	for k in 3:
		var s := Sprite2D.new()
		s.texture = tex
		var c: Vector2i = glace[(k * 37 + 11) % glace.size()]
		s.position = Vector2(c * TUILE)
		add_child(s)
		_brumes.append({"s": s, "x0": s.position.x, "phase": k * 2.1})


func _process(delta: float) -> void:
	if _salle == null or _salle.grille != Etat.salle_courante:
		return
	var t := Time.get_ticks_msec() / 1000.0
	for b in _brumes:
		b["s"].position.x = b["x0"] + sin(t * 0.25 + b["phase"]) * 30.0
		b["s"].modulate.a = 0.7 + 0.3 * sin(t * 0.4 + b["phase"])
	_attente -= delta
	if _attente <= 0.0 and not _bouts.is_empty():
		_attente = randf_range(2.5, 6.0)
		_goutte(_bouts[randi() % _bouts.size()])


# Une goutte se détache d'une pointe de stalactite et tombe sur la glace
func _goutte(depart: Vector2) -> void:
	var g := ColorRect.new()
	g.size = Vector2(1, 2)
	g.color = Color(0.8, 0.95, 1.0, 0.9)
	g.position = depart
	add_child(g)
	var t := create_tween()
	t.tween_property(g, "position:y", depart.y + randf_range(14, 26), 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_property(g, "size", Vector2(3, 1), 0.05)
	t.parallel().tween_property(g, "position:x", depart.x - 1, 0.05)
	t.tween_property(g, "modulate:a", 0.0, 0.25)
	t.tween_callback(g.queue_free)
