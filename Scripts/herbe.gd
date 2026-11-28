extends StaticBody2D
class_name Herbe
# Une touffe d'herbe haute qu'on coupe à la lance (comme dans Zelda) : feuilles qui volent, parfois un rubis ou un cœur.
# Elle repousse quand on revient dans l'écran (elle est recréée avec lui), sauf si `repousse` est faux.

const SON_COUPE := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Slash.wav"
const VARIANTES := ["v_herbe_haute_1", "v_herbe_haute_2", "v_herbe_haute_3"]

var _coupee := false
var _sprite: Sprite2D
var _sur_coupe: Callable    # appelé quand elle est coupée (mini-jeu du champ : compter les rubis...)
var chance_rubis := 0.28
var chance_coeur := 0.06


# `texture` : image de la touffe (16x16) ; la position du nœud = coin haut-gauche de sa case.
func initialiser(texture: Texture2D) -> void:
	add_to_group("cassable")
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = false
	_sprite.position = Vector2(0, -1)
	add_child(_sprite)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(12, 12)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)
	_sprite.rotation = 0.0


# Léger balancement quand le joueur passe tout près (vie !)
func _process(_delta: float) -> void:
	if _coupee or get_parent().grille != Etat.salle_courante:
		return   # inutile d'animer une touffe qu'on ne voit pas
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	if joueur == null:
		return
	var d := joueur.global_position.distance_to(global_position + Vector2(8, 8))
	_sprite.skew = lerpf(_sprite.skew, (sin(Time.get_ticks_msec() / 90.0) * 0.18) if d < 20.0 else 0.0, 0.2)


func frapper() -> void:
	couper()


func couper() -> void:
	if _coupee:
		return
	_coupee = true
	Butin.lacher(get_parent(), global_position + Vector2(8, 8), chance_rubis, chance_coeur)
	if _sur_coupe.is_valid():
		_sur_coupe.call(global_position + Vector2(8, 8))
	_feuilles()
	var flux = load(SON_COUPE)
	if flux != null:
		var lecteur := AudioStreamPlayer2D.new()
		lecteur.stream = flux
		lecteur.volume_db = -12.0
		lecteur.pitch_scale = randf_range(1.2, 1.5)
		get_parent().add_child(lecteur)
		lecteur.global_position = global_position
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)
	queue_free()


# Brins d'herbe qui s'envolent et retombent (ajoutés à l'écran, pas à la touffe qui disparaît).
func _feuilles() -> void:
	var salle := get_parent()
	for i in 6:
		var brin := ColorRect.new()
		brin.size = Vector2(2, 3)
		brin.color = [Color(0.45, 0.7, 0.2), Color(0.6, 0.82, 0.3), Color(0.33, 0.58, 0.18)][i % 3]
		brin.position = position + Vector2(8, 8)
		brin.z_index = 2
		salle.add_child(brin)
		var arrivee := brin.position + Vector2(randf_range(-14.0, 14.0), randf_range(-6.0, 8.0))
		var t := brin.create_tween()
		t.tween_property(brin, "position:x", arrivee.x, 0.5)
		t.parallel().tween_property(brin, "position:y", brin.position.y - randf_range(8.0, 16.0), 0.18).set_ease(Tween.EASE_OUT)
		t.tween_property(brin, "position:y", arrivee.y, 0.32).set_ease(Tween.EASE_IN)
		t.tween_property(brin, "modulate:a", 0.0, 0.6)
		t.tween_callback(brin.queue_free)
