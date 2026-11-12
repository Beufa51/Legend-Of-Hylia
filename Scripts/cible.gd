extends StaticBody2D
class_name Cible
# Le réceptacle du rayon de lumière (lettre Y du plan). Quand le rayon le touche, il s'allume
# (et la salle lève son drapeau `drapeau_rayon`). Il reste allumé ensuite.
# Il a la forme d'un soleil éteint (même motif que le soleil d'où part le rayon) et brille doucement
# tant qu'il est éteint : on comprend qu'il attend la lumière.

var allumee := false
var _sprite: Sprite2D
var _image_allumee: Texture2D
var _lumiere: PointLight2D
var _temps := 0.0


func initialiser(eteinte: Texture2D, allumee_tex: Texture2D) -> void:
	_image_allumee = allumee_tex
	_sprite = Sprite2D.new()
	_sprite.texture = eteinte
	_sprite.centered = false
	add_child(_sprite)
	_lumiere = Lumiere.creer(Color(1.0, 0.85, 0.45), 0.8, 0.0)
	_lumiere.position = Vector2(8, 9)
	add_child(_lumiere)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(14, 14)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)


func allumer() -> void:
	if allumee:
		return
	allumee = true
	_sprite.modulate = Color.WHITE
	_sprite.texture = _image_allumee
	_lumiere.energy = 1.0


# Éteint : une faible pulsation dorée attire l'œil.
func _process(delta: float) -> void:
	if allumee:
		return
	_temps += delta
	var p := 0.5 + 0.5 * sin(_temps * 3.0)
	_sprite.modulate = Color(1.0 + 0.5 * p, 1.0 + 0.35 * p, 1.0)
