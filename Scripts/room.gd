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
#   1 à 5 = cloche à frapper à la lance (le chiffre = sa note, 1 = la plus grave)
#   C  = statue du coq chanteur : frappée, elle joue la `melodie` de la salle
#   R  = soleil incrusté dans le mur : le rayon de lumière part de là (vers la seule case de sol voisine)
#   M  = miroir « / »   N = miroir « \\ » : un coup de lance le fait pivoter ; le rayon rebondit dessus
#   Y  = réceptacle du rayon (lève `drapeau_rayon`)   W = fragment d'aile à ramasser (lève `drapeau_gemme`)
#   H  = porte fermée qui s'ouvre avec `drapeau_porte2` (une 2e porte dans la même salle)
#   ^ v < > = sentinelle (statue de garde) qui regarde dans cette direction (voir `periodes_sentinelles`)
# Une ouverture dans le mur du bord = une porte vers la salle voisine.
# Les graphismes sont les petites images de Assets/Gemini/tuiles/ (voir Outils/traiter_gemini.py).

const TUILE := 16
const TAILLE_SALLE := Vector2i(400, 224)
const DOSSIER := "res://Assets/Gemini/tuiles/"

# Caractères qui bloquent le joueur (en plus des murs)
const SOLIDES := "#SOBR"
# Épaisseur des murs du bord (en tuiles)
const EPAISSEUR := 2
# Son d'une fausse note (pack Ninja Adventure)
const SON_ERREUR := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Cancel.wav"
# Regard des sentinelles : portée (en cases) et couleur des cases surveillées
const PORTEE_REGARD := 7
const COULEUR_REGARD := Color(1.0, 0.85, 0.3, 0.28)
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
@export var melodie := ""          # notes à rejouer sur les cloches, dans l'ordre (ex. "132")
@export var drapeau_melodie := ""  # levé quand on a rejoué toute la mélodie sans faute
@export var indice := ""           # message affiché la première fois qu'on entre dans la salle
# Sentinelles : temps (s) entre deux quarts de tour de chaque sentinelle, dans l'ordre de lecture du plan
# (de gauche à droite, de haut en bas). 0 ou absent = elle ne tourne pas.
@export var periodes_sentinelles: PackedFloat32Array
@export var retour := Vector2.ZERO   # où un garde ramène le joueur repéré (position dans le monde)
@export var drapeau_repos := ""      # quand ce drapeau est levé, les sentinelles ne surveillent plus
@export var drapeau_porte2 := ""     # les portes H de cette salle s'ouvrent quand ce drapeau est levé
@export var drapeau_rayon := ""      # levé quand le rayon de lumière touche le réceptacle Y
@export var chanteur_au_soleil := false   # la statue du coq ne chante que si le rayon l'éclaire

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
var _portes2: Array[Porte] = []
# Rayon de lumière
var _source := Vector2i(-1, -1)   # case du soleil R (-1 = pas de rayon dans cette salle)
var _dir_source := Vector2i.RIGHT
var _miroirs := {}                # { case : Miroir }
var _cible: Cible
var _case_cible := Vector2i(-1, -1)
var _case_chanteur := Vector2i(-1, -1)
var _points_rayon := PackedVector2Array()   # le trajet du rayon (centres des cases), pour le dessin
var _calque_rayon: Node2D
var _lumieres_rayon: Array[PointLight2D] = []
var _statue_au_soleil := false
var _cloches := {}         # { note (int) : Cloche }
var _progression := 0      # combien de notes de la mélodie ont déjà été rejouées
var _en_chant := false     # vrai pendant que la statue chante
var _sentinelles: Array[Sentinelle] = []
var _regards := {}         # { case : vrai si la sentinelle va bientôt tourner } = cases surveillées
var _calque_regards: Node2D   # dessine les cases surveillées par-dessus le sol
var _repere := false       # le joueur vient d'être repéré (on attend que le garde le ramène)


func _ready() -> void:
	# On place la salle à sa case de la grille (chaque case = une salle entière)
	position = Vector2(grille * TAILLE_SALLE)
	modulate = teinte  # ne teinte que cette salle (le joueur est ailleurs dans la scène)
	_creer_decor()
	_creer_collisions()
	Etat.drapeau_change.connect(_sur_drapeau)
	if Etat.est(drapeau_porte):
		_sur_drapeau(drapeau_porte)  # drapeau déjà levé : les portes sont ouvertes d'emblée
	if Etat.est(drapeau_porte2):
		_sur_drapeau(drapeau_porte2)
	if _cible != null and Etat.est(drapeau_rayon):
		_cible.allumer()
	if Etat.est(drapeau_melodie):
		for cloche in _cloches.values():
			cloche.dorer()


# Anime torches et braseros en alternant leurs images.
func _process(delta: float) -> void:
	_temps += delta
	for a in _animes:
		var images: Array = a["images"]
		a["sprite"].texture = images[int(_temps * 6.0 + a["decalage"]) % images.size()]
	# Les lueurs vacillent doucement
	for i in _lumieres.size():
		_lumieres[i].modulate.a = 0.8 + 0.2 * sin(_temps * 7.0 + i * 1.7) * sin(_temps * 3.1 + i)
	# Les sentinelles ne surveillent que la salle où se trouve le joueur
	if not _sentinelles.is_empty() and grille == Etat.salle_courante:
		_surveiller(delta)
	if _source.x >= 0 and grille == Etat.salle_courante:
		_tracer_rayon()


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
	if _source.x >= 0:
		_calque_rayon = Node2D.new()
		_calque_rayon.z_index = 1
		var additif := CanvasItemMaterial.new()
		additif.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # le rayon "éclaire" ce qu'il traverse
		_calque_rayon.material = additif
		_calque_rayon.draw.connect(_dessiner_rayon)
		add_child(_calque_rayon)
	if not _sentinelles.is_empty():
		_calque_regards = Node2D.new()
		_calque_regards.z_index = 1
		_calque_regards.draw.connect(_dessiner_regards)
		add_child(_calque_regards)


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
				"1", "2", "3", "4", "5":
					var cloche := Cloche.new()
					cloche.position = pos
					add_child(cloche)
					cloche.initialiser(self, int(layout[y][x]), sombre, _image("cloche_support"), _image("cloche_" + layout[y][x]))
					_cloches[int(layout[y][x])] = cloche
					_occupe[Vector2i(x, y)] = cloche
				"^", "v", "<", ">":
					var sentinelle := Sentinelle.new()
					sentinelle.position = pos
					add_child(sentinelle)
					var directions := {"^": Vector2i.UP, "v": Vector2i.DOWN, "<": Vector2i.LEFT, ">": Vector2i.RIGHT}
					var n := _sentinelles.size()
					var periode: float = periodes_sentinelles[n] if n < periodes_sentinelles.size() else 0.0
					sentinelle.initialiser(Vector2i(x, y), directions[layout[y][x]], periode, _image("statue_chevalier"), sombre)
					_sentinelles.append(sentinelle)
					_occupe[Vector2i(x, y)] = sentinelle
				"R":
					_source = Vector2i(x, y)
					for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
						if not _est_mur(x + d.x, y + d.y):
							_dir_source = d
					_poser("source_soleil", pos)
				"M", "N":
					var miroir := Miroir.new()
					miroir.position = pos
					add_child(miroir)
					miroir.initialiser(layout[y][x] == "M", _image("miroir_m"), _image("miroir_n"))
					_miroirs[Vector2i(x, y)] = miroir
					_occupe[Vector2i(x, y)] = miroir
				"Y":
					_cible = Cible.new()
					_cible.position = pos
					add_child(_cible)
					_cible.initialiser(_image("cible"), _image("cible_allumee"))
					_case_cible = Vector2i(x, y)
					_occupe[Vector2i(x, y)] = _cible
				"W":
					var fragment := Ramassable.new()
					fragment.position = pos
					add_child(fragment)
					fragment.initialiser(drapeau_gemme, "Fragment de l'aile gauche obtenu !", _image("fragment_aile"))
				"C":
					_case_chanteur = Vector2i(x, y)
					var chanteur := Chanteur.new()
					chanteur.position = pos
					add_child(chanteur)
					chanteur.initialiser(self, _image("statue_oiseau"), sombre)
					_occupe[Vector2i(x, y)] = chanteur


# Portes D (drapeau_porte) et H (drapeau_porte2).
func _poser_portes() -> void:
	_poser_portes_lettre("D", _portes)
	_poser_portes_lettre("H", _portes2)


# Regroupe les cases voisines portant la lettre : chaque groupe devient UNE porte, dessinée avec l'image porte_LxH.
func _poser_portes_lettre(lettre: String, liste: Array[Porte]) -> void:
	var vues := {}
	for y in layout.size():
		for x in layout[y].length():
			var depart := Vector2i(x, y)
			if layout[y][x] != lettre or vues.has(depart):
				continue
			var groupe: Array[Vector2i] = []
			var a_voir: Array[Vector2i] = [depart]
			while not a_voir.is_empty():
				var c: Vector2i = a_voir.pop_back()
				if vues.has(c) or c.y < 0 or c.y >= layout.size() or c.x < 0 or c.x >= layout[c.y].length() or layout[c.y][c.x] != lettre:
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
			liste.append(porte)
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
	_progression = 0
	for sentinelle in _sentinelles:
		sentinelle.reinitialiser()
	for miroir in _miroirs.values():
		miroir.reinitialiser()
	for brasero in _braseros:
		if brasero.allume and not brasero.verrouille:
			brasero.eteindre()
	_repere = false


# Appelé par un brasero qui vient de s'allumer : si tous brûlent en même temps, c'est gagné.
func verifier_braseros() -> void:
	if drapeau_braseros == "":
		return   # braseros sans énigme (ex. pour détourner le regard des sentinelles)
	for brasero in _braseros:
		if not brasero.allume:
			return
	for brasero in _braseros:
		brasero.verrouiller()
	Etat.poser(drapeau_braseros)


# Mode développeur : une case libre où poser le joueur, le plus près possible de l'entrée du bas (12, 11).
# Renvoie la position (dans le monde) du centre du joueur.
func point_arrivee() -> Vector2:
	var meilleure := Vector2i(12, 11)
	var meilleure_distance := 1000000
	for y in range(EPAISSEUR, layout.size() - EPAISSEUR):
		for x in range(EPAISSEUR, layout[y].length() - EPAISSEUR):
			var c := Vector2i(x, y)
			if ".TPF".contains(layout[y][x]) and not _occupe.has(c):
				var d := (c - Vector2i(12, 11)).length_squared()
				if d < meilleure_distance:
					meilleure = c
					meilleure_distance = d
	return position + Vector2(meilleure * TUILE) + Vector2(8, 3)   # les pieds du joueur au centre de la case


# --- Sentinelles -----------------------------------------------------------------

# Chaque image : les sentinelles tournent la tête (ou fixent la flamme la plus proche),
# on calcule les cases qu'elles voient, et si le joueur est sur l'une d'elles, il est repéré.
func _surveiller(delta: float) -> void:
	_regards.clear()
	var au_repos := Etat.est(drapeau_repos)
	for sentinelle in _sentinelles:
		if au_repos:
			sentinelle.endormir()
			continue
		sentinelle.avancer(delta)
		sentinelle.regarder(_direction_attiree(sentinelle))
		var bientot := sentinelle.va_tourner()
		for c in _cases_vues(sentinelle.case, sentinelle.direction):
			_regards[c] = bientot
	_calque_regards.queue_redraw()
	if au_repos or _repere:
		return
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	if joueur == null:
		return
	var pied := to_local(joueur.global_position) + Vector2(0, 5)   # les pieds du joueur
	if _regards.has(Vector2i(floori(pied.x / TUILE), floori(pied.y / TUILE))):
		_repere = true
		Etat.repere.emit(retour)


# Une flamme allumée attire le regard : la sentinelle fixe le brasero allumé le plus proche.
func _direction_attiree(sentinelle: Sentinelle) -> Vector2i:
	var meilleur: Brasero = null
	var meilleure_distance := INF
	for brasero in _braseros:
		var d := Vector2(sentinelle.case).distance_squared_to(brasero.position / TUILE)
		if brasero.allume and d < meilleure_distance:
			meilleur = brasero
			meilleure_distance = d
	if meilleur == null:
		return sentinelle.direction_normale()
	var vers := meilleur.position / TUILE - Vector2(sentinelle.case)
	if absf(vers.x) >= absf(vers.y):
		return Vector2i(signi(roundi(vers.x)), 0)
	return Vector2i(0, signi(roundi(vers.y)))


# Les cases vues : un cône qui s'élargit (1, 3, 3, puis 5 cases de large), arrêté par tout obstacle.
func _cases_vues(depuis: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	var vues: Array[Vector2i] = []
	var cote := Vector2i(-dir.y, dir.x)   # perpendiculaire au regard
	for distance in range(1, PORTEE_REGARD + 1):
		var demi := mini(2, int(distance / 2.0))
		for decalage in range(-demi, demi + 1):
			var c := depuis + dir * distance + cote * decalage
			if not _opaque(c) and _ligne_libre(depuis, c, distance * 4):
				vues.append(c)
	return vues


# Vrai si rien ne bloque la vue entre deux cases (on avance par petits pas sur la ligne).
func _ligne_libre(a: Vector2i, b: Vector2i, pas: int) -> bool:
	for i in range(1, pas):
		var t := float(i) / pas
		var c := Vector2i(floori(a.x + (b.x - a.x) * t + 0.5), floori(a.y + (b.y - a.y) * t + 0.5))
		if c != a and c != b and _opaque(c):
			return false
	return true


# Une case cache la vue : murs, statues, braseros, et tout ce qui occupe une case (blocs, pots, portes...).
func _opaque(c: Vector2i) -> bool:
	if c.y < 0 or c.y >= layout.size() or c.x < 0 or c.x >= layout[c.y].length():
		return true
	return "#SOBKR".contains(layout[c.y][c.x]) or _occupe.has(c)


# Dessine les cases surveillées (elles clignotent juste avant que la sentinelle tourne).
func _dessiner_regards() -> void:
	for c in _regards:
		var couleur := COULEUR_REGARD
		if _repere:
			couleur = Color(1.0, 0.2, 0.15, 0.45)
		elif _regards[c] and int(_temps * 8.0) % 2 == 0:
			couleur.a *= 0.4
		_calque_regards.draw_rect(Rect2(Vector2(c * TUILE), Vector2(TUILE, TUILE)), couleur)


# --- Rayon de lumière --------------------------------------------------------------

# Suit le rayon case par case depuis le soleil : il rebondit sur les miroirs et s'arrête sur le premier obstacle.
func _tracer_rayon() -> void:
	var c := _source
	var dir := _dir_source
	_points_rayon = PackedVector2Array([_centre(c)])
	var cases: Array[Vector2i] = []
	var sur_statue := false
	for _i in 300:   # sécurité : jamais plus de 300 cases (le rayon pourrait tourner en rond entre miroirs)
		var suivante := c + dir
		if _miroirs.has(suivante):
			_points_rayon.append(_centre(suivante))
			dir = _miroirs[suivante].renvoyer(dir)
			c = suivante
			continue
		if suivante == _case_cible:
			_points_rayon.append(_centre(suivante) - Vector2(dir) * 5.0)
			if not _cible.allumee:
				_cible.allumer()
				Etat.poser(drapeau_rayon)
			break
		if suivante == _case_chanteur:
			_points_rayon.append(_centre(suivante) - Vector2(dir) * 5.0)
			sur_statue = true
			break
		if _opaque(suivante):
			_points_rayon.append(_centre(c) + Vector2(dir) * 8.0)
			break
		c = suivante
		cases.append(c)
	# Le coq chante quand le soleil se lève sur lui !
	if sur_statue and not _statue_au_soleil:
		jouer_melodie()
	_statue_au_soleil = sur_statue
	_calque_rayon.queue_redraw()
	if sombre:
		_eclairer_rayon(cases)


func _centre(c: Vector2i) -> Vector2:
	return Vector2(c * TUILE) + Vector2(8, 8)


# Dans une salle sombre, le rayon éclaire son chemin : une lumière toutes les 2 cases.
func _eclairer_rayon(cases: Array[Vector2i]) -> void:
	var n := 0
	for i in range(0, cases.size(), 2):
		if n >= _lumieres_rayon.size():
			var l := Lumiere.creer(Color(1.0, 0.92, 0.6), 0.5, 0.9)
			add_child(l)
			_lumieres_rayon.append(l)
		_lumieres_rayon[n].position = Vector2(cases[i] * TUILE) + Vector2(8, 8)
		_lumieres_rayon[n].enabled = true
		n += 1
	for j in range(n, _lumieres_rayon.size()):
		_lumieres_rayon[j].enabled = false


# Le rayon : un trait doré épais et transparent (halo) + un trait fin presque blanc (cœur), qui scintille.
func _dessiner_rayon() -> void:
	var scintille := 0.85 + 0.15 * sin(_temps * 12.0)
	for i in range(_points_rayon.size() - 1):
		_calque_rayon.draw_line(_points_rayon[i], _points_rayon[i + 1], Color(1.0, 0.7, 0.2, 0.35 * scintille), 6.0)
		_calque_rayon.draw_line(_points_rayon[i], _points_rayon[i + 1], Color(1.0, 0.95, 0.7, 0.9 * scintille), 2.0)


# La statue du coq a été frappée : elle chante... sauf si elle attend le soleil.
func statue_frappee() -> void:
	if chanteur_au_soleil and not _statue_au_soleil:
		Etat.annoncer("La statue reste muette... Le coq ne chante qu'au lever du soleil.")
		return
	jouer_melodie()


# --- Énigme du chant du coq ----------------------------------------------------

# La statue chante : chaque note de la mélodie fait sonner et briller sa cloche, l'une après l'autre.
func jouer_melodie() -> void:
	if _en_chant:
		return
	_en_chant = true
	_progression = 0
	for i in melodie.length():
		var cloche: Cloche = _cloches.get(int(melodie[i]))
		if cloche != null:
			cloche.sonner(Cloche.ECLAT)
		await get_tree().create_timer(0.6).timeout
	_en_chant = false


# Appelé par une cloche frappée par le joueur.
func cloche_frappee(note: int) -> void:
	if melodie == "" or _en_chant or Etat.est(drapeau_melodie):
		return
	if str(note) == melodie[_progression]:
		_progression += 1
		if _progression == melodie.length():
			_progression = 0
			for cloche in _cloches.values():
				cloche.dorer()
			Etat.poser(drapeau_melodie)
		return
	# Fausse note : toutes les cloches rougissent et on recommence depuis le début
	_progression = 0
	for cloche in _cloches.values():
		cloche.rougir()
	_jouer_son(SON_ERREUR, -6.0)


func _jouer_son(chemin: String, volume_db: float) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = volume_db
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)


func _sur_drapeau(nom: String) -> void:
	if nom == "":
		return
	for paire in [[drapeau_porte, _portes], [drapeau_porte2, _portes2]]:
		if nom != paire[0]:
			continue
		var liste: Array = paire[1]
		if not liste.is_empty() and grille != Etat.salle_courante:
			Etat.annoncer("Un bruit sourd : une porte s'est ouverte quelque part...")
		for porte in liste:
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
	return "#R".contains(layout[y][x])


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
			if (x == 0 or y == 0 or x == layout[y].length() - 1 or y == layout.size() - 1) and "#R".contains(layout[y][x]):
				a_voir.append(Vector2i(x, y))
	while not a_voir.is_empty():
		var c: Vector2i = a_voir.pop_back()
		if c.x < 0 or c.y < 0 or c.y >= layout.size() or c.x >= layout[c.y].length():
			continue
		if vus.has(c) or not "#R".contains(layout[c.y][c.x]):
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
