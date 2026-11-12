extends StaticBody2D
class_name Porte
# Une porte fermée : double battant de bois cerclé de fer (image porte_LxH.png, voir Outils/traiter_gemini.py).
# Une seule Porte couvre toutes les cases `D` voisines. Elle disparaît quand on appelle ouvrir().

const SON_OUVERTURE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact5.wav"

var _collision: CollisionShape2D
var ouverte := false


# `taille` : taille de la porte en pixels (multiple de 16) ; `texture` : son image.
func initialiser(taille: Vector2, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	add_child(sprite)
	var forme := RectangleShape2D.new()
	forme.size = taille
	_collision = CollisionShape2D.new()
	_collision.shape = forme
	_collision.position = taille / 2.0
	add_child(_collision)


# La porte s'ouvre : elle ne bloque plus, fait trembler l'écran, puis s'efface doucement.
func ouvrir() -> void:
	if ouverte:
		return
	ouverte = true
	_collision.set_deferred("disabled", true)
	Etat.secousse.emit()
	var flux = load(SON_OUVERTURE)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		lecteur.volume_db = -2.0
		get_parent().add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
