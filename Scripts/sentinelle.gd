extends StaticBody2D
class_name Sentinelle
# Une sentinelle : un garde de pierre (lettres du plan : ^ v < > = direction du regard au départ).
# Le sprite du garde (pack Ninja Adventure) se tourne vraiment vers où il regarde : on comprend que c'est un garde.
# Elle peut tourner la tête d'un quart de tour (sens des aiguilles d'une montre) toutes les `periode` secondes ;
# la tête tourne en douceur. C'est la salle (room.gd) qui calcule le CÔNE de vision et qui repère le joueur.

const ORDRE := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]   # rotation horaire
const PREAVIS := 0.6           # secondes avant de tourner : le cône clignote pour prévenir
const VITESSE_ROTATION := 7.0  # radians par seconde (un quart de tour ≈ 0,2 s)
# Le garde : image Idle du pack, 4 cases de 16 px (colonnes : bas, haut, gauche, droite)
const IMAGE_GARDE := "res://Assets/Ninja_adventure/Actor/Character/GladiatorBlue/SeparateAnim/Idle.png"
const COLONNE := {Vector2i.DOWN: 0, Vector2i.UP: 1, Vector2i.LEFT: 2, Vector2i.RIGHT: 3}
const PIERRE := Color(0.78, 0.8, 0.9)      # teinte « statue de pierre » du garde
# Bulles au-dessus de la tête (Ui/Emote du pack) : « ? » = attiré par une flamme, « ! » = joueur repéré
const BULLE_QUESTION := "res://Assets/Ninja_adventure/Ui/Emote/emote23.png"
const BULLE_ALERTE := "res://Assets/Ninja_adventure/Ui/Emote/emote22.png"

var case := Vector2i.ZERO
var direction := Vector2i.DOWN   # où elle veut regarder (peut être attirée par une flamme)
var angle := 0.0                 # où elle regarde VRAIMENT (en radians) : suit `direction` en douceur
var _direction_depart := Vector2i.DOWN
var _direction_normale := Vector2i.DOWN   # où elle regarde selon sa rotation
var periode := 0.0                 # 0 = ne tourne jamais
var _temps := 0.0
var _sprite: Sprite2D
var _bulle: Sprite2D
var _lumiere: PointLight2D
var endormie := false


# `calque` : noeud où poser la bulle (au-dessus de l'obscurité, pour qu'on la voie même dans le noir).
func initialiser(sa_case: Vector2i, dir: Vector2i, sa_periode: float, dans_le_noir: bool, calque: Node2D) -> void:
	case = sa_case
	_direction_depart = dir
	periode = sa_periode
	# Petit socle de pierre sous les pieds : « c'est une statue »
	var socle := ColorRect.new()
	socle.color = Color(0.22, 0.22, 0.28)
	socle.position = Vector2(1, 11)
	socle.size = Vector2(14, 5)
	add_child(socle)
	var haut_socle := ColorRect.new()
	haut_socle.color = Color(0.45, 0.46, 0.55)
	haut_socle.position = Vector2(1, 11)
	haut_socle.size = Vector2(14, 1)
	add_child(haut_socle)
	_sprite = Sprite2D.new()
	_sprite.texture = load(IMAGE_GARDE)
	_sprite.centered = false
	_sprite.region_enabled = true
	_sprite.position = Vector2(0, -4)   # le garde est debout sur son socle
	_sprite.modulate = PIERRE
	add_child(_sprite)
	_bulle = Sprite2D.new()
	_bulle.position = position + Vector2(8, -14)
	_bulle.visible = false
	calque.add_child(_bulle)
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
	if periode > 0.0:
		_temps += delta
		var quarts := int(_temps / periode)
		_direction_normale = ORDRE[(ORDRE.find(_direction_depart) + quarts) % 4]
	# La tête tourne doucement vers la direction voulue
	angle = rotate_toward(angle, Vector2(direction).angle(), VITESSE_ROTATION * delta)


# Direction choisie par la salle : la direction normale, ou vers une flamme (`attiree` = vrai).
func regarder(dir: Vector2i, attiree: bool = false) -> void:
	direction = dir
	_sprite.region_rect = Rect2(COLONNE[dir] * 16, 0, 16, 16)
	_lumiere.position = Vector2(8, 8) + Vector2(dir) * 8.0
	if attiree:
		_montrer_bulle(BULLE_QUESTION)
	elif _bulle.texture != null and _bulle.texture.resource_path == BULLE_QUESTION:
		_bulle.visible = false


func direction_normale() -> Vector2i:
	return _direction_normale


# Vrai juste avant un quart de tour (pour faire clignoter le cône).
func va_tourner() -> bool:
	return periode > 0.0 and periode - fmod(_temps, periode) < PREAVIS


# Le joueur est repéré : « ! » au-dessus de la tête.
func alerter() -> void:
	_montrer_bulle(BULLE_ALERTE)


func _montrer_bulle(chemin: String) -> void:
	_bulle.texture = load(chemin)
	_bulle.visible = true


# Statue au repos (la plume est obtenue) : elle ne surveille plus.
func endormir() -> void:
	endormie = true
	_sprite.modulate = PIERRE.darkened(0.35)
	_lumiere.energy = 0.0
	_bulle.visible = false


func reinitialiser() -> void:
	_temps = 0.0
	_direction_normale = _direction_depart
	regarder(_direction_depart)
	angle = Vector2(_direction_depart).angle()
	_bulle.visible = false
