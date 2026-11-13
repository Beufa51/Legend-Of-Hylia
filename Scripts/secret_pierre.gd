extends StaticBody2D
class_name SecretPierre
# Un ROCHER FISSURÉ : un coup de lance le brise et révèle un secret (un coffre caché, voir exterieur.gd::_poser_coffres).

const SON := "res://Assets/Ninja_adventure/Audio/Sounds/Impact/Impact3.wav"

var _revele: Callable
var _casse := false


func initialiser(texture: Texture2D, quand_brise: Callable) -> void:
	_revele = quand_brise
	add_to_group("frappable")
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(8 - texture.get_width() / 2.0, 16 - texture.get_height())
	add_child(sprite)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(14, 12)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 9)
	add_child(collision)


# Appelé par la lance.
func frapper() -> void:
	if _casse:
		return
	_casse = true
	var flux = load(SON)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		get_parent().add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)
	_revele.call()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)
	collision_layer = 0
