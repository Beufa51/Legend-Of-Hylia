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
#   MAISONS (4x4, la porte est sur la rangée du bas) : M orange, N bleue, T chaume, R rouge, K caserne (pierre), L bois
#   E  = étal du marché (3x2)  o = tonneau   j = bannière rouge (1x2)
#   Q  = girouette du coq (3x4)   W = puits (2x2)
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
	"A": ["v_arbre_a", Vector2i(2, 2), true, 0.03],
	"a": ["v_arbre_b", Vector2i(2, 2), true, 0.03],
	"P": ["v_sapin", Vector2i(2, 2), true, 0.025],
	"b": ["v_buisson", Vector2i(1, 1), true, 0.07],
	"B": ["v_buisson_baies", Vector2i(1, 1), true, 0.07],
	"f": ["v_tournesol", Vector2i(1, 1), false, 0.22],
	"g": ["v_fleur_rouge", Vector2i(1, 1), false, 0.22],
	"w": ["v_marguerite", Vector2i(1, 1), false, 0.22],
	"o": ["v_tonneau", Vector2i(1, 1), true, 0.0],
	"x": ["v_caisse", Vector2i(1, 1), true, 0.0],
	"n": ["v_panneau", Vector2i(1, 1), true, 0.0],
	"u": ["v_souche", Vector2i(1, 1), true, 0.0],
	"r": ["v_roche", Vector2i(2, 2), true, 0.0],
	"j": ["v_banniere", Vector2i(1, 2), true, 0.1],
	"W": ["v_puits", Vector2i(2, 2), true, 0.0],
	"e": ["v_cloture", Vector2i(2, 1), true, 0.0],   # clôture (2 cases de large)
	"z": ["v_poteau", Vector2i(1, 1), true, 0.0],    # poteau de clôture
	# Maisons : emprise 4x4, la porte est sur la dernière rangée (colonne dans PORTES_MAISONS)
	"M": ["v_maison_orange", Vector2i(4, 4), true, 0.0],
	"N": ["v_maison_bleue", Vector2i(4, 4), true, 0.0],
	"T": ["v_maison_chaume", Vector2i(4, 4), true, 0.0],
	"R": ["v_maison_rouge", Vector2i(4, 4), true, 0.0],
	"K": ["v_maison_caserne", Vector2i(4, 4), true, 0.0],
	"L": ["v_maison_bois", Vector2i(4, 4), true, 0.0],
}
# Colonne de la porte de chaque maison (0 à 3, depuis la gauche) : sert à placer les `passages` (voir generer_village.py)
const PORTES_MAISONS := {"M": 1, "N": 1, "T": 1, "R": 1, "K": 2, "L": 1}
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

var _solides := {}   # cases bloquées par un objet
var _couvertes := {} # cases recouvertes par un objet (bloquant ou non) : pas de touffe d'herbe dessus
var _plantes: Array = []   # [sprite, amplitude, phase] : ce qui se balance au vent
var _temps := 0.0
var _coq: Sprite2D   # le coq de la girouette


func _ready() -> void:
	position = Vector2(grille * TAILLE_SALLE)
	modulate = teinte
	_creer_decor()
	_creer_collisions()
	_poser_animaux()
	_poser_pnjs()
	_poser_passages()
	_poser_minijeu()


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
	if grille != Etat.salle_courante or not _vent_actif:
		return   # inutile d'animer un écran qu'on ne voit pas
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
	for y in layout.size():
		for x in layout[y].length():
			var c := layout[y][x]
			if OBJETS_G.has(c):
				_poser_objet_g(OBJETS_G[c], Vector2i(x, y))
			elif c == "Q":   # girouette : mât + coq qui tourne au vent (3x4)
				_poser_objet(["tuile:girouette_mat", Rect2i(0, 0, 3, 4), true, 0.0], Vector2i(x, y))
			elif c == "E":   # étal du marché : paniers sur une table
				_poser_region(MAISONS, Rect2i(16, 16, 3, 1), Vector2i(x, y + 1))
				_poser_region(MAISONS, Rect2i(16, 13, 3, 1), Vector2i(x, y))
				for dx in 3:
					for dy in 2:
						_solides[Vector2i(x + dx, y + dy)] = true
						_couvertes[Vector2i(x + dx, y + dy)] = true
	# Touffes d'herbe, une fois les objets posés (jamais sous un objet)
	for y in layout.size():
		for x in layout[y].length():
			if _touffe_ici(x, y):
				_poser_sprite(TOUFFES_G[(x * 7 + y * 3) % TOUFFES_G.size()], Vector2i(x, y), Vector2i.ONE, 0.2)


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


# Pose un objet Gemini (voir OBJETS_G) dont l'emprise commence à `cellule`.
func _poser_objet_g(def: Array, cellule: Vector2i) -> void:
	var emprise: Vector2i = def[1]
	_poser_sprite(def[0], cellule, emprise, def[3])
	for dx in emprise.x:
		for dy in emprise.y:
			_couvertes[cellule + Vector2i(dx, dy)] = true
			if def[2]:
				_solides[cellule + Vector2i(dx, dy)] = true


# Une image centrée sur son emprise, alignée en bas. `balance` > 0 : elle se balance au vent (base fixe).
func _poser_sprite(nom: String, cellule: Vector2i, emprise: Vector2i, balance := 0.0) -> void:
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
	_coq.position = Vector2(cellule * TUILE) + Vector2(24, 17)
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
