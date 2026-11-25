class_name Carte
extends Control
## La CARTE du menu pause (créée par pause.gd).
## Elle montre les écrans de la scène où l'on est (le village, ou l'aile du donjon) : seuls ceux déjà VISITÉS sont dessinés
## (plan réel de l'écran, réduit à 1 pixel par case) ; les écrans inconnus qui touchent un écran visité apparaissent en gris avec un « ? ».
## Un point doré clignote là où se tient le héros. Les maisons (intérieurs) ne sont pas sur la carte.
## Les écrans visités viennent de `Etat.visites` (sauvegardé) ; `Etat.memoriser_position` les enregistre à chaque entrée dans un écran.

const ZONE := Rect2(8, 22, 384, 174)    # où dessiner la carte (l'écran fait 400x224)
const TAILLE_ECRAN := Vector2i(25, 14)  # un écran = 25 x 14 cases

# Couleurs : donjon
const MUR := Color(0.11, 0.11, 0.2)
const SOL_A := Color(0.52, 0.56, 0.66)
const SOL_B := Color(0.47, 0.51, 0.61)
const PORTE := Color(0.85, 0.62, 0.2)
const EAU := Color(0.27, 0.5, 0.78)
const GLACE := Color(0.72, 0.88, 0.96)
const VIDE := Color(0.03, 0.03, 0.07)
# Couleurs : extérieur
const HERBE_A := Color(0.40, 0.66, 0.30)
const HERBE_B := Color(0.37, 0.62, 0.28)
const CHEMIN := Color(0.84, 0.74, 0.5)
const PONT := Color(0.55, 0.38, 0.2)
const ARBRE := Color(0.14, 0.36, 0.18)
const BUISSON := Color(0.2, 0.46, 0.22)
const PIERRE := Color(0.5, 0.5, 0.6)
const PIERRE_SOMBRE := Color(0.3, 0.3, 0.4)
const OR := Color(0.98, 0.8, 0.32)
const TOITS := {   # lettre d'une maison -> couleur du toit
	"M": Color(0.74, 0.4, 0.26), "N": Color(0.3, 0.45, 0.72), "T": Color(0.78, 0.66, 0.34),
	"R": Color(0.74, 0.22, 0.22), "S": Color(0.52, 0.52, 0.58), "K": Color(0.35, 0.6, 0.55), "L": Color(0.45, 0.32, 0.2),
}
const BATIMENTS := ["U", "F", "G", "J", "H", "Z"]   # entrées et façades de la Forteresse

const NOMS_VILLAGE := {
	"AlleeGauche": "Allée de l'aile gauche", "AlleeDroite": "Allée de l'aile droite",
	"TempleGauche": "Entrée de l'aile gauche", "TempleDroit": "Entrée de l'aile droite",
	"Parvis": "Le parvis", "Queue": "La queue de la Forteresse", "Verger": "Le verger",
	"GrandChemin": "Le grand chemin", "TerrainGarde": "Terrain de la Garde",
	"VillageOuest": "Village, côté ouest", "PlaceDuCoq": "Place du Coq", "VillageEst": "Village, côté est",
	"MaisonHeros": "Ma maison", "Riviere": "La rivière", "Ferme": "La ferme", "RouteSud": "La route du sud",
}
const NOMS_CORPS := {"Vestibule": "La queue", "Couloir": "Le couloir", "Arene": "L'arène"}

var _monde: Node
var _scene := ""
var _ecrans := {}       # Vector2i (grille) -> Ecran
var _vus := {}          # Vector2i -> vrai si l'écran a été visité
var _images := {}       # Vector2i -> ImageTexture (plan réduit de l'écran)
var _min := Vector2i.ZERO
var _cols := 1
var _rangees := 1
var _echelle := 1.0
var _origine := Vector2.ZERO
var _temps := 0.0
var _titre := ""
var _lieu := ""         # nom de l'endroit où l'on se trouve
var _courant: Ecran     # l'écran de la carte où se tient le héros (nul dans une maison)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Prépare la carte pour le monde donné (appelé chaque fois qu'on ouvre la page).
func ouvrir(monde: Node) -> void:
	_monde = monde
	_scene = monde.scene_file_path
	_ecrans.clear()
	_vus.clear()
	_images.clear()
	_courant = null
	var plus_petit := Vector2i(1000, 1000)
	var plus_grand := Vector2i(-1000, -1000)
	for e in monde.get_children():
		if not e is Ecran or e is Interieur:
			continue
		_ecrans[e.grille] = e
		_vus[e.grille] = Etat.visites.has(_scene + "|" + e.name)
		plus_petit = Vector2i(mini(plus_petit.x, e.grille.x), mini(plus_petit.y, e.grille.y))
		plus_grand = Vector2i(maxi(plus_grand.x, e.grille.x), maxi(plus_grand.y, e.grille.y))
	if _ecrans.is_empty():
		return
	# l'écran où l'on est compte toujours comme visité (anciennes sauvegardes)
	var ici: Vector2i = monde.salle_actuelle
	if _ecrans.has(ici):
		_vus[ici] = true
		_courant = _ecrans[ici]
	_min = plus_petit
	_cols = plus_grand.x - plus_petit.x + 1
	_rangees = plus_grand.y - plus_petit.y + 1
	var s := minf(ZONE.size.x / (_cols * TAILLE_ECRAN.x), ZONE.size.y / (_rangees * TAILLE_ECRAN.y))
	_echelle = floorf(s) if s >= 2.0 else maxf(0.5, floorf(s * 2.0) / 2.0)
	var taille := Vector2(_cols, _rangees) * Vector2(TAILLE_ECRAN) * _echelle
	_origine = (ZONE.position + (ZONE.size - taille) / 2.0).round()
	for g in _ecrans:
		if _vus[g]:
			_images[g] = ImageTexture.create_from_image(_plan(_ecrans[g]))
	_titre = _nom_du_monde()
	_lieu = _nom_du_lieu()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if visible:
		_temps += delta
		queue_redraw()


# --- Textes -----------------------------------------------------------------------------------------

func _nom_du_monde() -> String:
	if not _monde.donjon:
		return Noms.VILLAGE
	var forteresse: String = Noms.FORTERESSE.substr(0, 1).to_upper() + Noms.FORTERESSE.substr(1)
	match _monde.cote:
		"gauche": return forteresse + " : aile gauche"
		"droite": return forteresse + " : aile droite"
	return forteresse + " : le corps"


func _nom_du_lieu() -> String:
	if _courant == null:
		return "Dans un bâtiment"
	return nom_d_ecran(_courant.name)


## Nom lisible d'un écran (« Plume 3 · salle 2 », « Place du Coq »...).
func nom_d_ecran(nom: String) -> String:
	if not _monde.donjon:
		return NOMS_VILLAGE.get(nom, nom)
	if _monde.cote == "corps":
		return NOMS_CORPS.get(nom, nom)
	if nom == "Vestibule":
		return "Vestibule"
	if nom == "Entree":
		return "Entrée de l'aile"
	if nom.begins_with("Epine"):
		return "Couloir de l'aile"
	if nom.begins_with("Plume"):
		var reste := nom.substr(5)
		if reste.begins_with("D"):
			reste = reste.substr(1)
		var chiffre := reste.substr(0, 1)
		var lettre := reste.substr(1, 1)
		if lettre == "":
			return "Plume " + chiffre
		return "Plume %s · salle %d" % [chiffre, lettre.unicode_at(0) - 96]
	return nom


# --- Dessin ------------------------------------------------------------------------------------------

func _draw() -> void:
	if _ecrans.is_empty():
		return
	var police := ThemeDB.fallback_font
	_texte_centre(police, _titre, 13, 12, 13, OR)
	for g in _ecrans:
		var r := _rect_de(g)
		if _images.has(g):
			draw_texture_rect(_images[g], r, false)
			draw_rect(r, Color(0, 0, 0, 0.55), false, 1.0)
		elif _est_voisin_visite(g):
			draw_rect(r, Color(0.13, 0.14, 0.2))
			draw_rect(r, Color(0.3, 0.32, 0.42), false, 1.0)
			var l := police.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
			draw_string(police, Vector2(r.get_center().x - l.x / 2.0, r.get_center().y + 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.58, 0.7))
	# l'écran où l'on se trouve : cadre doré qui respire + point du héros
	if _courant != null:
		var r := _rect_de(_courant.grille)
		var alpha := 0.55 + 0.45 * sin(_temps * 4.0)
		draw_rect(r, Color(OR.r, OR.g, OR.b, alpha), false, 2.0)
		var p: Vector2 = _monde.joueur.position - _courant.position
		var centre := r.position + Vector2(p.x / Ecran.TUILE, p.y / Ecran.TUILE) * _echelle
		centre = centre.clamp(r.position, r.end)
		if fmod(_temps, 0.8) < 0.55:
			draw_circle(centre, 3.0, Color(0.1, 0.05, 0.0))
			draw_circle(centre, 2.0, Color(1.0, 0.92, 0.45))
	_texte_centre(police, "Tu es ici : " + _lieu, 11, 210, 11, Color(0.92, 0.92, 0.98))


# Un écran dans la fenêtre de la carte (les bords sont arrondis au pixel : les écrans voisins se touchent sans trou).
func _rect_de(g: Vector2i) -> Rect2:
	var c := Vector2(g - _min) * Vector2(TAILLE_ECRAN) * _echelle
	var d := Vector2(g - _min + Vector2i.ONE) * Vector2(TAILLE_ECRAN) * _echelle
	var a := (_origine + c).round()
	var b := (_origine + d).round()
	return Rect2(a, b - a)


func _est_voisin_visite(g: Vector2i) -> bool:
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _vus.get(g + d, false):
			return true
	return false


func _texte_centre(police: Font, texte: String, taille: int, y: float, _t: int, couleur: Color) -> void:
	var l := police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille)
	var x := (get_viewport_rect().size.x - l.x) / 2.0   # (un Control dans un CanvasLayer n'a pas de taille propre : on prend celle de l'écran)
	draw_string(police, Vector2(x + 1, y + 1), texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, Color(0, 0, 0, 0.8))
	draw_string(police, Vector2(x, y), texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, couleur)


# --- Plan réduit d'un écran (1 pixel par case) -------------------------------------------------------

func _plan(e: Ecran) -> Image:
	var img := Image.create(TAILLE_ECRAN.x, TAILLE_ECRAN.y, false, Image.FORMAT_RGBA8)
	if e is Room:
		_peindre_salle(img, e)
	else:
		_peindre_dehors(img, e)
	return img


func _lettre(e: Ecran, x: int, y: int) -> String:
	if y >= e.layout.size() or x >= e.layout[y].length():
		return "#"
	return e.layout[y][x]


func _peindre_salle(img: Image, e: Ecran) -> void:
	for y in TAILLE_ECRAN.y:
		for x in TAILLE_ECRAN.x:
			var c := _lettre(e, x, y)
			var couleur: Color = SOL_A if (x + y) % 2 == 0 else SOL_B
			match c:
				"#", "R":
					couleur = MUR
				" ":
					couleur = VIDE
				"D", "H", "E":
					couleur = PORTE
				"~", "w":
					couleur = EAU
				"i":
					couleur = GLACE
				"q":
					couleur = VIDE
			img.set_pixel(x, y, couleur)


func _peindre_dehors(img: Image, e: Ecran) -> void:
	for y in TAILLE_ECRAN.y:
		for x in TAILLE_ECRAN.x:
			var c := _lettre(e, x, y)
			var couleur: Color = HERBE_A if (x + y) % 2 == 0 else HERBE_B
			match c:
				":": couleur = CHEMIN
				"~": couleur = EAU
				"=": couleur = PONT
			img.set_pixel(x, y, couleur)
	# les objets, par-dessus (la lettre est au coin haut-gauche de l'objet)
	for y in TAILLE_ECRAN.y:
		for x in TAILLE_ECRAN.x:
			var c := _lettre(e, x, y)
			var taille := Vector2i.ONE
			if Exterieur.OBJETS_G.has(c):
				taille = Exterieur.OBJETS_G[c][1]
			elif c == "Q":
				taille = Vector2i(3, 3)
			var couleur := Color(0, 0, 0, 0)
			if c in ["A", "a", "P"]:
				couleur = ARBRE
			elif c in ["b", "B"]:
				couleur = BUISSON
			elif TOITS.has(c):
				couleur = TOITS[c]
			elif c in BATIMENTS:
				couleur = PIERRE
			elif c in ["V", "X", "Q", "E", "j"]:
				couleur = OR
			elif c in ["W", "r", "u", "e", "z", "o", "x", "n"]:
				couleur = PIERRE_SOMBRE
			elif c == "f":
				couleur = Color(1.0, 0.9, 0.3)
			elif c == "g":
				couleur = Color(0.95, 0.3, 0.3)
			elif c == "w":
				couleur = Color(0.97, 0.97, 0.97)
			if couleur.a == 0.0:
				continue
			if c in ["F", "G", "J", "H"]:   # les façades font 25 cases de large : on ne garde que le bâtiment, pas le ciel
				taille = Vector2i(25, 12)
			for dy in taille.y:
				for dx in taille.x:
					if x + dx < TAILLE_ECRAN.x and y + dy < TAILLE_ECRAN.y:
						img.set_pixel(x + dx, y + dy, couleur)
