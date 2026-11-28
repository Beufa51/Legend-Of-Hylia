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
#   Z = MALLE À DÉCORS (maison du héros) : un coup de lance ouvre le mode décoration (decoration.gd)
# Les habitants (`pnjs`) fonctionnent comme dehors.
# MAISON À DÉCORER (`decorable`) : les meubles achetés chez Rosine (Etat.decors, catalogue decors.gd) sont posés par-dessus le plan.
# `cases_vitales` ("x y") : des cases qui doivent toujours rester libres et atteignables depuis la porte (réveil au lit, tableau d'honneur...).
# AGRANDIR : la maison utilise `layout_revele` quand `drapeau_revele` est levé (voir ecran.gd), même en direct (on reconstruit l'écran).

@export var style := "maison"
@export var decorable := false
@export var cases_vitales: PackedStringArray

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
	"Z": ["v_coffre", Vector2i(2, 2), true],
}

var _solides := {}           # cases bloquées par le plan (murs, meubles fixes) ; les décors du joueur n'y sont pas
var _calque_tapis: Node2D    # décors posés à plat (tapis, bannières), sous les meubles
var _calque_decors: Node2D   # décors du joueur (images + collisions)
var _malle: MalleDeco


func _init() -> void:
	interieur = true


# Bruit des pas : planches dans une maison, dalles à la caserne.
func surface_pas(_pos: Vector2) -> String:
	return "bois" if style == "maison" else "dalle"


func _ready() -> void:
	_construire()
	Etat.drapeau_change.connect(func(nom):
		if nom == drapeau_revele and drapeau_revele != "":
			call_deferred("_reconstruire"))


# Agrandissement acheté pendant la partie : on refait l'écran avec le nouveau plan.
func _reconstruire() -> void:
	for enfant in get_children():
		remove_child(enfant)
		enfant.queue_free()
	_solides.clear()
	_construire()


func _construire() -> void:
	_appliquer_revelation()
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
	_calque_tapis = Node2D.new()   # (les tapis du joueur : au-dessus du sol, sous les meubles)
	add_child(_calque_tapis)
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
				if c == "Z":   # la malle : un corps à part, qui réagit au coup de lance
					_malle = MalleDeco.new()
					_malle.position = Vector2(x, y) * TUILE + Vector2(emprise * TUILE) / 2.0
					_malle.interieur = self
					add_child(_malle)
	_calque_decors = Node2D.new()
	add_child(_calque_decors)
	if decorable:
		Decors.preparer()
		poser_decors()
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


# --- MAISON À DÉCORER --------------------------------------------------------------------------------

func _def(id: String) -> Dictionary:
	return Decors.CATALOGUE[id]


# (Re)pose tous les décors du joueur : images alignées comme les meubles (centrées sur l'emprise, posées en bas), + collisions.
func poser_decors() -> void:
	for calque in [_calque_tapis, _calque_decors]:
		for enfant in calque.get_children():
			enfant.queue_free()
	var places := []
	for d in Etat.decors:
		if d["x"] >= 0:
			places.append(d)
	places.sort_custom(func(a, b): return a["y"] + _def(a["id"])["emprise"].y < b["y"] + _def(b["id"])["emprise"].y)
	for d in places:
		var def := _def(d["id"])
		var calque := _calque_decors if def["bloque"] else _calque_tapis
		var sprite := Sprite2D.new()
		sprite.texture = _image(def["image"])
		sprite.centered = false
		var emprise: Vector2i = def["emprise"]
		var taille := Vector2(sprite.texture.get_size())
		sprite.position = (Vector2((d["x"] + emprise.x / 2.0) * TUILE, (d["y"] + emprise.y) * TUILE) - Vector2(taille.x / 2.0, taille.y)).round()
		calque.add_child(sprite)
		if def["bloque"]:
			var corps := StaticBody2D.new()
			var forme := RectangleShape2D.new()
			forme.size = Vector2(emprise * TUILE)
			var collision := CollisionShape2D.new()
			collision.shape = forme
			collision.position = Vector2(d["x"], d["y"]) * TUILE + Vector2(emprise * TUILE) / 2.0
			corps.add_child(collision)
			_calque_decors.add_child(corps)


# Les cases (de l'écran) couvertes par un décor posé en `case`.
func cases_de(id: String, case: Vector2i) -> Array[Vector2i]:
	var liste: Array[Vector2i] = []
	var emprise: Vector2i = _def(id)["emprise"]
	for dx in emprise.x:
		for dy in emprise.y:
			liste.append(case + Vector2i(dx, dy))
	return liste


# Le décor posé sur cette case (index dans Etat.decors), les meubles avant les tapis ; -1 s'il n'y en a pas.
func decor_en(case: Vector2i) -> int:
	var tapis := -1
	for i in Etat.decors.size():
		var d: Dictionary = Etat.decors[i]
		if d["x"] >= 0 and case in cases_de(d["id"], Vector2i(d["x"], d["y"])):
			if _def(d["id"])["bloque"]:
				return i
			tapis = i
	return tapis


func _vitales() -> Array[Vector2i]:
	var liste: Array[Vector2i] = []
	for ligne in cases_vitales:
		var m := ligne.split(" ")
		liste.append(Vector2i(int(m[0]), int(m[1])))
	return liste


# Une case de SOL de la pièce (pas un mur, pas la porte, pas sous un meuble fixe) ?
func _sol_libre(case: Vector2i) -> bool:
	if case.y < 0 or case.y >= layout.size() or case.x < 0 or case.x >= layout[case.y].length():
		return false
	return layout[case.y][case.x] == "." and not _solides.has(case)


# Les cases occupées par les décors bloquants (sauf celui d'index `sauf`).
func _cases_decors(sauf: int) -> Dictionary:
	var occupe := {}
	for i in Etat.decors.size():
		var d: Dictionary = Etat.decors[i]
		if i != sauf and d["x"] >= 0 and _def(d["id"])["bloque"]:
			for c in cases_de(d["id"], Vector2i(d["x"], d["y"])):
				occupe[c] = true
	return occupe


# Peut-on poser le décor n° `index` (de type `id`) en `case` ? Vérifie le sol, les autres décors, le joueur, les habitants,
# et que la porte mène toujours aux cases vitales (on ne s'enferme jamais).
func peut_poser(index: int, case: Vector2i) -> bool:
	var id: String = Etat.decors[index]["id"]
	var def := _def(id)
	var cases := cases_de(id, case)
	for c in cases:
		if not _sol_libre(c):
			return false
	if not def["bloque"]:   # un tapis : seulement pas sur un autre tapis
		for i in Etat.decors.size():
			var d: Dictionary = Etat.decors[i]
			if i != index and d["x"] >= 0 and not _def(d["id"])["bloque"]:
				for c in cases_de(d["id"], Vector2i(d["x"], d["y"])):
					if c in cases:
						return false
		return true
	var occupe := _cases_decors(index)
	var vitales := _vitales()
	for c in cases:
		if occupe.has(c) or c in vitales:
			return false
	# ni sur le joueur, ni sur un habitant
	var corps: Array = get_tree().get_nodes_in_group("pnj")
	var joueur := get_tree().get_first_node_in_group("joueur")
	if joueur:
		corps.append(joueur)
	for n in corps:
		var pied := Vector2i(((n.global_position - position) / TUILE).floor())
		if pied in cases:
			return false
	for c in cases:
		occupe[c] = true
	return _vitales_atteignables(occupe)


# Depuis la porte (1re case vitale), toutes les cases vitales sont-elles atteignables à pied ?
func _vitales_atteignables(occupe: Dictionary) -> bool:
	var vitales := _vitales()
	if vitales.is_empty():
		return true
	var vus := {vitales[0]: true}
	var file: Array[Vector2i] = [vitales[0]]
	while not file.is_empty():
		var c: Vector2i = file.pop_back()
		for v in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + v
			if not vus.has(n) and _sol_libre(n) and not occupe.has(n):
				vus[n] = true
				file.append(n)
	for c in vitales:
		if not vus.has(c):
			return false
	return true


# Coup de lance sur la malle : le mode décoration s'ouvre.
func ouvrir_decoration() -> void:
	if decorable and not Etat.en_dialogue:
		add_child(Decoration.creer(self))
