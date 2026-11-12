extends MiniJeu
class_name MiniPoules
# CHASSE AUX POULES : 6 poules se sont échappées. Ramène-les dans l'enclos (cases marquées `k` dans le plan de la ferme)
# avant la fin du temps. Elles fuient quand tu t'approches : pousse-les vers l'entrée de l'enclos !
# Une poule entrée dans l'enclos y reste. Points de départ des poules : cases marquées `s`.
# Rubans (temps) : moins de 60 s = bronze, moins de 45 s = argent, moins de 30 s = or.

const DUREE := 75.0
const SEUILS := [60.0, 45.0, 30.0]
const PLANCHES := [
	"res://Assets/Ninja_adventure/Actor/Animal/Chicken/SpriteSheetWhite.png",
	"res://Assets/Ninja_adventure/Actor/Animal/Chicken/SpriteSheetBrown.png",
]
const VITESSE := 28.0

var _enclos := Rect2()
var _poules: Array = []      # [poule, rentrée ?]
var _dedans := 0
var _zone_ecran := Rect2(Vector2(16, 16), Vector2(368, 192))


func _init() -> void:
	id = "poules"


func _depart() -> void:
	_nettoyer()
	# l'enclos = la boîte qui entoure les cases `k` ; les départs = les cases `s`
	var depart: Array[Vector2] = []
	var coin_min := Vector2(1000, 1000)
	var coin_max := Vector2(-1, -1)
	for y in ecran.layout.size():
		for x in ecran.layout[y].length():
			var c: String = ecran.layout[y][x]
			if c == "k":
				coin_min = coin_min.min(Vector2(x * 16, y * 16))
				coin_max = coin_max.max(Vector2(x * 16 + 16, y * 16 + 16))
			elif c == "s":
				depart.append(Vector2(x * 16 + 8, y * 16 + 10))
	_enclos = Rect2(coin_min, coin_max - coin_min)
	_dedans = 0
	for i in depart.size():
		var poule := Animal.new()
		poule.position = depart[i]
		ecran.add_child(poule)
		poule.initialiser(PLANCHES[i % 2], VITESSE, true, "poule", _zone_ecran)
		poule.add_to_group("poules_ferme")
		_poules.append([poule, false])
	Etat.annoncer("Ramène les %d poules dans l'enclos ! Elles fuient quand tu t'approches." % _poules.size())


func _maj(_delta: float) -> void:
	for p in _poules:
		if not p[1] and is_instance_valid(p[0]) and _enclos.has_point(p[0].position):
			p[1] = true
			_dedans += 1
			p[0].limiter(_enclos.grow(-5.0))   # elle reste dans l'enclos
			_jouer("res://Assets/Ninja_adventure/Audio/Sounds/Bonus/Coin.wav", -10.0)
	if _dedans >= _poules.size():
		_terminer(_temps, false, SEUILS, "poules", "s")
	elif _temps >= DUREE:
		en_cours = false
		_hud.visible = false
		Etat.annoncer("Temps écoulé ! Il reste %d poule(s) dehors. Reparle à la fermière pour réessayer." % (_poules.size() - _dedans))


func _texte_hud() -> String:
	return "Poules : %d / %d    Temps : %d" % [_dedans, _poules.size(), maxi(0, ceili(DUREE - _temps))]


# Au (re)départ ou à l'abandon : les anciennes poules du jeu disparaissent
func _nettoyer() -> void:
	for poule in get_tree().get_nodes_in_group("poules_ferme"):
		poule.queue_free()
	_poules.clear()
