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
#   l  = FOYER (salle `braseros_feu`) : brasero allumé en permanence, un coup de lance enflamme la lance quelques secondes
#   w  = flaque d'eau (ne bloque pas) : y entrer avec la lance enflammée l'éteint
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
#   i  = GLACE : le joueur (et un bloc poussé) glisse tout droit jusqu'à un obstacle ou jusqu'au sol normal
#        (un plot baissé n'est pas de la glace : on s'arrête dessus). R = retour au début de la salle.
#   r  = départ du REFLET (double fantôme aux gestes inversés gauche/droite, voir reflet.gd) ; il appuie aussi sur les boutons P
#   a  = dalle du reflet : quand TOUTES sont occupées en même temps (par le joueur ou le reflet) -> `drapeau_reflet`
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
const COLONNES_NICHES := [9, 14]   # niches voûtées à barreaux (2 colonnes de large) : donnent du relief au mur du haut
# Images animées (pack donjon Craftpix, voir Outils/traiter_pack_donjon.py). Le brasero fait 20x26 :
# sa case de 16x16 est en bas au centre, d'où le décalage.
const BRASERO := ["brasero_1", "brasero_2", "brasero_3", "brasero_4", "brasero_5", "brasero_6"]
const TORCHE := ["torche_1", "torche_2", "torche_3", "torche_4", "torche_5", "torche_6"]
const DECALAGE_BRASERO := Vector2(-2, -10)

# Énigmes : noms de drapeaux (voir etat.gd). Vide = rien.
@export var fond_image := ""      # salle dont le sol et les murs sont UNE image peinte (Assets/Gemini/tuiles/<nom>.png, 400x224) : formes non carrées (éventail du vestibule du donjon final) ; le plan sert aux collisions
@export var drapeau_plumes_gravees := ""   # quand ce drapeau est levé (la plume de cette colonne est ramassée), les plumes gravées deviennent dorées
@export var fenetres := false      # fenêtres en arche dans le mur du haut (épines = le rempart de la façade)
@export var plumes_gravees := 0   # nombre de plumes de pierre gravées dans le mur du haut (= numéro de la plume : 1 à 5, comme sur le HUD) ; 0 = aucune
@export var ciel_etoile := false   # (avec ciel_ouvert) murs en CRÉNEAUX et CIEL ÉTOILÉ au-delà des remparts au lieu de briques pleines (arène du boss)
@export var ciel_ouvert := false   # salle SANS TOIT (cour du château, couloirs de la queue) : ombres de nuages, oiseaux, lumière de lune, feuilles (Scripts/ciel_ouvert.gd)
@export var drapeau_plaque := ""   # levé quand TOUTES les plaques P portent un bloc
@export var drapeau_porte := ""    # les portes D de cette salle s'ouvrent quand ce drapeau est levé
@export var drapeau_gemme := ""    # levé quand on ramasse la plume G de cette salle
@export var drapeau_cristal := ""  # levé quand on frappe le cristal K de cette salle
@export var drapeau_braseros := "" # levé quand TOUS les braseros L sont allumés en même temps
@export var duree_braseros := 14.0 # secondes avant qu'un brasero L s'éteigne
@export var braseros_feu := false   # mode « lance enflammée » : les braseros L ne s'allument qu'avec une lance enflammée (au contact d'un foyer `l` ou d'un brasero déjà allumé)
@export var chemin_braseros: PackedStringArray   # mode « tête de coq » : cases "x y" des braseros L DANS L'ORDRE où il faut les allumer (vide = mode normal)
@export var duree_chemin := 24.0   # mode chemin : secondes pour allumer toute la série avant que tout s'éteigne
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
# ESCALIERS DE DESCENTE (décor, on marche dessus) : "x y" = case du coin haut-gauche d'un escalier de 3x3 cases (image escalier_donjon). Voir world.gd::_descendre_escalier.
@export var escaliers_descente: PackedStringArray
@export var drapeau_coffre := ""     # levé quand on ouvre le coffre Q
@export var texte_coffre := "Tu as trouvé une petite clé !"
@export var drapeau_levier := ""     # levé quand on bascule le levier J
@export var drapeau_cle := ""        # la clé qui ouvre les portes à serrure E de cette salle
@export var drapeau_serrure := ""    # levé quand une porte E est ouverte (elle s'ouvre avec ce drapeau)
@export var periode_pics := 2.4      # durée d'un cycle des pics Z (secondes)
@export var drapeau_reflet := ""     # levé quand toutes les dalles du reflet `a` sont occupées en même temps
@export var niches := true           # niches voûtées à barreaux dans le mur du haut (faux = mur nu : évite de confondre avec une herse)
# CHEMIN DE RUNES (énigme sans texte) : cases "x y" d'une ligne de runes gravées au sol, DANS L'ORDRE (du mécanisme vers la porte).
# Quand `drapeau_runes` est levé, l'énergie court d'une rune à l'autre (elles se remplissent d'or), PUIS les portes s'ouvrent.
@export var chemin_runes: PackedStringArray
@export var drapeau_runes := ""

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
var _flaques := {}         # { case : vrai } flaques d'eau (éteignent la lance enflammée)
var _ordre := 0            # mode chemin : combien de braseros sont déjà allumés dans l'ordre
var _t_chemin := 0.0       # mode chemin : temps écoulé depuis le premier brasero
var _echec_t := 0.0        # mode chemin : l'éclair rouge après une erreur
var _calque_chemin: Node2D
var _marques_vides := {}   # { case : vrai } marques encore libres : elles pulsent pour attirer l'oeil
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
var _portes_cle: Array[Porte] = []
var _pics := {}            # { case : Pics }
var _pique := false        # le joueur vient d'être touché par des pics (on attend le retour)
var _chargement := true    # vrai pendant _ready : les portes déjà ouvertes s'ouvrent sans bruit
var _a_glace := false      # la salle contient de la glace (lettre i)
var _case_reflet := Vector2i(-1, -1)   # départ du reflet (lettre r) ; -1 = pas de reflet
var _reflet: Reflet
var _dalles_reflet := {}   # { case : Sprite2D }
var _etait_courante := false


func _ready() -> void:
	# On place la salle à sa case de la grille (chaque case = une salle entière)
	position = Vector2(grille * TAILLE_SALLE)
	modulate = teinte  # ne teinte que cette salle (le joueur est ailleurs dans la scène)
	_creer_decor()
	_creer_collisions()
	_poser_passages()   # sorties vers un autre écran / une autre scène (ex. la porte du vestibule du donjon final vers le village)
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
	if not chemin_braseros.is_empty():
		_gerer_chemin(delta)
	if not _flaques.is_empty() and grille == Etat.salle_courante:
		_surveiller_flaques()
	# Les marques encore vides pulsent doucement (« il y a quelque chose à poser ici »)
	for cellule in _boutons:
		var v := 1.0
		if _marques_vides.get(cellule, true):
			v = 1.0 + 0.45 * (0.5 + 0.5 * sin(_temps * 3.5))
		_boutons[cellule].modulate = Color(v, v, v)
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
	if _a_glace:
		_annoncer_glace()
	if _case_reflet.x >= 0:
		_gerer_reflet()


# --- Chargement ---------------------------------------------------------------

# --- Décor --------------------------------------------------------------------

func _creer_decor() -> void:
	for ligne in layout:
		if ligne.contains("i"):
			_a_glace = true
	if fond_image != "":
		_poser(fond_image, Vector2.ZERO)
	for y in layout.size():
		if fond_image != "":
			break   # (le fond peint remplace les tuiles de sol et de mur)
		for x in layout[y].length():
			var pos := Vector2(x * TUILE, y * TUILE)
			if not _est_mur(x, y):
				_poser(_nom_sol(x, y), pos)
				# Case de porte (sur le bord de la salle) : sol assombri = passage
				if x < EPAISSEUR or y < EPAISSEUR or x >= layout[y].length() - EPAISSEUR or y >= layout.size() - EPAISSEUR:
					_poser_rect(pos, Vector2(TUILE, TUILE), Color(0, 0, 0, 0.35))
			else:
				_poser_mur(x, y)
	if ciel_ouvert:   # fleurs et cailloux dans l'herbe de la cour (décor, sans collision)
		for y in layout.size():
			for x in layout[y].length():
				if layout[y][x] == ";":
					var h := (x * 17 + y * 29 + x * y * 5) % 23
					if h == 0 or h == 9:
						_poser("v_fleur_rouge", Vector2(x * TUILE, y * TUILE) + Vector2(0, 1))
					elif h == 4:
						_poser("v_roche", Vector2(x * TUILE, y * TUILE) + Vector2(0, 1))
	_poser_runes()
	_poser_objets()
	_poser_escaliers()   # (après les tapis : l'escalier se pose par-dessus)
	_poser_portes()
	_poser_details()
	if ciel_ouvert:
		var ciel := CielOuvert.new()
		ciel.cases_etoiles = _cases_ciel
		add_child(ciel)
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
	if layout[y][x] == "i":
		return "glace_1" if (x * 3 + y * 5) % 4 else "glace_2"
	var h := (x * 7 + y * 13 + x * y * 3) % 37
	var lettre := layout[y][x]
	if ciel_etoile and lettre == ".":   # cour du château : dalles de pierre claire et chaude, joints décalés (Outils/fabriquer_sol_corps.py)
		return "sol_dalle_cour" + ["", "_b", "", "_c", "_b", ""][(x + y * 2 + h) % 6]
	if lettre == "," or lettre == ";":   # donjon final : terre battue de la queue, herbe de la cour (Outils/fabriquer_sol_corps.py)
		var base := "sol_terre" if lettre == "," else "sol_herbe"
		return base + ("" if h % 3 else ("_b" if h % 2 else "_c"))
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
var _cases_ciel: Array[Vector2] = []   # cases de ciel étoilé (étoiles qui scintillent : ciel_ouvert.gd)


func _nom_ciel(x: int, y: int) -> String:
	return "ciel_nuit_" + ["a", "b", "c", "a", "b"][(x * 5 + y * 11) % 5]


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
		if ciel_etoile and nom == "mur_face_haut" and y == 0:
			_poser(_nom_ciel(x, y), pos)   # créneaux : entre les merlons on voit le ciel
			_cases_ciel.append(pos)
			_poser("mur_creneaux", pos)
			return
		_poser(nom, pos)
		return
	if ciel_etoile:
		_poser(_nom_ciel(x, y), pos)   # au-delà du rempart : le ciel du soir (les liserés posés plus bas dessinent le parapet)
		_cases_ciel.append(pos)
	else:
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


# --- Chemin de runes (exports `chemin_runes`, `drapeau_runes`) ------------------------------
var _runes: Array[Sprite2D] = []   # la rune dorée de chaque case (invisible tant que l'énergie n'est pas passée)
var _runes_allumees := false
const PAS_RUNES := 0.09            # secondes entre deux runes qui s'allument


func _poser_runes() -> void:
	for i in chemin_runes.size():
		var m := chemin_runes[i].split(" ", false)
		if m.size() != 2:
			continue
		var pos := Vector2(int(m[0]) * TUILE, int(m[1]) * TUILE)
		var k := 1 + (int(m[0]) * 7 + int(m[1]) * 3) % 3
		_poser("rune_sol_%d" % k, pos)
		var dore := _poser("rune_sol_on_%d" % k, pos)
		dore.modulate.a = 0.0
		_runes.append(dore)


# Les runes se remplissent d'or l'une après l'autre (instantane = salle déjà résolue au chargement).
func _allumer_runes(instantane: bool) -> void:
	if _runes_allumees:
		return
	_runes_allumees = true
	for i in _runes.size():
		var rune := _runes[i]
		if instantane:
			rune.modulate.a = 1.0
			continue
		var tween := create_tween()
		rune.modulate = Color(2.2, 2.0, 1.4, 0.0)   # éclat blanc-doré qui retombe vers l'or
		tween.tween_property(rune, "modulate", Color(2.2, 2.0, 1.4, 1.0), 0.08)
		tween.tween_property(rune, "modulate", Color.WHITE, 0.35)
		_poser_lumiere(rune.position + Vector2(8, 8), 14.0)
		await get_tree().create_timer(PAS_RUNES).timeout
	if instantane:
		for rune in _runes:
			_poser_lumiere(rune.position + Vector2(8, 8), 14.0)
	else:
		await get_tree().create_timer(0.15).timeout


# Escaliers de descente (export `escaliers_descente`).
func _poser_escaliers() -> void:
	for ligne in escaliers_descente:
		var m := ligne.split(" ", false)
		if m.size() == 2:
			_poser("escalier_donjon", Vector2(int(m[0]) * TUILE, int(m[1]) * TUILE))


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
					_poser("statue_chevalier", pos + Vector2(-3, TUILE - 34))
				"O":
					_poser("statue_oiseau", pos + Vector2(-3, TUILE - 34))
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
					_boutons[Vector2i(x, y)] = _poser("marque", pos)
					_plaques.append(Vector2i(x, y))
				"L":
					var brasero := Brasero.new()
					brasero.position = pos
					add_child(brasero)
					var flammes: Array[Texture2D] = []
					for nom in BRASERO:
						flammes.append(_image(nom))
					brasero.initialiser(self, duree_braseros, _image("brasero_eteint"), flammes)
					brasero.ordonne = not chemin_braseros.is_empty()
					brasero.mode_feu = braseros_feu
					_braseros.append(brasero)
					_occupe[Vector2i(x, y)] = brasero
				"l":
					var foyer := Brasero.new()
					foyer.position = pos
					add_child(foyer)
					var flammes_foyer: Array[Texture2D] = []
					for nom in BRASERO:
						flammes_foyer.append(_image(nom))
					foyer.initialiser(self, duree_braseros, _image("brasero_eteint"), flammes_foyer)
					foyer.allumer_foyer()   # pas dans `_braseros` : il est déjà allumé, il ne compte pas dans l'énigme
					_occupe[Vector2i(x, y)] = foyer
				"w":
					_flaques[Vector2i(x, y)] = true
					# la flaque se raccorde à ses voisines (bits : 1 nord, 2 sud, 4 ouest, 8 est) ; rives arrondies là où il n'y a pas d'eau
					var bits := 0
					if y > 0 and layout[y - 1][x] == "w": bits |= 1
					if y < layout.size() - 1 and layout[y + 1][x] == "w": bits |= 2
					if x > 0 and layout[y][x - 1] == "w": bits |= 4
					if x < layout[y].length() - 1 and layout[y][x + 1] == "w": bits |= 8
					var v := (x * 3 + y * 5) % 4   # 4 variantes pour que l'eau ne se répète pas
					var f1 := "flaque_%d_%d_1" % [bits, v]
					var f2 := "flaque_%d_%d_2" % [bits, v]
					_poser_anime([f1, f1, f1, f1, f2, f2, f2, f2], pos, x + y)
					if sombre:   # on doit voir les flaques dans le noir : une faible lueur bleue
						var l := Lumiere.creer(Color(0.4, 0.65, 1.0), 0.5, 0.6)
						l.position = pos + Vector2(8, 8)
						add_child(l)
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
				"r":
					_case_reflet = Vector2i(x, y)
				"a":
					_dalles_reflet[Vector2i(x, y)] = _poser("dalle_reflet", pos)
					if sombre:   # on doit les voir dans le noir
						var lueur := Lumiere.creer(Color(0.5, 0.8, 1.0), 0.35, 0.5)
						lueur.position = pos + Vector2(8, 8)
						add_child(lueur)
				"z":
					var dalle := Dalle.new()
					dalle.textures = [_image("dalle_rouge"), _image("dalle_bleue"), _image("dalle_doree")]
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
					bloc.initialiser(self, Vector2i(x, y), _image("bloc_pierre"), _image("bloc_pierre_actif"))
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
					cloche.initialiser(self, int(layout[y][x]), sombre, _image("plaque_cloche_" + layout[y][x]), _image("cloche_" + layout[y][x]))
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
	var rappel := _oublier.bind(cellule, noeud)
	if not noeud.tree_exiting.is_connected(rappel):   # un noeud peut être suivi plusieurs fois sur la même case
		noeud.tree_exiting.connect(rappel)


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
	return ".TPFXVouziar".contains(layout[cellule.y][cellule.x]) and not _occupe.has(cellule)


# Appelé après chaque poussée : si toutes les plaques portent un bloc, on lève le drapeau.
func verifier_plaques() -> void:
	_maj_boutons()
	if drapeau_plaque == "" or _plaques.is_empty():
		return
	for plaque in _plaques:
		if not (_occupe.get(plaque) is Bloc or _reflet_sur(plaque)):
			return
	Etat.poser(drapeau_plaque)


# Chaque bouton s'enfonce quand un bloc est dessus, et remonte sinon.
func _maj_boutons() -> void:
	for cellule in _boutons:
		var appuye: bool = _occupe.get(cellule) is Bloc or _reflet_sur(cellule)
		_boutons[cellule].texture = _image("marque_active" if appuye else "marque")
		_marques_vides[cellule] = not appuye
	# un bloc posé sur une marque s'illumine (rune dorée) : on voit que c'est bon sans aucun texte
	for bloc in _blocs:
		bloc.briller(_boutons.has(bloc.case))


# Touche R : les blocs reviennent à leur place de départ.
func reinitialiser() -> void:
	if _reflet != null and is_instance_valid(_reflet):
		_reflet.reinitialiser()
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
	_ordre = 0
	_t_chemin = 0.0
	if braseros_feu:
		var joueur = get_tree().get_first_node_in_group("joueur")
		if joueur != null:
			joueur.eteindre_feu()
	if _calque_chemin != null and not _braseros.is_empty() and not _braseros[0].verrouille:
		_rearmer_chemin()
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
	_dalles[c].retourner()
	for d in _dalles.values():
		if not d.bleue:
			return
	for d in _dalles.values():
		d.valider()
	Etat.poser(drapeau_fragile)


func _dalles_resolues() -> bool:
	return drapeau_fragile == "" or Etat.est(drapeau_fragile)


# --- Glace ----------------------------------------------------------------------
# Le joueur (player.gd) demande à la salle où il est : est-ce de la glace ? jusqu'où glisse-t-on ?
# Les règles sont les mêmes que celles du solveur qui a vérifié les salles (voir Outils/generer_aile_droite.py).

func a_de_la_glace() -> bool:
	return _a_glace


# Salle où la touche R ramène le joueur au début (on peut s'y coincer : glace, reflet décalé).
func recommence_au_debut() -> bool:
	return _a_glace or (_case_reflet.x >= 0 and not Etat.est(drapeau_reflet))


# --- Reflet ----------------------------------------------------------------------

# Le reflet est créé à la 1re image où le joueur est dans la salle (il copie son apparence),
# remis à son départ à chaque entrée dans la salle ; il presse les boutons et occupe les dalles du reflet.
func _gerer_reflet() -> void:
	var courante := grille == Etat.salle_courante
	var resolu := Etat.est(drapeau_reflet)
	if courante and not _etait_courante and not resolu:
		var joueur := get_tree().get_first_node_in_group("joueur")
		if _reflet == null and joueur != null:
			_reflet = Reflet.new()
			add_child(_reflet)
			_reflet.initialiser(self, _case_reflet, joueur, sombre)
		elif _reflet != null and is_instance_valid(_reflet):
			_reflet.reinitialiser()
	_etait_courante = courante
	if not courante or _reflet == null or not is_instance_valid(_reflet):
		return
	# Boutons : le reflet les enfonce (un bouton enfoncé une fois suffit à ouvrir pour de bon)
	if not _boutons.is_empty():
		verifier_plaques()
	# Dalles du reflet : allumées quand quelqu'un est dessus ; toutes à la fois = gagné
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	var case_joueur := case_des_pieds(joueur.global_position) if joueur != null else Vector2i(-99, -99)
	var toutes := not _dalles_reflet.is_empty()
	for c in _dalles_reflet:
		var occupee: bool = c == case_joueur or _reflet_sur(c)
		_dalles_reflet[c].texture = _image("dalle_reflet_on" if occupee else "dalle_reflet")
		toutes = toutes and occupee
	if toutes and not resolu and drapeau_reflet != "":
		Etat.poser(drapeau_reflet)
		_reflet.disparaitre()
		Etat.annoncer("Le reflet se fond dans la lumière...")


# Le reflet a-t-il les pieds sur cette case ?
func _reflet_sur(c: Vector2i) -> bool:
	if _reflet == null or not is_instance_valid(_reflet) or not _reflet.is_physics_processing():
		return false
	var pied := _reflet.position + Vector2(0, 5)
	return Vector2i(floori(pied.x / TUILE), floori(pied.y / TUILE)) == c


# La salle prévient le joueur qu'il est sur un terrain glacé (seulement la salle où il se trouve).
func _annoncer_glace() -> void:
	var joueur := get_tree().get_first_node_in_group("joueur")
	if joueur == null:
		return
	if grille == Etat.salle_courante:
		joueur.terrain = self
	elif joueur.terrain == self:
		joueur.terrain = null


# Case (de cette salle) sous les pieds d'un personnage dont on donne la position dans le monde.
func case_des_pieds(position_monde: Vector2) -> Vector2i:
	var pied := to_local(position_monde) + Vector2(0, 5)
	return Vector2i(floori(pied.x / TUILE), floori(pied.y / TUILE))


# Position (dans le monde) du joueur debout au centre de la case : ses pieds sont 5 px sous son centre.
func position_sur_case(c: Vector2i) -> Vector2:
	return global_position + Vector2(c * TUILE) + Vector2(8, 3)


func est_glace(c: Vector2i) -> bool:
	return c.y >= 0 and c.y < layout.size() and c.x >= 0 and c.x < layout[c.y].length() and layout[c.y][c.x] == "i"


# Une case où l'on ne peut pas entrer en glissant : mur, objet solide, bloc, plot levé, porte fermée...
func case_bloquee(c: Vector2i) -> bool:
	if c.y < 0 or c.y >= layout.size() or c.x < 0 or c.x >= layout[c.y].length():
		return true
	if _est_mur(c.x, c.y) or SOLIDES.contains(layout[c.y][c.x]):
		return true
	var occupant = _occupe.get(c)
	if occupant == null or not is_instance_valid(occupant):
		return false
	return not (occupant is Porte and occupant.ouverte)


# Depuis la case de glace `c`, on glisse dans la direction `d` : on avance tant que la case suivante
# est libre et glacée ; une case libre NON glacée (sol, plot baissé) arrête la glissade dessus.
func destination_glissade(c: Vector2i, d: Vector2i) -> Vector2i:
	for _i in 100:
		var suivante := c + d
		if case_bloquee(suivante):
			return c
		c = suivante
		if not est_glace(c):
			return c
	return c


# Le joueur, arrêté sur la glace, pousse vers la case `c` : s'il y a un bloc, il le pousse (le bloc glisse aussi).
func pousser_bloc(c: Vector2i, d: Vector2i) -> bool:
	var occupant = _occupe.get(c)
	if occupant is Bloc:
		occupant.pousser(d)
		return true
	return false


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


# L'eau éteint la lance enflammée du joueur.
func _surveiller_flaques() -> void:
	var joueur = get_tree().get_first_node_in_group("joueur")
	if joueur != null and joueur.a_feu() and _flaques.has(case_des_pieds(joueur.global_position)):
		joueur.eteindre_feu(true)


# --- Les braseros « tête de coq » : on les allume dans l'ordre du tracé, avant qu'ils s'éteignent -------------
# Un trait doré pâle est gravé au sol entre les braseros (visible même dans le noir). Le prochain à allumer pulse ;
# un mauvais brasero, ou trop de lenteur, éteint tout. Quand le dessin est complet, il s'embrase et la porte s'ouvre.

# Met les braseros dans l'ordre du chemin (une seule fois, au premier appel).
func _ordonner_braseros() -> void:
	var rang := {}
	for i in chemin_braseros.size():
		var xy := chemin_braseros[i].split(" ")
		rang[Vector2i(int(xy[0]), int(xy[1]))] = i
	_braseros.sort_custom(func(a: Brasero, b: Brasero) -> bool:
		return rang.get(Vector2i(a.position / TUILE), 0) < rang.get(Vector2i(b.position / TUILE), 0))
	if _calque_chemin == null:
		var calque := CanvasLayer.new()
		calque.follow_viewport_enabled = true   # au-dessus de l'obscurité : le dessin se voit dans le noir
		add_child(calque)
		_calque_chemin = Node2D.new()
		_calque_chemin.position = position
		_calque_chemin.draw.connect(_dessiner_chemin)
		calque.add_child(_calque_chemin)
		_braseros[0].attendu = true


# Appelé par un brasero frappé : vrai s'il est bien le prochain de la série.
func brasero_frappe(b: Brasero) -> bool:
	var rang := _braseros.find(b)
	if rang != _ordre:
		_echouer()
		return false
	if _ordre == 0:
		_t_chemin = 0.0
	b.attendu = false
	_ordre += 1
	if _ordre < _braseros.size():
		_braseros[_ordre].attendu = true
	return true


# Erreur ou temps écoulé : tout s'éteint, on recommence.
func _echouer() -> void:
	_echec_t = 0.6
	_ordre = 0
	_t_chemin = 0.0
	for brasero in _braseros:
		if brasero.allume and not brasero.verrouille:
			brasero.eteindre()
	_rearmer_chemin()
	var son = load(SON_ERREUR)
	if son:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = son
		lecteur.volume_db = -4.0
		add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)


# Tout est éteint : seul le premier brasero de la série pulse.
func _rearmer_chemin() -> void:
	for brasero in _braseros:
		brasero.attendu = false
		brasero.vie = 1.0
	if not _braseros.is_empty():
		_braseros[0].attendu = true


func _gerer_chemin(delta: float) -> void:
	if _calque_chemin == null:
		if _braseros.is_empty():
			return
		_ordonner_braseros()
	if _braseros[0].verrouille:
		if grille == Etat.salle_courante:
			_calque_chemin.queue_redraw()
		return
	if _ordre > 0:
		_t_chemin += delta
		var vie := clampf(1.0 - _t_chemin / duree_chemin, 0.0, 1.0)
		for brasero in _braseros:
			brasero.vie = vie
		if _t_chemin >= duree_chemin:
			_echouer()
	_echec_t = maxf(0.0, _echec_t - delta)
	if grille == Etat.salle_courante:
		_calque_chemin.queue_redraw()


# Le tracé de la tête de coq : pointillé pâle ; les segments déjà reliés brillent ; l'anneau marque le prochain brasero.
func _dessiner_chemin() -> void:
	var n := _braseros.size()
	if n < 2:
		return
	var pts: Array[Vector2] = []
	for b in _braseros:
		pts.append(b.position + Vector2(8, 8))
	var resolu := _braseros[0].verrouille
	var pulse := 0.5 + 0.5 * sin(_temps * 4.0)
	var pale := Color(1.0, 0.8, 0.35, 0.30)
	if _echec_t > 0.0:
		pale = Color(1.0, 0.25, 0.2, 0.3 + 0.7 * _echec_t / 0.6)
	var contour := n - 1   # le dernier brasero est l'œil : il n'est pas relié par un trait
	for i in contour:
		var a := pts[i]
		var c := pts[(i + 1) % contour]   # le dernier trait referme le contour (cou)
		var allume_a: bool = _braseros[i].allume
		var allume_c: bool = _braseros[(i + 1) % contour].allume
		var relie := resolu or (i + 1 < contour and allume_a and allume_c) or (i + 1 == contour and resolu)
		if relie:
			var force := 0.85 + (0.15 * pulse if resolu else 0.0)
			_calque_chemin.draw_line(a, c, Color(1.0, 0.7, 0.2, 0.30 * force), 6.0)
			_calque_chemin.draw_line(a, c, Color(1.0, 0.92, 0.6, 0.95 * force), 2.0)
		else:
			_calque_chemin.draw_dashed_line(a, c, pale, 1.0, 3.0)
	# l'œil
	var oeil := pts[n - 1]
	if _braseros[n - 1].allume:
		_calque_chemin.draw_circle(oeil, 5.0, Color(1.0, 0.85, 0.4, 0.5))
	else:
		_calque_chemin.draw_arc(oeil, 6.0, 0, TAU, 20, pale, 1.0)
	# prochain brasero à allumer : anneau qui pulse
	if not resolu and _ordre < n:
		_calque_chemin.draw_arc(pts[_ordre], 9.0 + 2.0 * pulse, 0, TAU, 24, Color(1.0, 0.9, 0.5, 0.5 + 0.4 * pulse), 1.5)


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
			pass   # (aucun texte : la bulle « ? » au-dessus de la sentinelle suffit)
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
		_jouer_son("res://Assets/Ninja_adventure/Audio/Sounds/Menu/Cancel.wav", -8.0)   # la statue reste muette : un son sourd, sans texte
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
	if nom == drapeau_runes and not _runes.is_empty():
		await _allumer_runes(_chargement)   # l'énergie court jusqu'à la porte, qui ne s'ouvre qu'ensuite
	for paire in [[drapeau_porte, _portes], [drapeau_porte2, _portes2], [drapeau_serrure, _portes_cle]]:
		if nom != paire[0]:
			continue
		var liste: Array = paire[1]
		if not liste.is_empty() and grille != Etat.salle_courante and not _chargement:
			pass   # (aucun texte : la secousse et le bruit sourd de la porte suffisent)
		for porte in liste:
			if is_instance_valid(porte):
				porte.ouvrir(_chargement)


# Torches et bannières sur le mur du haut (seulement là où il y a du mur au-dessus du sol).
func _poser_details() -> void:
	if fond_image == "" and not ciel_ouvert:
		_poser_frise()
	if sombre or fond_image != "":
		return  # pas de torches dans une salle sombre
	for x in COLONNES_BANNIERES:
		if _mur_haut_libre(x):
			_poser("banniere", Vector2(x * TUILE, EPAISSEUR * TUILE - 26))
	if ciel_ouvert:   # pas de barreaux de cachot en plein air : une seule grande arche au fond (la porte vers la tour de tête)
		if _mur_haut_libre(11) and _mur_haut_libre(12):
			_poser("niche_grille", Vector2(11 * TUILE, EPAISSEUR * TUILE - 21))
	else:
		for x in (COLONNES_NICHES if niches else []):
			if _mur_haut_libre(x) and _mur_haut_libre(x + 1):
				_poser("niche_grille", Vector2(x * TUILE, EPAISSEUR * TUILE - 21))
	for x in COLONNES_TORCHES:
		if _mur_haut_libre(x):
			_poser_anime(TORCHE, Vector2(x * TUILE + 2, EPAISSEUR * TUILE - 24), x)
			_poser_lumiere(Vector2(x * TUILE + 8, EPAISSEUR * TUILE + 2), 52.0)


# Décor des ailes repris de la FAÇADE : frise de runes dorées sur la corniche du mur du haut (elle scintille doucement),
# plumes de pierre gravées dans le mur (autant que le numéro de la plume ; elles deviennent DORÉES une fois la plume ramassée),
# fenêtres en arche dans les épines. Dans une salle sombre, la frise luit très faiblement (calque au-dessus de l'obscurité).
const EMPLACEMENTS_PLUMES := [2, 22, 5, 19, 8]
const COLONNES_FENETRES := [3, 9, 15, 21]
var _plumes_murales: Array[Sprite2D] = []

func _poser_frise() -> void:
	var parent: Node = self
	if sombre:
		var calque := CanvasLayer.new()
		calque.follow_viewport_enabled = true   # l'obscurité (CanvasModulate) ne touche pas ce calque
		add_child(calque)
		parent = Node2D.new()
		parent.position = position
		parent.modulate.a = 0.3
		calque.add_child(parent)
	for x in range(2, 23):
		var ys := _haut_du_sol(x)
		if ys < 0:
			continue
		var rune := _sprite_dans(parent, "frise_runes_%d" % ((x * 5 + x / 3) % 4 + 1), Vector2(x * TUILE, (ys - 2) * TUILE + 3))
		rune.modulate.a = 0.78
		var tw := create_tween().set_loops()
		tw.tween_interval(x * 0.12)
		tw.tween_property(rune, "modulate:a", 1.0, 1.1)
		tw.tween_property(rune, "modulate:a", 0.78, 1.1)
		tw.tween_interval(maxf(0.1, (23 - x) * 0.12))
	var doree := Etat.est(drapeau_plumes_gravees)
	for i in mini(plumes_gravees, EMPLACEMENTS_PLUMES.size()):
		var x: int = EMPLACEMENTS_PLUMES[i]
		var ys := _haut_du_sol(x)
		if ys >= 0:
			var plume := _sprite_dans(self, "plume_pierre_or" if doree else "plume_pierre", Vector2(x * TUILE, ys * TUILE - 21))
			_plumes_murales.append(plume)
	if not doree and drapeau_plumes_gravees != "" and not _plumes_murales.is_empty():
		Etat.drapeau_change.connect(_sur_drapeau_plumes)
	if fenetres:
		for x in COLONNES_FENETRES:
			var ys := _haut_du_sol(x)
			if ys >= 0:
				_poser("fenetre_arche", Vector2(x * TUILE + 2, ys * TUILE - 20))


# La plume vient d'être ramassée : les plumes gravées de la salle se changent en or, avec un éclat.
func _sur_drapeau_plumes(nom: String) -> void:
	if nom != drapeau_plumes_gravees:
		return
	Etat.drapeau_change.disconnect(_sur_drapeau_plumes)
	for i in _plumes_murales.size():
		var plume := _plumes_murales[i]
		var tw := create_tween()
		tw.tween_interval(0.25 * i)
		tw.tween_callback(func() -> void:
			plume.texture = _image("plume_pierre_or")
			plume.modulate = Color(2.2, 2.0, 1.4))
		tw.tween_property(plume, "modulate", Color.WHITE, 0.6)


# Rangée du sol le plus haut dans la colonne x, s'il y a au moins 2 rangées de mur au-dessus (la corniche) ; sinon -1.
func _haut_du_sol(x: int) -> int:
	for y in layout.size():
		if _est_sol(x, y):
			return y if y >= 2 and _est_mur(x, y - 1) and _est_mur(x, y - 2) else -1
	return -1


func _sprite_dans(parent: Node, nom: String, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _image(nom)
	sprite.centered = false
	sprite.position = pos
	parent.add_child(sprite)
	return sprite


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
