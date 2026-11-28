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

static var _coups_poules := 0   # à force de frapper les poules...
static var _dernier_coup_poule := -100.0
const COUPS_AVANT_PANIQUE := 5   # ...elles s'affolent et se dispersent (elles n'attaquent JAMAIS : plus de poules qui coincent le joueur)
const DUREE_PANIQUE := 3.0

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
	add_to_group("animaux")   # exterieur.gd les place devant/derrière les arbres selon leur hauteur
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
		add_to_group("poules")
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


# --- Poule portée (mini-jeu de la ferme) : le joueur la prend dans ses bras, puis la LANCE (comme les cocottes de Zelda) ---
var portee := false
var verrouillee := false   # déjà rentrée dans l'enclos : on ne peut plus la reprendre


func attraper() -> void:
	portee = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	z_index = 2
	_sprite.flip_h = false
	Animal.cri_poule(self)


# Elle vole de `depart` à `arrivee` (positions globales, par-dessus les clôtures), puis se remet à picorer.
func lancer(depart: Vector2, arrivee: Vector2) -> void:
	portee = false
	global_position = depart
	var vol := create_tween()
	vol.tween_property(self, "global_position", arrivee, 0.3)
	var arc := create_tween()
	arc.tween_property(_sprite, "position:y", -24.0, 0.15).set_ease(Tween.EASE_OUT)
	arc.tween_property(_sprite, "position:y", -5.0, 0.15).set_ease(Tween.EASE_IN)
	await vol.finished
	z_index = 0
	collision_layer = 1
	collision_mask = 1
	_fuite = 0.0
	_direction = Vector2.ZERO
	_chrono = 1.0
	set_physics_process(true)


static func cri_poule(poule: Animal) -> void:
	poule._crier()


# Change la zone où l'animal a le droit d'aller (ex. : la poule rentrée dans l'enclos y reste).
func limiter(zone: Rect2) -> void:
	_zone = zone


func _physics_process(delta: float) -> void:
	_chrono -= delta
	_fuite -= delta
	var joueur := _joueur()
	if _peureux and joueur and _fuite <= 0.0 and joueur.global_position.distance_to(global_position) < DISTANCE_PEUR:
		_fuite = 0.9
	if _fuite > 0.0 and joueur:
		# Fuite : droit devant, mais en contournant ce qui bloque (arbre, mur, bord de l'écran) au lieu de vibrer contre
		_direction = _direction_libre((global_position - joueur.global_position).normalized())
	elif _fuite <= 0.0 and _chrono <= 0.0:
		# Nouvel état : se promener (60 %) ou s'arrêter pour picorer (40 %)
		if _vitesse > 0.0 and randf() < 0.6:
			_direction = _direction_libre(Vector2.from_angle(randf() * TAU))
			_chrono = randf_range(0.8, 2.2)
		else:
			_direction = Vector2.ZERO
			_chrono = randf_range(1.0, 3.5)
	var vitesse := _vitesse * (3.2 if _fuite > 0.0 else 1.0)
	velocity = _direction * vitesse
	move_and_slide()
	# Bloqué au repos : on choisit tout de suite autre chose à faire
	if _fuite <= 0.0 and get_slide_collision_count() > 0:
		_chrono = 0.0
		_direction = Vector2.ZERO
	_animer(delta)


# Première direction praticable en partant de `voulue` puis en tournant de plus en plus (jamais vers un obstacle ni hors de la zone).
func _direction_libre(voulue: Vector2) -> Vector2:
	if voulue == Vector2.ZERO:
		voulue = Vector2.RIGHT
	for angle in [0.0, 0.6, -0.6, 1.2, -1.2, 1.9, -1.9, PI]:
		var d := voulue.rotated(angle)
		if _zone.has_point(position + d * 8.0) and not test_move(global_transform, d * 6.0):
			return d
	return Vector2.ZERO


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
	_direction = _direction_libre((global_position - joueur.global_position).normalized())


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
		if maintenant - _dernier_coup_poule > 8.0:
			_coups_poules = 0   # on a laissé les poules tranquilles : elles pardonnent
		_dernier_coup_poule = maintenant
		_coups_poules += 1
		if _coups_poules >= COUPS_AVANT_PANIQUE:
			_coups_poules = 0
			_paniquer()
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


# Trop de coups : TOUTES les poules de l'écran s'affolent et se dispersent en caquetant (aucune attaque, aucun dégât).
func _paniquer() -> void:
	Etat.annoncer("Les poules s'affolent de tous côtés !")
	var joueur := _joueur()
	for p in get_tree().get_nodes_in_group("poules"):
		if p.portee or p.verrouillee or joueur == null:
			continue
		p._fuir(joueur, DUREE_PANIQUE)
		p._crier()
