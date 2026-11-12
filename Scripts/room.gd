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
	_creer_decor()
	_creer_collisions()


# Pose un Sprite2D par case (sol ou mur) avec la bonne portion de la planche.
func _creer_decor() -> void:
	var planche: Texture2D = load(PLANCHE)
	if planche == null:
		push_error("Room : impossible de charger " + PLANCHE)
		return
	for y in layout.size():
		for x in layout[y].length():
			var tuile := TUILE_MUR if layout[y][x] == "#" else TUILE_SOL
			var sprite := Sprite2D.new()
			sprite.texture = planche
			sprite.centered = false
			sprite.region_enabled = true
			sprite.region_rect = Rect2(tuile.x * TUILE, tuile.y * TUILE, TUILE, TUILE)
			sprite.position = Vector2(x * TUILE, y * TUILE)
			add_child(sprite)


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

