extends CharacterBody2D
class_name Reflet
# Le REFLET (aile droite, plume D4) : un double fantôme du joueur, qui part de la case `r` de la salle.
# Il fait les MÊMES mouvements que le joueur, mais avec la gauche et la droite INVERSÉES (haut et bas identiques).
# Il se cogne aux murs et aux objets comme le joueur ; quand il est bloqué alors que le joueur avance,
# les deux se « décalent » : c'est tout le principe des énigmes. Il ne gêne pas le joueur (ils se traversent).
# Il appuie sur les boutons `P` et se tient sur les dalles du reflet `a` (voir room.gd, section Reflet).

const SAUT_MAXI := 12.0   # au-delà, le joueur a été téléporté : le reflet ne suit pas ce « saut »

var salle: Room
var depart := Vector2.ZERO          # position de départ (dans la salle)
var _joueur: Node2D
var _avant := Vector2.ZERO          # position du joueur à l'image précédente
var _sprite: AnimatedSprite2D
var _lumiere: PointLight2D
var _pulse: Tween


func initialiser(une_salle: Room, case_depart: Vector2i, joueur: Node2D, sombre: bool) -> void:
	salle = une_salle
	_joueur = joueur
	depart = Vector2(case_depart * 16) + Vector2(8, 3)   # les pieds au centre de la case (comme le joueur)
	position = depart
	collision_layer = 0          # personne ne se cogne au reflet...
	collision_mask = 1           # ... mais lui se cogne aux murs, blocs, statues, plots
	add_collision_exception_with(joueur)   # et il traverse le joueur
	var forme := RectangleShape2D.new()
	forme.size = Vector2(8, 6)   # même boîte que le joueur (sous ses pieds)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(0, 5)
	add_child(collision)
	# Même apparence que le joueur, en fantôme bleuté
	var modele: AnimatedSprite2D = joueur.sprite
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = modele.sprite_frames
	_sprite.offset = modele.offset
	# Silhouette de VERRE : le héros passé en bleu glacé translucide (le dessin se devine en clair/sombre)
	# avec un CONTOUR lumineux blanc-bleu et un léger scintillement qui monte. Mêmes poses que le héros.
	var mat := ShaderMaterial.new()
	mat.shader = _shader_verre()
	_sprite.material = mat
	add_child(_sprite)
	_sprite.play("repos_bas")
	if sombre:   # dans le noir, le reflet luit
		_lumiere = Lumiere.creer(Color(0.5, 0.8, 1.0), 0.55, 0.7)
		add_child(_lumiere)
	_pulse = create_tween().set_loops()
	_pulse.tween_method(_regler_intensite, 0.75, 1.0, 0.8)
	_pulse.tween_method(_regler_intensite, 1.0, 0.75, 0.8)
	reinitialiser()


func _regler_intensite(v: float) -> void:
	if _sprite != null and _sprite.material is ShaderMaterial:
		(_sprite.material as ShaderMaterial).set_shader_parameter("intensite", v)


static var _shader_cache: Shader

func _shader_verre() -> Shader:
	if _shader_cache == null:
		_shader_cache = Shader.new()
		_shader_cache.code = """
shader_type canvas_item;
uniform float intensite = 1.0;
uniform vec3 couleur_sombre = vec3(0.16, 0.34, 0.62);
uniform vec3 couleur_claire = vec3(0.62, 0.9, 1.0);
uniform vec3 couleur_contour = vec3(0.78, 0.96, 1.0);
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec2 p = TEXTURE_PIXEL_SIZE;
	float voisin = max(max(texture(TEXTURE, UV + vec2(p.x, 0.0)).a, texture(TEXTURE, UV - vec2(p.x, 0.0)).a),
		max(texture(TEXTURE, UV + vec2(0.0, p.y)).a, texture(TEXTURE, UV - vec2(0.0, p.y)).a));
	float bord = clamp(voisin - t.a, 0.0, 1.0);
	float lum = dot(t.rgb, vec3(0.3, 0.59, 0.11));
	vec3 verre = mix(couleur_sombre, couleur_claire, lum);
	float scint = 0.5 + 0.5 * sin(UV.y / max(p.y, 0.0001) * 0.55 - TIME * 4.0);
	verre += vec3(0.10, 0.14, 0.18) * scint;
	vec3 contour = couleur_contour;
	float a_corps = t.a * 0.58 * intensite;
	float a_bord = bord * 0.95 * intensite;
	float a = max(a_corps, a_bord);
	vec3 c = (verre * a_corps + contour * a_bord) / max(a_corps + a_bord, 0.001);
	COLOR = vec4(c, a);
}
"""
	return _shader_cache


# Retour à la case de départ (entrée dans la salle, touche R, retour au début).
func reinitialiser() -> void:
	position = depart
	velocity = Vector2.ZERO
	if _joueur != null:
		_avant = _joueur.global_position


func _physics_process(delta: float) -> void:
	if salle == null or salle.grille != Etat.salle_courante or delta <= 0.0:
		if _joueur != null:
			_avant = _joueur.global_position
		return
	var deplacement: Vector2 = _joueur.global_position - _avant
	_avant = _joueur.global_position
	if deplacement.length() > SAUT_MAXI:
		deplacement = Vector2.ZERO
	# Miroir : la gauche devient la droite, le haut reste le haut
	velocity = Vector2(-deplacement.x, deplacement.y) / delta
	move_and_slide()
	_recaler_contre_obstacle()
	# Animation : la même que le joueur, tournée dans l'autre sens à gauche/droite
	var sens: String = _joueur.direction
	if sens == "gauche":
		sens = "droite"
	elif sens == "droite":
		sens = "gauche"
	_sprite.play(("marche_" if deplacement.length() > 0.05 else "repos_") + sens)


# Quand le reflet est bloqué par un mur, il s'arrête collé au mur, donc décalé de ~5 px par rapport au centre de sa case :
# il ne passerait plus dans une niche d'une case. On le recentre dans sa case (sur l'axe du blocage) : il reste « sur la grille ».
func _recaler_contre_obstacle() -> void:
	if get_slide_collision_count() == 0 or salle == null:
		return
	var origine: Vector2 = salle.global_position
	var rel: Vector2 = global_position - origine
	var cible := rel
	for i in get_slide_collision_count():
		var n: Vector2 = get_slide_collision(i).get_normal()
		if absf(n.y) > 0.5:
			cible.y = roundf((rel.y - 3.0) / 16.0) * 16.0 + 3.0
		if absf(n.x) > 0.5:
			cible.x = roundf((rel.x - 8.0) / 16.0) * 16.0 + 8.0
	if cible != rel and not test_move(Transform2D(0.0, origine + cible), Vector2.ZERO):
		global_position = origine + cible


# L'énigme est résolue : le reflet s'efface.
func disparaitre() -> void:
	set_physics_process(false)
	_pulse.kill()
	var t := create_tween()
	t.tween_method(_regler_intensite, 1.0, 0.0, 0.8)
	t.tween_callback(queue_free)
