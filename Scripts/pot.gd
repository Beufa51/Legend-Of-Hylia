extends StaticBody2D
class_name Pot
# Un pot cassable : bloque le joueur, éclate en morceaux quand la lance le touche.

const SON_CASSE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact3.wav"
const COULEUR_MORCEAUX := Color(0.72, 0.42, 0.27)
const COULEURS := [Color(0.78, 0.45, 0.24), Color(0.42, 0.5, 0.62), Color(0.42, 0.56, 0.3)]   # ocre, bleu, vert (pots Gemini)

var butin := false   # vrai (village) : un pot cassé peut laisser un rubis ou un cœur
var _casse := false
var _couleur := COULEUR_MORCEAUX


# `texture` : image du pot ; la position du nœud = coin haut-gauche de sa case (16x16).
func initialiser(texture: Texture2D, couleur := COULEUR_MORCEAUX) -> void:
	_couleur = couleur
	add_to_group("cassable")
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(0, -1)   # pot 16x16, posé au fond de sa case
	add_child(sprite)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(12, 12)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)


# Appelé par la lance (via frapper) : le pot éclate (une seule fois).
func frapper() -> void:
	casser()


# Le pot éclate.
func casser() -> void:
	if _casse:
		return
	_casse = true
	if butin:
		Butin.lacher(get_parent(), global_position + Vector2(8, 8), 0.55, 0.15)
	_lancer_morceaux()
	_jouer_son()
	queue_free()


# Tessons de la couleur du pot qui s'envolent, retombent et restent un moment au sol avant de s'effacer
# (ajoutés à la salle, pas au pot qui disparaît).
func _lancer_morceaux() -> void:
	var salle := get_parent()
	for i in 7:
		var morceau := ColorRect.new()
		morceau.color = _couleur.darkened(randf_range(0.0, 0.35)) if i % 3 else _couleur.lightened(0.2)
		morceau.size = Vector2(randi_range(2, 3), 2)
		morceau.position = position + Vector2(7, 7)
		morceau.mouse_filter = Control.MOUSE_FILTER_IGNORE
		salle.add_child(morceau)
		var angle := randf() * TAU
		var arrivee: Vector2 = morceau.position + Vector2(cos(angle), sin(angle) * 0.6) * randf_range(5.0, 13.0)
		var sommet := (morceau.position + arrivee) / 2.0 - Vector2(0, randf_range(4.0, 8.0))
		var tween := morceau.create_tween()
		tween.tween_property(morceau, "position", sommet, 0.13).set_ease(Tween.EASE_OUT)
		tween.tween_property(morceau, "position", arrivee, 0.15).set_ease(Tween.EASE_IN)
		tween.tween_interval(randf_range(2.5, 4.0))
		tween.tween_property(morceau, "modulate:a", 0.0, 1.0)
		tween.tween_callback(morceau.queue_free)


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
