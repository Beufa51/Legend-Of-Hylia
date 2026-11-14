extends Ecran
class_name Exterieur
# Un écran EXTÉRIEUR (village, chemins, forêt...). Même principe qu'une salle du donjon
# (plan texte `layout` de 25 x 14 cases, position `grille`, glissement de caméra), mais sans murs :
# ce sont les arbres, maisons, buissons... qui bloquent le joueur.
# Lettres du plan :
#   .  = herbe            :  = chemin de terre (les bords s'arrondissent tout seuls)
#   A  = arbre rond (2x2)  a = autre arbre rond (2x2)   P = sapin (2x2)   r = roche (2x2)
#   b  = buisson (1x1)  B = buisson à baies   u = souche   n = panneau   x = caisse
#   e  = clôture (2 cases)   z = poteau   k = case de l'enclos (marqueur)   s = point de départ d'une poule (marqueur)
#   f  = tournesol   g = fleur rouge   w = marguerite (fleurs : décor, ne bloquent pas)
#   MAISONS du pack Village Top Down (Outils/traiter_village_jadson.py) : M orange 8x3, N bleue 5x3, T verte 5x3, R rouge 5x3, S ardoise 8x3, L grange 8x3, K caserne 8x3, U temple 8x3 (église) ; la porte est sur la dernière rangée (colonne 2, temple colonne 3)
#   E  = étal du marché (3x2)  o = tonneau   j = bannière rouge (1x2)
#   Q  = girouette du coq (3x3)   W = puits (2x2)
#   ~  = eau de la rivière (bloque)   = = pont de bois (on marche dessus, au-dessus de l'eau)
# ANIMAUX : pas dans le plan, mais dans la liste `animaux` : "lettre x y", par ex. "c 9 9"
#   c  = poule blanche   h = poule rousse   k = chat   d = chien
# PASSAGES (portes de maison) : liste `passages` (voir ecran.gd). La case de la porte est en bas de la maison, 2e colonne.
# HABITANTS : dans la liste `pnjs`, une ligne par habitant : "Perso x y direction | Nom | phrase // phrase // ..."
#   (Perso = dossier du pack Actor/Character, ex. OldMan, Villager2, Woman ; direction = bas, haut, gauche, droite)
# VIE : les plantes, arbres et bannières se balancent au vent (force donnée par Ambiance.force_vent),
# des touffes d'herbe sont semées toutes seules dans l'herbe libre.
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

# Objets Gemini : lettre -> [image (Assets/Gemini/tuiles), emprise en cases (largeur, hauteur), bloque ?, balancement au vent (0 = immobile)]
# L'image est posée CENTRÉE sur l'emprise et ALIGNÉE EN BAS : un arbre ou une maison peut dépasser vers le haut.
const OBJETS_G := {
	"A": ["v_arbre_a", Vector2i(3, 3), true, 0.03],
	"a": ["v_arbre_b", Vector2i(3, 3), true, 0.03],
	"P": ["v_sapin", Vector2i(3, 3), true, 0.025],
	"b": ["v_buisson", Vector2i(1, 1), true, 0.07],
	"B": ["v_buisson_baies", Vector2i(1, 1), true, 0.07],
	"f": ["v_tournesol", Vector2i(1, 1), false, 0.22],
	"g": ["v_fleur_rouge", Vector2i(1, 1), false, 0.22],
	"w": ["v_marguerite", Vector2i(1, 1), false, 0.22],
	"o": ["v_tonneau", Vector2i(1, 1), true, 0.0],
	"x": ["v_caisse", Vector2i(1, 1), true, 0.0],
	"n": ["v_panneau", Vector2i(1, 1), true, 0.0],
	"u": ["v_souche", Vector2i(1, 1), true, 0.0],
	"r": ["v_roche", Vector2i(1, 1), true, 0.0],
	"j": ["v_banniere", Vector2i(1, 2), true, 0.1],
	"W": ["v_puits", Vector2i(2, 2), true, 0.0],
	"e": ["v_cloture", Vector2i(2, 1), true, 0.0],   # clôture (2 cases de large)
	"z": ["v_poteau", Vector2i(1, 1), true, 0.0],    # poteau de clôture
	# Maisons du pack « Village Top Down » : emprise = les murs (le toit dépasse vers le haut) ; la porte est sur la dernière rangée (colonne dans PORTES_MAISONS)
	"M": ["v_maison_orange", Vector2i(8, 3), true, 0.0],
	"N": ["v_maison_bleue", Vector2i(5, 3), true, 0.0],
	"T": ["v_maison_chaume", Vector2i(5, 3), true, 0.0],
	"R": ["v_maison_rouge", Vector2i(5, 3), true, 0.0],
	"S": ["v_maison_pierre", Vector2i(8, 3), true, 0.0],
	"K": ["v_maison_caserne", Vector2i(8, 3), true, 0.0],   # la caserne
	"L": ["v_maison_bois", Vector2i(8, 3), true, 0.0],      # la grange
	"U": ["v_temple_entree", Vector2i(7, 3), true, 0.0],    # ENTRÉE DE DONJON : façade de pierre à créneaux, pilastres, bannières, torches et grande arche sombre (porte en colonne 3)
	# FAÇADES des trois entrées du donjon du coq (400x96 = 25x6 cases, collées en haut de l'écran : le bâtiment CONTINUE sur l'écran du dessus, sans arbres derrière).
	# Elles sont solides ; les cases de la porte (rangée 5, colonnes 11-13) sont des `passages` (donc libres). Voir Outils/fabriquer_facade.py.
	"F": ["v_facade_aile_g", Vector2i(25, 12), true, 0.0],          # entrée de l'aile GAUCHE : 5 tours de plus en plus hautes vers la droite
	"G": ["v_facade_aile_d_fermee", Vector2i(25, 12), true, 0.0],   # entrée de l'aile DROITE, herse baissée (le garde barre la route)
	"J": ["v_facade_aile_d", Vector2i(25, 12), true, 0.0],          # entrée de l'aile DROITE, herse levée
	"q": ["v_facade_queue_sol", Vector2i(24, 2), false, 0.0],       # bande de sol sous la façade de la queue (même image que la cinématique), colonnes 1-24
	"H": ["v_facade_queue", Vector2i(25, 12), true, 0.0],           # entrée du donjon final : la QUEUE du coq (éventail de tours aux pointes en flammes)
	# LES DEUX STÈLES DU PARVIS : une GRIFFE de pierre (le pied du coq de l'image du coq-forteresse, jambe qui monte et disparaît dans la forêt) + une PIERRE posée DEVANT elle,
	# où l'on dépose le symbole d'une aile (fenêtre ornée d'ailes). Images : Outils/traiter_griffes.py et Outils/traiter_pierres.py ; logique : STELES, world.gd::_ceremonie_stele.
	"C": ["v_griffe_g", Vector2i(6, 2), true, 0.0],                # griffe GAUCHE (décor : le pied de l'aile gauche)
	"D": ["v_griffe_d", Vector2i(6, 2), true, 0.0],                # griffe DROITE
	"V": ["v_pierre_g_vide", Vector2i(3, 1), true, 0.0],           # pierre de l'aile gauche (devant la griffe gauche)
	"X": ["v_pierre_d_vide", Vector2i(3, 1), true, 0.0],           # pierre de l'aile droite
}
# Colonne de la porte de chaque maison (0 à 3, depuis la gauche) : sert à placer les `passages` (voir generer_village.py)
const PORTES_MAISONS := {"M": 2, "N": 2, "T": 2, "R": 2, "S": 2, "K": 2, "L": 2, "U": 3}
# Centre de la fenêtre d'une pierre-stèle, depuis le coin haut-gauche de son emprise 3x1 (en pixels) : là où vole le symbole
const NICHE_STELE := Vector2(24, 0)
# Stèles : lettre -> [côté, image une fois le symbole déposé]
const STELES := {"V": ["gauche", "v_pierre_g_pleine"], "X": ["droite", "v_pierre_d_pleine"]}
# Touffes d'herbe semées automatiquement (images Gemini)
const TOUFFES_G := ["v_herbe_1", "v_herbe_2"]
# Animaux : lettre -> [planche, vitesse (px/s), peureux ?, son quand on le frappe]
const ANIMAUX := {
	"c": ["res://Assets/Ninja_adventure/Actor/Animal/Chicken/SpriteSheetWhite.png", 22.0, true, "poule"],
	"h": ["res://Assets/Ninja_adventure/Actor/Animal/Chicken/SpriteSheetBrown.png", 22.0, true, "poule"],
	"k": ["res://Assets/Ninja_adventure/Actor/Animal/Cat/SpriteSheet.png", 0.0, false, "chat"],
	"d": ["res://Assets/Ninja_adventure/Actor/Animal/Dog/SpriteSheet.png", 14.0, false, "chien"],
}

# Animaux de l'écran : "lettre x y" (voir ANIMAUX)
@export var animaux: PackedStringArray
# RELIEF : terrasses (plateaux d'herbe surélevés avec une falaise au sud), "x y largeur hauteur" en cases (largeur >= 3, hauteur >= 4 : rangée du haut, milieu, bord de falaise, falaise).
# On marche sur le dessus ; le bord et la falaise bloquent. Les escaliers ("x y" = case du coin haut-gauche, ils font 2 cases de large et 4 de haut) percent la falaise : c'est le seul accès.
# COFFRES : "x y drapeau | texte" (un coup de lance l'ouvre ; texte avec %d = nombre d'insignes). SECRETS : "sx sy cx cy drapeau | texte" = un rocher fissuré en (sx,sy) ; le briser à la lance fait apparaître un coffre en (cx,cy).
@export var coffres: PackedStringArray
@export var secrets: PackedStringArray
@export var terrasses: PackedStringArray
@export var escaliers: PackedStringArray

var _solides := {}   # cases bloquées par un objet
var _couvertes := {} # cases recouvertes par un objet (bloquant ou non) : pas de touffe d'herbe dessus
var _objets := {}          # { case du coin haut-gauche : Sprite2D } des grands objets (pour la forêt qui s'écarte)
var _hauts: Array = []     # [sprite, ligne de base (y local)] : arbres, maisons... le héros passe DERRIÈRE quand il est plus haut qu'eux
var _plantes: Array = []   # [sprite, amplitude, phase] : ce qui se balance au vent
var _temps := 0.0
var _eaux: Array = []      # [sprite, nom de l'image, ...] de chaque case d'eau : 2 images alternées = l'eau qui scintille
var _image_eau := -1       # laquelle des 2 images est affichée
var _coq: Sprite2D   # le coq de la girouette
var _cases_portes: Array[Vector2i] = []   # cases des passages (portes de maison), lues dans `passages`


func _ready() -> void:
	_appliquer_revelation()
	position = Vector2(grille * TAILLE_SALLE)
	modulate = teinte
	_creer_decor()
	_creer_collisions()
	_poser_animaux()
	_poser_pnjs()
	_poser_passages()
	_poser_minijeu()
	_poser_coffres()


# Le vent : les petites plantes se décalent d'un pixel selon une vague qui traverse l'écran.
var _vent_actif := true


# TEST du flou (développement seulement) : F3 coupe / remet le balancement des plantes.
func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_vent_actif = not _vent_actif
		for p in _plantes:
			p[0].position.x = p[3]
		if grille == Etat.salle_courante:
			Etat.annoncer("Plantes au vent : " + ("ON" if _vent_actif else "OFF"))


func _process(delta: float) -> void:
	if grille != Etat.salle_courante:
		return   # inutile d'animer un écran qu'on ne voit pas
	# Les grands objets passent DEVANT le héros quand il est derrière eux (plus haut à l'écran), sinon derrière lui
	var acteurs: Array = get_tree().get_nodes_in_group("joueur") + get_tree().get_nodes_in_group("animaux") + get_tree().get_nodes_in_group("pnj")
	for a in acteurs:
		var acteur := a as Node2D
		if acteur == null or (acteur is Animal and acteur.portee):
			continue   # une poule portée reste toujours devant
		if not acteur.is_in_group("joueur") and not is_ancestor_of(acteur):
			continue   # un acteur d'un autre écran
		var local := acteur.global_position - global_position
		var derriere := false
		var pres_porte := false   # devant une porte, le héros reste DEVANT la maison (sinon il paraît passer en dessous quand il entre)
		for c in _cases_portes:
			if absf(local.x - (c.x * TUILE + 8)) < 20.0 and local.y > c.y * TUILE - 12.0 and local.y < c.y * TUILE + 28.0:
				pres_porte = true
		for h in _hauts:
			if pres_porte:
				break
			if local.x > h[2].x and local.x < h[2].y and local.y + 6.0 < h[1] - TUILE:
				derriere = true
				break
		acteur.z_index = 0 if derriere else 2
	if not _eaux.is_empty():
		var image := int(Time.get_ticks_msec() / 700) % 2
		if image != _image_eau:
			_image_eau = image
			for e in _eaux:
				e[0].texture = _image("%s_%d" % [e[1], image + 1])
	if not _vent_actif:
		return
	_temps += delta
	var force := Ambiance.force_vent
	for p in _plantes:
		# Décalage d'un pixel ENTIER (pas de déformation : le skew faisait un effet de flou). Seules les petites plantes bougent, surtout pendant les rafales.
		var sprite: Sprite2D = p[0]
		sprite.position.x = p[3] + roundf(p[1] * 6.0 * force * sin(_temps * 2.3 - p[2]))
	if _coq:   # le coq se retourne quand le vent change de sens (son pivot : le bas du mât)
		_coq.scale.x = clampf(sin(_temps * 0.45) * 5.0, -1.0, 1.0)
		_coq.rotation = sin(_temps * 3.1) * 0.05 * force


func _creer_decor() -> void:
	_poser_sol()
	_poser_relief()
	for y in layout.size():
		for x in layout[y].length():
			var c := layout[y][x]
			if OBJETS_G.has(c):
				_poser_objet_g(OBJETS_G[c], Vector2i(x, y))
			elif c == "Q":   # girouette : mât + coq qui tourne au vent (3x3)
				_poser_objet(["tuile:girouette_mat", Rect2i(0, 0, 3, 3), true, 0.0], Vector2i(x, y))
			elif c == "E":   # étal du marché : paniers sur une table
				_poser_region(MAISONS, Rect2i(16, 16, 3, 1), Vector2i(x, y + 1))
				_poser_region(MAISONS, Rect2i(16, 13, 3, 1), Vector2i(x, y))
				for dx in 3:
					for dy in 2:
						_solides[Vector2i(x + dx, y + dy)] = true
						_couvertes[Vector2i(x + dx, y + dy)] = true
	# Les GRIFFES du parvis sont dessinées SOUS les arbres (leur jambe monte et disparaît dans la forêt : les arbres en cachent le haut)
	var premier := get_child_count()
	for c in _objets:
		premier = mini(premier, _objets[c].get_index())
	for c in _objets:
		if layout[c.y][c.x] == "C" or layout[c.y][c.x] == "D":
			move_child(_objets[c], premier)
	# Touffes d'herbe, une fois les objets posés (jamais sous un objet)
	for y in layout.size():
		for x in layout[y].length():
			if _touffe_ici(x, y):
				_poser_sprite(TOUFFES_G[(x * 7 + y * 3) % TOUFFES_G.size()], Vector2i(x, y), Vector2i.ONE, 0.2)


# Le sol : herbe (couleurs joyeuses, images Gemini/code) avec quelques touffes, et chemin de terre là où il y a « : ».
func _poser_sol() -> void:
	for y in layout.size():
		for x in layout[y].length():
			var pos := Vector2(x * TUILE, y * TUILE)
			if _est_eau(x, y):
				# RIVIÈRE : `~` = eau (bloque), `=` = pont (on marche dessus). L'eau a une rive claire côté herbe.
				var base := _nom_eau(x, y)
				var sprite := _poser(base + "_1", pos)
				_eaux.append([sprite, base])
				if layout[y][x] == "=":
					var cote := "g" if layout[y][maxi(x - 1, 0)] != "=" else ("d" if layout[y][mini(x + 1, layout[y].length() - 1)] != "=" else "m")
					_poser("v_pont_" + cote, pos).z_index = 0
				else:
					_solides[Vector2i(x, y)] = true
					_couvertes[Vector2i(x, y)] = true
			elif _est_chemin(x, y):
				_poser(_nom_chemin(x, y), pos)
			else:
				var h := (x * 73 + y * 151 + grille.x * 31 + grille.y * 17) % 24   # « hasard » fixe : environ 1 case sur 4 porte un détail (fleurs, touffe, cailloux)
				_poser("v_herbe_sol_%d" % (h + 1) if h < 6 else "v_herbe_sol", pos)


# Une porte de maison s'OUVRE (rectangle sombre qui s'ouvre sur la porte, puis se referme) : appelée par world.gd quand le héros entre ou sort.
func ouvrir_porte(case: Vector2i, duree := 1.4) -> void:
	var lettre := ""
	for l in PORTES_MAISONS:
		var x: int = case.x - PORTES_MAISONS[l]
		var y := case.y - 2
		if x >= 0 and y >= 0 and y < layout.size() and x < layout[y].length() and layout[y][x] == l:
			lettre = l
	if lettre == "" or lettre == "U":
		return   # (l'entrée de donjon est déjà une arche ouverte et sombre)
	var taille := Vector2(24, 24) if lettre == "Z" else Vector2(12, 19)
	var ouverture := ColorRect.new()
	ouverture.color = Color(0.04, 0.025, 0.03)
	ouverture.size = taille
	ouverture.pivot_offset = taille / 2.0
	ouverture.position = Vector2(case.x * TUILE + 8 - taille.x / 2.0, case.y * TUILE + 6 - taille.y)
	ouverture.scale = Vector2(0.1, 1.0)
	ouverture.z_index = 1
	add_child(ouverture)
	var t := create_tween()
	t.tween_property(ouverture, "scale:x", 1.0, 0.22)
	t.tween_interval(duree)
	t.tween_property(ouverture, "modulate:a", 0.0, 0.3)
	t.tween_callback(ouverture.queue_free)


# COFFRES et SECRETS (voir les exports `coffres` et `secrets`).
func _poser_coffres() -> void:
	var images: Array[Texture2D] = []
	for i in range(1, 6):
		images.append(_image("coffre_%d" % i))
	for ligne in coffres:
		var m := ligne.split("|", false, 1)
		var t := m[0].strip_edges().split(" ", false)
		if t.size() == 3:
			_creer_coffre(Vector2i(int(t[0]), int(t[1])), t[2], m[1].strip_edges() if m.size() > 1 else "", images)
	for ligne in secrets:
		var m := ligne.split("|", false, 1)
		var t := m[0].strip_edges().split(" ", false)
		if t.size() != 5:
			push_warning("Exterieur : secret mal écrit : " + ligne)
			continue
		var case_coffre := Vector2i(int(t[2]), int(t[3]))
		var drapeau := t[4]
		var texte := m[1].strip_edges() if m.size() > 1 else ""
		if Etat.est("secret_" + drapeau):
			_creer_coffre(case_coffre, drapeau, texte, images)   # déjà découvert : le coffre est là
			continue
		var pierre := SecretPierre.new()
		pierre.position = Vector2(int(t[0]), int(t[1])) * TUILE
		add_child(pierre)
		pierre.initialiser(_image("v_roche_fissuree"), func():
			Etat.noter("secret_" + drapeau)
			Etat.annoncer("Un coffre était caché derrière le rocher !")
			_creer_coffre(case_coffre, drapeau, texte, images))


func _creer_coffre(case: Vector2i, drapeau: String, texte: String, images: Array[Texture2D]) -> void:
	var coffre := Coffre.new()
	coffre.position = Vector2(case * TUILE)
	add_child(coffre)
	coffre.initialiser(drapeau, texte, images, _image("insigne"))


# RELIEF : dessine les terrasses (morceaux v_ter_<rangée><colonne>) et les escaliers, et rend le bord et la falaise solides.
func _poser_relief() -> void:
	for ligne in terrasses:
		var m := ligne.split(" ", false)
		if m.size() != 4:
			push_warning("Exterieur : terrasse mal écrite : " + ligne)
			continue
		var x0 := int(m[0])
		var y0 := int(m[1])
		var w := int(m[2])
		var h := int(m[3])
		for j in h:
			for i in w:
				var r := 0 if j == 0 else (2 if j == h - 2 else (3 if j == h - 1 else 1))
				var c := 0 if i == 0 else (2 if i == w - 1 else 1)
				_poser("v_ter_%d%d" % [r, c], Vector2((x0 + i) * TUILE, (y0 + j) * TUILE))
				var case := Vector2i(x0 + i, y0 + j)
				_couvertes[case] = true
				if i == 0 or i == w - 1 or j == 0 or j >= h - 2:
					_solides[case] = true
	for ligne in escaliers:
		var m := ligne.split(" ", false)
		if m.size() != 2:
			push_warning("Exterieur : escalier mal écrit : " + ligne)
			continue
		var x0 := int(m[0])
		var y0 := int(m[1])
		_poser("v_escalier", Vector2(x0 * TUILE, y0 * TUILE))
		for j in 4:
			for i in 2:
				_solides.erase(Vector2i(x0 + i, y0 + j))   # on monte l'escalier


# De l'eau (ou un pont au-dessus de l'eau) ici ? Hors de l'écran, on prolonge la cellule du bord.
func _est_eau(x: int, y: int) -> bool:
	y = clampi(y, 0, layout.size() - 1)
	x = clampi(x, 0, layout[y].length() - 1)
	return layout[y][x] == "~" or layout[y][x] == "="


# Quelle image d'eau ? Comme le chemin : elle dépend des 4 voisins (bits : 1 nord, 2 sud, 4 ouest, 8 est) ;
# entourée d'eau partout : v_eau_f + 4 bits pour les coins de terre. (Le nom reçoit ensuite _1 ou _2 : les 2 images alternent.)
func _nom_eau(x: int, y: int) -> String:
	var bits := 0
	if _est_eau(x, y - 1): bits |= 1
	if _est_eau(x, y + 1): bits |= 2
	if _est_eau(x - 1, y): bits |= 4
	if _est_eau(x + 1, y): bits |= 8
	if bits != 15:
		return "v_eau_%d" % bits
	var coins := 0
	if not _est_eau(x + 1, y - 1): coins |= 1
	if not _est_eau(x - 1, y - 1): coins |= 2
	if not _est_eau(x + 1, y + 1): coins |= 4
	if not _est_eau(x - 1, y + 1): coins |= 8
	return "v_eau_f%d" % coins


# Hors de l'écran, on prolonge la cellule du bord (un chemin qui sort de l'écran n'a pas de bordure).
func _est_chemin(x: int, y: int) -> bool:
	y = clampi(y, 0, layout.size() - 1)
	x = clampi(x, 0, layout[y].length() - 1)
	return layout[y][x] == ":"


# Bruit des pas : terre sur le chemin, herbe ailleurs.
func surface_pas(pos: Vector2) -> String:
	var l := to_local(pos)
	return "terre" if _est_chemin(int(l.x / TUILE), int(l.y / TUILE)) else "herbe"


# Quelle image de chemin ? Elle dépend des 4 voisins (bits : 1 nord, 2 sud, 4 ouest, 8 est) ;
# entouré de chemin partout : v_chemin_f + 4 bits pour les coins en herbe (1 NE, 2 NO, 4 SE, 8 SO).
func _nom_chemin(x: int, y: int) -> String:
	var bits := 0
	if _est_chemin(x, y - 1): bits |= 1
	if _est_chemin(x, y + 1): bits |= 2
	if _est_chemin(x - 1, y): bits |= 4
	if _est_chemin(x + 1, y): bits |= 8
	if bits != 15:
		return "v_chemin_%d" % bits
	var coins := 0
	if not _est_chemin(x + 1, y - 1): coins |= 1
	if not _est_chemin(x - 1, y - 1): coins |= 2
	if not _est_chemin(x + 1, y + 1): coins |= 4
	if not _est_chemin(x - 1, y + 1): coins |= 8
	return "v_chemin_f%d" % coins


func _poser_objet_g(def: Array, cellule: Vector2i) -> void:
	var emprise: Vector2i = def[1]
	var image := _poser_sprite(def[0], cellule, emprise, def[3])
	_objets[cellule] = image
	var lettre_objet := layout[cellule.y][cellule.x]
	if STELES.has(lettre_objet) and Etat.est("stele_" + STELES[lettre_objet][0]):
		image.texture = _image(STELES[lettre_objet][1])   # le symbole est déjà déposé
	if def[2] and image.texture.get_height() >= 24:   # grand objet : le héros doit pouvoir passer derrière
		image.z_index = 1   # arbres/maisons : devant le sol ; chaque acteur choisit de passer devant (2) ou derrière (0)
		_hauts.append([image, (cellule.y + emprise.y) * TUILE, Vector2(cellule.x * TUILE - 8, (cellule.x + emprise.x) * TUILE + 8)])
	for dx in emprise.x:
		for dy in emprise.y:
			_couvertes[cellule + Vector2i(dx, dy)] = true
			if def[2]:
				_solides[cellule + Vector2i(dx, dy)] = true


# Une image centrée sur son emprise, alignée en bas. `balance` > 0 : elle se balance au vent (base fixe).
func _poser_sprite(nom: String, cellule: Vector2i, emprise: Vector2i, balance := 0.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _image(nom)
	sprite.centered = false
	var taille := Vector2(sprite.texture.get_size())
	var bas_milieu := Vector2((cellule.x + emprise.x / 2.0) * TUILE, (cellule.y + emprise.y) * TUILE)
	if balance > 0.0:
		sprite.offset = Vector2(-taille.x / 2.0, -taille.y)
		sprite.position = bas_milieu.round()
		_plantes.append([sprite, balance, sprite.position.x * 0.025, sprite.position.x])
	else:
		sprite.position = (bas_milieu - Vector2(taille.x / 2.0, taille.y)).round()
	add_child(sprite)
	return sprite


func _poser_objet(def: Array, cellule: Vector2i) -> void:
	var region: Rect2i = def[1]
	var image: String = def[0]
	if image.begins_with("tuile:"):
		_poser(image.substr(6), Vector2(cellule * TUILE))
		if image == "tuile:girouette_mat":
			_poser_coq_girouette(cellule)
	else:
		_poser_region(image, region, cellule, def[3])
	for dx in region.size.x:
		for dy in region.size.y:
			_couvertes[cellule + Vector2i(dx, dy)] = true
			if def[2]:
				_solides[cellule + Vector2i(dx, dy)] = true


# Le coq tournant tout en haut du mât.
func _poser_coq_girouette(cellule: Vector2i) -> void:
	_coq = Sprite2D.new()
	_coq.texture = _image("girouette_coq")
	_coq.offset = Vector2(0, -_coq.texture.get_height() / 2.0)   # pivot = pieds du coq
	_coq.position = Vector2(cellule * TUILE) + Vector2(24, 13)
	add_child(_coq)


# Pose un morceau (en cases) d'une planche du pack. Sprite2D + region : marche sur toutes les cartes graphiques.
# `balance` > 0 : l'objet se balance au vent (il penche depuis sa base, qui reste fixe).
func _poser_region(fichier: String, region: Rect2i, cellule: Vector2i, balance := 0.0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(fichier)
	sprite.centered = false
	sprite.region_enabled = true
	var taille := Vector2(region.size * TUILE)
	sprite.region_rect = Rect2(Vector2(region.position * TUILE), taille)
	sprite.position = Vector2(cellule * TUILE)
	if balance > 0.0:
		# le point d'accroche passe en bas au milieu : c'est le haut qui bouge
		sprite.offset = Vector2(-taille.x / 2.0, -taille.y)
		sprite.position += Vector2(taille.x / 2.0, taille.y)
		_plantes.append([sprite, balance, sprite.position.x * 0.025, sprite.position.x])
	add_child(sprite)


# Une touffe d'herbe ici ? Sur ~1 case d'herbe sur 6, pas sous un objet ni au bord d'un chemin (calcul fixe, pas de hasard).
func _touffe_ici(x: int, y: int) -> bool:
	if (x * 37 + y * 91 + grille.x * 13) % 6 != 0 or layout[y][x] != "." or _couvertes.has(Vector2i(x, y)):
		return false
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if _est_chemin(x + d.x, y + d.y):
			return false
	return true


func _poser_animaux() -> void:
	for ligne in animaux:
		var morceaux := ligne.split(" ")
		if morceaux.size() != 3 or not ANIMAUX.has(morceaux[0]):
			push_warning("Exterieur : animal mal écrit : " + ligne)
			continue
		var def: Array = ANIMAUX[morceaux[0]]
		var animal := Animal.new()
		animal.position = Vector2(int(morceaux[1]) * TUILE + 8, int(morceaux[2]) * TUILE + 10)
		add_child(animal)
		animal.initialiser(def[0], def[1], def[2], def[3], Rect2(Vector2(TUILE, TUILE), Vector2(TAILLE_SALLE) - Vector2(TUILE, TUILE) * 2))


func _creer_collisions() -> void:
	for ligne in passages:
		var m0 := ligne.split(" ", false, 2)
		if m0.size() >= 2:
			_cases_portes.append(Vector2i(int(m0[0]), int(m0[1])))
	for ligne in passages:
		var m := ligne.split(" ", false, 2)
		if m.size() >= 2:
			_solides.erase(Vector2i(int(m[0]), int(m[1])))   # on marche dans la porte
	var corps := StaticBody2D.new()
	add_child(corps)
	for cellule in _solides:
		var forme := RectangleShape2D.new()
		forme.size = Vector2(TUILE, TUILE)
		var collision := CollisionShape2D.new()
		collision.shape = forme
		collision.position = Vector2(cellule * TUILE) + Vector2(TUILE, TUILE) / 2.0
		corps.add_child(collision)


# Le point `pos` (en pixels monde) est-il dans un obstacle ? (sert à reprendre une sauvegarde sans coincer le héros)
func position_bloquee(pos: Vector2) -> bool:
	var rel := pos - position
	return _solides.has(Vector2i(floori(rel.x / TUILE), floori(rel.y / TUILE)))


# Une cellule libre pour poser le joueur (mode développeur) : la plus proche du centre de l'écran.
func point_arrivee() -> Vector2:
	var meilleure := Vector2i(12, 11)
	var distance := 1000000
	for y in layout.size():
		for x in layout[y].length():
			var c := Vector2i(x, y)
			if not _solides.has(c) and (layout[y][x] == "." or layout[y][x] == ":") and not _touffe_ici(x, y):
				var d := (c - Vector2i(12, 10)).length_squared()
				if d < distance:
					meilleure = c
					distance = d
	return position + Vector2(meilleure * TUILE) + Vector2(8, 3)


# --- Les stèles-pattes (parvis) ------------------------------------------------------------------
# Case d'une stèle ("gauche" ou "droite") dans cet écran ; (-1, -1) s'il n'y en a pas.
func case_stele(cote: String) -> Vector2i:
	for lettre in STELES:
		if STELES[lettre][0] == cote:
			for y in layout.size():
				var x := layout[y].find(lettre)
				if x >= 0:
					return Vector2i(x, y)
	return Vector2i(-1, -1)


# Position (monde) de la niche d'une stèle : là où vole le symbole.
func position_niche(cote: String) -> Vector2:
	var c := case_stele(cote)
	return position + Vector2(c * TUILE) + NICHE_STELE


# Le symbole vient d'être déposé : la stèle prend son image « pleine » avec un éclat.
func allumer_stele(cote: String) -> void:
	var c := case_stele(cote)
	if c.x < 0 or not _objets.has(c):
		return
	var image: Sprite2D = _objets[c]
	for lettre in STELES:
		if STELES[lettre][0] == cote:
			image.texture = _image(STELES[lettre][1])
	image.modulate = Color(2.4, 2.1, 1.5)
	create_tween().tween_property(image, "modulate", Color.WHITE, 0.8)
	for cellule in _objets:   # la griffe derrière la pierre s'illumine aussi
		if layout[cellule.y][cellule.x] == ("C" if cote == "gauche" else "D"):
			var griffe: Sprite2D = _objets[cellule]
			griffe.modulate = Color(1.9, 1.6, 1.1)
			create_tween().tween_property(griffe, "modulate", Color.WHITE, 1.2)


# --- La forêt qui s'écarte (parvis, cérémonie de la stèle : world.gd::_ceremonie_stele) -------------------
# Les arbres dont le coin est dans `zone` glissent sur le côté (à gauche s'ils sont à gauche de `axe_x`, sinon à droite)
# en s'effaçant. (Les collisions ne changent pas : la scène est rechargée juste après, avec son plan « révélé ».)
func ecarter_foret(zone: Rect2i, axe_x: float, duree := 2.2) -> void:
	for cellule in _objets:
		if not zone.has_point(cellule):
			continue
		var arbre: Sprite2D = _objets[cellule]
		_plantes = _plantes.filter(func(p): return p[0] != arbre)   # il ne se balance plus au vent
		var sens := -1.0 if arbre.position.x + arbre.texture.get_width() / 2.0 < axe_x else 1.0
		var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_property(arbre, "position:x", arbre.position.x + sens * 110.0, duree)
		t.tween_property(arbre, "modulate:a", 0.0, duree * 0.6).set_delay(duree * 0.4)


# Fait apparaître doucement un grand objet (ex. le temple du corps du coq), DERRIÈRE les arbres qui s'écartent.
func faire_apparaitre(lettre: String, cellule: Vector2i, duree := 2.0) -> void:
	var def: Array = OBJETS_G[lettre]
	var sprite := _poser_sprite(def[0], cellule, def[1])
	var premier := get_child_count() - 1
	for c in _objets:
		premier = mini(premier, _objets[c].get_index())
	move_child(sprite, premier)
	sprite.modulate.a = 0.0
	create_tween().tween_property(sprite, "modulate:a", 1.0, duree)
