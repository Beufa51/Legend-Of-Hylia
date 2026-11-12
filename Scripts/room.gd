extends Node2D
class_name Room
# Une salle de 25x14 tuiles de 16 px (= 400x224, la taille de l'écran).
# Le plan de la salle est écrit en texte dans `layout` :
#   #  = mur (bloque le joueur)       .  = sol
#   T  = sol avec tapis               B  = brasero (bloque)
#   S  = statue de chevalier (bloque) O  = statue d'oiseau (bloque)
#   V  = pot cassable à coups de lance (bloque tant qu'il est entier)
#   P  = plaque de pression orange (sol, ne bloque pas)   F = dalle à flèches (sol)
#   X  = bloc à pousser (sur le sol)  D = porte fermée (s'ouvre quand `drapeau_porte` est levé)
#   G  = plume dorée à ramasser (lève `drapeau_gemme`)
#   K  = cristal à frapper à la lance (lève `drapeau_cristal`)
#   L  = brasero à allumer à la lance, dans une salle `sombre` (voir `drapeau_braseros`)
#   P  = bouton de sol : s'enfonce quand un bloc est dessus (voir `drapeau_plaque`)
# Une ouverture dans le mur du bord = une porte vers la salle voisine.
# Les graphismes sont les petites images de Assets/Gemini/tuiles/ (voir Outils/traiter_gemini.py).

const TUILE := 16
const TAILLE_SALLE := Vector2i(400, 224)
const DOSSIER := "res://Assets/Gemini/tuiles/"

# Caractères qui bloquent le joueur (en plus des murs)
const SOLIDES := "#SOB"
# Épaisseur des murs du bord (en tuiles)
const EPAISSEUR := 2
# Colonnes (en tuiles) des torches et des bannières sur le mur du haut
const COLONNES_TORCHES := [4, 20]
const COLONNES_BANNIERES := [7, 17]

# Plan de la salle (14 lignes de 25 caractères). Modifiable dans l'inspecteur.
@export var layout: PackedStringArray
# Position de la salle dans la grille du donjon : (0,0), (1,0), (0,-1)...
@export var grille := Vector2i.ZERO
# Teinte de la salle (blanc = couleurs normales). Chaque salle a son ambiance.
@export var teinte := Color.WHITE
# Énigmes : noms de drapeaux (voir etat.gd). Vide = rien.
@export var drapeau_plaque := ""   # levé quand TOUTES les plaques P portent un bloc
@export var drapeau_porte := ""    # les portes D de cette salle s'ouvrent quand ce drapeau est levé
@export var drapeau_gemme := ""    # levé quand on ramasse la plume G de cette salle
@export var drapeau_cristal := ""  # levé quand on frappe le cristal K de cette salle
@export var sombre := false        # salle plongée dans le noir (seules les lumières éclairent)
@export var drapeau_braseros := "" # levé quand TOUS les braseros L sont allumés en même temps
@export var duree_braseros := 14.0 # secondes avant qu'un brasero L s'éteigne

# Cache des images déjà chargées (partagé entre toutes les salles)
static var _cache := {}
# Lueur des flammes (texture et matériau partagés par toutes les lumières)
static var _tex_lumiere: GradientTexture2D
static var _mat_lumiere: CanvasItemMaterial

# Éléments animés : chaque entrée = { "sprite", "images", "decalage" }
var _animes: Array[Dictionary] = []
var _temps := 0.0
var _lumieres: Array[Sprite2D] = []
# Ce qui occupe une case : { Vector2i : noeud } (pots, blocs, portes). Sert à savoir si une case est libre.
var _occupe := {}
var _blocs: Array[Bloc] = []
var _plaques: Array[Vector2i] = []
var _braseros: Array[Brasero] = []
var _boutons := {}   # { case : Sprite2D } image de chaque bouton (relevé / enfoncé)
var _portes: Array[Porte] = []


func _ready() -> void:
	# On place la salle à sa case de la grille (chaque case = une salle entière)
	position = Vector2(grille * TAILLE_SALLE)
	modulate = teinte  # ne teinte que cette salle (le joueur est ailleurs dans la scène)
	_creer_decor()
	_creer_collisions()
	Etat.drapeau_change.connect(_sur_drapeau)
	if Etat.est(drapeau_porte):
		_sur_drapeau(drapeau_porte)  # drapeau déjà levé : les portes sont ouvertes d'emblée


# Anime torches et braseros en alternant leurs images.
func _process(delta: float) -> void:
	_temps += delta
	for a in _animes:
		var images: Array = a["images"]
		a["sprite"].texture = images[int(_temps * 6.0 + a["decalage"]) % images.size()]
	# Les lueurs vacillent doucement
	for i in _lumieres.size():
		_lumieres[i].modulate.a = 0.8 + 0.2 * sin(_temps * 7.0 + i * 1.7) * sin(_temps * 3.1 + i)


# --- Chargement ---------------------------------------------------------------

func _image(nom: String) -> Texture2D:
	if not _cache.has(nom):
		var chemin := DOSSIER + nom + ".png"
		var tex = load(chemin) if ResourceLoader.exists(chemin) else null
		if tex == null:
			# Image pas encore importée par Godot : on la lit directement dans le fichier
			var img := Image.load_from_file(ProjectSettings.globalize_path(chemin))
			if img != null:
				tex = ImageTexture.create_from_image(img)
			else:
				push_error("Room : image introuvable " + chemin)
		_cache[nom] = tex
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
	_poser_portes()
	_poser_details()


# Tuile de sol : damier discret de deux tons (comme Zelda SNES), avec de rares dalles fissurées/usées.
# Le calcul est fixe (pas de hasard) : une salle a toujours le même aspect.
func _nom_sol(x: int, y: int) -> String:
	var h := (x * 7 + y * 13 + x * y * 3) % 37
	var clair := (x + y) % 2 == 0
	if h == 0:
		return "sol_plat_c" if clair else "sol_plat_d"
	return "sol_plat" if clair else "sol_plat_b"


# Mur : fond sombre + liserés de pierre du côté du sol.
func _poser_mur(x: int, y: int) -> void:
	var pos := Vector2(x * TUILE, y * TUILE)
	_poser("mur_fond", pos)
	# Relief : le mur loin du sol est plus sombre, celui qui touche le sol reste clair
	if not (_est_sol(x, y - 1) or _est_sol(x, y + 1) or _est_sol(x + 1, y) or _est_sol(x - 1, y)
			or _est_sol(x + 1, y + 1) or _est_sol(x - 1, y + 1) or _est_sol(x + 1, y - 1) or _est_sol(x - 1, y - 1)):
		_poser_rect(pos, Vector2(TUILE, TUILE), Color(0, 0, 0, 0.38))
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
					var pot := Pot.new()
					pot.position = pos
					add_child(pot)
					pot.initialiser(_image("vase_1"))
					_suivre(pot, Vector2i(x, y))
				"B":
					_poser_anime(["brasero_1", "brasero_2", "brasero_3"], pos, x + y)
					_poser_lumiere(pos + Vector2(8, 6), 44.0)
				"P":
					_boutons[Vector2i(x, y)] = _poser("bouton", pos)
					_plaques.append(Vector2i(x, y))
				"L":
					var brasero := Brasero.new()
					brasero.position = pos
					add_child(brasero)
					var flammes: Array[Texture2D] = [_image("brasero_1"), _image("brasero_2"), _image("brasero_3")]
					brasero.initialiser(self, duree_braseros, _image("brasero_eteint"), flammes)
					_braseros.append(brasero)
					_occupe[Vector2i(x, y)] = brasero
				"K":
					var cristal := Cristal.new()
					cristal.position = pos
					add_child(cristal)
					cristal.initialiser(drapeau_cristal, "")
				"X":
					var bloc := Bloc.new()
					add_child(bloc)
					bloc.initialiser(self, Vector2i(x, y), _image("dalle_fleches"))
					_occupe[Vector2i(x, y)] = bloc
					_blocs.append(bloc)
				"D":
					pass  # les portes sont créées plus bas, par groupes de cases voisines (_poser_portes)
				"G":
					var plume := Ramassable.new()
					plume.position = pos
					add_child(plume)
					plume.initialiser(drapeau_gemme, "Plume obtenue !")
				"F":
					_poser("dalle_fleches", pos)


# Regroupe les cases `D` voisines : chaque groupe devient UNE porte, dessinée avec l'image porte_LxH.
func _poser_portes() -> void:
	var vues := {}
	for y in layout.size():
		for x in layout[y].length():
			var depart := Vector2i(x, y)
			if layout[y][x] != "D" or vues.has(depart):
				continue
			var groupe: Array[Vector2i] = []
			var a_voir: Array[Vector2i] = [depart]
			while not a_voir.is_empty():
				var c: Vector2i = a_voir.pop_back()
				if vues.has(c) or c.y < 0 or c.y >= layout.size() or c.x < 0 or c.x >= layout[c.y].length() or layout[c.y][c.x] != "D":
					continue
				vues[c] = true
				groupe.append(c)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					a_voir.append(c + d)
			var haut_gauche := groupe[0]
			var bas_droite := groupe[0]
			for c in groupe:
				haut_gauche = Vector2i(mini(haut_gauche.x, c.x), mini(haut_gauche.y, c.y))
				bas_droite = Vector2i(maxi(bas_droite.x, c.x), maxi(bas_droite.y, c.y))
			var taille := Vector2(bas_droite - haut_gauche + Vector2i.ONE) * TUILE
			var porte := Porte.new()
			porte.position = Vector2(haut_gauche * TUILE)
			add_child(porte)
			porte.initialiser(taille, _image("porte_%dx%d" % [int(taille.x), int(taille.y)]))
			_portes.append(porte)
			for c in groupe:
				_suivre(porte, c)


# --- Énigmes : cases occupées, plaques, portes ---------------------------------

# Note qu'un noeud occupe une case ; la case se libère toute seule quand le noeud disparaît.
func _suivre(noeud: Node, cellule: Vector2i) -> void:
	_occupe[cellule] = noeud
	noeud.tree_exiting.connect(_oublier.bind(cellule, noeud))


func _oublier(cellule: Vector2i, noeud: Node) -> void:
	if _occupe.get(cellule) == noeud:
		_occupe.erase(cellule)


func occuper(cellule: Vector2i, noeud: Node) -> void:
	_occupe[cellule] = noeud


func liberer(cellule: Vector2i) -> void:
	_occupe.erase(cellule)


# Une case est libre pour un bloc si c'est du sol (pas un mur ni une statue) et que rien ne l'occupe.
func case_libre(cellule: Vector2i) -> bool:
	if cellule.y < 0 or cellule.y >= layout.size() or cellule.x < 0 or cellule.x >= layout[cellule.y].length():
		return false
	return ".TPFXV".contains(layout[cellule.y][cellule.x]) and not _occupe.has(cellule)


# Appelé après chaque poussée : si toutes les plaques portent un bloc, on lève le drapeau.
func verifier_plaques() -> void:
	_maj_boutons()
	if drapeau_plaque == "" or _plaques.is_empty():
		return
	for plaque in _plaques:
		if not (_occupe.get(plaque) is Bloc):
			return
	Etat.poser(drapeau_plaque)


# Chaque bouton s'enfonce quand un bloc est dessus, et remonte sinon.
func _maj_boutons() -> void:
	for cellule in _boutons:
		var appuye: bool = _occupe.get(cellule) is Bloc
		_boutons[cellule].texture = _image("bouton_enfonce" if appuye else "bouton")


# Touche R : les blocs reviennent à leur place de départ.
func reinitialiser() -> void:
	for bloc in _blocs:
		bloc.reinitialiser()
	_maj_boutons()


# Appelé par un brasero qui vient de s'allumer : si tous brûlent en même temps, c'est gagné.
func verifier_braseros() -> void:
	for brasero in _braseros:
		if not brasero.allume:
			return
	for brasero in _braseros:
		brasero.verrouiller()
	Etat.poser(drapeau_braseros)


func _sur_drapeau(nom: String) -> void:
	if nom != "" and nom == drapeau_porte:
		if not _portes.is_empty() and grille != Etat.salle_courante:
			Etat.annoncer("Un bruit sourd : une porte s'est ouverte quelque part...")
		for porte in _portes:
			if is_instance_valid(porte):
				porte.ouvrir()


# Torches et bannières sur le mur du haut (seulement là où il y a du mur au-dessus du sol).
func _poser_details() -> void:
	if sombre:
		return  # pas de torches dans une salle sombre
	for x in COLONNES_BANNIERES:
		if _mur_haut_libre(x):
			_poser("banniere", Vector2(x * TUILE, EPAISSEUR * TUILE - 26))
	for x in COLONNES_TORCHES:
		if _mur_haut_libre(x):
			_poser_anime(["torche_1", "torche_2"], Vector2(x * TUILE, (EPAISSEUR - 1) * TUILE), x)
			_poser_lumiere(Vector2(x * TUILE + 8, EPAISSEUR * TUILE + 2), 52.0)


# Vrai si la dernière ligne du mur du haut en (x) est un mur avec du sol juste en dessous.
func _mur_haut_libre(x: int) -> bool:
	return _est_mur(x, EPAISSEUR - 1) and _est_sol(x, EPAISSEUR)


# Lueur orangée (mélangée en "addition") autour d'une flamme.
func _poser_lumiere(centre: Vector2, rayon: float) -> void:
	if _tex_lumiere == null:
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.62, 0.25, 0.5))
		g.set_color(1, Color(1.0, 0.45, 0.1, 0.0))
		_tex_lumiere = GradientTexture2D.new()
		_tex_lumiere.gradient = g
		_tex_lumiere.width = 64
		_tex_lumiere.height = 64
		_tex_lumiere.fill = GradientTexture2D.FILL_RADIAL
		_tex_lumiere.fill_from = Vector2(0.5, 0.5)
		_tex_lumiere.fill_to = Vector2(1.0, 0.5)
		_mat_lumiere = CanvasItemMaterial.new()
		_mat_lumiere.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var lueur := Sprite2D.new()
	lueur.texture = _tex_lumiere
	lueur.material = _mat_lumiere
	lueur.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	lueur.position = centre
	lueur.scale = Vector2.ONE * (rayon * 2.0 / 64.0)
	add_child(lueur)
	_lumieres.append(lueur)


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
