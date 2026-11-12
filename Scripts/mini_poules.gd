extends MiniJeu
class_name MiniPoules
# CHASSE AUX POULES (façon cocottes de Zelda) : 5 poules se sont échappées. Approche-toi d'une poule et appuie sur Espace/J
# pour la PRENDRE dans tes bras, puis Espace/J encore pour la LANCER (par-dessus les clôtures !) dans l'enclos
# (cases marquées `k` dans le plan de la ferme). Une poule entrée dans l'enclos y reste. Points de départ : cases `s`.
# Rubans (temps) : moins de 50 s = bronze, moins de 35 s = argent, moins de 22 s = or.

const DUREE := 60.0
const SEUILS := [50.0, 35.0, 22.0]
const NB_POULES := 5
const PLANCHES := [
	"res://Assets/Ninja_adventure/Actor/Animal/Chicken/SpriteSheetWhite.png",
	"res://Assets/Ninja_adventure/Actor/Animal/Chicken/SpriteSheetBrown.png",
]
const VITESSE := 34.0

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
	for i in mini(depart.size(), NB_POULES):
		var poule := Animal.new()
		poule.position = depart[i]
		ecran.add_child(poule)
		poule.initialiser(PLANCHES[i % 2], VITESSE, false, "poule", _zone_ecran)   # elles ne fuient pas : on peut les attraper
		poule.add_to_group("poules_ferme")
		_poules.append([poule, false])
	Etat.annoncer("Prends une poule (Espace près d'elle), puis relance Espace pour la LANCER dans l'enclos !")


func _maj(_delta: float) -> void:
	for p in _poules:
		if not p[1] and is_instance_valid(p[0]) and _enclos.has_point(p[0].position):
			p[1] = true
			p[0].verrouillee = true
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
