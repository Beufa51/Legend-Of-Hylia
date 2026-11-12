extends Node2D
class_name Room
# Une salle de 20x11 tuiles de 16 px (= 320x180, la taille de l'écran).
# Le plan de la salle est écrit en texte dans `layout` :
#   #  = mur (bloque le joueur)
#   .  = sol
# Une ouverture dans le mur du bord = une porte vers la salle voisine.
# Les couleurs sont provisoires : on mettra les vrais graphismes du pack plus tard.

const TUILE := 16
const TAILLE_SALLE := Vector2i(320, 180)
const COULEUR_SOL := Color(0.35, 0.3, 0.4)
const COULEUR_MUR := Color(0.18, 0.15, 0.22)

# Plan de la salle (11 lignes de 20 caractères). Modifiable dans l'inspecteur.
@export var layout: PackedStringArray
# Position de la salle dans la grille du donjon : (0,0), (1,0), (0,-1)...
@export var grille := Vector2i.ZERO


func _ready() -> void:
	# On place la salle à sa case de la grille (chaque case = 320x180 pixels)
	position = Vector2(grille * TAILLE_SALLE)
	_creer_collisions()


# Dessine le sol puis chaque mur.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(TAILLE_SALLE)), COULEUR_SOL)
	for y in layout.size():
		for x in layout[y].length():
			if layout[y][x] == "#":
				draw_rect(Rect2(x * TUILE, y * TUILE, TUILE, TUILE), COULEUR_MUR)


# Ajoute une boîte de collision à chaque mur.
func _creer_collisions() -> void:
	var corps := StaticBody2D.new()
	add_child(corps)
	for y in layout.size():
		for x in layout[y].length():
			if layout[y][x] == "#":
				var forme := RectangleShape2D.new()
				forme.size = Vector2(TUILE, TUILE)
				var collision := CollisionShape2D.new()
				collision.shape = forme
				collision.position = Vector2(x * TUILE + TUILE / 2.0, y * TUILE + TUILE / 2.0)
				corps.add_child(collision)
