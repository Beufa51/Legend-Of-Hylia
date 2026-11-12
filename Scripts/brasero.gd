extends StaticBody2D
class_name Brasero
# Un brasero à allumer d'un coup de lance (salle sombre). Il s'éteint tout seul au bout de `duree` secondes,
# sauf si la salle est résolue (tous les braseros allumés en même temps) : alors il reste allumé.

const SON_ALLUME := "res://Assets/Ninja_adventure/Audio/Sounds/Magic & Skill/Magic4.wav"

var salle: Node2D          # la salle (Room) : on la prévient quand un brasero s'allume
var duree := 14.0
var allume := false
var verrouille := false    # vrai quand l'énigme est résolue
var _reste := 0.0
var _temps := 0.0
var _sprite: Sprite2D
var _images_flamme: Array[Texture2D] = []
var _image_eteint: Texture2D
var _lumiere: PointLight2D


func initialiser(une_salle: Node2D, secondes: float, eteint: Texture2D, flammes: Array[Texture2D]) -> void:
	salle = une_salle
	duree = secondes
	_image_eteint = eteint
	_images_flamme = flammes
	add_to_group("frappable")
	_sprite = Sprite2D.new()
	_sprite.texture = eteint
	_sprite.centered = false
	add_child(_sprite)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(12, 12)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)
	_lumiere = Lumiere.creer(Color(1.0, 0.72, 0.4), 1.5, 1.0)
	_lumiere.position = Vector2(8, 6)
	_lumiere.enabled = false
	add_child(_lumiere)


# Appelé par la lance.
func frapper() -> void:
	if verrouille:
		return
	if not allume:
		_jouer_son()
	allume = true
	_reste = duree   # un nouveau coup remet le compteur à zéro
	_lumiere.enabled = true
	salle.verifier_braseros()


# L'énigme est résolue : le brasero ne s'éteindra plus.
func verrouiller() -> void:
	verrouille = true


func eteindre() -> void:
	allume = false
	_lumiere.enabled = false
	_sprite.texture = _image_eteint


func _process(delta: float) -> void:
	if not allume:
		return
	_temps += delta
	_sprite.texture = _images_flamme[int(_temps * 6.0) % _images_flamme.size()]
	if verrouille:
		return
	_reste -= delta
	if _reste <= 0.0:
		eteindre()
	elif _reste < 3.0:
		# Dernières secondes : la lumière clignote pour prévenir
		_lumiere.energy = 0.4 + 0.6 * absf(sin(_temps * 10.0))
	else:
		_lumiere.energy = 1.0


func _jouer_son() -> void:
	var flux = load(SON_ALLUME)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -3.0
	salle.add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
