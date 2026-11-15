extends Node2D
class_name GouffreVie
# De la VIE dans un gouffre (énigme du pont, Plume 3b) : brume qui dérive, lueurs bleutées au fond qui pulsent,
# poussière lumineuse qui remonte, petits cailloux qui tombent du bord, cailloux posés sur les rebords.
# Purement décoratif : aucune collision. `zone` = rectangle du gouffre en pixels (dans la salle).

const TUILE := 16
const COULEUR_LUEUR := [Color(0.25, 0.5, 1.0), Color(0.5, 0.35, 1.0), Color(0.2, 0.8, 0.9)]

var zone: Rect2
var _brumes: Array = []       # [{sprite, vitesse}]
var _lueurs: Array = []       # [{sprite, phase, base}]
var _prochain_caillou := 1.0
var _t := 0.0
var _rnd := RandomNumberGenerator.new()
static var _tex_doux: GradientTexture2D


func initialiser(la_zone: Rect2, plan: PackedStringArray) -> void:
	zone = la_zone
	_rnd.seed = int(zone.position.x * 31 + zone.position.y * 17 + zone.size.x)
	z_index = 0
	_creer_lueurs()
	_creer_poussiere()
	_creer_brume()
	_poser_cailloux_du_bord(plan)


func _process(delta: float) -> void:
	_t += delta
	for b in _brumes:
		var s: Sprite2D = b["sprite"]
		s.position.x += b["vitesse"] * delta
		if s.position.x > zone.end.x + 40.0:
			s.position.x = zone.position.x - 40.0
		elif s.position.x < zone.position.x - 40.0:
			s.position.x = zone.end.x + 40.0
		s.modulate.a = b["alpha"] * (0.7 + 0.3 * sin(_t * 0.6 + b["phase"]))
	for l in _lueurs:
		var s2: Sprite2D = l["sprite"]
		s2.modulate.a = l["base"] * (0.55 + 0.45 * sin(_t * 1.3 + l["phase"]))
	_prochain_caillou -= delta
	if _prochain_caillou <= 0.0:
		_prochain_caillou = _rnd.randf_range(0.7, 2.2)
		_lancer_caillou()


# Texture ronde et douce (centre opaque, bord transparent), partagée.
static func _texture_douce() -> GradientTexture2D:
	if _tex_doux == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1.0))
		g.set_color(1, Color(1, 1, 1, 0.0))
		_tex_doux = GradientTexture2D.new()
		_tex_doux.gradient = g
		_tex_doux.width = 64
		_tex_doux.height = 64
		_tex_doux.fill = GradientTexture2D.FILL_RADIAL
		_tex_doux.fill_from = Vector2(0.5, 0.5)
		_tex_doux.fill_to = Vector2(1.0, 0.5)
	return _tex_doux


func _creer_lueurs() -> void:
	var additif := CanvasItemMaterial.new()
	additif.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var nombre := int(zone.size.x / 48.0) + 2
	for i in nombre:
		var s := Sprite2D.new()
		s.texture = _texture_douce()
		s.material = additif
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.modulate = COULEUR_LUEUR[i % COULEUR_LUEUR.size()]
		s.position = Vector2(_rnd.randf_range(zone.position.x + 10, zone.end.x - 10), _rnd.randf_range(zone.position.y + 12, zone.end.y - 12))
		s.scale = Vector2.ONE * _rnd.randf_range(0.7, 1.3)
		add_child(s)
		_lueurs.append({"sprite": s, "phase": _rnd.randf() * TAU, "base": _rnd.randf_range(0.18, 0.34)})


func _creer_brume() -> void:
	var nombre := int(zone.size.x / 70.0) + 2
	for i in nombre:
		var s := Sprite2D.new()
		s.texture = _texture_douce()
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.modulate = Color(0.7, 0.78, 0.95, 0.13)
		s.position = Vector2(_rnd.randf_range(zone.position.x, zone.end.x), _rnd.randf_range(zone.position.y + 8, zone.end.y - 8))
		s.scale = Vector2(_rnd.randf_range(1.6, 2.6), _rnd.randf_range(0.7, 1.1))
		add_child(s)
		_brumes.append({"sprite": s, "vitesse": _rnd.randf_range(-7.0, 9.0), "alpha": _rnd.randf_range(0.09, 0.17), "phase": _rnd.randf() * TAU})


# Poussière lumineuse qui remonte lentement du fond.
func _creer_poussiere() -> void:
	var p := CPUParticles2D.new()
	p.position = zone.get_center()
	p.amount = int(zone.size.x / 6.0)
	p.lifetime = 4.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = zone.size / 2.0
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 8.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.5
	var degrade := Gradient.new()
	degrade.set_color(0, Color(0.6, 0.8, 1.0, 0.0))
	degrade.add_point(0.3, Color(0.6, 0.85, 1.0, 0.7))
	degrade.set_color(1, Color(0.6, 0.8, 1.0, 0.0))
	p.color_ramp = degrade
	add_child(p)


# Un petit caillou se détache du bord nord et tombe dans le vide (il s'estompe en tombant).
func _lancer_caillou() -> void:
	var c := ColorRect.new()
	c.size = Vector2(2, 2)
	c.color = Color(0.45, 0.5, 0.62)
	c.position = Vector2(_rnd.randf_range(zone.position.x + 4, zone.end.x - 4), zone.position.y + 3)
	add_child(c)
	var chute := _rnd.randf_range(14.0, 30.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(c, "position:y", c.position.y + chute, 0.7).set_ease(Tween.EASE_IN)
	tween.tween_property(c, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(c.queue_free)


# Cailloux posés sur le sol, le long des deux rebords (décor, sans collision).
func _poser_cailloux_du_bord(plan: PackedStringArray) -> void:
	var gauche := int(zone.position.x / TUILE)
	var droite := int(zone.end.x / TUILE) - 1
	var haut := int(zone.position.y / TUILE)
	var bas := int(zone.end.y / TUILE) - 1
	for x in range(gauche, droite + 1):
		for rangee in [haut - 1, bas + 1]:
			if rangee < 0 or rangee >= plan.size() or x >= plan[rangee].length() or plan[rangee][x] != ".":
				continue
			if _rnd.randf() > 0.22:
				continue
			var nombre := _rnd.randi_range(1, 3)
			for i in nombre:
				var r := ColorRect.new()
				var grand := _rnd.randf() < 0.3
				r.size = Vector2(2, 2) if grand else Vector2(1, 1)
				r.color = [Color(0.48, 0.54, 0.66), Color(0.36, 0.41, 0.52), Color(0.58, 0.64, 0.76)][_rnd.randi() % 3]
				r.position = Vector2(x * TUILE + _rnd.randf_range(1, 13), rangee * TUILE + _rnd.randf_range(1, 13))
				add_child(r)
