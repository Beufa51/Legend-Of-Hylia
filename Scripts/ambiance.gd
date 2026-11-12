extends Node2D
class_name Ambiance
# L'AMBIANCE DE L'EXTÉRIEUR : ce qui rend le village vivant, sans rien changer aux écrans.
#   - le vent souffle par rafales (force_vent, lue par exterieur.gd pour balancer les plantes) ;
#   - des feuilles et des pétales traversent l'écran, emportés par le vent ;
#   - l'ombre de gros nuages glisse lentement sur le sol ;
#   - deux papillons volettent ;
#   - bruit du vent et chants d'oiseaux de temps en temps.
# Créée par world.gd seulement à l'extérieur (pas dans le donjon). Elle suit la caméra.

static var force_vent := 1.0   # 1 = vent normal ; monte pendant les rafales

const FEUILLE := "res://Assets/Ninja_adventure/FX/Particle/Leaf.png"        # 6 images de 12x7
const PETALE := "res://Assets/Ninja_adventure/FX/Particle/LeafPink.png"
const NUAGE := "res://Assets/Ninja_adventure/FX/Particle/Clouds.png"
const SON_VENT := "res://Assets/Ninja_adventure/Audio/Sounds/Ambient/Wind.wav"
const SON_OISEAU := "res://Assets/Ninja_adventure/Audio/Sounds/Creature/Bird.wav"
const MAX_FEUILLES := 4
const COULEURS_PAPILLONS := [Color(1.0, 0.95, 0.5), Color(1.0, 0.6, 0.8)]

var camera: Camera2D
var _temps := 0.0
var _rafale := 0.0          # 0 = calme, 1 = rafale
var _prochaine_rafale := 4.0
var _prochaine_feuille := 0.0
var _prochain_oiseau := 3.0
var _feuilles: Array = []   # [sprite, vitesse, phase]
var _nuages: Array[Sprite2D] = []
var _papillons: Array = []  # [centre relatif à la caméra, phase, couleur]


func _ready() -> void:
	z_index = 5   # au-dessus du décor et du joueur (les ombres de nuages passent sur tout)
	for i in 0:   # ombres de nuages désactivées (effet de flou)
		var nuage := Sprite2D.new()
		nuage.texture = load(NUAGE)
		nuage.scale = Vector2(4, 3)
		nuage.modulate = Color(0, 0, 0, 0.12)
		nuage.position = Vector2(-120 + i * 300, -40 + i * 110)   # relatif au centre de la caméra
		add_child(nuage)
		_nuages.append(nuage)
	for i in 2:
		_papillons.append([Vector2(randf_range(-150, 150), randf_range(-70, 60)), randf() * TAU, COULEURS_PAPILLONS[i]])
	_bruit_du_vent()


func _process(delta: float) -> void:
	if camera == null:
		return
	position = camera.position   # tout est placé autour du centre de l'écran
	_temps += delta
	# Rafales : de temps en temps le vent forcit pendant 2-3 s
	_prochaine_rafale -= delta
	if _prochaine_rafale <= 0.0:
		_prochaine_rafale = randf_range(16.0, 28.0)
		var t := create_tween()
		t.tween_property(self, "_rafale", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
		t.tween_interval(randf_range(1.0, 2.0))
		t.tween_property(self, "_rafale", 0.0, 1.8).set_trans(Tween.TRANS_SINE)
	force_vent = 0.3 + 0.08 * sin(_temps * 0.7) + 0.5 * _rafale   # vent discret
	_bouger_feuilles(delta)
	# Ombres des nuages : elles dérivent, et reviennent par la gauche
	for nuage in _nuages:
		nuage.position.x += (6.0 + 6.0 * force_vent) * delta
		if nuage.position.x > 380:
			nuage.position.x = -380
			nuage.position.y = randf_range(-90, 90)
	# Oiseaux qui chantent au loin
	_prochain_oiseau -= delta
	if _prochain_oiseau <= 0.0:
		_prochain_oiseau = randf_range(5.0, 11.0)
		_jouer(SON_OISEAU, -17.0, randf_range(0.9, 1.3))
	queue_redraw()   # papillons


func _bouger_feuilles(delta: float) -> void:
	_prochaine_feuille -= delta * force_vent
	if _prochaine_feuille <= 0.0 and _feuilles.size() < MAX_FEUILLES:
		_prochaine_feuille = randf_range(1.5, 3.5)
		var feuille := Sprite2D.new()
		feuille.texture = load(PETALE if randf() < 0.3 else FEUILLE)
		feuille.hframes = 6
		feuille.position = Vector2(-210, randf_range(-110, 100))   # entre par la gauche de l'écran
		add_child(feuille)
		_feuilles.append([feuille, randf_range(35.0, 60.0), randf() * TAU])
	for f in _feuilles.duplicate():
		var sprite: Sprite2D = f[0]
		sprite.position.x += f[1] * (0.5 + force_vent) * delta
		sprite.position.y += sin(_temps * 2.5 + f[2]) * 18.0 * delta + 6.0 * delta   # elle ondule en tombant doucement
		sprite.frame = int(_temps * 8.0 + f[2] * 3.0) % 6
		if sprite.position.x > 215 or sprite.position.y > 120:
			_feuilles.erase(f)
			sprite.queue_free()


# Les papillons : deux petites ailes qui battent, sur une trajectoire en boucle.
func _draw() -> void:
	for p in _papillons:
		var phase: float = p[1]
		var centre: Vector2 = p[0] + Vector2(sin(_temps * 0.6 + phase) * 40.0, sin(_temps * 1.1 + phase * 2.0) * 18.0)
		var ouvert := sin(_temps * 18.0 + phase) > 0.0
		var couleur: Color = p[2]
		if ouvert:
			draw_rect(Rect2(centre + Vector2(-2, -1), Vector2(2, 2)), couleur)
			draw_rect(Rect2(centre + Vector2(1, -1), Vector2(2, 2)), couleur)
		else:
			draw_rect(Rect2(centre + Vector2(-1, -2), Vector2(1, 2)), couleur)
			draw_rect(Rect2(centre + Vector2(1, -2), Vector2(1, 2)), couleur)
		draw_rect(Rect2(centre + Vector2(0, -1), Vector2(1, 2)), Color(0.2, 0.15, 0.1))


# Le vent souffle en continu, tout doucement (le son est rejoué quand il se termine).
func _bruit_du_vent() -> void:
	var flux = load(SON_VENT)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -32.0
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.play)


func _jouer(chemin: String, volume_db: float, hauteur: float) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = volume_db
	lecteur.pitch_scale = hauteur
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
