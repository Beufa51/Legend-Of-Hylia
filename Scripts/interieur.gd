extends Ecran
class_name Interieur
# L'INTÉRIEUR d'une maison (un seul écran, 25 x 14 cases, même taille que les autres).
# On y entre par une porte de l'extérieur (voir `passages` dans ecran.gd) et on en sort de même.
# Lettres du plan :
#   ' ' = vide (noir, hors de la maison)   # = mur (brique)   . = sol de bois   m = paillasson (devant la porte)
#   L = lit (2x3)   S = étagère (2x3)   o = tonneau   B = banc (3x1)
# Une lettre d'objet se met sur le coin HAUT-GAUCHE de l'objet ; le reste de l'objet reste en « . » dans le plan.
# Les habitants (`pnjs`) fonctionnent comme dehors.

const PACK := "res://Assets/Ninja_adventure/Backgrounds/Tilesets/"
const SOL := PACK + "Interior/TilesetInteriorFloor.png"
const LITS := PACK + "tileset_bed.png"
const MAISONS := PACK + "TilesetHouse.png"
const CASE_SOL := Vector2i(4, 13)      # tuile de bois dans TilesetInteriorFloor
const CASE_PAILLASSON := Vector2i(3, 13)

# lettre -> [image, région en cases, bloque ?]
const OBJETS := {
	"L": [LITS, Rect2i(0, 3, 2, 3), true],
	"S": [LITS, Rect2i(7, 6, 2, 3), true],
	"o": [MAISONS, Rect2i(16, 15, 1, 1), true],
	"B": [LITS, Rect2i(2, 6, 3, 2), true],
}

var _solides := {}


func _init() -> void:
	interieur = true


func _ready() -> void:
	position = Vector2(grille * TAILLE_SALLE)
	modulate = teinte
	var noir := ColorRect.new()   # tout l'écran en noir, la maison se dessine par-dessus
	noir.color = Color.BLACK
	noir.size = Vector2(TAILLE_SALLE)
	add_child(noir)
	for y in layout.size():
		for x in layout[y].length():
			var c := layout[y][x]
			var cellule := Vector2i(x, y)
			if c == " ":
				_solides[cellule] = true
			elif c == "#":
				_poser_rect_image("mur_fond", cellule)
				_solides[cellule] = true
			else:
				_poser_region(SOL, Rect2i(CASE_PAILLASSON if c == "m" else CASE_SOL, Vector2i.ONE), cellule)
	for y in layout.size():
		for x in layout[y].length():
			if OBJETS.has(layout[y][x]):
				var def: Array = OBJETS[layout[y][x]]
				_poser_region(def[0], def[1], Vector2i(x, y))
				for dx in def[1].size.x:
					for dy in def[1].size.y:
						_solides[Vector2i(x + dx, y + dy)] = true
	_poser_pnjs()
	_poser_passages()
	_creer_collisions()


func _poser_rect_image(nom: String, cellule: Vector2i) -> void:
	_poser(nom, Vector2(cellule * TUILE))


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


# Une case libre pour poser le joueur (mode développeur) : la plus proche du milieu.
func point_arrivee() -> Vector2:
	var meilleure := Vector2i(12, 8)
	var distance := 1000000
	for y in layout.size():
		for x in layout[y].length():
			var c := Vector2i(x, y)
			if not _solides.has(c) and layout[y][x] in [".", "m"]:
				var d := (c - Vector2i(12, 8)).length_squared()
				if d < distance:
					meilleure = c
					distance = d
	return position + Vector2(meilleure * TUILE) + Vector2(8, 3)
