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
const TUILE_SOL_ETOILE := Vector2i(14, 11)  # petit motif en étoile (rare)
const TUILE_SOL_BRIQUE := Vector2i(11, 10)  # fissure / brique (rare)

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
			var est_mur := layout[y][x] == "#"
			var tuile := TUILE_MUR if est_mur else _tuile_sol(x, y)
			_poser_tuile(planche, tuile, Vector2(x * TUILE, y * TUILE))
			# Petite ombre sur le sol, juste sous un mur : donne de la profondeur
			if not est_mur and y > 0 and layout[y - 1][x] == "#":
				var ombre := ColorRect.new()
				ombre.color = Color(0, 0, 0, 0.27)
				ombre.size = Vector2(TUILE, 5)
				ombre.position = Vector2(x * TUILE, y * TUILE)
				add_child(ombre)


# Choisit une tuile de sol : surtout du sol uni, avec quelques motifs rares.
# Le calcul est fixe (pas de hasard) : une salle a toujours le même aspect.
func _tuile_sol(x: int, y: int) -> Vector2i:
	var h := (x * 7 + y * 13 + x * y * 3) % 17
	if h == 0:
		return TUILE_SOL_ETOILE
	if h == 1:
		return TUILE_SOL_BRIQUE
	return TUILE_SOL


# Crée un Sprite2D d'une tuile de la planche à la position donnée.
func _poser_tuile(planche: Texture2D, tuile: Vector2i, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = planche
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(tuile.x * TUILE, tuile.y * TUILE, TUILE, TUILE)
	sprite.position = pos
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

