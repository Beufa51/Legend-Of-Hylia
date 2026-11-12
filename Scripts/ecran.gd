extends Node2D
class_name Ecran
# Ce qui est COMMUN à tous les écrans du jeu : une salle de donjon (room.gd) ou un écran
# extérieur (exterieur.gd). Chaque écran fait 25 x 14 cases de 16 px (= 400 x 224, la taille
# de l'écran) et a une place dans la grille de sa scène.
# Règle : ne mettre ICI que ce qui sert aux deux. Une mécanique de donjon va dans room.gd,
# une chose d'extérieur dans exterieur.gd : modifier l'un ne casse pas l'autre.

const TUILE := 16
const TAILLE_SALLE := Vector2i(400, 224)
const DOSSIER := "res://Assets/Gemini/tuiles/"

# Plan de l'écran (14 lignes de 25 caractères). Les lettres dépendent du type d'écran.
@export var layout: PackedStringArray
# Position de l'écran dans la grille de sa scène : (0,0), (1,0), (0,-1)...
@export var grille := Vector2i.ZERO
# Teinte de l'écran (blanc = couleurs normales).
@export var teinte := Color.WHITE
@export var sombre := false        # écran plongé dans le noir (seules les lumières éclairent)
@export var indice := ""           # message affiché la première fois qu'on entre dans l'écran
# Habitants de l'écran : "Perso x y direction | Nom | phrase // phrase" (voir l'en-tête de exterieur.gd)
@export var pnjs: PackedStringArray
# Passages (portes de maison...) : "x y Ecran dx dy" = en marchant sur la case (x,y), le joueur
# arrive dans l'écran nommé `Ecran`, sur sa case (dx,dy). "x y ! texte" = simple message (porte fermée).
@export var passages: PackedStringArray
var interieur := false             # vrai dans une maison (pas de vent ni de feuilles)

# Cache des images déjà chargées (partagé entre tous les écrans)
static var _cache := {}


# Remet l'écran dans son état de départ (touche R). Rien à faire par défaut.
func reinitialiser() -> void:
	pass


# Une case où poser le joueur (mode développeur, retours rapides). Par défaut : le centre.
func point_arrivee() -> Vector2:
	return position + Vector2(TAILLE_SALLE) / 2.0


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
				push_error("Ecran : image introuvable " + chemin)
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




# Habitants : une ligne par personnage (voir pnj.gd)
func _poser_pnjs() -> void:
	for ligne in pnjs:
		var parties := ligne.split("|")
		var tete := parties[0].strip_edges().split(" ")
		if parties.size() != 3 or tete.size() != 4:
			push_warning("Ecran : habitant mal écrit : " + ligne)
			continue
		var texte := PackedStringArray()
		for phrase in parties[2].split("//"):
			texte.append(phrase.strip_edges())
		var pnj := Pnj.new()
		pnj.position = Vector2(int(tete[1]) * TUILE + 8, int(tete[2]) * TUILE + 13)
		add_child(pnj)
		pnj.initialiser(tete[0], parties[1].strip_edges(), texte, tete[3], grille)


# Passages : une petite zone sur la case ; quand le joueur y entre -> changement d'écran (signal Etat.passage)
func _poser_passages() -> void:
	for ligne in passages:
		var m := ligne.split(" ", false, 2)
		if m.size() < 3:
			push_warning("Ecran : passage mal écrit : " + ligne)
			continue
		var zone := Area2D.new()
		zone.collision_layer = 0
		zone.collision_mask = 1
		zone.position = Vector2(int(m[0]) * TUILE + 8, int(m[1]) * TUILE + 8)
		var forme := RectangleShape2D.new()
		forme.size = Vector2(10, 8)
		var collision := CollisionShape2D.new()
		collision.shape = forme
		zone.add_child(collision)
		add_child(zone)
		if m[2].begins_with("!"):
			var texte := m[2].substr(1).strip_edges()
			zone.body_entered.connect(func(corps): if corps.is_in_group("joueur"): Etat.annoncer(texte))
		else:
			var d := m[2].split(" ")
			var cible := d[0]
			var case := Vector2i(int(d[1]), int(d[2]))
			zone.body_entered.connect(func(corps): if corps.is_in_group("joueur"): Etat.passage.emit(cible, case))
