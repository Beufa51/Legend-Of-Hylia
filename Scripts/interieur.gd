extends Ecran
class_name Interieur
# L'INTÉRIEUR d'une maison (un seul écran, 25 x 14 cases, même taille que les autres).
# On y entre par une porte de l'extérieur (voir `passages` dans ecran.gd) et on en sort de même.
# `style` : "maison" (bois, murs crème) ou "caserne" (pierre).
# Lettres du plan :
#   ' ' = vide (noir)   # = mur plein (côtés et bas)   . = sol   m = porte (paillasson)
#   MUR DU HAUT (2x2, lettre sur la case haut-gauche) : w x = pans de mur, y = fenêtre, v = tableau, z = cheminée
#   MEUBLES (lettre sur la case haut-gauche de l'emprise) :
#     maison  : L lit rouge  l lit bleu  S étagère  A armoire  T table ronde  U table  C chaise  k coffre
#               o tonneau  p pot  q marmite  B banc  t tapis rouge  Y tapis rond
#     caserne : G lit  H râtelier lances  I râtelier armes  J boucliers  K mannequin  F brasero  M table de carte
#               D coffre d'armes  N bannière  B banc long  o tonneau
# Les habitants (`pnjs`) fonctionnent comme dehors.

@export var style := "maison"

# Par style : sol, murs. Meubles : lettre -> [image, emprise (largeur, hauteur) en cases, bloque ?]
const STYLES := {
	"maison": {
		"sol": ["v_sol_bois", "v_sol_bois", "v_sol_bois", "v_sol_bois_b", "v_sol_bois_c"],
		"mur": "v_mur_bois",
		"haut": {"w": "v_mur_a", "x": "v_mur_b", "y": "v_mur_fenetre", "v": "v_mur_tableau", "z": "v_cheminee"},
	},
	"caserne": {
		"sol": ["v_sol_pierre"],
		"mur": "v_mur_pierre_16",
		"haut": {"w": "v_mur_pierre", "x": "v_mur_pierre", "y": "v_mur_pierre", "v": "v_mur_pierre", "z": "v_mur_pierre_cheminee"},
	},
}
const MEUBLES := {
	"L": ["v_lit_rouge", Vector2i(2, 3), true],
	"l": ["v_lit_bleu", Vector2i(2, 3), true],
	"S": ["v_etagere", Vector2i(3, 2), true],
	"A": ["v_armoire", Vector2i(2, 3), true],
	"T": ["v_table_ronde", Vector2i(2, 2), true],
	"U": ["v_table", Vector2i(4, 2), true],
	"C": ["v_chaise", Vector2i(1, 1), true],
	"k": ["v_coffre", Vector2i(2, 2), true],
	"o": ["v_tonneau", Vector2i(1, 1), true],
	"p": ["v_pot", Vector2i(1, 1), true],
	"q": ["v_marmite", Vector2i(1, 1), true],
	"B": ["v_banc", Vector2i(3, 1), true],
	"t": ["v_tapis_rouge", Vector2i(3, 2), false],
	"Y": ["v_tapis_rond", Vector2i(3, 3), false],
	"G": ["v_lit_caserne", Vector2i(2, 3), true],
	"H": ["v_ratelier_lances", Vector2i(4, 2), true],
	"I": ["v_ratelier_armes", Vector2i(4, 2), true],
	"J": ["v_boucliers", Vector2i(2, 1), true],
	"K": ["v_mannequin", Vector2i(1, 2), true],
	"F": ["v_brasero", Vector2i(1, 2), true],
	"M": ["v_table_carte", Vector2i(4, 2), true],
	"D": ["v_coffre_armes", Vector2i(2, 2), true],
	"N": ["v_banniere", Vector2i(1, 2), false],
	"m": ["v_paillasson", Vector2i(1, 1), false],
}

var _solides := {}


func _init() -> void:
	interieur = true


func _ready() -> void:
	position = Vector2(grille * TAILLE_SALLE)
	modulate = teinte
	var def: Dictionary = STYLES.get(style, STYLES["maison"])
	var noir := ColorRect.new()   # tout l'écran en noir, la maison se dessine par-dessus
	noir.color = Color.BLACK
	noir.size = Vector2(TAILLE_SALLE)
	add_child(noir)
	# 1) le sol et les murs pleins
	var sols: Array = def["sol"]
	for y in layout.size():
		for x in layout[y].length():
			var c := layout[y][x]
			var cellule := Vector2i(x, y)
			if c == " ":
				_solides[cellule] = true
			elif c == "#":
				_poser(def["mur"], Vector2(cellule * TUILE))
				_solides[cellule] = true
			elif def["haut"].has(c):
				_solides[cellule] = true   # (le dessin du pan de mur vient après)
			else:
				_poser(sols[(x * 7 + y * 13) % sols.size()], Vector2(cellule * TUILE))
	# 2) les pans de mur du haut (2x2), puis 3) les meubles, de haut en bas
	for y in layout.size():
		for x in layout[y].length():
			var c := layout[y][x]
			if def["haut"].has(c):
				_poser(def["haut"][c], Vector2(x * TUILE, y * TUILE))
				for dx in 2:
					for dy in 2:
						_solides[Vector2i(x + dx, y + dy)] = true
	for y in layout.size():
		for x in layout[y].length():
			var c := layout[y][x]
			if MEUBLES.has(c):
				var m: Array = MEUBLES[c]
				var emprise: Vector2i = m[1]
				var sprite := _poser(m[0], Vector2.ZERO)
				var taille := Vector2(sprite.texture.get_size())
				sprite.position = (Vector2((x + emprise.x / 2.0) * TUILE, (y + emprise.y) * TUILE) - Vector2(taille.x / 2.0, taille.y)).round()
				if m[2]:
					for dx in emprise.x:
						for dy in emprise.y:
							_solides[Vector2i(x + dx, y + dy)] = true
	_poser_pnjs()
	_poser_passages()
	_poser_minijeu()
	_creer_collisions()


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
