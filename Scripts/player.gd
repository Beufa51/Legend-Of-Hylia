extends CharacterBody2D
# Joueur : déplacement dans 4 directions + animations (marche / repos) + coup de lance (touche Espace ou J).
# Les animations sont construites ici à partir des planches du héros (Assets/Heros),
# donc rien à configurer à la main dans l'éditeur.

const VITESSE := 70.0  # pixels par seconde
const FACTEUR_COURSE := 1.7  # vitesse multipliée quand on court (touche Maj ou K)
const HEROS := "res://Assets/Heros/"   # planches du héros (voir Outils/preparer_heros.py)
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
var _recul := Vector2.ZERO  # poussée subie (coup de bec d'une poule...), s'éteint toute seule
var porte: Animal         # la poule qu'on porte (mini-jeu de la ferme), sinon null
var _temps_pousse := 0.0  # depuis combien de temps on pousse contre un bloc
# GLACE (voir room.gd, section Glace) : la salle où l'on est s'annonce dans `terrain` si elle a de la glace.
const VITESSE_GLISSADE := 130.0
const SON_GLISSADE := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Whoosh2.wav"
const SON_BUTEE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact.wav"
var terrain = null            # la salle (Room) glacée où se trouve le joueur, sinon null
var _glisse := false          # en train de glisser (on ne contrôle plus rien)
var _cible_glissade := Vector2.ZERO
var _case_avant := Vector2i(-99, -99)   # case des pieds à l'image précédente
var _attente_glace := 0.0     # petite pause entre deux glissades / poussées depuis la glace


func _ready() -> void:
	add_to_group("joueur")
	sprite.sprite_frames = _creer_animations()
	sprite.offset = Vector2(0, -5)   # cases de 32 px : on remonte l'image pour que les pieds soient sur la collision (en bas)
	sprite.play("repos_bas")
	_creer_lance()
	lumiere = Lumiere.creer(Color(0.85, 0.92, 1.0), 0.6, 0.7)
	lumiere.enabled = false
	add_child(lumiere)


func _physics_process(delta: float) -> void:
	if porte != null:
		if is_instance_valid(porte):
			porte.global_position = global_position + Vector2(0, -12)   # la poule est tenue au-dessus de la tête
		else:
			porte = null
	if attaque:
		_frapper_ce_quon_touche()
		return  # pas de déplacement pendant le coup
	if Input.is_action_just_pressed("attack"):
		var habitant := _habitant_proche()
		if habitant:
			habitant.parler(self)   # près d'un habitant, la touche d'action sert à PARLER
		elif porte != null:
			_lancer_poule()         # on porte une poule : la touche d'action la LANCE
		else:
			var poule := _poule_proche()
			if poule != null:
				porte = poule       # près d'une poule du mini-jeu : on la PREND
				poule.attraper()
			else:
				_attaquer()
		return
	# Vecteur d'entrée : (-1..1, -1..1) selon les touches pressées
	var entree := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _gerer_glace(entree, delta):
		return
	var court := Input.is_action_pressed("run")
	velocity = entree * VITESSE * (FACTEUR_COURSE if court else 1.0) * (0.85 if porte != null else 1.0) + _recul
	_recul = _recul.move_toward(Vector2.ZERO, 600.0 * delta)
	sprite.speed_scale = 1.6 if court else 1.0   # les jambes vont plus vite quand on court
	move_and_slide()
	_pousser_les_blocs(entree, delta)
	_mettre_a_jour_animation(entree)


# --- Glace -----------------------------------------------------------------------
# Renvoie vrai si la glace s'occupe du déplacement à cette image (glissade en cours, ou arrêté sur la glace).
func _gerer_glace(entree: Vector2, delta: float) -> bool:
	if _glisse:
		global_position = global_position.move_toward(_cible_glissade, VITESSE_GLISSADE * delta)
		if global_position.distance_to(_cible_glissade) < 0.5:
			global_position = _cible_glissade
			_glisse = false
			_attente_glace = 0.12
			if terrain != null and terrain.est_glace(terrain.case_des_pieds(global_position)):
				_jouer_son(SON_BUTEE, -14.0)   # on s'arrête contre un obstacle
		_case_avant = terrain.case_des_pieds(global_position) if terrain != null else _case_avant
		return true
	if terrain == null or not is_instance_valid(terrain):
		terrain = null
		return false
	_attente_glace = maxf(0.0, _attente_glace - delta)
	var c: Vector2i = terrain.case_des_pieds(global_position)
	var avant := _case_avant
	_case_avant = c
	if not terrain.est_glace(c):
		return false
	var d := _direction_entree(entree)
	if not terrain.est_glace(avant) and avant != c:
		# On vient de poser le pied sur la glace en marchant : on part en glissade dans le sens de la marche
		if d == Vector2i.ZERO:
			d = Vector2i(VECTEURS[direction])
		_partir(c, d)
		return true
	# Arrêté sur la glace : une direction = glisser (ou pousser le bloc qui est devant)
	velocity = Vector2.ZERO
	sprite.play("repos_" + direction)
	if d == Vector2i.ZERO or _attente_glace > 0.0:
		return true
	_tourner_vers(d)
	if terrain.pousser_bloc(c + d, d):
		_attente_glace = 0.4
		return true
	_partir(c, d)
	return true


# Glisse depuis la case de glace `c` dans la direction `d` (jusqu'où la salle le dit).
func _partir(c: Vector2i, d: Vector2i) -> void:
	_tourner_vers(d)
	var arrivee: Vector2i = terrain.destination_glissade(c, d)
	_cible_glissade = terrain.position_sur_case(arrivee)
	_glisse = true
	velocity = Vector2.ZERO
	sprite.play("repos_" + direction)
	if arrivee != c:
		_jouer_son(SON_GLISSADE, -12.0)


# Direction dominante des touches (une seule des 4 directions), ou ZERO.
func _direction_entree(entree: Vector2) -> Vector2i:
	if entree.length() < 0.3:
		return Vector2i.ZERO
	if absf(entree.x) > absf(entree.y):
		return Vector2i(signi(roundi(signf(entree.x))), 0)
	return Vector2i(0, signi(roundi(signf(entree.y))))


func _tourner_vers(d: Vector2i) -> void:
	for nom in VECTEURS:
		if Vector2i(VECTEURS[nom]) == d:
			direction = nom


# Arrête net une glissade (téléportation, retour au début de la salle...).
func arreter_glissade() -> void:
	_glisse = false
	_case_avant = Vector2i(-99, -99)


# Un habitant du village assez près pour lui parler ?
func _habitant_proche() -> Pnj:
	for n in get_tree().get_nodes_in_group("pnj"):
		if n.peut_parler(self):
			return n
	return null


# Une poule du mini-jeu de la ferme assez près pour la prendre ?
func _poule_proche() -> Animal:
	for p in get_tree().get_nodes_in_group("poules_ferme"):
		if not p.portee and p.collision_layer == 1 and p.global_position.distance_to(global_position) < 18.0 and not p.verrouillee:
			return p
	return null


# Lance la poule devant soi, le plus loin possible (44, 30 ou 14 px) sur une place libre : elle passe par-dessus les clôtures.
func _lancer_poule() -> void:
	var poule := porte
	porte = null
	if not is_instance_valid(poule):
		return
	var vecteur: Vector2 = VECTEURS[direction]
	var cible := global_position + vecteur * 14.0
	for d in [44.0, 30.0, 14.0]:
		var point: Vector2 = global_position + vecteur * d
		var requete := PhysicsPointQueryParameters2D.new()
		requete.position = point
		requete.collision_mask = 1
		requete.exclude = [get_rid()]
		if get_world_2d().direct_space_state.intersect_point(requete, 1).is_empty():
			cible = point
			break
	_jouer_son(SON_LANCE, -6.0)
	poule.lancer(global_position + Vector2(0, -12), cible)


# Pousse le joueur (sans le blesser) : utilisé par les poules en colère.
func repousser(force: Vector2) -> void:
	_recul = force


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


# Découpe les planches du héros (Assets/Heros/, faites par Outils/preparer_heros.py : cases de 32 px,
# une ligne par direction dans l'ordre bas, haut, gauche, droite) en animations.
# heros_marche.png : 9 images par direction (la 1re = debout) ; heros_coup.png : 8 images d'estoc.
func _creer_animations() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var marche: Texture2D = load(HEROS + "heros_marche.png")
	var coup: Texture2D = load(HEROS + "heros_coup.png")
	for ligne in DIRECTIONS.size():
		var d: String = DIRECTIONS[ligne]
		frames.add_animation("marche_" + d)
		frames.set_animation_speed("marche_" + d, 10.0)
		frames.set_animation_loop("marche_" + d, true)
		for col in range(1, 9):   # images 1 à 8 : le cycle de marche
			frames.add_frame("marche_" + d, _decoupe(marche, col, ligne))
		frames.add_animation("repos_" + d)
		frames.set_animation_loop("repos_" + d, true)
		frames.add_frame("repos_" + d, _decoupe(marche, 0, ligne))
		frames.add_animation("attaque_" + d)
		frames.set_animation_speed("attaque_" + d, 30.0)   # 8 images en ~0,26 s : la durée du coup de lance
		frames.set_animation_loop("attaque_" + d, false)
		for col in 8:
			frames.add_frame("attaque_" + d, _decoupe(coup, col, ligne))
	return frames


# Renvoie l'image (colonne, ligne) d'une planche de cases 32x32.
func _decoupe(texture: Texture2D, col: int, ligne: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * 32, ligne * 32, 32, 32)
	return atlas
