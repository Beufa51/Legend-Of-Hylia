extends StaticBody2D
class_name Miroir
# Un miroir sur socle (lettres du plan : M = « / », N = « \ »). Un coup de lance le fait pivoter d'un quart de tour
# (il passe de / à \ et inversement). Le rayon de lumière (room.gd) rebondit dessus.

const SON := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Whoosh2.wav"

var oblique := true            # vrai = « / », faux = « \ »
var _depart := true
var _sprite: Sprite2D
var _images: Array[Texture2D] = []   # [image de /, image de \]
var _dernier_coup := -1000


func initialiser(est_oblique: bool, image_m: Texture2D, image_n: Texture2D) -> void:
	_depart = est_oblique
	_images = [image_m, image_n]
	add_to_group("frappable")
	_sprite = Sprite2D.new()
	_sprite.position = Vector2(8, 8)   # centré, pour pouvoir le faire tourner sur lui-même
	add_child(_sprite)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(14, 14)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)
	reinitialiser()


# Direction du rayon après le miroir. « / » : droite -> haut, haut -> droite, gauche -> bas, bas -> gauche.
func renvoyer(dir: Vector2i) -> Vector2i:
	if oblique:
		return Vector2i(-dir.y, -dir.x)
	return Vector2i(dir.y, dir.x)


func frapper() -> void:
	var maintenant := Time.get_ticks_msec()
	if maintenant - _dernier_coup < 400:
		return
	_dernier_coup = maintenant
	oblique = not oblique
	# Petite animation : le miroir se retourne (il s'aplatit, change d'image, puis revient)
	var tween := create_tween()
	tween.tween_property(_sprite, "scale:x", 0.0, 0.08)
	tween.tween_callback(_maj_image)
	tween.tween_property(_sprite, "scale:x", 1.0, 0.08)
	var flux = load(SON)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		lecteur.volume_db = -6.0
		get_parent().add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)


func reinitialiser() -> void:
	oblique = _depart
	_sprite.scale = Vector2.ONE
	_maj_image()


func _maj_image() -> void:
	_sprite.texture = _images[0] if oblique else _images[1]
