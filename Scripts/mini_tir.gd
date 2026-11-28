extends MiniJeu
class_name MiniTir
# STAND DE TIR À LA LANCE : pendant 30 secondes, des pots apparaissent sur l'étagère du fond (cases marquées `c` dans le plan
# de l'intérieur) ; chacun reste 2 secondes. Casse-les à coups de lance : 1 point par pot.
# Rubans : 8 points = bronze, 14 = argent, 20 = or.

const DUREE := 30.0
const PERIODE := 0.75    # un nouveau pot toutes les 0,75 s au début (0,45 s à la fin)
const VIE := 2.0         # un pot reste 2 s au début (1,2 s à la fin)
const MAX_CIBLES := 3    # 5 à la fin
const SEUILS := [12, 20, 28]
const VALEUR_DORE := 3

var _emplacements: Array[Vector2] = []   # où peuvent apparaître les pots (coin haut-gauche des cases `c`)
var _cibles: Array = []                  # [pot, emplacement, heure d'apparition]
var _score := 0
var _prochain := 0.0
var _nb_pots := 0


func _init() -> void:
	id = "tir"


func _depart() -> void:
	_emplacements.clear()
	for y in ecran.layout.size():
		for x in ecran.layout[y].length():
			if ecran.layout[y][x] == "c":
				_emplacements.append(Vector2(x * 16, y * 16))
	_score = 0
	_nb_pots = 0
	_prochain = 0.6
	Etat.annoncer("Casse un maximum de pots en 30 secondes ! Les pots dorés valent 3 points.")


func _maj(delta: float) -> void:
	# Pots touchés (disparus) ou trop vieux
	for cible in _cibles.duplicate():
		var pot = cible[0]   # sans type : un pot cassé est un objet détruit
		if not is_instance_valid(pot) or pot.is_queued_for_deletion():
			_score += cible[3]
			_jouer("res://Assets/Ninja_adventure/Audio/Sounds/Bonus/Coin.wav", -10.0 if cible[3] == 1 else -2.0)
			_cibles.erase(cible)
		elif _temps - cible[2] > _vie() * (0.7 if cible[3] > 1 else 1.0):
			pot.queue_free()   # raté : il disparaît sans point
			_cibles.erase(cible)
	if _temps >= DUREE:
		_fin()
		return
	_prochain -= delta
	if _prochain <= 0.0 and _cibles.size() < _max_cibles():
		_apparition()
		_prochain = lerpf(PERIODE, 0.45, _avancement())


# 0 au début, 1 à la fin : la partie s'accélère
func _avancement() -> float:
	return clampf(_temps / DUREE, 0.0, 1.0)


func _vie() -> float:
	return lerpf(VIE, 1.2, _avancement())


func _max_cibles() -> int:
	return 3 + int(_avancement() * 2.5)


func _apparition() -> void:
	var libres: Array[Vector2] = []
	for e in _emplacements:
		var occupe := false
		for c in _cibles:
			if c[1] == e:
				occupe = true
		if not occupe and not _joueur_pres(e + Vector2(8, 8), 14.0):   # jamais sur le joueur
			libres.append(e)
	if libres.is_empty():
		return
	var e: Vector2 = libres[randi() % libres.size()]
	var pot := Pot.new()
	pot.position = e
	ecran.add_child(pot)
	pot.initialiser(ecran._image("vase_1"))
	_nb_pots += 1
	var valeur := 1
	if _nb_pots % 5 == 0:   # un pot doré de temps en temps : vaut 3 points, reste moins longtemps
		valeur = VALEUR_DORE
		pot.get_child(0).modulate = Color(1.6, 1.3, 0.3)
	_cibles.append([pot, e, _temps, valeur])


func _texte_hud() -> String:
	return "Pots : %d    Temps : %d" % [_score, maxi(0, ceili(DUREE - _temps))]


func _fin() -> void:
	_nettoyer()
	_terminer(_score, true, SEUILS, "tir", "pots")


func _nettoyer() -> void:
	for c in _cibles:
		if is_instance_valid(c[0]):
			c[0].queue_free()
	_cibles.clear()
