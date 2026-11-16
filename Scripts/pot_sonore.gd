extends Pot
class_name PotSonore
# Un POT SONORE (lettre `U` du plan) : un pot doré dont on voit les ondes sonores. Quand la lance le brise, il fait un GRAND BRUIT :
# la salle l'entend (signal `bruit_fait`) et les sentinelles tournent la tête vers lui (voir room.gd : `_sur_bruit`).
# Le joueur le reconnaît à son éclat doré, à ses ondes qui pulsent et aux petites étincelles qui s'en échappent.

signal bruit_fait

const OR := Color(1.0, 0.82, 0.35)
const SON_CLOCHE := "res://Assets/Ninja_adventure/Audio/Sounds/Bonus/Coin.wav"

var _temps := randf() * 6.0
var _etincelles: CPUParticles2D
var _anneaux: Array[Sprite2D] = []      # 2 anneaux dorés (image Gemini) qui s'élargissent en boucle
var _tessons: Texture2D                 # image des tessons laissés au sol quand le pot éclate


# Même appel que le pot normal. `anneaux` / `brise` : images Gemini (Outils/traiter_pots_sonores.py), `doree` : le pot a déjà sa couleur
# (sinon on le teinte en or). Sans images, les anneaux sont dessinés en code.
func decorer(anneaux: Texture2D = null, brise: Texture2D = null, doree := false) -> void:
	_tessons = brise
	if not doree:
		for enfant in get_children():
			if enfant is Sprite2D:
				enfant.modulate = Color(1.45, 1.15, 0.62)   # éclat doré (on garde la forme du pot de la salle)
	if anneaux != null:
		for i in 2:
			var anneau := Sprite2D.new()
			anneau.texture = anneaux
			anneau.position = Vector2(8, 9)
			add_child(anneau)
			move_child(anneau, 0)   # derrière le pot (les images du pot sont ajoutées avant : on passe l'anneau en premier)
			_anneaux.append(anneau)
	_etincelles = CPUParticles2D.new()
	_etincelles.position = Vector2(8, 8)
	_etincelles.amount = 5
	_etincelles.lifetime = 1.6
	_etincelles.direction = Vector2(0, -1)
	_etincelles.spread = 40.0
	_etincelles.gravity = Vector2.ZERO
	_etincelles.initial_velocity_min = 4.0
	_etincelles.initial_velocity_max = 9.0
	_etincelles.scale_amount_min = 1.0
	_etincelles.scale_amount_max = 1.5
	_etincelles.color = OR
	add_child(_etincelles)


func _process(delta: float) -> void:
	_temps += delta
	for i in _anneaux.size():
		var phase := fmod(_temps * 0.7 + i * 0.5, 1.0)   # l'anneau grandit puis s'efface, l'autre est décalé d'une demi-période
		_anneaux[i].scale = Vector2.ONE * (0.3 + phase * 0.8)
		_anneaux[i].modulate.a = 0.85 * (1.0 - phase)
	if _anneaux.is_empty():
		queue_redraw()


# Sans image d'anneaux : des ondes dorées dessinées en code.
func _draw() -> void:
	if not _anneaux.is_empty():
		return
	for i in 2:
		var phase := fmod(_temps * 0.7 + i * 0.5, 1.0)
		var couleur := OR
		couleur.a = 0.55 * (1.0 - phase)
		draw_arc(Vector2(8, 9), 5.0 + phase * 9.0, 0.0, TAU, 28, couleur, 1.0)


# Le pot éclate AVEC un grand bruit : une cloche claire et l'alerte aux sentinelles.
func casser() -> void:
	if _casse:
		return
	bruit_fait.emit()
	var flux = load(SON_CLOCHE)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		lecteur.pitch_scale = 0.55
		lecteur.volume_db = 2.0
		get_parent().add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)
	_laisser_les_tessons()
	super.casser()


# Les tessons dorés restent au sol quelques secondes (ajoutés à la salle, pas au pot qui disparaît).
func _laisser_les_tessons() -> void:
	if _tessons == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = _tessons
	sprite.centered = false
	sprite.position = position
	get_parent().add_child(sprite)
	var tween := sprite.create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	tween.tween_callback(sprite.queue_free)
