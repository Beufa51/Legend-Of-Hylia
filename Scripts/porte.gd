extends StaticBody2D
class_name Porte
# Une case de porte fermée (bois et fer, dessinée en code). Elle disparaît quand on appelle ouvrir().

const COULEUR_BOIS := Color(0.45, 0.28, 0.15)
const COULEUR_BOIS_SOMBRE := Color(0.32, 0.19, 0.10)
const COULEUR_FER := Color(0.30, 0.30, 0.36)
const TUILE := 16

var _collision: CollisionShape2D
var ouverte := false


func initialiser() -> void:
	_dessiner_rect(Vector2.ZERO, Vector2(TUILE, TUILE), COULEUR_BOIS)
	_dessiner_rect(Vector2(5, 0), Vector2(1, TUILE), COULEUR_BOIS_SOMBRE)     # lames de bois
	_dessiner_rect(Vector2(11, 0), Vector2(1, TUILE), COULEUR_BOIS_SOMBRE)
	_dessiner_rect(Vector2(0, 2), Vector2(TUILE, 3), COULEUR_FER)             # bandes de fer
	_dessiner_rect(Vector2(0, 11), Vector2(TUILE, 3), COULEUR_FER)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(TUILE, TUILE)
	_collision = CollisionShape2D.new()
	_collision.shape = forme
	_collision.position = Vector2(TUILE / 2.0, TUILE / 2.0)
	add_child(_collision)


func _dessiner_rect(pos: Vector2, taille: Vector2, couleur: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = taille
	r.color = couleur
	add_child(r)


# La porte s'ouvre : elle ne bloque plus, puis s'efface doucement.
func ouvrir() -> void:
	if ouverte:
		return
	ouverte = true
	_collision.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
