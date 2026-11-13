extends StaticBody2D
class_name Cristal
# Un cristal à frapper avec la lance : il s'allume et lève un drapeau (ouvre une porte, par exemple).
# Dessiné en code. Il reste allumé une fois frappé.
# Dans une salle à PLOTS (aile droite), c'est un COMMUTATEUR : chaque coup inverse les plots
# orange et bleus, et le cristal prend la couleur des plots levés.

const SON := "res://Assets/Ninja_adventure/Audio/Sounds/Magic & Skill/Magic2.wav"
const BLEU := Color(0.25, 0.55, 0.95)
const BLEU_CLAIR := Color(0.7, 0.9, 1.0)
const OR := Color(1.0, 0.85, 0.35)

var drapeau := ""
var texte := ""
var actif := false
var _corps: Polygon2D
var _reflet: Polygon2D
var _salle: Room = null       # salle à plots : le cristal est un commutateur
var _attente := 0.0           # la lance touche pendant plusieurs images : un seul basculement par coup


func initialiser(nom_drapeau: String, message: String, salle_a_plots: Room = null) -> void:
	_salle = salle_a_plots
	drapeau = nom_drapeau
	texte = message
	add_to_group("frappable")
	# socle de pierre
	var socle := ColorRect.new()
	socle.position = Vector2(3, 11)
	socle.size = Vector2(10, 4)
	socle.color = Color(0.35, 0.38, 0.36)
	add_child(socle)
	# cristal : losange allongé
	_corps = Polygon2D.new()
	_corps.polygon = PackedVector2Array([Vector2(8, 0), Vector2(13, 6), Vector2(11, 12), Vector2(5, 12), Vector2(3, 6)])
	_corps.color = BLEU
	add_child(_corps)
	_reflet = Polygon2D.new()
	_reflet.polygon = PackedVector2Array([Vector2(7, 2), Vector2(9, 6), Vector2(7, 10), Vector2(5, 6)])
	_reflet.color = BLEU_CLAIR
	add_child(_reflet)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(12, 14)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)


func _process(delta: float) -> void:
	_attente = maxf(0.0, _attente - delta)


# Couleur du commutateur : celle des plots levés.
func colorer(orange_leves: bool) -> void:
	_corps.color = Plot.ORANGE if orange_leves else Plot.BLEU
	_reflet.color = _corps.color.lightened(0.55)


# Appelé par la lance.
func frapper() -> void:
	if _salle != null:   # commutateur des plots
		if _attente > 0.0:
			return
		_attente = 0.45
		_jouer_son()
		_salle.basculer_plots()
		return
	if actif:
		return
	actif = true
	_corps.color = OR
	_reflet.color = Color(1, 1, 0.9)
	_jouer_son()
	Etat.poser(drapeau)
	if texte != "":
		Etat.annoncer(texte)


func _jouer_son() -> void:
	var flux = load(SON)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		lecteur.volume_db = -3.0
		get_parent().add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)
