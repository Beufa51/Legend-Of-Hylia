extends CharacterBody2D
# Joueur : déplacement dans 4 directions + animations (marche / repos).
# Les animations sont construites ici à partir des planches du pack Ninja Adventure,
# donc rien à configurer à la main dans l'éditeur.

const VITESSE := 70.0  # pixels par seconde
const DOSSIER := "res://Assets/Ninja_adventure/Actor/Character/Knight/SeparateAnim/"
# Ordre des colonnes dans les planches : bas, haut, gauche, droite
const DIRECTIONS := ["bas", "haut", "gauche", "droite"]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction := "bas"  # dernière direction regardée


func _ready() -> void:
	sprite.sprite_frames = _creer_animations()
	sprite.play("repos_bas")


func _physics_process(_delta: float) -> void:
	# Vecteur d'entrée : (-1..1, -1..1) selon les touches pressées
	var entree := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = entree * VITESSE
	move_and_slide()
	_mettre_a_jour_animation(entree)


func _mettre_a_jour_animation(entree: Vector2) -> void:
	if entree != Vector2.ZERO:
		# Direction dominante : horizontale ou verticale
		if absf(entree.x) > absf(entree.y):
			direction = "droite" if entree.x > 0 else "gauche"
		else:
			direction = "bas" if entree.y > 0 else "haut"
		sprite.play("marche_" + direction)
	else:
		sprite.play("repos_" + direction)


# Découpe les planches Walk.png (4x4) et Idle.png (4x1) en animations.
func _creer_animations() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var marche: Texture2D = load(DOSSIER + "Walk.png")
	var repos: Texture2D = load(DOSSIER + "Idle.png")
	for col in DIRECTIONS.size():
		var nom_marche: String = "marche_" + DIRECTIONS[col]
		frames.add_animation(nom_marche)
		frames.set_animation_speed(nom_marche, 8.0)
		frames.set_animation_loop(nom_marche, true)
		for ligne in 4:  # 4 images de marche par direction
			frames.add_frame(nom_marche, _decoupe(marche, col, ligne))
		var nom_repos: String = "repos_" + DIRECTIONS[col]
		frames.add_animation(nom_repos)
		frames.set_animation_loop(nom_repos, true)
		frames.add_frame(nom_repos, _decoupe(repos, col, 0))
	return frames


# Renvoie l'image (colonne, ligne) d'une planche de cases 16x16.
func _decoupe(texture: Texture2D, col: int, ligne: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * 16, ligne * 16, 16, 16)
	return atlas
