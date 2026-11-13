extends StaticBody2D
class_name Chanteur
# La statue du coq chanteur (lettre C du plan) : quand on la frappe avec la lance,
# elle "chante" la mélodie de la salle, et chaque cloche s'illumine quand sa note passe.

var salle: Node2D
var _sprite: Sprite2D
var _lumiere: PointLight2D
var _dernier_coup := -1000


func initialiser(une_salle: Node2D, texture: Texture2D, dans_le_noir: bool) -> void:
	salle = une_salle
	add_to_group("frappable")
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = false
	_sprite.position = Vector2(-3, 16 - 34)   # l'image fait 22x34 px : posée sur sa case
	add_child(_sprite)
	_lumiere = Lumiere.creer(Color(1.0, 0.6, 0.5), 0.7, 0.4 if dans_le_noir else 0.0)
	_lumiere.position = Vector2(8, 0)
	add_child(_lumiere)
	# Collision sur TOUTE la statue (sa case + sa tête qui dépasse au-dessus) :
	# on peut la frapper par le bas, par les côtés ou par le haut.
	var forme := RectangleShape2D.new()
	forme.size = Vector2(16, 30)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 0)
	add_child(collision)


func frapper() -> void:
	var maintenant := Time.get_ticks_msec()
	if maintenant - _dernier_coup < 400:
		return
	_dernier_coup = maintenant
	# Petit sursaut de la statue, puis la salle joue la mélodie (si elle le peut)
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", 16 - 34 - 3, 0.08)
	tween.tween_property(_sprite, "position:y", 16 - 34, 0.1)
	salle.statue_frappee()
