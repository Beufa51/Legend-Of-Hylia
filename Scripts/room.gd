extends Node2D
class_name Room
# Une salle de 20x11 tuiles de 16 px (= 320x180, la taille de l'écran).
# Le plan de la salle est écrit en texte dans `layout` :
#   #  = mur (bloque le joueur)
#   .  = sol
# Une ouverture dans le mur du bord = une porte vers la salle voisine.
# Les graphismes viennent de la planche TilesetInteriorFloor.png du pack Ninja Adventure.

const TUILE := 16
const TAILLE_SALLE := Vector2i(320, 180)
const PLANCHE := "res://Assets/Ninja_adventure/Backgrounds/Tilesets/Interior/TilesetInteriorFloor.png"
# Position (colonne, ligne) des tuiles dans la planche. Pour changer le décor, change ces nombres.
const TUILE_SOL := Vector2i(12, 7)   # sol vert-gris
const TUILE_MUR := Vector2i(12, 13)  # pierre sombre (piliers / blocs au milieu de la salle)
# Cadre de mur vert (style donjon) : planche TilesetWallSimple.png, cadre de 5x5 tuiles
# qui commence à la tuile (5, 6). On y prend les coins et les bords.
const PLANCHE_CADRE := "res://Assets/Ninja_adventure/Backgrounds/Tilesets/Interior/TilesetWallSimple.png"
const ORIGINE_CADRE := Vector2i(5, 6)
# Torches (animation de flamme) et bannières accrochées au mur du haut.
const PLANCHE_FEU := "res://Assets/Ninja_adventure/FX/Particle/Fire.png"   # 8 images de 12x12
const PLANCHE_MAISON := "res://Assets/Ninja_adventure/Backgrounds/Tilesets/TilesetHouse.png"
const COLONNES_TORCHES := [3, 16]    # colonnes (en tuiles) des torches sur le mur du haut
const COLONNES_BANNIERES := [6, 13]  # colonnes des bannières
const BANNIERE := Rect2(23 * 16, 20 * 16, 16, 32)  # bannière rouge dans TilesetHouse.png
const COULEUR_VIDE := Color(0.07, 0.10, 0.11)  # noir-vert : l'intérieur épais des murs
const TUILE_SOL_ETOILE := Vector2i(14, 11)  # petit motif en étoile (rare)
const TUILE_SOL_BRIQUE := Vector2i(11, 10)  # fissure / brique (rare)

# Plan de la salle (11 lignes de 20 caractères). Modifiable dans l'inspecteur.
@export var layout: PackedStringArray
# Position de la salle dans la grille du donjon : (0,0), (1,0), (0,-1)...
@export var grille := Vector2i.ZERO

var _flammes: Array[Sprite2D] = []
var _temps := 0.0


func _ready() -> void:
	# On place la salle à sa case de la grille (chaque case = 320x180 pixels)
	position = Vector2(grille * TAILLE_SALLE)
	_creer_decor()
	_creer_collisions()


# Pose le décor : sol, murs avec cadre, piliers, ombres.
func _creer_decor() -> void:
	var planche: Texture2D = load(PLANCHE)
	var cadre: Texture2D = load(PLANCHE_CADRE)
	if planche == null or cadre == null:
		push_error("Room : impossible de charger une planche de tuiles")
		return
	var murs_cadre := _murs_du_cadre()
	for y in layout.size():
		for x in layout[y].length():
			var pos := Vector2(x * TUILE, y * TUILE)
			if not _est_mur(x, y):
				_poser_tuile(planche, _tuile_sol(x, y), pos)
				# Petite ombre sur le sol, juste sous un mur : donne de la profondeur
				if _est_mur(x, y - 1):
					_poser_rect(pos, Vector2(TUILE, 5), Color(0, 0, 0, 0.27))
				# Case de porte (sur le bord de la salle) : sol assombri = passage
				if x == 0 or y == 0 or x == layout[y].length() - 1 or y == layout.size() - 1:
					_poser_rect(pos, Vector2(TUILE, TUILE), Color(0, 0, 0, 0.45))
			elif not murs_cadre.has(Vector2i(x, y)):
				# Pilier ou bloc isolé : pierre sombre
				_poser_tuile(planche, TUILE_MUR, pos)
			else:
				var piece := _piece_cadre(x, y)
				if piece.x < 0:
					_poser_rect(pos, Vector2(TUILE, TUILE), COULEUR_VIDE)  # mur épais
				else:
					_poser_tuile(cadre, ORIGINE_CADRE + piece, pos)
	_poser_details()


# Torches et bannières sur le mur du haut (seulement là où il y a du mur au-dessus du sol).
func _poser_details() -> void:
	for x in COLONNES_BANNIERES:
		if _mur_haut_libre(x):
			var banniere := Sprite2D.new()
			banniere.texture = load(PLANCHE_MAISON)
			banniere.region_enabled = true
			banniere.region_rect = BANNIERE
			banniere.centered = false
			banniere.position = Vector2(x * TUILE, 9)
			add_child(banniere)
	for x in COLONNES_TORCHES:
		if _mur_haut_libre(x):
			_poser_torche(Vector2(x * TUILE + TUILE / 2.0, 0))


# Vrai si la case (x, 0) est un mur avec du sol juste en dessous.
func _mur_haut_libre(x: int) -> bool:
	return _est_mur(x, 0) and _est_sol(x, 1) and layout.size() > 1


# Une torche : support en métal + manche + flamme animée.
func _poser_torche(haut: Vector2) -> void:
	_poser_rect(haut + Vector2(-3, 10), Vector2(6, 2), Color(0.35, 0.35, 0.4))   # coupelle
	_poser_rect(haut + Vector2(-1, 12), Vector2(2, 4), Color(0.45, 0.28, 0.15))  # manche
	var flamme := Sprite2D.new()
	flamme.texture = load(PLANCHE_FEU)
	flamme.hframes = 8
	flamme.frame = 3
	flamme.position = haut + Vector2(0, 5)
	add_child(flamme)
	_flammes.append(flamme)


# Anime les flammes (on boucle sur les images 3 à 6 de Fire.png).
func _process(delta: float) -> void:
	_temps += delta
	for i in _flammes.size():
		_flammes[i].frame = 3 + int(_temps * 8.0 + i * 2) % 4


# Vrai si la case est un mur (hors de la salle = mur).
func _est_mur(x: int, y: int) -> bool:
	if y < 0 or y >= layout.size() or x < 0 or x >= layout[y].length():
		return true
	return layout[y][x] == "#"


# Vrai si la case est du sol (hors de la salle = pas du sol).
func _est_sol(x: int, y: int) -> bool:
	return not _est_mur(x, y)


# Liste des murs reliés au bord de la salle (ce sont eux qui reçoivent le cadre).
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
		if vus.has(c) or not _est_mur(c.x, c.y):
			continue
		if c.x < 0 or c.y < 0 or c.y >= layout.size() or c.x >= layout[c.y].length():
			continue
		vus[c] = true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			a_voir.append(c + d)
	return vus


# Quelle pièce du cadre pour ce mur ? Renvoie sa position (colonne, ligne) dans le cadre 5x5,
# ou (-1,-1) si le mur ne touche aucun sol (on met alors du noir).
func _piece_cadre(x: int, y: int) -> Vector2i:
	var n := _est_sol(x, y - 1)
	var s := _est_sol(x, y + 1)
	var e := _est_sol(x + 1, y)
	var o := _est_sol(x - 1, y)
	# Sur le bord de la salle, une porte ne doit pas casser le mur en "coins" :
	# on ignore les voisins le long du bord pour garder un bord continu.
	if y == 0 or y == layout.size() - 1:
		e = false
		o = false
	if x == 0 or x == layout[y].length() - 1:
		n = false
		s = false
	if s and e: return Vector2i(0, 0)   # coin haut-gauche
	if s and o: return Vector2i(4, 0)   # coin haut-droite
	if n and e: return Vector2i(0, 4)   # coin bas-gauche
	if n and o: return Vector2i(4, 4)   # coin bas-droite
	if s: return Vector2i(3, 0)         # bord du haut
	if n: return Vector2i(3, 4)         # bord du bas
	if e: return Vector2i(0, 2)         # bord gauche
	if o: return Vector2i(4, 2)         # bord droit
	if _est_sol(x + 1, y + 1): return Vector2i(0, 0)
	if _est_sol(x - 1, y + 1): return Vector2i(4, 0)
	if _est_sol(x + 1, y - 1): return Vector2i(0, 4)
	if _est_sol(x - 1, y - 1): return Vector2i(4, 4)
	return Vector2i(-1, -1)


# Rectangle de couleur unie (ombres, murs épais).
func _poser_rect(pos: Vector2, taille: Vector2, couleur: Color) -> void:
	var r := ColorRect.new()
	r.color = couleur
	r.size = taille
	r.position = pos
	add_child(r)


# Choisit une tuile de sol : surtout du sol uni, avec quelques motifs rares.
# Le calcul est fixe (pas de hasard) : une salle a toujours le même aspect.
func _tuile_sol(x: int, y: int) -> Vector2i:
	var h := (x * 7 + y * 13 + x * y * 3) % 17
	if h == 0:
		return TUILE_SOL_ETOILE
	if h == 1:
		return TUILE_SOL_BRIQUE
	return TUILE_SOL


# Crée un Sprite2D d'une tuile de la planche à la position donnée.
func _poser_tuile(planche: Texture2D, tuile: Vector2i, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = planche
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(tuile.x * TUILE, tuile.y * TUILE, TUILE, TUILE)
	sprite.position = pos
	add_child(sprite)


# Ajoute une boîte de collision à chaque mur.
func _creer_collisions() -> void:
	var corps := StaticBody2D.new()
	add_child(corps)
	for y in layout.size():
		for x in layout[y].length():
			if layout[y][x] == "#":
				var forme := RectangleShape2D.new()
				forme.size = Vector2(TUILE, TUILE)
				var collision := CollisionShape2D.new()
				collision.shape = forme
				collision.position = Vector2(x * TUILE + TUILE / 2.0, y * TUILE + TUILE / 2.0)
				corps.add_child(collision)

