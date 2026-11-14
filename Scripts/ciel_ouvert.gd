class_name CielOuvert
extends Node2D
## EFFETS DE PLEIN AIR pour une salle sans toit (Room.ciel_ouvert) : ce qui fait sentir qu'on est dehors, sous le ciel du soir :
##   - des OMBRES DE NUAGES qui glissent lentement sur le sol ;
##   - une grande lueur froide de LUNE ;
##   - de temps en temps l'OMBRE D'UN OISEAU qui traverse la cour ;
##   - quelques FEUILLES poussées par le vent.
## Tout est dessiné par-dessus la salle (z_index), en mélange doux : ça ne gêne ni le jeu ni les collisions.

const TAILLE := Vector2(400, 224)
var cases_etoiles: Array[Vector2] = []   # cases de ciel (coin haut-gauche) où des étoiles scintillent
var _t := 0.0
var _etoiles: Array[ColorRect] = []
var _ombres: Array[Sprite2D] = []
var _lune: Sprite2D
var _oiseau: Node2D
var _prochain_oiseau := 5.0


func _ready() -> void:
	z_index = 3
	var tex := _degrade(PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)]), PackedFloat32Array([0.0, 0.5, 1.0]))
	for i in 6:
		var s := Sprite2D.new()
		s.texture = tex
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.position = Vector2(randf_range(-100, 500), randf_range(20, 210))
		s.scale = Vector2(randf_range(2.6, 4.4), randf_range(1.0, 1.7))
		s.modulate = Color(0, 0.02, 0.1, randf_range(0.26, 0.36))
		add_child(s)
		_ombres.append(s)
	_lune = Sprite2D.new()
	_lune.texture = tex
	_lune.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_lune.position = TAILLE * 0.5
	_lune.scale = Vector2(4.2, 2.6)
	var additif := CanvasItemMaterial.new()
	additif.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_lune.material = additif
	_lune.modulate = Color(0.3, 0.4, 0.75, 0.13)
	add_child(_lune)
	for c in cases_etoiles:   # étoiles qui scintillent (quelques-unes par case de ciel)
		if randf() < 0.55:
			var e := ColorRect.new()
			e.size = Vector2(2, 2) if randf() < 0.25 else Vector2(1, 1)
			e.color = Color(0.85, 0.9, 1.0, 1.0)
			e.position = c + Vector2(randi() % 15, randi() % 15)
			e.set_meta("phase", randf() * 6.28)
			add_child(e)
			_etoiles.append(e)
	var feuilles := CPUParticles2D.new()
	feuilles.position = Vector2(-10, 112)
	feuilles.amount = 9
	feuilles.lifetime = 9.0
	feuilles.preprocess = 9.0
	feuilles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	feuilles.emission_rect_extents = Vector2(4, 100)
	feuilles.direction = Vector2(1, 0.25)
	feuilles.spread = 20.0
	feuilles.initial_velocity_min = 30.0
	feuilles.initial_velocity_max = 55.0
	feuilles.gravity = Vector2(0, 4)
	feuilles.scale_amount_min = 1.2
	feuilles.scale_amount_max = 2.2
	feuilles.angular_velocity_min = -160.0
	feuilles.angular_velocity_max = 160.0
	feuilles.color = Color(0.55, 0.75, 0.4, 0.85)
	add_child(feuilles)


func _process(delta: float) -> void:
	_t += delta
	for i in _ombres.size():
		var s := _ombres[i]
		s.position.x += (7.0 + i * 3.0) * delta
		s.position.y += sin(_t * 0.2 + i) * 2.0 * delta
		if s.position.x > TAILLE.x + 200.0:
			s.position.x = -200.0
	for e in _etoiles:
		e.modulate.a = 0.45 + 0.55 * sin(_t * 2.2 + float(e.get_meta("phase"))) * sin(_t * 0.7 + float(e.get_meta("phase")))
	_lune.modulate.a = 0.12 + 0.03 * sin(_t * 0.6)
	_prochain_oiseau -= delta
	if _prochain_oiseau <= 0.0 and _oiseau == null:
		_lancer_oiseau()
	if _oiseau != null:
		_oiseau.position += _oiseau.get_meta("v") * delta
		_oiseau.scale.y = 0.35 + 0.65 * absf(sin(_t * 11.0))
		if _oiseau.position.x > TAILLE.x + 30.0 or _oiseau.position.y > TAILLE.y + 30.0:
			_oiseau.queue_free()
			_oiseau = null
			_prochain_oiseau = randf_range(9.0, 16.0)


# L'ombre d'un oiseau : deux ailes en V, qui battent, traversent la cour en diagonale.
func _lancer_oiseau() -> void:
	var o := Node2D.new()
	var corps := Polygon2D.new()
	corps.polygon = PackedVector2Array([Vector2(-9, 1), Vector2(-3, -3), Vector2(0, 0), Vector2(3, -3), Vector2(9, 1), Vector2(0, 3)])
	corps.color = Color(0, 0.02, 0.08, 0.3)
	o.add_child(corps)
	o.position = Vector2(-20, randf_range(10, 120))
	o.rotation = 0.35
	o.set_meta("v", Vector2(48, 20))
	add_child(o)
	_oiseau = o


func _degrade(couleurs: PackedColorArray, offsets: PackedFloat32Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = couleurs
	g.offsets = offsets
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex
