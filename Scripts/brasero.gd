extends StaticBody2D
class_name Brasero
# Un brasero à allumer d'un coup de lance (salle sombre). Il s'éteint tout seul au bout de `duree` secondes,
# sauf si la salle est résolue (tous les braseros allumés en même temps) : alors il reste allumé.

const SON_ALLUME := "res://Assets/Ninja_adventure/Audio/Sounds/Magic & Skill/Magic4.wav"

var salle: Node2D          # la salle (Room) : on la prévient quand un brasero s'allume
var duree := 14.0
var allume := false
var verrouille := false    # vrai quand l'énigme est résolue
var foyer := false         # mode « lance enflammée » : foyer allumé en permanence, il donne le feu à la lance
var mode_feu := false      # mode « lance enflammée » : ne s'allume qu'avec une lance enflammée, puis reste allumé (et sert de relais)
var ordonne := false       # mode « chemin » (tête de coq) : la salle gère l'ordre et la durée, le brasero ne s'éteint pas seul
var attendu := false       # c'est LUI le prochain à allumer : il pulse doucement
var vie := 1.0             # 1 = flamme pleine, 0 = sur le point de s'éteindre (mode chemin)
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
	_sprite.position = Room.DECALAGE_BRASERO   # image 20x26, la case est en bas au centre
	add_child(_sprite)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(12, 12)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)
	_lumiere = Lumiere.creer(Color(1.0, 0.72, 0.4), 1.5, 1.0)
	_lumiere.position = Vector2(8, 6)
	add_child(_lumiere)
	_regler_lumiere(false)


# Appelé par la lance.
func frapper() -> void:
	if verrouille:
		return
	if foyer or mode_feu:
		_frapper_avec_feu()
		return
	if ordonne:
		if allume:
			return
		if not salle.brasero_frappe(self):   # mauvais ordre : la salle éteint tout
			return
	if not allume:
		_jouer_son()
	allume = true
	_reste = duree   # un nouveau coup remet le compteur à zéro
	_regler_lumiere(true)
	salle.verifier_braseros()


# Salle « lance enflammée » : frapper un brasero ALLUMÉ enflamme la lance ; frapper un brasero ÉTEINT avec une lance enflammée l'allume pour de bon.
func _frapper_avec_feu() -> void:
	var joueur = get_tree().get_first_node_in_group("joueur")
	if joueur == null:
		return
	if allume:
		joueur.prendre_feu()
	elif joueur.a_feu():
		allume = true
		_jouer_son()
		_regler_lumiere(true)
		salle.verifier_braseros()


# Foyer : allumé dès le début, pour toujours.
func allumer_foyer() -> void:
	foyer = true
	allume = true
	_regler_lumiere(true)


# L'énigme est résolue : le brasero ne s'éteindra plus.
func verrouiller() -> void:
	verrouille = true


func eteindre() -> void:
	allume = false
	attendu = false
	_sprite.modulate = Color.WHITE
	_regler_lumiere(false)
	_sprite.texture = _image_eteint


# Allumé : grande lueur. Éteint : une toute petite braise, pour qu'on repère le brasero dans le noir.
func _regler_lumiere(allumee: bool) -> void:
	_lumiere.texture_scale = 1.5 if allumee else 0.5
	_lumiere.energy = 1.0 if allumee else 0.35


func _process(delta: float) -> void:
	_temps += delta
	if not allume:
		if attendu:   # le prochain à allumer : braise qui pulse
			var v := 0.5 + 0.5 * sin(_temps * 5.0)
			_lumiere.texture_scale = 0.6 + 0.5 * v
			_lumiere.energy = 0.5 + 0.7 * v
			_sprite.modulate = Color(1.0 + 0.5 * v, 1.0 + 0.3 * v, 1.0)
		return
	_sprite.texture = _images_flamme[int(_temps * 6.0) % _images_flamme.size()]
	if verrouille:
		return
	if foyer or mode_feu:
		_lumiere.energy = 1.0   # allumé pour de bon : pas de compte à rebours
		return
	if ordonne:
		# la flamme rétrécit à mesure que le temps passe ; elle vacille dans les dernières secondes
		_lumiere.texture_scale = 0.8 + 0.7 * vie
		_lumiere.energy = 1.0 if vie > 0.2 else 0.4 + 0.6 * absf(sin(_temps * 10.0))
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
