extends Node2D
# Gère la caméra : écran fixe par salle, avec glissement quand le joueur
# passe dans une salle voisine.

const TAILLE_SALLE := Vector2i(400, 224)
const DUREE_GLISSEMENT := 0.6  # secondes

@onready var joueur: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

var salle_actuelle := Vector2i.ZERO  # case de la grille où se trouve la caméra
var en_transition := false


func _ready() -> void:
	salle_actuelle = _salle_du_joueur()
	camera.position = _centre_salle(salle_actuelle)


func _process(_delta: float) -> void:
	if en_transition:
		return
	var nouvelle := _salle_du_joueur()
	if nouvelle != salle_actuelle:
		_glisser_vers(nouvelle)


# Dans quelle case de la grille se trouve le joueur ?
func _salle_du_joueur() -> Vector2i:
	return Vector2i(
		floori(joueur.position.x / TAILLE_SALLE.x),
		floori(joueur.position.y / TAILLE_SALLE.y))


func _centre_salle(salle: Vector2i) -> Vector2:
	return Vector2(salle * TAILLE_SALLE) + Vector2(TAILLE_SALLE) / 2.0


# Fait glisser la caméra vers la nouvelle salle ; le joueur est figé pendant ce temps.
func _glisser_vers(salle: Vector2i) -> void:
	en_transition = true
	salle_actuelle = salle
	joueur.set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(camera, "position", _centre_salle(salle), DUREE_GLISSEMENT)
	await tween.finished
	joueur.set_physics_process(true)
	en_transition = false
