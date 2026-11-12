extends CharacterBody2D
class_name Animal
# Un animal du village (poule, chat, chien...). Il se promène au hasard, picore, s'arrête.
# Un animal PEUREUX (poule) s'enfuit quand le joueur s'approche.
# Un coup de lance ne le blesse pas : il sursaute, crie et s'enfuit (zéro combat !).
# Planche du pack Ninja Adventure : 2 images de 16x16 côte à côte, l'animal regarde à droite.

const SONS := {
	"poule": "res://Assets/Ninja_adventure/Audio/Sounds/Creature/Bird.wav",
	"chien": "res://Assets/Ninja_adventure/Audio/Sounds/Creature/Dog.wav",
	"chat": "",
}
const DISTANCE_PEUR := 30.0   # px : un animal peureux fuit si le joueur est plus près que ça

static var _coups_poules := 0   # pour le clin d'œil : à force de frapper les poules...

var _sprite: Sprite2D
var _vitesse := 0.0
var _peureux := false
var _espece := ""
var _zone := Rect2()          # où il a le droit d'aller (coordonnées de l'écran parent)
var _direction := Vector2.ZERO
var _chrono := 0.0            # temps restant dans l'état actuel
var _fuite := 0.0             # temps de fuite restant
var _image_chrono := 0.0
var _dernier_coup := -10.0
var _plumes: CPUParticles2D


func initialiser(planche: String, vitesse: float, peureux: bool, espece: String, zone: Rect2) -> void:
	_vitesse = vitesse
	_peureux = peureux
	_espece = espece
	_zone = zone
	collision_layer = 1   # couche 1 : la lance peut le toucher
	collision_mask = 1    # il se cogne aux arbres, maisons...
	var forme := CircleShape2D.new()
	forme.radius = 4.0
	var collision := CollisionShape2D.new()
	collision.shape = forme
	add_child(collision)
	_sprite = Sprite2D.new()
	_sprite.texture = load(planche)
	_sprite.hframes = 2
	_sprite.position = Vector2(0, -5)
	add_child(_sprite)
	if espece == "poule":
		_plumes = CPUParticles2D.new()   # petites plumes qui volent quand on la frappe
		_plumes.emitting = false
		_plumes.one_shot = true
		_plumes.amount = 8
		_plumes.lifetime = 0.6
		_plumes.explosiveness = 1.0
		_plumes.spread = 180.0
		_plumes.initial_velocity_min = 25.0
		_plumes.initial_velocity_max = 45.0
		_plumes.gravity = Vector2(0, 60)
		_plumes.scale_amount_min = 1.0
		_plumes.scale_amount_max = 2.0
		_plumes.color = Color(1, 1, 1) if planche.ends_with("White.png") else Color(0.75, 0.3, 0.2)
		_plumes.position = Vector2(0, -6)
		add_child(_plumes)
	_chrono = randf_range(0.5, 2.0)


func _physics_process(delta: float) -> void:
	_chrono -= delta
	_fuite -= delta
	var joueur := _joueur()
	if _peureux and joueur and joueur.global_position.distance_to(global_position) < DISTANCE_PEUR and _fuite <= 0.0:
		_fuir(joueur, 0.9)
	if _fuite <= 0.0 and _chrono <= 0.0:
		# Nouvel état : se promener (60 %) ou s'arrêter pour picorer (40 %)
		if _vitesse > 0.0 and randf() < 0.6:
			_direction = Vector2.from_angle(randf() * TAU)
			_chrono = randf_range(0.8, 2.2)
		else:
			_direction = Vector2.ZERO
			_chrono = randf_range(1.0, 3.5)
	var vitesse := _vitesse * (3.2 if _fuite > 0.0 else 1.0)
	velocity = _direction * vitesse
	# Ne pas sortir de son écran : demi-tour au bord
	var suivante := position + velocity * delta
	if not _zone.has_point(suivante):
		_direction = (_zone.get_center() - position).normalized()
		velocity = _direction * vitesse
	move_and_slide()
	_animer(delta)


# Marche : les 2 images alternent ; à l'arrêt : il picore de temps en temps (image 2 un instant).
func _animer(delta: float) -> void:
	_image_chrono += delta
	if velocity.length() > 1.0:
		_sprite.frame = int(_image_chrono * (14.0 if _fuite > 0.0 else 6.0)) % 2
		if absf(velocity.x) > 1.0:
			_sprite.flip_h = velocity.x < 0.0
	else:
		_sprite.frame = 1 if fmod(_image_chrono, 1.6) > 1.35 else 0


func _fuir(joueur: Node2D, duree: float) -> void:
	_fuite = duree
	_direction = (global_position - joueur.global_position).normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT


# Coup de lance : sursaut, cri, fuite. (Appelé à chaque image tant que la lance le touche : anti-répétition.)
func frapper() -> void:
	var maintenant := Time.get_ticks_msec() / 1000.0
	if maintenant - _dernier_coup < 0.5:
		return
	_dernier_coup = maintenant
	_crier()
	var saut := create_tween()
	saut.tween_property(_sprite, "position:y", -13.0, 0.12).set_ease(Tween.EASE_OUT)
	saut.tween_property(_sprite, "position:y", -5.0, 0.18).set_ease(Tween.EASE_IN)
	if _plumes:
		_plumes.restart()
	var joueur := _joueur()
	if joueur and _vitesse > 0.0:
		_fuir(joueur, 1.8)
	if _espece == "poule":
		_coups_poules += 1
		if _coups_poules == 6:
			Etat.annoncer("Les poules du village te regardent d'un drôle d'air... Elles ont la rancune tenace.")
	elif _espece == "chat":
		Etat.annoncer("Le chat ouvre un œil, soupire... et se rendort.")


func _crier() -> void:
	var chemin: String = SONS.get(_espece, "")
	if chemin == "":
		return
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer2D.new()
	lecteur.stream = flux
	lecteur.volume_db = -6.0
	lecteur.pitch_scale = randf_range(1.15, 1.45) if _espece == "poule" else 1.0
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)


func _joueur() -> Node2D:
	return get_tree().get_first_node_in_group("joueur") as Node2D
