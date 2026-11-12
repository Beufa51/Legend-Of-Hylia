extends StaticBody2D
class_name Sentinelle
# Une statue de garde qui surveille (lettres du plan : ^ v < > = direction du regard au départ).
# Elle peut tourner la tête d'un quart de tour (sens des aiguilles d'une montre) toutes les `periode` secondes.
# C'est la salle (room.gd) qui calcule les cases vues et qui repère le joueur.

const ORDRE := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]   # rotation horaire
const PREAVIS := 0.6   # secondes avant de tourner : le regard clignote pour prévenir

var case := Vector2i.ZERO
var direction := Vector2i.DOWN   # où elle regarde vraiment (peut être attirée par une flamme)
var _direction_depart := Vector2i.DOWN
var _direction_normale := Vector2i.DOWN   # où elle regarde selon sa rotation
var periode := 0.0                 # 0 = ne tourne jamais
var _temps := 0.0
var _oeil: Polygon2D
var _lumiere: PointLight2D


func initialiser(sa_case: Vector2i, dir: Vector2i, sa_periode: float, texture: Texture2D, dans_le_noir: bool) -> void:
	case = sa_case
	_direction_depart = dir
	periode = sa_periode
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(0, 16 - 30)   # l'image fait 30 px de haut : posée sur sa case
	add_child(sprite)
	# "Œil" : petit triangle lumineux devant la statue, qui montre où elle regarde
	_oeil = Polygon2D.new()
	_oeil.polygon = PackedVector2Array([Vector2(4, -3), Vector2(4, 3), Vector2(9, 0)])
	_oeil.color = Color(1.0, 0.75, 0.25)
	_oeil.position = Vector2(8, 8)
	_oeil.z_index = 1
	add_child(_oeil)
	_lumiere = Lumiere.creer(Color(1.0, 0.7, 0.35), 0.35, 0.8 if dans_le_noir else 0.0)
	add_child(_lumiere)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(16, 16)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)
	reinitialiser()


# Fait avancer le temps (rotation de la tête). Appelé par la salle, seulement quand on y est.
func avancer(delta: float) -> void:
	if periode <= 0.0:
		return
	_temps += delta
	var quarts := int(_temps / periode)
	_direction_normale = ORDRE[(ORDRE.find(_direction_depart) + quarts) % 4]


# Direction choisie par la salle : la direction normale, ou vers une flamme.
func regarder(dir: Vector2i) -> void:
	direction = dir
	_oeil.rotation = Vector2(dir).angle()
	_lumiere.position = Vector2(8, 8) + Vector2(dir) * 8.0


func direction_normale() -> Vector2i:
	return _direction_normale


# Vrai juste avant un quart de tour (pour faire clignoter le regard).
func va_tourner() -> bool:
	return periode > 0.0 and periode - fmod(_temps, periode) < PREAVIS


# Statue au repos (la plume de la salle est obtenue) : l'œil s'éteint.
func endormir() -> void:
	_oeil.color = Color(0.35, 0.3, 0.25)
	_lumiere.energy = 0.0


func reinitialiser() -> void:
	_temps = 0.0
	_direction_normale = _direction_depart
	regarder(_direction_depart)
