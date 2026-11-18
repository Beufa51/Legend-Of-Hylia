extends Node2D
class_name OndePlots
# Onde de couleur qui part du cristal commutateur et s'élargit à la vitesse à laquelle les plots changent d'état
# (voir Room.basculer_plots) : on voit que c'est le cristal qui commande les plots.

var couleur := Color(1.0, 0.62, 0.25)
const VITESSE := 600.0
var _rayon := 4.0
var _vie := 0.0
const DUREE := 0.7


static func jouer(parent: Node, centre: Vector2, orange_leves: bool) -> void:
	var onde := OndePlots.new()
	onde.position = centre
	onde.couleur = Color(1.0, 0.62, 0.25) if orange_leves else Color(0.45, 0.7, 1.0)
	onde.z_index = 3
	var materiau := CanvasItemMaterial.new()
	materiau.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	onde.material = materiau
	parent.add_child(onde)


func _process(delta: float) -> void:
	_vie += delta
	_rayon += VITESSE * delta
	if _vie >= DUREE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var a := clampf(1.0 - _vie / DUREE, 0.0, 1.0)
	draw_arc(Vector2.ZERO, _rayon, 0.0, TAU, 48, Color(couleur.r, couleur.g, couleur.b, 0.55 * a), 3.0)
	draw_arc(Vector2.ZERO, _rayon - 4.0, 0.0, TAU, 48, Color(couleur.r, couleur.g, couleur.b, 0.25 * a), 2.0)
