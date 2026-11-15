extends StaticBody2D
class_name Bloc
# Un bloc que le joueur pousse d'une case à la fois (il faut pousser un instant contre lui).
# Sur la glace, il glisse jusqu'à un obstacle.

const SON_POUSSE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact.wav"
const TUILE := 16
const DUREE := 0.2  # secondes pour glisser d'une case

var salle: Node2D       # la salle (Room) qui contient ce bloc
var case: Vector2i      # case actuelle (colonne, ligne) dans la salle
var depart: Vector2i    # case de départ (pour recommencer la salle)
var en_mouvement := false
var _collision: CollisionShape2D
var _tween_chute: Tween
var _comble := false   # le bloc remplit un trou : son aspect ne change plus
var _sprite: Sprite2D
var _texture_normale: Texture2D
var _texture_enfonce: Texture2D   # le bloc qui comble un trou (face supérieure au niveau du sol, bord sombre)
var _texture_active: Texture2D   # rune dorée : le bloc est posé sur une marque


func initialiser(une_salle: Node2D, sa_case: Vector2i, texture: Texture2D, texture_active: Texture2D = null, texture_enfonce: Texture2D = null) -> void:
	salle = une_salle
	case = sa_case
	depart = sa_case
	add_to_group("poussable")
	position = Vector2(case * TUILE)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(0, TUILE - texture.get_height())   # un bloc plus haut que large : il dépasse vers le haut, son pied reste sur sa case
	add_child(sprite)
	_sprite = sprite
	_texture_normale = texture
	_texture_active = texture_active
	_texture_enfonce = texture_enfonce
	var forme := RectangleShape2D.new()
	forme.size = Vector2(TUILE, TUILE)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(TUILE / 2.0, TUILE / 2.0)
	add_child(collision)
	_collision = collision


# Pousse le bloc d'une case dans la direction `dir` (ex. Vector2i.LEFT), si la place est libre.
func pousser(dir: Vector2i) -> void:
	if en_mouvement:
		return
	var cible := case + dir
	if not salle.case_libre(cible):
		return
	# Sur la GLACE, le bloc continue de glisser jusqu'à un obstacle (ou jusqu'au sol normal)
	var cases := 1
	while salle.has_method("est_glace") and salle.est_glace(cible) and salle.case_libre(cible + dir):
		cible += dir
		cases += 1
	salle.liberer(case)
	salle.occuper(cible, self)
	case = cible
	en_mouvement = true
	_jouer_son()
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(case * TUILE), DUREE * (1.0 if cases == 1 else 0.6 * cases))
	await tween.finished
	en_mouvement = false
	salle.verifier_plaques()
	if salle.has_method("bloc_arrive"):
		salle.bloc_arrive(self)


# Le bloc tombe dans le trou et le comble : il s'enfonce d'un coup, la poussière se soulève, puis il reste en place
# (on voit qu'on marche sur le bloc ; sa face supérieure arrive au niveau du sol).
func combler() -> void:
	_comble = true
	z_index = 0
	modulate = Color(1, 1, 1)
	_collision.set_deferred("disabled", true)
	if _texture_enfonce != null:
		_sprite.texture = _texture_enfonce
		_sprite.position = Vector2.ZERO     # le bloc comblé est plat (au niveau du sol)
	var haut := position
	var tween := create_tween()
	_tween_chute = tween
	tween.tween_property(self, "position", haut + Vector2(0, 6), 0.12).set_ease(Tween.EASE_IN)   # il s'enfonce derrière la lèvre du bord
	tween.tween_callback(_poussiere)
	tween.tween_property(self, "position", haut, 0.14).set_ease(Tween.EASE_OUT)                  # et se cale EXACTEMENT au niveau du sol


# Petit nuage de poussière à l'impact.
func _poussiere() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(TUILE / 2.0, TUILE - 3)
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 14
	p.lifetime = 0.7
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.gravity = Vector2(0, 14)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 24.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	var degrade := Gradient.new()
	degrade.set_color(0, Color(0.75, 0.8, 0.9, 0.8))
	degrade.set_color(1, Color(0.75, 0.8, 0.9, 0.0))
	p.color_ramp = degrade
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


# Allume (ou éteint) la rune du bloc.
func briller(actif: bool) -> void:
	if _comble:
		return
	if _texture_active != null:
		_sprite.texture = _texture_active if actif else _texture_normale


# Remet le bloc à sa case de départ (touche R).
func reinitialiser() -> void:
	if _tween_chute != null and _tween_chute.is_valid():
		_tween_chute.kill()
	z_index = 0
	modulate = Color(1, 1, 1)
	_comble = false
	_sprite.texture = _texture_normale
	_sprite.position = Vector2(0, TUILE - _texture_normale.get_height())
	_collision.set_deferred("disabled", false)
	salle.liberer(case)
	case = depart
	salle.occuper(case, self)
	position = Vector2(case * TUILE)
	en_mouvement = false


func _jouer_son() -> void:
	var flux = load(SON_POUSSE)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -8.0
	salle.add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
