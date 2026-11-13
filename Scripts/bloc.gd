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
var _sprite: Sprite2D
var _texture_normale: Texture2D
var _texture_active: Texture2D   # rune dorée : le bloc est posé sur une marque


func initialiser(une_salle: Node2D, sa_case: Vector2i, texture: Texture2D, texture_active: Texture2D = null) -> void:
	salle = une_salle
	case = sa_case
	depart = sa_case
	add_to_group("poussable")
	position = Vector2(case * TUILE)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	add_child(sprite)
	_sprite = sprite
	_texture_normale = texture
	_texture_active = texture_active
	var forme := RectangleShape2D.new()
	forme.size = Vector2(TUILE, TUILE)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(TUILE / 2.0, TUILE / 2.0)
	add_child(collision)


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


# Allume (ou éteint) la rune du bloc.
func briller(actif: bool) -> void:
	if _texture_active != null:
		_sprite.texture = _texture_active if actif else _texture_normale


# Remet le bloc à sa case de départ (touche R).
func reinitialiser() -> void:
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
