extends StaticBody2D
class_name Pot
# Un pot cassable : bloque le joueur, éclate en morceaux quand la lance le touche.

const SON_CASSE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact3.wav"
const COULEUR_MORCEAUX := Color(0.72, 0.42, 0.27)

var _casse := false


# `texture` : image du pot ; la position du nœud = coin haut-gauche de sa case (16x16).
func initialiser(texture: Texture2D) -> void:
	add_to_group("cassable")
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(3, 3)
	add_child(sprite)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(12, 12)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)


# Appelé par la lance : le pot éclate (une seule fois).
func casser() -> void:
	if _casse:
		return
	_casse = true
	_lancer_morceaux()
	_jouer_son()
	queue_free()


# Petits morceaux qui s'envolent puis disparaissent (ajoutés à la salle, pas au pot qui disparaît).
func _lancer_morceaux() -> void:
	var salle := get_parent()
	for i in 6:
		var morceau := ColorRect.new()
		morceau.color = COULEUR_MORCEAUX
		morceau.size = Vector2(2, 2)
		morceau.position = position + Vector2(7, 7)
		salle.add_child(morceau)
		var angle := randf() * TAU
		var arrivee: Vector2 = morceau.position + Vector2(cos(angle), sin(angle)) * randf_range(8.0, 16.0)
		var tween := morceau.create_tween()
		tween.set_parallel(true)
		tween.tween_property(morceau, "position", arrivee, 0.35)
		tween.tween_property(morceau, "modulate:a", 0.0, 0.35)
		tween.chain().tween_callback(morceau.queue_free)


# Joue le bruit dans un lecteur ajouté à la salle (il survit au pot).
func _jouer_son() -> void:
	var flux = load(SON_CASSE)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -4.0
	get_parent().add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
