extends Node2D
class_name Room
# Une salle de 20x11 tuiles de 16 px (= 320x180, la taille de l'écran).
# Le plan de la salle est écrit en texte dans `layout` :
#   #  = mur (bloque le joueur)
#   .  = sol
# Une ouverture dans le mur du bord = une porte vers la salle voisine.
# Les graphismes viennent de la planche TilesetInteriorFloor.png du pack Ninja Adventure.

const TUILE := 16
const TAILLE_SALLE := Vector2i(320, 180)
const PLANCHE := "res://Assets/Ninja_adventure/Backgrounds/Tilesets/Interior/TilesetInteriorFloor.png"
# Position (colonne, ligne) des tuiles dans la planche. Pour changer le décor, change ces nombres.
const TUILE_SOL := Vector2i(12, 7)   # sol vert-gris
const TUILE_MUR := Vector2i(12, 13)  # pierre sombre

# Plan de la salle (11 lignes de 20 caractères). Modifiable dans l'inspecteur.
@export var layout: PackedStringArray
# Position de la salle dans la grille du donjon : (0,0), (1,0), (0,-1)...
@export var grille := Vector2i.ZERO


func _ready() -> void:
	# On place la salle à sa case de la grille (chaque case = 320x180 pixels)
	position = Vector2(grille * TAILLE_SALLE)
	_creer_collisions()
	# DIAGNOSTIC (à retirer) : affiche dans l'onglet Sortie ce que la salle a reçu
	print("Room ", name, " : ", layout.size(), " lignes, position ", position, ", visible=", is_visible_in_tree())
	queue_redraw()


# Dessine chaque case de la salle (sol ou mur) avec la tuile correspondante.
func _draw() -> void:
	var planche: Texture2D = load(PLANCHE)
	if planche == null:
		# Sécurité : si l'image ne charge pas, on dessine en couleurs et on le signale
		push_error("Room : impossible de charger " + PLANCHE)
		_dessiner_sans_image()
		return
	for y in layout.size():
		for x in layout[y].length():
			var tuile := TUILE_MUR if layout[y][x] == "#" else TUILE_SOL
			draw_texture_rect_region(planche,
				Rect2(x * TUILE, y * TUILE, TUILE, TUILE),
				Rect2(tuile.x * TUILE, tuile.y * TUILE, TUILE, TUILE))


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


# Plan B (couleurs unies) si la planche de tuiles est introuvable.
func _dessiner_sans_image() -> void:
	for y in layout.size():
		for x in layout[y].length():
			var couleur := Color(0.18, 0.15, 0.22) if layout[y][x] == "#" else Color(0.35, 0.3, 0.4)
			draw_rect(Rect2(x * TUILE, y * TUILE, TUILE, TUILE), couleur)
