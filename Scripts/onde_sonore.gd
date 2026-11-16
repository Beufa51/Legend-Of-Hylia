extends Node2D
class_name OndeSonore
# Une grosse onde de bruit qui s'étend depuis un point (un pot sonore qui éclate) : trois anneaux dorés qui grandissent et s'effacent.
# C'est le signal visuel « tout le monde a entendu » : les sentinelles tournent alors la tête vers ce point.

const OR := Color(1.0, 0.85, 0.4)
const RAYON_MAX := 120.0   # pixels (environ 7 cases = la portée du regard)
const DUREE := 1.0

var _progression := 0.0
var _echelle := 1.0   # 1 = grande onde de bruit, plus petit = simple éclat


static func jouer(parent: Node, centre: Vector2, echelle := 1.0) -> void:
	var onde := OndeSonore.new()
	onde._echelle = echelle
	onde.position = centre
	onde.z_index = 5
	parent.add_child(onde)
	var tween := onde.create_tween()
	tween.tween_property(onde, "_progression", 1.0, DUREE).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(onde.queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for i in 3:
		var p := clampf(_progression * 1.25 - i * 0.14, 0.0, 1.0)
		if p <= 0.0:
			continue
		var couleur := OR
		couleur.a = 0.8 * (1.0 - p)
		draw_arc(Vector2.ZERO, 4.0 + p * RAYON_MAX * _echelle, 0.0, TAU, 48, couleur, 2.0 if i == 0 else 1.0)
