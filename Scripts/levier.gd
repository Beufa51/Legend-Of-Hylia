extends StaticBody2D
class_name Levier
# Un LEVIER (lettre `J`) : un coup de lance le bascule (animation du pack donjon Craftpix) et lève
# son drapeau (ex. il ouvre une porte). Il ne se rebascule pas. Déjà levé : il reste basculé.

const SON := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Hit2.wav"

var drapeau := ""
var _sprite: Sprite2D
var _images: Array[Texture2D] = []
var actif := false


func initialiser(nom_drapeau: String, images: Array[Texture2D]) -> void:
	drapeau = nom_drapeau
	_images = images
	add_to_group("frappable")
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture = images[0]
	add_child(_sprite)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(12, 10)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 10)
	add_child(collision)
	if Etat.est(drapeau):
		actif = true
		_sprite.texture = images[-1]


# Appelé par la lance.
func frapper() -> void:
	if actif:
		return
	actif = true
	var flux = load(SON)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		lecteur.volume_db = -4.0
		add_child(lecteur)
		lecteur.play()
	var tween := create_tween()
	tween.tween_method(func(t: float): _sprite.texture = _images[mini(int(t), _images.size() - 1)], 0.0, float(_images.size()) - 0.01, 0.3)
	Etat.poser(drapeau)
