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
	_sprite.modulate = Color(0.55, 0.85, 1.25, 0.6)
	add_child(_sprite)
	_sprite.play("repos_bas")
	if sombre:   # dans le noir, le reflet luit
		_lumiere = Lumiere.creer(Color(0.5, 0.8, 1.0), 0.55, 0.7)
		add_child(_lumiere)
	_pulse = create_tween().set_loops()
	_pulse.tween_property(_sprite, "modulate:a", 0.45, 0.8)
	_pulse.tween_property(_sprite, "modulate:a", 0.7, 0.8)
	reinitialiser()


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
	# Animation : la même que le joueur, tournée dans l'autre sens à gauche/droite
	var sens: String = _joueur.direction
	if sens == "gauche":
		sens = "droite"
	elif sens == "droite":
		sens = "gauche"
	_sprite.play(("marche_" if deplacement.length() > 0.05 else "repos_") + sens)


# L'énigme est résolue : le reflet s'efface.
func disparaitre() -> void:
	set_physics_process(false)
	_pulse.kill()
	var t := create_tween()
	t.tween_property(_sprite, "modulate:a", 0.0, 0.8)
	t.tween_callback(queue_free)
