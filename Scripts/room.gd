extends Node2D
class_name Room
# Une salle de 25x14 tuiles de 16 px (= 400x224, la taille de l'écran).
# Le plan de la salle est écrit en texte dans `layout` :
#   #  = mur (bloque le joueur)       .  = sol
#   T  = sol avec tapis               B  = brasero (bloque)
#   S  = statue de chevalier (bloque) O  = statue d'oiseau (bloque)
#   V  = vase (bloque)
# Une ouverture dans le mur du bord = une porte vers la salle voisine.
# Les graphismes sont les petites images de Assets/Gemini/tuiles/ (voir Outils/traiter_gemini.py).

const TUILE := 16
const TAILLE_SALLE := Vector2i(400, 224)
const DOSSIER := "res://Assets/Gemini/tuiles/"

# Caractères qui bloquent le joueur (en plus des murs)
const SOLIDES := "#SOBV"
# Épaisseur des murs du bord (en tuiles)
const EPAISSEUR := 2
# Colonnes (en tuiles) des torches et des bannières sur le mur du haut
const COLONNES_TORCHES := [4, 20]
const COLONNES_BANNIERES := [7, 17]

# Plan de la salle (14 lignes de 25 caractères). Modifiable dans l'inspecteur.
@export var layout: PackedStringArray
# Position de la salle dans la grille du donjon : (0,0), (1,0), (0,-1)...
@export var grille := Vector2i.ZERO

# Cache des images déjà chargées (partagé entre toutes les salles)
static var _cache := {}

# Éléments animés : chaque entrée = { "sprite", "images", "decalage" }
var _animes: Array[Dictionary] = []
var _temps := 0.0


func _ready() -> void:
	# On place la salle à sa case de la grille (chaque case = une salle entière)
	position = Vector2(grille * TAILLE_SALLE)
	_creer_decor()
	_creer_collisions()


# Anime torches et braseros en alternant leurs images.
func _process(delta: float) -> void:
	_temps += delta
	for a in _animes:
		var images: Array = a["images"]
		a["sprite"].texture = images[int(_temps * 6.0 + a["decalage"]) % images.size()]


# --- Chargement ---------------------------------------------------------------

func _image(nom: String) -> Texture2D:
	if not _cache.has(nom):
		_cache[nom] = load(DOSSIER + nom + ".png")
		if _cache[nom] == null:
			push_error("Room : image introuvable " + DOSSIER + nom + ".png")
	return _cache[nom]


# Pose une image à la position donnée (coin haut-gauche) et la renvoie.
func _poser(nom: String, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _image(nom)
	sprite.centered = false
	sprite.position = pos
	add_child(sprite)
	return sprite


# Rectangle de couleur unie (ombres, passages).
func _poser_rect(pos: Vector2, taille: Vector2, couleur: Color) -> void:
	var r := ColorRect.new()
	r.color = couleur
	r.size = taille
	r.position = pos
	add_child(r)


# --- Décor --------------------------------------------------------------------

func _creer_decor() -> void:
	var murs_cadre := _murs_du_cadre()
	for y in layout.size():
		for x in layout[y].length():
			var pos := Vector2(x * TUILE, y * TUILE)
			if not _est_mur(x, y):
				_poser(_nom_sol(x, y), pos)
				# Petite ombre sur le sol, juste sous un mur : donne de la profondeur
				if _est_mur(x, y - 1):
					_poser_rect(pos, Vector2(TUILE, 5), Color(0, 0, 0, 0.27))
				# Case de porte (sur le bord de la salle) : sol assombri = passage
				if x < EPAISSEUR or y < EPAISSEUR or x >= layout[y].length() - EPAISSEUR or y >= layout.size() - EPAISSEUR:
					_poser_rect(pos, Vector2(TUILE, TUILE), Color(0, 0, 0, 0.45))
			elif murs_cadre.has(Vector2i(x, y)):
				_poser_mur(x, y)
			else:
				_poser("dalle_unie", pos)  # pilier / bloc isolé
	_poser_objets()
	_poser_details()


# Tuile de sol : sol plat et uni, comme dans Zelda SNES (peu de détails au sol).
func _nom_sol(_x: int, _y: int) -> String:
	return "sol_plat"


# Mur : fond sombre + liserés de pierre du côté du sol.
func _poser_mur(x: int, y: int) -> void:
	var pos := Vector2(x * TUILE, y * TUILE)
	_poser("mur_fond", pos)
	var n := _est_sol(x, y - 1)
	var s := _est_sol(x, y + 1)
	var e := _est_sol(x + 1, y)
	var o := _est_sol(x - 1, y)
	# Coins d'abord (deux côtés de sol), puis les côtés restants
	var utilise := {"n": false, "s": false, "e": false, "o": false}
	for coin in [["n", "o", n, o], ["n", "e", n, e], ["s", "o", s, o], ["s", "e", s, e]]:
		if coin[2] and coin[3]:
			_poser("mur_coin_" + coin[0] + coin[1], pos)
			utilise[coin[0]] = true
			utilise[coin[1]] = true
	for cote in [["n", n], ["s", s], ["e", e], ["o", o]]:
		if cote[1] and not utilise[cote[0]]:
			_poser("mur_bord_" + cote[0], pos)
	# Angle rentrant : sol seulement en diagonale
	if not (n or s or e or o):
		if _est_sol(x + 1, y + 1):
			_poser("mur_dot_se", pos)
		if _est_sol(x - 1, y + 1):
			_poser("mur_dot_so", pos)
		if _est_sol(x + 1, y - 1):
			_poser("mur_dot_ne", pos)
		if _est_sol(x - 1, y - 1):
			_poser("mur_dot_no", pos)


# Tapis, statues, braseros, vases posés d'après les lettres du plan.
func _poser_objets() -> void:
	for y in layout.size():
		for x in layout[y].length():
			var pos := Vector2(x * TUILE, y * TUILE)
			match layout[y][x]:
				"T":
					_poser("tapis_milieu", pos)
				"S":
					_poser("statue_chevalier", pos + Vector2(0, TUILE - 30))
				"O":
					_poser("statue_oiseau", pos + Vector2(0, TUILE - 30))
				"V":
					_poser("vase_1", pos + Vector2(3, 3))
				"B":
					_poser_anime(["brasero_1", "brasero_2", "brasero_3"], pos, x + y)


# Torches et bannières sur le mur du haut (seulement là où il y a du mur au-dessus du sol).
func _poser_details() -> void:
	for x in COLONNES_BANNIERES:
		if _mur_haut_libre(x):
			_poser("banniere", Vector2(x * TUILE, EPAISSEUR * TUILE - 26))
	for x in COLONNES_TORCHES:
		if _mur_haut_libre(x):
			_poser_anime(["torche_1", "torche_2"], Vector2(x * TUILE, (EPAISSEUR - 1) * TUILE), x)


# Vrai si la dernière ligne du mur du haut en (x) est un mur avec du sol juste en dessous.
func _mur_haut_libre(x: int) -> bool:
	return _est_mur(x, EPAISSEUR - 1) and _est_sol(x, EPAISSEUR)


# Pose un élément animé (alternance de plusieurs images).
func _poser_anime(noms: Array, pos: Vector2, decalage: int) -> void:
	var images: Array = []
	for nom in noms:
		images.append(_image(nom))
	var sprite := _poser(noms[0], pos)
	_animes.append({"sprite": sprite, "images": images, "decalage": decalage})


# --- Plan ---------------------------------------------------------------------

# Vrai si la case est un mur (hors de la salle = mur).
func _est_mur(x: int, y: int) -> bool:
	if y < 0 or y >= layout.size() or x < 0 or x >= layout[y].length():
		return true
	return layout[y][x] == "#"


# Vrai si la case est dans la salle et n'est pas un mur (objets compris).
func _est_sol(x: int, y: int) -> bool:
	return not _est_mur(x, y)


# Liste des murs reliés au bord de la salle (ils reçoivent liserés de pierre).
# Les blocs isolés au milieu (piliers) n'y sont pas.
func _murs_du_cadre() -> Dictionary:
	var vus := {}
	var a_voir: Array[Vector2i] = []
	for y in layout.size():
		for x in layout[y].length():
			if (x == 0 or y == 0 or x == layout[y].length() - 1 or y == layout.size() - 1) and layout[y][x] == "#":
				a_voir.append(Vector2i(x, y))
	while not a_voir.is_empty():
		var c: Vector2i = a_voir.pop_back()
		if c.x < 0 or c.y < 0 or c.y >= layout.size() or c.x >= layout[c.y].length():
			continue
		if vus.has(c) or layout[c.y][c.x] != "#":
			continue
		vus[c] = true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			a_voir.append(c + d)
	return vus


# --- Collisions ---------------------------------------------------------------

# Ajoute une boîte de collision à chaque mur et objet solide.
func _creer_collisions() -> void:
	var corps := StaticBody2D.new()
	add_child(corps)
	for y in layout.size():
		for x in layout[y].length():
			if SOLIDES.contains(layout[y][x]):
				var forme := RectangleShape2D.new()
				forme.size = Vector2(TUILE, TUILE)
				var collision := CollisionShape2D.new()
				collision.shape = forme
				collision.position = Vector2(x * TUILE + TUILE / 2.0, y * TUILE + TUILE / 2.0)
				corps.add_child(collision)
