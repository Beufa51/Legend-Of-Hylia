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
#   MAISONS dessinées en code (Outils/fabriquer_maisons.py), vues de dessus (5x4, la porte est sur la rangée du bas, 3e colonne) : M rouge+poutres, N ardoise, T chaume, R rouge+pierre, S pierre, L grange en bois ; K = caserne (7x4, porte en 4e colonne)
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
	# Maisons : emprise 7x4 (112 px, sprite agrandi x1,3), la porte est sur la dernière rangée (colonne dans PORTES_MAISONS)
	"M": ["v_maison_orange", Vector2i(7, 4), true, 0.0],
	"N": ["v_maison_bleue", Vector2i(7, 4), true, 0.0],
	"T": ["v_maison_chaume", Vector2i(7, 4), true, 0.0],
	"R": ["v_maison_rouge", Vector2i(7, 4), true, 0.0],
	"S": ["v_maison_pierre", Vector2i(7, 4), true, 0.0],
	"K": ["v_maison_caserne", Vector2i(7, 4), true, 0.0],   # la caserne est plus large (7x4)
	"L": ["v_maison_bois", Vector2i(7, 4), true, 0.0],
	"U": ["v_temple_entree", Vector2i(7, 4), true, 0.0],
	"Z": ["v_corps_coq", Vector2i(9, 5), true, 0.0],       # le CORPS DU COQ (parvis révélé) : bâtiment en forme de coq, porte en colonne 4 (Outils/fabriquer_plans_mode7.py)
	"Y": ["v_stele_vide", Vector2i(1, 1), true, 0.0],      # stèle du coq (parvis), empreintes des ailes vides (Outils/fabriquer_stele.py)
	"y": ["v_stele_pleine", Vector2i(1, 1), true, 0.0],    # la même, avec les deux ailes posées   # entrée du temple du donjon : arche de pierre + ouverture sombre + marches (porte en colonne 3)
}
# Colonne de la porte de chaque maison (0 à 3, depuis la gauche) : sert à placer les `passages` (voir generer_village.py)
const PORTES_MAISONS := {"M": 3, "N": 3, "T": 3, "R": 3, "S": 3, "K": 3, "L": 3, "U": 3, "Z": 4}
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
var _objets := {}          # { case du coin haut-gauche : Sprite2D } des grands objets (pour la forêt qui s'écarte)
var _hauts: Array = []     # [sprite, ligne de base (y local)] : arbres, maisons... le héros passe DERRIÈRE quand il est plus haut qu'eux
var _plantes: Array = []   # [sprite, amplitude, phase] : ce qui se balance au vent
var _temps := 0.0
var _coq: Sprite2D   # le coq de la girouette


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
		for h in _hauts:
			if local.x > h[2].x and local.x < h[2].y and local.y + 6.0 < h[1] - TUILE:
				derriere = true
				break
		acteur.z_index = 0 if derriere else 2
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


# Le sol : herbe (couleurs joyeuses, images Gemini/code) avec quelques touffes, et chemin de terre là où il y a « : ».
func _poser_sol() -> void:
	for y in layout.size():
		for x in layout[y].length():
			var pos := Vector2(x * TUILE, y * TUILE)
			if _est_chemin(x, y):
				_poser(_nom_chemin(x, y), pos)
			else:
				var h := (x * 73 + y * 151 + grille.x * 31 + grille.y * 17) % 13   # « hasard » fixe
				_poser("v_herbe_sol_%d" % (h + 1) if h < 2 else "v_herbe_sol", pos)


# Hors de l'écran, on prolonge la cellule du bord (un chemin qui sort de l'écran n'a pas de bordure).
func _est_chemin(x: int, y: int) -> bool:
	y = clampi(y, 0, layout.size() - 1)
	x = clampi(x, 0, layout[y].length() - 1)
	return layout[y][x] == ":"


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
