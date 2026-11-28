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
const COUPS_AVANT_COLERE := 5   # ...toutes les poules de l'écran s'énervent et attaquent (comme les cocottes de Zelda) : 1 cœur par coup de bec
const DUREE_COLERE := 20.0      # elles se calment au bout de 20 s, ou dès que le joueur quitte l'écran

var _sprite: Sprite2D
var _vitesse := 0.0
var _peureux := false
var _espece := ""
var _zone := Rect2()          # où il a le droit d'aller (coordonnées de l'écran parent)
var _direction := Vector2.ZERO
var _chrono := 0.0            # temps restant dans l'état actuel
var _fuite := 0.0             # temps de fuite restant
var _colere := 0.0            # temps restant de colère (poule qui fonce sur le joueur)
var _bec := 0.0               # délai entre deux coups de bec
var _renfort := false         # poule venue en renfort : disparaît après la colère
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
	_sprite.scale = Vector2(1.15, 1.15)
	_sprite.position.y = 8.0   # elle part des bras du héros et est soulevée au-dessus de sa tête
	create_tween().tween_property(_sprite, "position:y", -3.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Animal.cri_poule(self)


# Poule portée : elle se débat (ailes qui battent, secousses) et caquette de temps en temps.
var _debat := 0.0


func _process(delta: float) -> void:
	if not portee:
		return
	_debat += delta
	_sprite.frame = int(_debat * 16.0) % 2
	_sprite.rotation = sin(_debat * 28.0) * 0.22
	_sprite.scale = Vector2(1.15 + sin(_debat * 20.0) * 0.06, 1.15 - sin(_debat * 20.0) * 0.06)
	if fmod(_debat, 1.3) < delta:
		_crier()


# Elle vole de `depart` à `arrivee` (positions globales, par-dessus les clôtures), puis se remet à picorer.
func lancer(depart: Vector2, arrivee: Vector2) -> void:
	portee = false
	global_position = depart
	_sprite.scale = Vector2.ONE
	var vol := create_tween()
	vol.tween_property(self, "global_position", arrivee, 0.42)
	var arc := create_tween()
	arc.tween_property(_sprite, "position:y", -34.0, 0.21).set_ease(Tween.EASE_OUT)
	arc.tween_property(_sprite, "position:y", -5.0, 0.21).set_ease(Tween.EASE_IN)
	var tourne := create_tween()   # elle bat des ailes en vol
	tourne.tween_property(_sprite, "rotation", 0.0, 0.42).from(-0.5)
	await vol.finished
	_poussiere()
	var rebond := create_tween()   # petit rebond à l'atterrissage
	rebond.tween_property(_sprite, "position:y", -10.0, 0.07).set_ease(Tween.EASE_OUT)
	rebond.tween_property(_sprite, "position:y", -5.0, 0.07).set_ease(Tween.EASE_IN)
	z_index = 0
	collision_layer = 1
	collision_mask = 1
	_fuite = 0.0
	_direction = Vector2.ZERO
	_chrono = 1.0
	set_physics_process(true)


# Petit nuage de poussière à l'atterrissage.
func _poussiere() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = 7
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 26.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.85, 0.8, 0.65, 0.8)
	p.position = Vector2(0, -2)
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func cri_poule(poule: Animal) -> void:
	poule._crier()


# Change la zone où l'animal a le droit d'aller (ex. : la poule rentrée dans l'enclos y reste).
func limiter(zone: Rect2) -> void:
	_zone = zone


func _physics_process(delta: float) -> void:
	_chrono -= delta
	_fuite -= delta
	var joueur := _joueur()
	if _colere > 0.0:
		_attaquer(delta, joueur)
		return
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
		if _coups_poules >= COUPS_AVANT_COLERE and not is_in_group("poules_ferme"):
			_coups_poules = 0
			_declencher_colere()
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


# TOUTES les poules de CET écran s'énervent, et des renforts arrivent par les bords (comme les cocottes de Zelda).
# Chaque coup de bec fait perdre un cœur : à zéro, le héros s'évanouit et se réveille dans son lit (world.gd).
func _declencher_colere() -> void:
	Etat.annoncer("Oh non... les poules sont furieuses ! Fuis de l'écran !")
	for p in get_parent().get_children():
		if p is Animal and p.is_in_group("poules") and not p.is_in_group("poules_ferme"):
			p._se_facher()
	for i in 4:
		var renfort := Animal.new()
		var bord := Vector2(_zone.position.x if i % 2 == 0 else _zone.end.x, randf_range(_zone.position.y, _zone.end.y))
		renfort.position = bord
		get_parent().add_child(renfort)
		renfort.initialiser("res://Assets/Ninja_adventure/Actor/Animal/Chicken/SpriteSheetWhite.png", _vitesse, true, "poule", _zone)
		renfort._renfort = true
		renfort._se_facher()


func _se_facher() -> void:
	_colere = DUREE_COLERE
	_bec = 0.4
	_sprite.modulate = Color(1.0, 0.55, 0.5)
	_crier()


func _calmer() -> void:
	_colere = 0.0
	_sprite.modulate = Color.WHITE
	_sprite.rotation = 0.0
	_fuite = 0.0
	_chrono = 0.5
	if _renfort:
		queue_free()


# Colère : la poule fonce sur le joueur et le picore (1 cœur par coup de bec, avec un répit entre deux).
# Elle se calme au bout d'un moment ou quand le joueur quitte l'écran (jamais de poursuite à travers tout le village).
func _attaquer(delta: float, joueur: Node2D) -> void:
	_colere -= delta
	_bec -= delta
	if _colere <= 0.0 or joueur == null or not _zone.grow(24.0).has_point(get_parent().to_local(joueur.global_position)):
		_calmer()
		return
	_direction = (joueur.global_position - global_position).normalized()
	velocity = _direction * _vitesse * 3.4
	move_and_slide()
	if _bec <= 0.0 and joueur.global_position.distance_to(global_position) < 13.0:
		_bec = 0.9
		_crier()
		if joueur.has_method("blesser"):
			joueur.blesser(global_position, 1)
		var saut := create_tween()
		saut.tween_property(_sprite, "position:y", -11.0, 0.08)
		saut.tween_property(_sprite, "position:y", -5.0, 0.1)
	_animer(delta)
	_sprite.rotation = sin(Time.get_ticks_msec() / 40.0) * 0.12   # elle s'agite
