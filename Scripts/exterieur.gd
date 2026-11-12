extends Room
class_name Exterieur
# Un écran EXTÉRIEUR (village, chemins, forêt...). Même principe qu'une salle du donjon
# (plan texte `layout` de 25 x 14 cases, position `grille`, glissement de caméra), mais sans murs :
# ce sont les arbres, maisons, buissons... qui bloquent le joueur.
# Lettres du plan :
#   .  = herbe            :  = chemin de terre (les bords s'arrondissent tout seuls)
#   A  = arbre rond (2x2)  a = autre arbre rond (2x2)   P = sapin (2x2)
#   b  = buisson (1x1)     f = fleurs jaunes (décor, ne bloque pas)   g = fleurs rouges (décor)
#   M  = maison orange (4x3)   N = maison beige (4x3)
#   E  = étal du marché (3x2)  o = tonneau   j = bannière rouge (1x2)
#   Q  = statue du coq (3x3)   W = puits (2x2)
# Une lettre d'objet se met sur la cellule du COIN HAUT-GAUCHE de l'objet ; les autres cases de l'objet
# restent en herbe ou en chemin dans le plan (le sol est dessiné dessous).

const PACK := "res://Assets/Ninja_adventure/Backgrounds/Tilesets/"
const SOL := PACK + "TilesetFloor.png"
const NATURE := PACK + "TilesetNature.png"
const MAISONS := PACK + "TilesetHouse.png"

# Herbe et chemin (TilesetFloor, en cases de 16 px)
const HERBE := Vector2i(11, 12)
const HERBE_DETAILS := [Vector2i(12, 12), Vector2i(13, 12), Vector2i(14, 12), Vector2i(15, 12)]
const CHEMIN_COIN := Vector2i(11, 7)   # coin haut-gauche du bloc 3x3 des bords du chemin (le centre est (12, 8))
# Coins intérieurs du chemin (quand seule une cellule en diagonale est de l'herbe)
const CHEMIN_INTERIEUR := {"se": Vector2i(16, 8), "so": Vector2i(17, 8), "ne": Vector2i(16, 9), "no": Vector2i(17, 9)}

# Objets : lettre -> [image, région dans l'image (en cases), bloque ?]
# (image "tuile:nom" = une image de Assets/Gemini/tuiles/, sa taille donne la région)
const OBJETS := {
	"A": [NATURE, Rect2i(16, 0, 2, 2), true],
	"a": [NATURE, Rect2i(18, 0, 2, 2), true],
	"P": [NATURE, Rect2i(0, 0, 2, 2), true],
	"b": [NATURE, Rect2i(0, 10, 1, 1), true],
	"f": [NATURE, Rect2i(0, 11, 1, 1), false],
	"g": [NATURE, Rect2i(1, 11, 1, 1), false],
	"M": [MAISONS, Rect2i(0, 0, 4, 3), true],
	"N": [MAISONS, Rect2i(4, 0, 4, 3), true],
	"o": [MAISONS, Rect2i(16, 15, 1, 1), true],
	"j": [MAISONS, Rect2i(23, 20, 1, 2), true],
	"Q": ["tuile:statue_coq", Rect2i(0, 0, 3, 3), true],
	"W": ["tuile:puits", Rect2i(0, 0, 2, 2), true],
}

var _solides := {}   # cases bloquées par un objet


func _creer_decor() -> void:
	_poser_sol()
	for y in layout.size():
		for x in layout[y].length():
			var c := layout[y][x]
			if OBJETS.has(c):
				_poser_objet(OBJETS[c], Vector2i(x, y))
			elif c == "E":   # étal du marché : paniers sur une table
				_poser_region(MAISONS, Rect2i(16, 16, 3, 1), Vector2i(x, y + 1))
				_poser_region(MAISONS, Rect2i(16, 13, 3, 1), Vector2i(x, y))
				for dx in 3:
					for dy in 2:
						_solides[Vector2i(x + dx, y + dy)] = true


# Le sol : herbe partout (avec quelques détails), chemin de terre là où il y a « : ».
func _poser_sol() -> void:
	for y in layout.size():
		for x in layout[y].length():
			var cellule := Vector2i(x, y)
			if _est_chemin(x, y):
				_poser_region(SOL, Rect2i(_tuile_chemin(x, y), Vector2i.ONE), cellule)
			else:
				var h := (x * 73 + y * 151 + grille.x * 31 + grille.y * 17) % 13   # « hasard » fixe
				var tuile: Vector2i = HERBE_DETAILS[h] if h < HERBE_DETAILS.size() else HERBE
				_poser_region(SOL, Rect2i(tuile, Vector2i.ONE), cellule)


# Hors de l'écran, on prolonge la cellule du bord (un chemin qui sort de l'écran n'a pas de bordure).
func _est_chemin(x: int, y: int) -> bool:
	y = clampi(y, 0, layout.size() - 1)
	x = clampi(x, 0, layout[y].length() - 1)
	return layout[y][x] == ":"


# Choisit la tuile de chemin selon les voisins (bords arrondis vers l'herbe).
func _tuile_chemin(x: int, y: int) -> Vector2i:
	var n := _est_chemin(x, y - 1)
	var s := _est_chemin(x, y + 1)
	var o := _est_chemin(x - 1, y)
	var e := _est_chemin(x + 1, y)
	if n and s and o and e:
		if not _est_chemin(x + 1, y + 1): return CHEMIN_INTERIEUR["se"]
		if not _est_chemin(x - 1, y + 1): return CHEMIN_INTERIEUR["so"]
		if not _est_chemin(x + 1, y - 1): return CHEMIN_INTERIEUR["ne"]
		if not _est_chemin(x - 1, y - 1): return CHEMIN_INTERIEUR["no"]
		return CHEMIN_COIN + Vector2i(1, 1)
	var col := 1
	if not o and e: col = 0
	elif o and not e: col = 2
	var lig := 1
	if not n and s: lig = 0
	elif n and not s: lig = 2
	return CHEMIN_COIN + Vector2i(col, lig)


func _poser_objet(def: Array, cellule: Vector2i) -> void:
	var region: Rect2i = def[1]
	var image: String = def[0]
	if image.begins_with("tuile:"):
		_poser(image.substr(6), Vector2(cellule * TUILE))
	else:
		_poser_region(image, region, cellule)
	if def[2]:
		for dx in region.size.x:
			for dy in region.size.y:
				_solides[cellule + Vector2i(dx, dy)] = true


# Pose un morceau (en cases) d'une planche du pack. Sprite2D + region : marche sur toutes les cartes graphiques.
func _poser_region(fichier: String, region: Rect2i, cellule: Vector2i) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(fichier)
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2(region.position * TUILE), Vector2(region.size * TUILE))
	sprite.position = Vector2(cellule * TUILE)
	add_child(sprite)


func _creer_collisions() -> void:
	var corps := StaticBody2D.new()
	add_child(corps)
	for cellule in _solides:
		var forme := RectangleShape2D.new()
		forme.size = Vector2(TUILE, TUILE)
		var collision := CollisionShape2D.new()
		collision.shape = forme
		collision.position = Vector2(cellule * TUILE) + Vector2(TUILE, TUILE) / 2.0
		corps.add_child(collision)


# Une cellule libre pour poser le joueur (mode développeur) : la plus proche du centre de l'écran.
func point_arrivee() -> Vector2:
	var meilleure := Vector2i(12, 11)
	var distance := 1000000
	for y in layout.size():
		for x in layout[y].length():
			var c := Vector2i(x, y)
			if not _solides.has(c) and (layout[y][x] == "." or layout[y][x] == ":"):
				var d := (c - Vector2i(12, 10)).length_squared()
				if d < distance:
					meilleure = c
					distance = d
	return position + Vector2(meilleure * TUILE) + Vector2(8, 3)
