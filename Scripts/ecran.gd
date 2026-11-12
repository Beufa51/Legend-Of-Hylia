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


