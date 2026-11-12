extends CharacterBody2D
# Joueur : déplacement dans 4 directions + animations (marche / repos) + coup de lance (touche Espace ou J).
# Les animations sont construites ici à partir des planches du pack Ninja Adventure,
# donc rien à configurer à la main dans l'éditeur.

const VITESSE := 70.0  # pixels par seconde
const FACTEUR_COURSE := 1.7  # vitesse multipliée quand on court (touche Maj ou K)
const DOSSIER := "res://Assets/Ninja_adventure/Actor/Character/Knight/SeparateAnim/"
# Ordre des colonnes dans les planches : bas, haut, gauche, droite
const DIRECTIONS := ["bas", "haut", "gauche", "droite"]
const VECTEURS := {"bas": Vector2.DOWN, "haut": Vector2.UP, "gauche": Vector2.LEFT, "droite": Vector2.RIGHT}
# La lance du garde royal (pack Ninja Adventure) : image de la lance tenue en main (pointe vers le bas dans l'image)
const LANCE_IMAGE := "res://Assets/Ninja_adventure/Items/Weapons/Lance/SpriteInHand.png"
const SON_LANCE := "res://Assets/Ninja_adventure/Audio/Sounds/Jump & Bounce/Jump2.wav"
const PORTEE_RENTREE := 4.0   # distance de la lance (en pixels) quand elle est rentrée
const PORTEE_SORTIE := 13.0   # distance de la lance quand elle est tendue

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction := "bas"  # dernière direction regardée
var attaque := false    # vrai pendant un coup de lance (le joueur ne bouge pas)
var lance: Node2D       # la lance (image + zone de touche), créée dans _ready
var zone: Area2D        # zone de touche de la lance
var lumiere: PointLight2D  # petite lumière autour du joueur (allumée seulement dans les salles sombres)
var _temps_pousse := 0.0  # depuis combien de temps on pousse contre un bloc


func _ready() -> void:
	add_to_group("joueur")
	sprite.sprite_frames = _creer_animations()
	sprite.play("repos_bas")
	_creer_lance()
	lumiere = Lumiere.creer(Color(0.85, 0.92, 1.0), 0.6, 0.7)
	lumiere.enabled = false
	add_child(lumiere)


func _physics_process(delta: float) -> void:
	if attaque:
		_frapper_ce_quon_touche()
		return  # pas de déplacement pendant le coup
	if Input.is_action_just_pressed("attack"):
		_attaquer()
		return
	# Vecteur d'entrée : (-1..1, -1..1) selon les touches pressées
	var entree := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var court := Input.is_action_pressed("run")
	velocity = entree * VITESSE * (FACTEUR_COURSE if court else 1.0)
	sprite.speed_scale = 1.6 if court else 1.0   # les jambes vont plus vite quand on court
	move_and_slide()
	_pousser_les_blocs(entree, delta)
	_mettre_a_jour_animation(entree)


# Si on avance contre un bloc "poussable" pendant un instant, il glisse d'une case.
func _pousser_les_blocs(entree: Vector2, delta: float) -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var autre = collision.get_collider()
		if autre == null or not autre.is_in_group("poussable"):
			continue
		var vers := -collision.get_normal()   # direction du joueur vers le bloc
		var dir := Vector2i(signi(roundi(vers.x)), 0) if absf(vers.x) > absf(vers.y) else Vector2i(0, signi(roundi(vers.y)))
		if entree.normalized().dot(Vector2(dir)) > 0.7:   # on appuie bien vers le bloc
			_temps_pousse += delta
			if _temps_pousse >= 0.3:
				autre.pousser(dir)
				_temps_pousse = 0.0
			return
	_temps_pousse = 0.0


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


# Allume ou éteint la petite lumière du joueur (appelé par world.gd selon la salle).
func regler_lumiere(allumee: bool) -> void:
	lumiere.enabled = allumee


# Construit la lance : une image + une zone (Area2D) qui détecte ce qu'elle touche.
func _creer_lance() -> void:
	lance = Node2D.new()
	lance.visible = false
	add_child(lance)
	var image := Sprite2D.new()
	image.texture = load(LANCE_IMAGE)
	lance.add_child(image)
	zone = Area2D.new()
	zone.collision_layer = 0   # la zone ne bloque personne
	zone.collision_mask = 1    # elle détecte les murs, pots, etc. (couche 1)
	zone.monitoring = false
	var forme := RectangleShape2D.new()
	forme.size = Vector2(6, 16)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	zone.add_child(collision)
	lance.add_child(zone)


# Un coup de lance : la lance sort devant le joueur, reste un instant, puis rentre.
func _attaquer() -> void:
	attaque = true
	var vecteur: Vector2 = VECTEURS[direction]
	sprite.play("attaque_" + direction)
	lance.rotation = vecteur.angle() - PI / 2.0   # l'image a la pointe vers le BAS : on la tourne pour qu'elle pointe dans la direction du coup
	lance.z_index = 1  # toujours devant (derrière le joueur, elle passait sous le sol du décor)
	lance.position = Vector2(0, 2) + vecteur * PORTEE_RENTREE
	lance.visible = true
	zone.monitoring = true
	_jouer_son(SON_LANCE, -6.0)
	var tween := create_tween()
	tween.tween_property(lance, "position", Vector2(0, 2) + vecteur * PORTEE_SORTIE, 0.09)
	tween.tween_interval(0.08)
	tween.tween_property(lance, "position", Vector2(0, 2) + vecteur * PORTEE_RENTREE, 0.09)
	await tween.finished
	zone.monitoring = false
	lance.visible = false
	attaque = false


# Pendant le coup : tout ce qui réagit à la lance (pots, cristaux...) dans sa zone est frappé.
func _frapper_ce_quon_touche() -> void:
	for corps in zone.get_overlapping_bodies():
		if corps.has_method("frapper"):
			corps.frapper()


func _jouer_son(chemin: String, volume_db: float) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = volume_db
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)


# Découpe les planches Walk.png (4x4) et Idle.png (4x1) en animations.
func _creer_animations() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var marche: Texture2D = load(DOSSIER + "Walk.png")
	var repos: Texture2D = load(DOSSIER + "Idle.png")
	var coup: Texture2D = load(DOSSIER + "Attack.png")  # 4 images : bas, haut, gauche, droite
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
		var nom_coup: String = "attaque_" + DIRECTIONS[col]
		frames.add_animation(nom_coup)
		frames.set_animation_loop(nom_coup, false)
		frames.add_frame(nom_coup, _decoupe(coup, col, 0))
	return frames


# Renvoie l'image (colonne, ligne) d'une planche de cases 16x16.
func _decoupe(texture: Texture2D, col: int, ligne: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * 16, ligne * 16, 16, 16)
	return atlas
