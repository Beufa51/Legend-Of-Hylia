extends Node2D
class_name VieSalle
# De la VIE dans une salle de donjon (règle du projet : jamais de décor plat) :
#  - poussière dorée qui flotte (seulement dans la salle où se trouve la caméra) ;
#  - détails au sol : éclats de pierre, fissures, mousse, tache d'humidité ; mousse et lianes sur le mur du haut ;
#  - toiles d'araignée dans les coins ;
#  - gouttes qui tombent du plafond (avec un petit rond dans l'eau et un son très doux) ;
#  - de temps en temps une chauve-souris traverse la salle ;
#  - sous chaque fenêtre en arche : un rayon de lumière poussiéreux.
# Aucune collision. Les détails sont semés avec une graine propre à la salle (ils ne changent pas d'une visite à l'autre).

const TUILE := 16
const SON_GOUTTE := "res://Assets/Sons/goutte.wav"

var salle: Room
var _rnd := RandomNumberGenerator.new()
var _poussiere: CPUParticles2D
var _rayons: Array = []       # [{poly, phase}]
var _prochaine_goutte := 3.0
var _prochaine_chauve := 25.0
var _t := 0.0
var _son_goutte: AudioStream


func initialiser(la_salle: Room) -> void:
	salle = la_salle
	_rnd.seed = la_salle.grille.x * 7919 + la_salle.grille.y * 104729 + la_salle.layout.size()
	_prochaine_goutte = _rnd.randf_range(2.0, 6.0)
	_prochaine_chauve = _rnd.randf_range(20.0, 50.0)
	_son_goutte = load(SON_GOUTTE) as AudioStream
	_poser_details_du_sol()
	_poser_mur_du_haut()
	_poser_toiles()
	_poser_rayons()
	_creer_poussiere()


func _en_vue() -> bool:
	return salle.grille == Etat.salle_courante


func _process(delta: float) -> void:
	_t += delta
	if _poussiere != null:
		_poussiere.emitting = _en_vue()
	if not _en_vue():
		return
	for r in _rayons:
		r["poly"].modulate.a = 0.75 + 0.25 * sin(_t * 0.7 + r["phase"])
	_prochaine_goutte -= delta
	if _prochaine_goutte <= 0.0:
		_prochaine_goutte = randf_range(3.0, 9.0)
		_goutte()
	_prochaine_chauve -= delta
	if _prochaine_chauve <= 0.0:
		_prochaine_chauve = randf_range(35.0, 80.0)
		_chauve_souris()


# --- Cases du sol libres (de simples dalles, rien dessus) -------------------------------------------------
func _cases_libres() -> Array:
	var cases := []
	for y in salle.layout.size():
		for x in salle.layout[y].length():
			if salle.layout[y][x] == ".":
				cases.append(Vector2i(x, y))
	return cases


func _a_cote_d_un_mur(c: Vector2i) -> bool:
	return salle._est_mur(c.x - 1, c.y) or salle._est_mur(c.x + 1, c.y) or salle._est_mur(c.x, c.y - 1) or salle._est_mur(c.x, c.y + 1)


func _pixel(pos: Vector2, taille: Vector2, couleur: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = taille
	r.color = couleur
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)


func _poser_details_du_sol() -> void:
	var cases := _cases_libres()
	if cases.is_empty():
		return
	var nombre := clampi(cases.size() / 9, 6, 26)
	for i in nombre:
		var c: Vector2i = cases[_rnd.randi() % cases.size()]
		var base := Vector2(c * TUILE)
		var type := _rnd.randi() % 5
		if type == 4 and not _a_cote_d_un_mur(c):
			type = _rnd.randi() % 4
		match type:
			0:   # éclats de pierre
				for k in _rnd.randi_range(2, 4):
					var clair := _rnd.randf() < 0.5
					_pixel(base + Vector2(_rnd.randi_range(1, 13), _rnd.randi_range(1, 13)), Vector2(1, 1) if _rnd.randf() < 0.6 else Vector2(2, 1), Color(0.5, 0.56, 0.68) if clair else Color(0.36, 0.41, 0.52))
			1:   # fissure en zigzag
				var p := base + Vector2(_rnd.randi_range(2, 8), _rnd.randi_range(3, 12))
				var sombre := Color(0.26, 0.3, 0.4)
				for k in _rnd.randi_range(4, 7):
					_pixel(p, Vector2(1, 1), sombre)
					p += Vector2(1, 0) if _rnd.randf() < 0.55 else Vector2(0, 1 if _rnd.randf() < 0.5 else -1)
			2:   # tache d'humidité (sombre, très douce) avec un reflet
				var w := _rnd.randi_range(5, 9)
				_pixel(base + Vector2(_rnd.randi_range(1, 6), _rnd.randi_range(5, 11)), Vector2(w, 3), Color(0.12, 0.16, 0.26, 0.28))
				_pixel(base + Vector2(_rnd.randi_range(2, 8), _rnd.randi_range(5, 10)), Vector2(2, 1), Color(0.6, 0.72, 0.9, 0.35))
			3:   # petits débris (graviers groupés)
				var o := base + Vector2(_rnd.randi_range(2, 10), _rnd.randi_range(2, 10))
				for k in _rnd.randi_range(3, 6):
					_pixel(o + Vector2(_rnd.randi_range(0, 4), _rnd.randi_range(0, 3)), Vector2(1, 1), Color(0.44, 0.49, 0.6) if k % 2 == 0 else Color(0.3, 0.34, 0.44))
			4:   # mousse contre un mur
				var vert := [Color(0.2, 0.34, 0.22), Color(0.28, 0.46, 0.28), Color(0.36, 0.56, 0.32)]
				var o2 := base + Vector2(_rnd.randi_range(1, 8), _rnd.randi_range(1, 9))
				for k in _rnd.randi_range(5, 9):
					_pixel(o2 + Vector2(_rnd.randi_range(0, 6), _rnd.randi_range(0, 4)), Vector2(1, 1) if _rnd.randf() < 0.7 else Vector2(2, 1), vert[_rnd.randi() % 3])


# Mousse et lianes qui pendent le long du mur du haut (au-dessus de la rangée du sol la plus haute).
func _poser_mur_du_haut() -> void:
	var colonnes := []
	for x in range(2, salle.layout[0].length() - 2):
		if salle._est_sol(x, 2) and salle._est_mur(x, 1) and salle._est_mur(x, 0):
			colonnes.append(x)
	if colonnes.is_empty():
		return
	for i in clampi(colonnes.size() / 5, 1, 5):
		var x: int = colonnes[_rnd.randi() % colonnes.size()]
		var px := x * TUILE + _rnd.randi_range(2, 13)
		var haut := 18 + _rnd.randi_range(0, 4)
		var longueur := _rnd.randi_range(4, 11)
		_pixel(Vector2(px, haut), Vector2(1, longueur), Color(0.18, 0.32, 0.2, 0.95))              # la liane
		for k in range(1, longueur, 3):
			_pixel(Vector2(px + (1 if k % 2 == 0 else -1), haut + k), Vector2(1, 1), Color(0.3, 0.52, 0.3))   # ses feuilles
		_pixel(Vector2(px - 1, haut - 1), Vector2(3, 2), Color(0.24, 0.42, 0.26))                  # touffe d'accroche
		if _rnd.randf() < 0.5:   # mousse au pied du mur
			for k in _rnd.randi_range(3, 6):
				_pixel(Vector2(x * TUILE + _rnd.randi_range(0, 14), 28 + _rnd.randi_range(0, 3)), Vector2(2, 1), Color(0.26, 0.44, 0.28, 0.9))


func _poser_toiles() -> void:
	var largeur: int = salle.layout[0].length()
	if _rnd.randf() < 0.6 and salle._est_sol(2, 2) and salle._est_mur(1, 2) and salle._est_mur(2, 1):
		salle._poser("toile_g", Vector2(2 * TUILE, 2 * TUILE))
	if _rnd.randf() < 0.6 and salle._est_sol(largeur - 3, 2) and salle._est_mur(largeur - 2, 2) and salle._est_mur(largeur - 3, 1):
		salle._poser("toile_d", Vector2((largeur - 2) * TUILE - 12, 2 * TUILE))


# Un rayon de lumière sous chaque fenêtre en arche (voir Room.COLONNES_FENETRES).
func _poser_rayons() -> void:
	if not salle.fenetres:
		return
	var additif := CanvasItemMaterial.new()
	additif.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for x in Room.COLONNES_FENETRES:
		var ys := salle._haut_du_sol(x)
		if ys < 0:
			continue
		var wx: float = x * TUILE + 8
		var wy: float = ys * TUILE - 3
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(wx - 5, wy), Vector2(wx + 5, wy), Vector2(wx + 31, wy + 64), Vector2(wx + 11, wy + 64)])
		poly.vertex_colors = PackedColorArray([Color(1, 0.92, 0.7, 0.2), Color(1, 0.92, 0.7, 0.2), Color(1, 0.9, 0.65, 0.0), Color(1, 0.9, 0.65, 0.0)])
		poly.material = additif
		add_child(poly)
		_rayons.append({"poly": poly, "phase": _rnd.randf() * TAU})


func _creer_poussiere() -> void:
	var largeur: int = salle.layout[0].length()
	var hauteur: int = salle.layout.size()
	var p := CPUParticles2D.new()
	p.position = Vector2(largeur, hauteur) * TUILE / 2.0
	p.amount = 22 if not salle.sombre else 10
	p.lifetime = 8.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(largeur - 4, hauteur - 4) * TUILE / 2.0
	p.direction = Vector2(0.4, -1)
	p.spread = 60.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	var degrade := Gradient.new()
	degrade.set_color(0, Color(1, 0.94, 0.78, 0.0))
	degrade.add_point(0.35, Color(1, 0.94, 0.78, 0.55))
	degrade.set_color(1, Color(1, 0.94, 0.78, 0.0))
	p.color_ramp = degrade
	p.emitting = false
	add_child(p)
	_poussiere = p


# Une goutte tombe du plafond, fait un petit rond dans la poussière du sol et "plic".
func _goutte() -> void:
	var cases := _cases_libres()
	if cases.is_empty():
		return
	var c: Vector2i = cases[randi() % cases.size()]
	var x := c.x * TUILE + randf_range(3, 13)
	var y := c.y * TUILE + randf_range(4, 12)
	var g := ColorRect.new()
	g.size = Vector2(1, 2)
	g.color = Color(0.7, 0.84, 1.0, 0.85)
	g.position = Vector2(x, y - 14)
	add_child(g)
	var tween := create_tween()
	tween.tween_property(g, "position:y", y, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(_goutte_arrivee.bind(g, Vector2(x, y)))


func _goutte_arrivee(g: ColorRect, point: Vector2) -> void:
	g.queue_free()
	_rond(point)
	if _son_goutte != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = _son_goutte
		lecteur.volume_db = -22.0
		lecteur.pitch_scale = randf_range(0.85, 1.35)
		add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)


func _rond(centre: Vector2) -> void:
	for k in 2:
		var r := ColorRect.new()
		r.size = Vector2(4, 1)
		r.color = Color(0.7, 0.84, 1.0, 0.6)
		r.pivot_offset = Vector2(2, 0.5)
		r.position = centre - Vector2(2, 0.5)
		add_child(r)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(r, "scale", Vector2(3.5 + k, 1), 0.6 + k * 0.15).set_delay(k * 0.12)
		tw.tween_property(r, "modulate:a", 0.0, 0.6 + k * 0.15).set_delay(k * 0.12)
		tw.chain().tween_callback(r.queue_free)


# Une chauve-souris traverse la salle d'un côté à l'autre (silhouette sombre aux ailes qui battent).
func _chauve_souris() -> void:
	var largeur: float = salle.layout[0].length() * TUILE
	var hauteur: float = salle.layout.size() * TUILE
	var sens := 1.0 if randf() < 0.5 else -1.0
	var corps := Node2D.new()
	var y0 := randf_range(hauteur * 0.25, hauteur * 0.6)
	corps.position = Vector2(-10 if sens > 0 else largeur + 10, y0)
	add_child(corps)
	var tete := Polygon2D.new()
	tete.polygon = PackedVector2Array([Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)])
	tete.color = Color(0.08, 0.07, 0.12)
	corps.add_child(tete)
	var ailes := []
	for cote in [-1.0, 1.0]:
		var aile := Polygon2D.new()
		aile.polygon = PackedVector2Array([Vector2(0, 0), Vector2(cote * 6, -3), Vector2(cote * 4, 0), Vector2(cote * 2, 1)])
		aile.color = Color(0.1, 0.09, 0.15)
		corps.add_child(aile)
		ailes.append(aile)
	var duree := (largeur + 20.0) / 55.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(corps, "position:x", largeur + 10 if sens > 0 else -10.0, duree)
	tween.tween_method(_battre.bind(corps, ailes, y0), 0.0, duree, duree)
	tween.chain().tween_callback(corps.queue_free)


# Vol ondulé et battement d'ailes (v = temps écoulé du vol).
func _battre(v: float, corps: Node2D, ailes: Array, y0: float) -> void:
	if not is_instance_valid(corps):
		return
	corps.position.y = y0 + sin(v * 9.0) * 6.0
	for a in ailes:
		a.scale.y = sin(v * 70.0) * 1.2
