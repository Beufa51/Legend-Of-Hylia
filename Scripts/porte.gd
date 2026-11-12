extends StaticBody2D
class_name Porte
# Une porte fermée : une grille de fer à barreaux (image porte_LxH.png, voir Outils/traiter_gemini.py).
# Une seule Porte couvre toutes les cases `D` voisines. Quand on appelle ouvrir(), la grille se relève.

const SON_OUVERTURE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact5.wav"

var _collision: CollisionShape2D
var _sprite: Sprite2D
var _taille := Vector2.ZERO
var ouverte := false


# `taille` : taille de la porte en pixels (multiple de 16) ; `texture` : son image.
func initialiser(taille: Vector2, texture: Texture2D) -> void:
	_taille = taille
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = false
	add_child(_sprite)
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
	# La grille se relève : elle rétrécit vers le haut (porte large) ou vers le côté (porte haute et étroite)
	var tween := create_tween()
	if _taille.x >= _taille.y:
		tween.tween_property(_sprite, "scale:y", 0.0, 0.7).set_ease(Tween.EASE_IN)
	else:
		tween.tween_property(_sprite, "scale:x", 0.0, 0.7).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
