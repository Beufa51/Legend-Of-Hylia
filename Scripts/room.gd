extends Ecran
class_name Room
# Une SALLE DE DONJON (voir ecran.gd pour ce qui est commun avec les écrans extérieurs).
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
#   o  = plot ORANGE (levé au départ)   u = plot BLEU (baissé au départ). Dans une salle à plots,
#        le cristal K est un commutateur : chaque coup de lance inverse les plots (voir plot.gd).
#   z  = dalle de couleur : chaque pas la retourne (rouge <-> bleue). Toutes bleues = `drapeau_fragile` (voir dalle.gd).
#   Q  = coffre (un coup de lance l'ouvre, lève `drapeau_coffre` ; ex. une clé)      J = levier (lève `drapeau_levier`)
#   E  = porte à serrure (porte de bois) : s'ouvre si le joueur la touche avec la clé `drapeau_cle` (lève `drapeau_serrure`)
#   Z  = pics qui sortent du sol en boucle (sortis = retour à `retour`)              ~ = eau (bloque)
# Portes : un groupe 3x2 sur le mur du HAUT = arche animée (herse, ou bois pour E) ; 3x1 dans un mur intérieur
# = herse basse ; les autres (bas, côtés) gardent l'ancienne grille.
# Une ouverture dans le mur du bord = une porte vers la salle voisine.
# Les graphismes sont les petites images de Assets/Gemini/tuiles/ (voir Outils/traiter_gemini.py).


# Caractères qui bloquent le joueur (en plus des murs)
const SOLIDES := "#SOBR~"
# Épaisseur des murs du bord (en tuiles)
const EPAISSEUR := 2
# Son d'une fausse note (pack Ninja Adventure)
const SON_ERREUR := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Cancel.wav"
# Regard des sentinelles : un CÔNE de vision (portée en cases, demi-ouverture en radians) et ses couleurs
const PORTEE_REGARD := 7
const DEMI_ANGLE := 0.4538   # 26 degrés (en radians)
const RAYONS_CONE := 24   # nombre de rayons lancés pour dessiner le cône (plus = plus lisse)
const COULEUR_REGARD := Color(1.0, 0.85, 0.3, 0.42)   # près de l'œil (le bout du cône est plus transparent)
const COULEUR_REPERE := Color(1.0, 0.2, 0.15, 0.55)
# Colonnes (en tuiles) des torches et des bannières sur le mur du haut
const COLONNES_TORCHES := [4, 20]
const COLONNES_BANNIERES := [7, 17]
# Images animées (pack donjon Craftpix, voir Outils/traiter_pack_donjon.py). Le brasero fait 20x26 :
# sa case de 16x16 est en bas au centre, d'où le décalage.
const BRASERO := ["brasero_1", "brasero_2", "brasero_3", "brasero_4", "brasero_5", "brasero_6"]
const TORCHE := ["torche_1", "torche_2", "torche_3", "torche_4", "torche_5", "torche_6"]
const DECALAGE_BRASERO := Vector2(-2, -10)

# Énigmes : noms de drapeaux (voir etat.gd). Vide = rien.
@export var drapeau_plaque := ""   # levé quand TOUTES les plaques P portent un bloc
@export var drapeau_porte := ""    # les portes D de cette salle s'ouvrent quand ce drapeau est levé
@export var drapeau_gemme := ""    # levé quand on ramasse la plume G de cette salle
@export var drapeau_cristal := ""  # levé quand on frappe le cristal K de cette salle
@export var drapeau_braseros := "" # levé quand TOUS les braseros L sont allumés en même temps
@export var duree_braseros := 14.0 # secondes avant qu'un brasero L s'éteigne
@export var melodie := ""          # notes à rejouer sur les cloches, dans l'ordre (ex. "132")
@export var drapeau_melodie := ""  # levé quand on a rejoué toute la mélodie sans faute
# Sentinelles : temps (s) entre deux quarts de tour de chaque sentinelle, dans l'ordre de lecture du plan
# (de gauche à droite, de haut en bas). 0 ou absent = elle ne tourne pas.
@export var periodes_sentinelles: PackedFloat32Array
@export var retour := Vector2.ZERO   # où un garde ramène le joueur repéré (position dans le monde)
@export var drapeau_repos := ""      # quand ce drapeau est levé, les sentinelles ne surveillent plus
@export var drapeau_porte2 := ""     # les portes H de cette salle s'ouvrent quand ce drapeau est levé
@export var drapeau_rayon := ""      # levé quand le rayon de lumière touche le réceptacle Y
@export var chanteur_au_soleil := false   # la statue du coq ne chante que si le rayon l'éclaire
@export var drapeau_fragile := ""    # levé quand TOUTES les dalles de couleur z sont bleues
@export var drapeau_coffre := ""     # levé quand on ouvre le coffre Q
@export var texte_coffre := "Tu as trouvé une petite clé !"
@export var drapeau_levier := ""     # levé quand on bascule le levier J
@export var drapeau_cle := ""        # la clé qui ouvre les portes à serrure E de cette salle
@export var drapeau_serrure := ""    # levé quand une porte E est ouverte (elle s'ouvre avec ce drapeau)
@export var periode_pics := 2.4      # durée d'un cycle des pics Z (secondes)

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
var _cones: Array[PackedVector2Array] = []   # un cône par sentinelle : [œil, puis les bouts des rayons]
var _cones_clignotent: Array[bool] = []      # vrai si la sentinelle va bientôt tourner
var _calque_regards: Node2D   # dessine les cônes AU-DESSUS de l'obscurité (dans un CanvasLayer)
var _flamme_vue := false      # le message « la flamme attire le regard » n'est montré qu'une fois
var _repere := false       # le joueur vient d'être repéré (on attend que le garde le ramène)
var _plots: Array[Plot] = []
var _commutateurs: Array[Cristal] = []
var _orange_leves := true  # vrai = les plots orange bloquent, les bleus sont baissés
var _dalles := {}          # { case : Dalle } dalles de couleur
var _case_pied := Vector2i(-1, -1)   # case où le joueur avait les pieds à l'image précédente
var _regle_dite := false   # la règle des dalles a été expliquée (au 1er pas sur une dalle)
var _portes_cle: Array[Porte] = []
var _pics := {}            # { case : Pics }
var _pique := false        # le joueur vient d'être touché par des pics (on attend le retour)
var _chargement := true    # vrai pendant _ready : les portes déjà ouvertes s'ouvrent sans bruit


func _ready() -> void:
	# On place la salle à sa case de la grille (chaque case = une salle entière)
	position = Vector2(grille * TAILLE_SALLE)
	modulate = teinte  # ne teinte que cette salle (le joueur est ailleurs dans la scène)
	_creer_decor()
	_creer_collisions()
	Etat.drapeau_change.connect(_sur_drapeau)
	for d in [drapeau_porte, drapeau_porte2, drapeau_serrure]:
		if Etat.est(d):
			_sur_drapeau(d)  # drapeau déjà levé : les portes sont ouvertes d'emblée, sans bruit
	_chargement = false
	if _cible != null and Etat.est(drapeau_rayon):
		_cible.allumer()
	if Etat.est(drapeau_melodie):
		for cloche in _cloches.values():
			cloche.dorer()
	if Etat.est(drapeau_fragile):
		for dalle in _dalles.values():
			dalle.valider(false)


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
	if not _dalles.is_empty() and grille == Etat.salle_courante:
		_suivre_pas()
	if not _pics.is_empty() and grille == Etat.salle_courante:
		_surveiller_pics()


# --- Chargement ---------------------------------------------------------------

# --- Décor --------------------------------------------------------------------

func _creer_decor() -> void:
	for y in layout.size():
		for x in layout[y].length():
			var pos := Vector2(x * TUILE, y * TUILE)
			if not _est_mur(x, y):
				_poser(_nom_sol(x, y), pos)
				# Case de porte (sur le bord de la salle) : sol assombri = passage
				if x < EPAISSEUR or y < EPAISSEUR or x >= layout[y].length() - EPAISSEUR or y >= layout.size() - EPAISSEUR:
					_poser_rect(pos, Vector2(TUILE, TUILE), Color(0, 0, 0, 0.35))
			else:
				_poser_mur(x, y)
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


# Tuile de sol (pack donjon Craftpix) : gris-bleu uni comme dans Zelda SNES, avec de rares dalles gravées. Le calcul est fixe (pas de hasard) : une salle a toujours le même aspect.
func _nom_sol(x: int, y: int) -> String:
	var h := (x * 7 + y * 13 + x * y * 3) % 37
	if h == 0:
		return "sol_plat_c"
	if h == 18:
		return "sol_plat_d"
	return "sol_plat"


# MUR (vue de 3/4, comme dans Zelda SNES) :
# - un mur avec du sol juste EN DESSOUS montre sa FACE de briques (`mur_face_bas`), et le mur juste
#   au-dessus de cette face aussi (`mur_face_haut`) : le mur du haut de la salle fait 2 rangées de briques ;
# - les autres murs sont vus DE DESSUS : sombres, avec un rebord de briques du côté du sol ;
# - un mur isolé d'une seule case est un petit pilier (`pilier`, 8 px plus haut que sa case).
# Images : Outils/traiter_pack_donjon.py.
func _face_bas(x: int, y: int) -> bool:
	return _est_mur(x, y) and y + 1 < layout.size() and _est_sol(x, y + 1)


func _poser_mur(x: int, y: int) -> void:
	var pos := Vector2(x * TUILE, y * TUILE)
	if not (_est_mur(x - 1, y) or _est_mur(x + 1, y) or _est_mur(x, y - 1) or _est_mur(x, y + 1)):
		_poser(_nom_sol(x, y), pos)
		_poser("pilier", pos - Vector2(0, 8))
		return
	var bas := _face_bas(x, y)
	if bas or (_face_bas(x, y + 1) and _est_mur(x, y - 1)):
		var nom := "mur_face_bas" if bas else "mur_face_haut"
		if not _est_mur(x - 1, y):
			nom += "_g"   # bout gauche de la face
		elif not _est_mur(x + 1, y):
			nom += "_d"   # bout droit
		if bas:
			_poser("sol_plat", pos)   # le bas de la face est transparent (ombre portée sur le sol)
		_poser(nom, pos)
		return
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
		for d in [["se", 1, 1], ["so", -1, 1], ["ne", 1, -1], ["no", -1, -1]]:
			if _est_sol(x + d[1], y + d[2]):
				_poser("mur_dot_" + d[0], pos)


# Tapis, statues, braseros, vases posés d'après les lettres du plan.
func _poser_objets() -> void:
	var a_plots := false
	for ligne in layout:
		if ligne.contains("o") or ligne.contains("u"):
			a_plots = true
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
					pot.initialiser(_image("vase_1" if (x + y) % 3 else "vase_2"))   # vases bleus et quelques bruns
					_suivre(pot, Vector2i(x, y))
				"B":
					_poser_anime(BRASERO, pos + DECALAGE_BRASERO, x + y)
					_poser_lumiere(pos + Vector2(8, 6), 44.0)
				"P":
					_boutons[Vector2i(x, y)] = _poser("bouton", pos)
					_plaques.append(Vector2i(x, y))
				"L":
					var brasero := Brasero.new()
					brasero.position = pos
					add_child(brasero)
					var flammes: Array[Texture2D] = []
					for nom in BRASERO:
						flammes.append(_image(nom))
					brasero.initialiser(self, duree_braseros, _image("brasero_eteint"), flammes)
					_braseros.append(brasero)
					_occupe[Vector2i(x, y)] = brasero
				"K":
					var cristal := Cristal.new()
					cristal.position = pos
					add_child(cristal)
					cristal.initialiser(drapeau_cristal, "", self if a_plots else null)
					if a_plots:
						cristal.colorer(true)
						_commutateurs.append(cristal)
					_occupe[Vector2i(x, y)] = cristal
				"Q":
					var coffre := Coffre.new()
					coffre.position = pos
					add_child(coffre)
					coffre.initialiser(drapeau_coffre, texte_coffre, _images_serie("coffre_", 5), _image("cle"))
					_occupe[Vector2i(x, y)] = coffre
				"J":
					var levier := Levier.new()
					levier.position = pos
					add_child(levier)
					levier.initialiser(drapeau_levier, _images_serie("levier_", 5))
					_occupe[Vector2i(x, y)] = levier
				"Z":
					var pics := Pics.new()
					pics.position = pos
					add_child(pics)
					# une colonne sur deux est décalée d'un demi-cycle : on passe entre elles au bon moment
					pics.initialiser(_images_serie("pics_", 5), periode_pics, fposmod(x * 0.5, 1.0), y == _premiere_rangee_pics(x))
					_pics[Vector2i(x, y)] = pics
				"~":
					_poser_anime(["eau_1", "eau_1", "eau_1", "eau_1", "eau_1", "eau_1", "eau_2", "eau_2", "eau_2", "eau_2", "eau_2", "eau_2"], pos, x + y)
					if y > 0 and layout[y - 1][x] != "~" and not _est_mur(x, y - 1):
						# bord de l'eau : une marche sombre et un reflet clair
						_poser_rect(pos, Vector2(TUILE, 2), Color(0.1, 0.12, 0.2))
						_poser_rect(pos + Vector2(0, 2), Vector2(TUILE, 1), Color(0.55, 0.85, 0.95, 0.8))
				"z":
					var dalle := Dalle.new()
					add_child(dalle)
					dalle.initialiser(Vector2i(x, y))
					_dalles[Vector2i(x, y)] = dalle
				"o", "u":
					var plot := Plot.new()
					add_child(plot)
					plot.initialiser(self, Vector2i(x, y), layout[y][x] == "o")
					_plots.append(plot)
				"X":
					var bloc := Bloc.new()
					add_child(bloc)
					bloc.initialiser(self, Vector2i(x, y), _image("dalle_fleches"))
					_occupe[Vector2i(x, y)] = bloc
					_blocs.append(bloc)
				"D":
					pass  # les portes sont créées plus bas, par groupes de cases voisines (_poser_portes)
				"G" when not Etat.est(drapeau_gemme):   # déjà ramassée (partie sauvegardée) : pas de plume
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
					sentinelle.initialiser(Vector2i(x, y), directions[layout[y][x]], periode, sombre, _calque_sentinelles())
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
				"W" when not Etat.est(drapeau_gemme):
					var fragment := Ramassable.new()
					fragment.position = pos
					add_child(fragment)
					var quelle := "droite" if drapeau_gemme.ends_with("droite") else "gauche"
					fragment.initialiser(drapeau_gemme, "Fragment de l'aile " + quelle + " obtenu !", _image("fragment_aile"))
					if quelle == "droite":
						fragment.scale.x = -1.0   # l'aile droite = l'aile gauche vue dans un miroir
						fragment.position.x += TUILE
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
	_poser_portes_lettre("E", _portes_cle)
	for porte in _portes_cle:
		porte.activer_serrure(drapeau_cle, drapeau_serrure)


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
			# Arche animée du pack donjon : porte 3x2 du mur du haut, ou porte 3x1 dans un mur intérieur
			var images: Array[Texture2D] = []
			if taille == Vector2(48, 32) and haut_gauche.y == 0:
				images = _images_serie("arche_bois_" if lettre == "E" else "arche_herse_", 5)
			elif taille == Vector2(48, 16) and haut_gauche.y >= EPAISSEUR and haut_gauche.y < layout.size() - EPAISSEUR:
				images = _images_serie("arche_basse_", 5)
			porte.initialiser(taille, _image("porte_%dx%d" % [int(taille.x), int(taille.y)]), images)
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
	return ".TPFXVouz".contains(layout[cellule.y][cellule.x]) and not _occupe.has(cellule)


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
	if not _plots.is_empty() and not _orange_leves:
		basculer_plots()   # les plots reprennent leur place de départ (orange levés)
	for dalle in _dalles.values():
		dalle.remettre()
	_case_pied = Vector2i(-1, -1)
	_pique = false


# --- Dalles de couleur -----------------------------------------------------------

# Chaque image : sur quelle case sont les pieds du joueur ? En arrivant sur une dalle, elle se retourne
# (rouge <-> bleue). Quand toutes sont bleues, c'est gagné.
func _suivre_pas() -> void:
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	if joueur == null:
		return
	var pied := to_local(joueur.global_position) + Vector2(0, 5)
	var c := Vector2i(floori(pied.x / TUILE), floori(pied.y / TUILE))
	if c == _case_pied:
		return
	# On ne change de case que si les pieds sont bien dedans (à 3 px du bord) : passer en diagonale
	# par le coin d'une dalle, ou longer sa bordure, ne la retourne pas.
	var dans := pied - Vector2(c * TUILE)
	if _case_pied.x >= 0 and (dans.x < 3 or dans.y < 3 or dans.x > TUILE - 3 or dans.y > TUILE - 3):
		return
	_case_pied = c
	if not _dalles.has(c) or _dalles_resolues():
		return
	if not _regle_dite:
		_regle_dite = true
		Etat.annoncer("Chaque pas retourne la dalle : rouge -> bleue, bleue -> rouge. Rends-les TOUTES bleues ! (R pour recommencer)")
	_dalles[c].retourner()
	for d in _dalles.values():
		if not d.bleue:
			return
	for d in _dalles.values():
		d.valider()
	Etat.poser(drapeau_fragile)


func _dalles_resolues() -> bool:
	return drapeau_fragile == "" or Etat.est(drapeau_fragile)


# --- Pics, séries d'images ------------------------------------------------------

# Les pieds du joueur sur des pics sortis : retour au début de la salle (comme une chute).
func _surveiller_pics() -> void:
	if _pique:
		return
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	if joueur == null:
		return
	var pied := to_local(joueur.global_position) + Vector2(0, 5)
	var c := Vector2i(floori(pied.x / TUILE), floori(pied.y / TUILE))
	if _pics.has(c) and _pics[c].dangereux:
		_pique = true
		Etat.pique.emit(retour)


# La rangée la plus haute d'une colonne de pics (c'est elle qui fait le bruit).
func _premiere_rangee_pics(x: int) -> int:
	for y in layout.size():
		if layout[y][x] == "Z":
			return y
	return -1


# Images numérotées : prefixe1, prefixe2... prefixeN.
func _images_serie(prefixe: String, n: int) -> Array[Texture2D]:
	var liste: Array[Texture2D] = []
	for i in n:
		liste.append(_image(prefixe + str(i + 1)))
	return liste


# Un coup sur le cristal commutateur : les plots levés se baissent, les baissés se lèvent.
func basculer_plots() -> void:
	_orange_leves = not _orange_leves
	for plot in _plots:
		plot.regler((plot.couleur == Plot.ORANGE) == _orange_leves)
	for cristal in _commutateurs:
		cristal.colorer(_orange_leves)


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

# Calque des cônes et des bulles : dans un CanvasLayer qui suit la caméra, pour rester visible
# même dans une salle sombre (l'obscurité, CanvasModulate, ne touche que le monde).
func _calque_sentinelles() -> Node2D:
	if _calque_regards == null:
		var calque := CanvasLayer.new()
		calque.follow_viewport_enabled = true
		add_child(calque)
		_calque_regards = Node2D.new()
		_calque_regards.position = position
		_calque_regards.draw.connect(_dessiner_regards)
		calque.add_child(_calque_regards)
	return _calque_regards


# Chaque image : les sentinelles tournent la tête (ou fixent la flamme la plus proche),
# on calcule leur cône de vision, et si les pieds du joueur sont dedans, il est repéré.
func _surveiller(delta: float) -> void:
	_cones.clear()
	_cones_clignotent.clear()
	var au_repos := Etat.est(drapeau_repos)
	for sentinelle in _sentinelles:
		if au_repos:
			sentinelle.endormir()
			continue
		var flamme := _direction_attiree(sentinelle)
		var attiree := flamme != Vector2i.ZERO
		sentinelle.regarder(flamme if attiree else sentinelle.direction_normale(), attiree)
		sentinelle.avancer(delta)
		if attiree and not _flamme_vue:
			_flamme_vue = true
			Etat.annoncer("La flamme attire le regard de la sentinelle !")
		_cones.append(_cone(sentinelle))
		_cones_clignotent.append(sentinelle.va_tourner())
	_calque_regards.queue_redraw()
	if au_repos or _repere:
		return
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	if joueur == null:
		return
	var pied := to_local(joueur.global_position) + Vector2(0, 5)   # les pieds du joueur
	for sentinelle in _sentinelles:
		if _voit(sentinelle, pied):
			_repere = true
			sentinelle.alerter()
			Etat.repere.emit(retour)
			return


# Une flamme allumée attire le regard : direction du brasero allumé le plus proche (ZERO s'il n'y en a pas).
func _direction_attiree(sentinelle: Sentinelle) -> Vector2i:
	var meilleur: Brasero = null
	var meilleure_distance := INF
	for brasero in _braseros:
		var d := Vector2(sentinelle.case).distance_squared_to(brasero.position / TUILE)
		if brasero.allume and d < meilleure_distance:
			meilleur = brasero
			meilleure_distance = d
	if meilleur == null:
		return Vector2i.ZERO
	var vers := meilleur.position / TUILE - Vector2(sentinelle.case)
	if absf(vers.x) >= absf(vers.y):
		return Vector2i(signi(roundi(vers.x)), 0)
	return Vector2i(0, signi(roundi(vers.y)))


func _oeil(sentinelle: Sentinelle) -> Vector2:
	return Vector2(sentinelle.case * TUILE) + Vector2(8, 8)


# Le cône : on lance des rayons en éventail depuis l'œil ; chacun s'arrête au premier obstacle.
func _cone(sentinelle: Sentinelle) -> PackedVector2Array:
	var oeil := _oeil(sentinelle)
	var points := PackedVector2Array([oeil])
	for i in RAYONS_CONE + 1:
		var a := sentinelle.angle - DEMI_ANGLE + 2.0 * DEMI_ANGLE * i / RAYONS_CONE
		points.append(oeil + Vector2.from_angle(a) * _portee_libre(oeil, a, sentinelle.case))
	return points


# Jusqu'où (en pixels) la vue porte dans cette direction avant de heurter un obstacle.
func _portee_libre(oeil: Vector2, a: float, case_sentinelle: Vector2i) -> float:
	var direction := Vector2.from_angle(a)
	var d := 0.0
	var portee := float(PORTEE_REGARD * TUILE)
	while d < portee:
		d += 2.0
		var p := oeil + direction * d
		var c := Vector2i(floori(p.x / TUILE), floori(p.y / TUILE))
		if c != case_sentinelle and _opaque(c):
			return d - 2.0
	return portee


# Vrai si le point est dans le cône de la sentinelle : assez près, dans l'angle, et rien ne cache la vue.
func _voit(sentinelle: Sentinelle, point: Vector2) -> bool:
	var oeil := _oeil(sentinelle)
	var vers := point - oeil
	if vers.length() > PORTEE_REGARD * TUILE:
		return false
	if absf(angle_difference(sentinelle.angle, vers.angle())) > DEMI_ANGLE:
		return false
	return _portee_libre(oeil, vers.angle(), sentinelle.case) >= vers.length() - 1.0


# Une case cache la vue : murs, statues, braseros, et tout ce qui occupe une case (blocs, pots, portes...).
func _opaque(c: Vector2i) -> bool:
	if c.y < 0 or c.y >= layout.size() or c.x < 0 or c.x >= layout[c.y].length():
		return true
	if "#SOBKR".contains(layout[c.y][c.x]):
		return true
	var occupant = _occupe.get(c)
	if occupant == null or not is_instance_valid(occupant):
		return false
	# Une porte ouverte (même si sa grille n'a pas fini de disparaître) laisse passer le regard et le rayon
	return not (occupant is Porte and occupant.ouverte)


# Dessine les cônes : un éventail de triangles, opaque près de l'œil, transparent au bout (façon jeu d'infiltration).
# Le cône clignote juste avant que la sentinelle tourne, et devient rouge quand le joueur est repéré.
func _dessiner_regards() -> void:
	for n in _cones.size():
		var points := _cones[n]
		var couleur := COULEUR_REPERE if _repere else COULEUR_REGARD
		if not _repere and _cones_clignotent[n] and int(_temps * 8.0) % 2 == 0:
			couleur.a *= 0.4
		var bout := couleur
		bout.a *= 0.3
		var couleurs := PackedColorArray([couleur, bout, bout])
		for i in range(1, points.size() - 1):
			# draw_primitive accepte les triangles « plats » (sans erreur), contrairement à draw_colored_polygon
			_calque_regards.draw_primitive(PackedVector2Array([points[0], points[i], points[i + 1]]), couleurs, PackedVector2Array())
		# Contour du cône : on voit bien où il s'arrête
		var contour := points.duplicate()
		contour.append(points[0])
		var couleur_bord := couleur
		couleur_bord.a = minf(1.0, couleur.a * 1.6)
		_calque_regards.draw_polyline(contour, couleur_bord, 1.0)


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
	for paire in [[drapeau_porte, _portes], [drapeau_porte2, _portes2], [drapeau_serrure, _portes_cle]]:
		if nom != paire[0]:
			continue
		var liste: Array = paire[1]
		if not liste.is_empty() and grille != Etat.salle_courante and not _chargement:
			Etat.annoncer("Un bruit sourd : une porte s'est ouverte quelque part...")
		for porte in liste:
			if is_instance_valid(porte):
				porte.ouvrir(_chargement)


# Torches et bannières sur le mur du haut (seulement là où il y a du mur au-dessus du sol).
func _poser_details() -> void:
	if sombre:
		return  # pas de torches dans une salle sombre
	for x in COLONNES_BANNIERES:
		if _mur_haut_libre(x):
			_poser("banniere", Vector2(x * TUILE, EPAISSEUR * TUILE - 26))
	for x in COLONNES_TORCHES:
		if _mur_haut_libre(x):
			_poser_anime(TORCHE, Vector2(x * TUILE + 2, EPAISSEUR * TUILE - 24), x)
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
