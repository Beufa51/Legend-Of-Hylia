extends Area2D
class_name Butin
# Un objet ramassable qui jaillit d'une herbe ou d'un pot : rubis (vert 1, jaune 5, rouge 20) ou petit cœur.
# Il saute, retombe, rebondit puis attend le joueur ; il est aspiré quand le joueur passe tout près.
# Il disparaît tout seul au bout de 14 s (il clignote avant), comme dans Zelda.

const GEMMES := {
	"vert": ["res://Assets/Ninja_adventure/Items/Resource/GemGreen.png", 1],
	"jaune": ["res://Assets/Ninja_adventure/Items/Resource/GemYellow.png", 5],
	"rouge": ["res://Assets/Ninja_adventure/Items/Resource/GemRed.png", 20],
}
const SON_RUBIS := "res://Assets/Ninja_adventure/Audio/Sounds/Bonus/Coin.wav"
const SON_COEUR := "res://Assets/Ninja_adventure/Audio/Sounds/Bonus/PowerUp1.wav"
const VIE := 14.0

var _genre := "vert"          # "vert" | "jaune" | "rouge" | "coeur"
var _sprite: Sprite2D
var _age := 0.0
var _ramasse := false
var _vol := Vector2.ZERO      # petit déplacement horizontal pendant le saut


# Tire un butin au hasard et le fait jaillir en `pos` (position globale). `chance_rubis` / `chance_coeur` : 0..1.
static func lacher(parent: Node, pos: Vector2, chance_rubis := 0.3, chance_coeur := 0.08) -> void:
	var tirage := randf()
	var genre := ""
	if tirage < chance_coeur:
		genre = "coeur"
	elif tirage < chance_coeur + chance_rubis:
		var t := randf()
		genre = "vert" if t < 0.72 else ("jaune" if t < 0.94 else "rouge")
	if genre == "":
		return
	creer(parent, pos, genre)


static func creer(parent: Node, pos: Vector2, genre: String) -> Butin:
	var b := Butin.new()
	b._genre = genre
	parent.add_child(b)
	b.global_position = pos
	b._demarrer()
	return b


func _demarrer() -> void:
	collision_layer = 0
	collision_mask = 1   # le joueur est sur la couche 1
	monitoring = true
	z_index = 3
	var forme := CircleShape2D.new()
	forme.radius = 7.0
	var c := CollisionShape2D.new()
	c.shape = forme
	add_child(c)
	_sprite = Sprite2D.new()
	if _genre == "coeur":
		var a := AtlasTexture.new()
		a.atlas = load("res://Assets/Gemini/tuiles/icone_coeur_plein.png")
		a.region = Rect2(Vector2.ZERO, a.atlas.get_size())
		_sprite.texture = a.atlas
		_sprite.scale = Vector2.ONE * (12.0 / maxf(a.atlas.get_size().x, 1.0))
	else:
		_sprite.texture = load(GEMMES[_genre][0])
	_sprite.position = Vector2(0, -4)
	add_child(_sprite)
	# petit saut : monte, retombe, rebondit
	_vol = Vector2(randf_range(-14.0, 14.0), 0.0)
	var t := create_tween()
	t.tween_property(_sprite, "position:y", -16.0, 0.16).set_ease(Tween.EASE_OUT)
	t.tween_property(_sprite, "position:y", -2.0, 0.18).set_ease(Tween.EASE_IN)
	t.tween_property(_sprite, "position:y", -7.0, 0.09).set_ease(Tween.EASE_OUT)
	t.tween_property(_sprite, "position:y", -2.0, 0.09).set_ease(Tween.EASE_IN)
	body_entered.connect(_sur_corps)


func _process(delta: float) -> void:
	_age += delta
	if _age < 0.45:
		global_position += _vol * delta * (1.0 - _age / 0.45)
	if _age > VIE - 3.0 and _sprite:
		_sprite.visible = int(_age * 10.0) % 2 == 0   # clignote avant de disparaître
	if _age > VIE:
		queue_free()
		return
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	if joueur and _age > 0.5 and not _ramasse:
		var d := joueur.global_position.distance_to(global_position)
		if d < 22.0:   # aspiré
			global_position = global_position.move_toward(joueur.global_position, 110.0 * delta)
		if d < 9.0:
			_prendre()


func _sur_corps(corps: Node) -> void:
	if corps.is_in_group("joueur") and _age > 0.4:
		_prendre()


func _prendre() -> void:
	if _ramasse:
		return
	_ramasse = true
	var joueur := get_tree().get_first_node_in_group("joueur")
	if _genre == "coeur":
		if joueur and joueur.has_method("guerir"):
			joueur.guerir(1)
		_son(SON_COEUR)
	else:
		Etat.gagner_rubis(GEMMES[_genre][1])
		_son(SON_RUBIS)
	queue_free()


func _son(chemin: String) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -6.0
	lecteur.pitch_scale = 1.0 + (0.1 if _genre == "jaune" else (0.2 if _genre == "rouge" else 0.0))
	get_tree().root.add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
