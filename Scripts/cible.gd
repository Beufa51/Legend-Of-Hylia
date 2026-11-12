extends StaticBody2D
class_name Cible
# Le réceptacle du rayon de lumière (lettre Y du plan). Quand le rayon le touche, il s'allume
# (et la salle lève son drapeau `drapeau_rayon`). Il reste allumé ensuite.

var allumee := false
var _sprite: Sprite2D
var _image_allumee: Texture2D
var _lumiere: PointLight2D


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
	_sprite.texture = _image_allumee
	_lumiere.energy = 1.0
