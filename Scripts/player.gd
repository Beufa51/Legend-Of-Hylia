extends CharacterBody2D
# Joueur : déplacement dans 4 directions + animations (marche / repos) + coup de lance (touche Espace ou J).
# Les animations sont construites ici à partir des planches du héros (Assets/Heros),
# donc rien à configurer à la main dans l'éditeur.

const VITESSE := 70.0  # pixels par seconde
const FACTEUR_COURSE := 1.7  # vitesse multipliée quand on court (touche Maj ou K)
const HEROS := "res://Assets/Heros/"   # planches du héros (voir Outils/preparer_heros.py)
# Héros Gemini (Outils/traiter_heros_gemini.py) : cases de 48x32 ; s'il est présent, il remplace l'ancien héros LPC
const HEROS_G := "res://Assets/Heros/heros_g.png"
const CASE_G := Vector2i(48, 32)
# Héros PIXEL CRAWLER habillé (Outils/habiller_heros.py) : cases 62x53, 16 lignes (marche / repos / estoc / touché x bas, haut, DROITE, GAUCHE... voir LIGNES_PC)
# Prioritaire sur le héros Gemini s'il existe ; supprimer ou renommer heros_pc.png pour revenir au héros Gemini.
const HEROS_PC := "res://Assets/Heros/heros_pc.png"
# HÉROS ACTUEL (2026-11-25) : le garde au casque à cimier rouge, fait par l'utilisateur avec un générateur LPC (Assets/Heros/garde_lpc.png,
# découpé par Outils/preparer_garde_lpc.py). PRIORITAIRE sur tous les autres héros, de toute la partie. Cases de 32 px,
# lignes : marche (0-3), repos (4-7), estoc (8-11), course (12-15), touché (16) ; directions bas, haut, gauche, droite.
const HEROS_LPC := "res://Assets/Heros/heros_lpc.png"
const CASE_LPC := Vector2i(32, 32)
const LIGNE_LPC := {"bas": 0, "haut": 1, "gauche": 2, "droite": 3}
var _lpc := false
const ECHELLE_PC := 0.8   # taille du héros Pixel Crawler (1.0 = taille d'origine, 31 px)
# Recrue à l'épée (pack Fantasy Tileset) : héros de toute l'épreuve ; la lance ne lui est remise qu'à l'adoubement (drapeau "lance_recue").
const RECRUE_REPOS := "res://Assets/Heros/recrue_Idle_p.png"
const RECRUE_MARCHE := "res://Assets/Heros/recrue_Walk_p.png"
const RECRUE_COUP := "res://Assets/Heros/recrue_Slash_p.png"
const CASE_RECRUE := Vector2i(30, 36)   # planches réduites à 75 % par Outils/reduire_recrue.py (pas de mise à l'échelle dans Godot : elle faisait perdre des pixels)
const ECHELLE_RECRUE := 1.0
const LIGNE_RECRUE := {"gauche": 0, "droite": 1, "haut": 2, "bas": 3}   # ordre des rangées dans les planches
var _recrue := false   # vrai = on joue la recrue à l'épée
const CASE_PC := Vector2i(62, 53)
const LIGNE_PC := {"bas": 0, "haut": 1, "droite": 2, "gauche": 3}   # ordre des directions dans chaque bloc de 4 lignes
# Le héros Gemini n'a pas de pose d'estoc de face / de dos (la planche ne dessine la lance que de profil) :
# vers le bas et le haut il lâche sa lance (images sans lance) et on dessine la lance ici (Outils/traiter_heros_gemini.py -> lance_g.png, pointe vers le BAS)
const LANCE_G := "res://Assets/Heros/lance_g.png"
const MAIN_G := {"bas": Vector2(-8, -6), "haut": Vector2(6, -6)}   # où la main tient la lance, par rapport aux pieds du héros
const AVANCE_G := 7.0   # de combien la lance avance pendant l'estoc
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
var _lance_g: Sprite2D  # lance dessinée de face / de dos pour le héros Gemini
var zone: Area2D        # zone de touche de la lance
var lumiere: PointLight2D  # petite lumière autour du joueur (allumée seulement dans les salles sombres)
var _recul := Vector2.ZERO  # poussée subie (coup de bec d'une poule...), s'éteint toute seule
# --- Feu (salle « lance enflammée », Plume 2a) : toucher un brasero allumé enflamme la lance quelques secondes ; l'eau l'éteint ---
const FEU_DUREE := 2.5
const SON_FEU := "res://Assets/Ninja_adventure/Audio/Sounds/Elemental/Fire.wav"
const SON_ETEINT := "res://Assets/Ninja_adventure/Audio/Sounds/Elemental/Bubble.wav"
var feu := 0.0                # secondes de feu restantes (0 = lance normale)
var _flamme: Node2D           # la flamme au-dessus de la tête
var _lumiere_feu: PointLight2D
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

# --- Cœurs (seulement utiles contre le Gardien du corps du coq : le reste du jeu ne blesse jamais) ---
signal coeurs_change(coeurs: int, maxi: int)
const COEURS_MAX := 5
const SON_BLESSE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Hit2.wav"
var coeurs := COEURS_MAX
var _invulnerable := 0.0      # temps restant pendant lequel on ne peut plus être touché (le héros clignote)


func _ready() -> void:
	add_to_group("joueur")
	_lpc = ResourceLoader.exists(HEROS_LPC)
	_recrue = not _lpc and ResourceLoader.exists(RECRUE_MARCHE) and ResourceLoader.exists(RECRUE_COUP) and ResourceLoader.exists(RECRUE_REPOS) and not Etat.est("lance_recue")
	if _lpc:
		sprite.sprite_frames = _creer_animations_lpc()
		sprite.scale = Vector2.ONE
		sprite.offset = Vector2(0, -10)   # pieds à la ligne 31 d'une case de 32 : on les pose sur la collision (sous le joueur)
	elif _recrue:
		sprite.sprite_frames = _creer_animations_recrue()
		sprite.scale = Vector2.ONE * ECHELLE_RECRUE
		sprite.offset = Vector2(0, -9)   # pieds à la ligne 30 d'une case de 36 : on les pose sur la collision
	elif ResourceLoader.exists(HEROS_PC):
		sprite.sprite_frames = _creer_animations_pc()
		sprite.scale = Vector2.ONE * ECHELLE_PC   # le héros du pack faisait 31 px de haut : on le réduit (~25 px)
		sprite.offset = Vector2(0, -7)   # les pieds du héros sont à la ligne 39 d'une case de 53 : on les pose sur la collision
	elif ResourceLoader.exists(HEROS_G):
		sprite.sprite_frames = _creer_animations_g()
		sprite.offset = Vector2(0, -9)   # les pieds du héros Gemini sont à la ligne 29 d'une case de 32 : on les pose sur la collision
	else:
		sprite.sprite_frames = _creer_animations()
		sprite.offset = Vector2(0, -5)   # cases de 32 px : on remonte l'image pour que les pieds soient sur la collision (en bas)
	sprite.play("repos_bas")
	_creer_lance()
	lumiere = Lumiere.creer(Color(0.85, 0.92, 1.0), 0.6, 0.7)
	lumiere.enabled = false
	add_child(lumiere)


func _physics_process(delta: float) -> void:
	if feu > 0.0:
		feu -= delta
		if feu <= 0.0:
			eteindre_feu()
		elif _flamme != null:
			_flamme.queue_redraw()
			_lumiere_feu.energy = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.02)
	if _invulnerable > 0.0:
		_invulnerable -= delta
		sprite.visible = _invulnerable <= 0.0 or int(_invulnerable * 12.0) % 2 == 0   # clignote
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
	_bruit_de_pas(delta, court)
	_mettre_a_jour_animation(entree)


# --- Bruit des pas : un pas tous les ~20 px parcourus (26 en courant), selon le sol (voir Ecran.surface_pas) ---
var _distance_pas := 0.0


func _bruit_de_pas(delta: float, court: bool) -> void:
	var v := get_real_velocity().length()
	if v < 8.0:
		_distance_pas = 0.0
		return
	_distance_pas += v * delta
	if _distance_pas < (26.0 if court else 20.0):
		return
	_distance_pas = 0.0
	var sol := "dalle"
	var monde := get_parent()
	if monde != null and monde.has_method("surface_pas"):
		sol = monde.surface_pas(global_position)
	var flux = load("res://Assets/Sons/pas_%s.wav" % sol)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -21.0 + randf_range(-2.0, 1.0)
	lecteur.pitch_scale = randf_range(0.9, 1.12)   # jamais deux pas identiques
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)


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


# Touché (par le Gardien) : perd `degats` cœurs, est repoussé loin de `source`, clignote un instant.
func blesser(source: Vector2, degats := 1) -> void:
	if _invulnerable > 0.0 or coeurs <= 0:
		return
	coeurs = maxi(coeurs - degats, 0)
	_invulnerable = 1.2
	_recul = (global_position - source).normalized() * 240.0
	_jouer_son(SON_BLESSE, -2.0)
	coeurs_change.emit(coeurs, COEURS_MAX)


# Tous les cœurs reviennent.
func soigner() -> void:
	coeurs = COEURS_MAX
	_invulnerable = 0.0
	sprite.visible = true
	coeurs_change.emit(coeurs, COEURS_MAX)


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
		var anim := "marche_" + direction
		if Input.is_action_pressed("run") and sprite.sprite_frames.has_animation("course_" + direction):
			anim = "course_" + direction   # héros LPC : une vraie animation de course
		sprite.play(anim)
	else:
		sprite.play("repos_" + direction)


func a_feu() -> bool:
	return feu > 0.0


# La lance prend feu (ou le feu est ravivé) : flamme au-dessus de la tête, lueur orange, pointe de la lance rougeoyante.
func prendre_feu() -> void:
	if feu <= 0.0:
		_jouer_son(SON_FEU, -6.0)
	feu = FEU_DUREE
	if _flamme == null:
		_flamme = Node2D.new()
		_flamme.position = Vector2(0, -26)
		_flamme.z_index = 5
		_flamme.draw.connect(_dessiner_flamme)
		add_child(_flamme)
		_lumiere_feu = Lumiere.creer(Color(1.0, 0.62, 0.25), 1.1, 0.9)
		add_child(_lumiere_feu)
	_flamme.visible = true
	_lumiere_feu.enabled = true
	lance.modulate = Color(1.7, 1.0, 0.6)


# L'eau (ou la fin du temps) éteint la lance.
func eteindre_feu(avec_bruit := false) -> void:
	if feu <= 0.0 and _flamme == null:
		return
	var avait := feu > 0.0
	feu = 0.0
	if _flamme != null:
		_flamme.visible = false
		_lumiere_feu.enabled = false
	lance.modulate = Color.WHITE
	if avec_bruit and avait:
		_jouer_son(SON_ETEINT, -2.0)


# Dessine la flamme : elle rétrécit avec le temps et vacille dans la dernière seconde.
func _dessiner_flamme() -> void:
	var reste := clampf(feu / FEU_DUREE, 0.0, 1.0)
	var t := Time.get_ticks_msec() * 0.012
	if feu < 1.0 and int(t * 1.5) % 2 == 0:
		return   # clignote : le feu va s'éteindre
	var h := 7.0 + 7.0 * reste + sin(t) * 1.2
	var l := 3.0 + 3.0 * reste
	_flamme.draw_colored_polygon(PackedVector2Array([Vector2(0, 5), Vector2(-l, 1), Vector2(-l * 0.6, -h * 0.5), Vector2(sin(t * 1.3) * 1.5, -h), Vector2(l * 0.6, -h * 0.5), Vector2(l, 1)]), Color(1.0, 0.35, 0.1, 0.95))
	_flamme.draw_colored_polygon(PackedVector2Array([Vector2(0, 4), Vector2(-l * 0.6, 1), Vector2(0, -h * 0.65), Vector2(l * 0.6, 1)]), Color(1.0, 0.7, 0.2, 1.0))
	_flamme.draw_colored_polygon(PackedVector2Array([Vector2(0, 4), Vector2(-l * 0.3, 2), Vector2(0, -h * 0.3), Vector2(l * 0.3, 2)]), Color(1.0, 0.95, 0.6, 1.0))


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
	image.visible = not (_lpc or _recrue or ResourceLoader.exists(HEROS_G) or ResourceLoader.exists(HEROS_PC))   # les héros Gemini / Pixel Crawler tiennent leur lance dans leurs images : on ne dessine pas la lance du pack en plus
	lance.add_child(image)
	if not _lpc and ResourceLoader.exists(HEROS_G) and ResourceLoader.exists(LANCE_G) and not ResourceLoader.exists(HEROS_PC):
		_lance_g = Sprite2D.new()
		_lance_g.texture = load(LANCE_G)
		_lance_g.centered = false
		_lance_g.offset = Vector2(-2.5, -10.0)   # la main tient la lance à 10 px de son extrémité haute (pointe en bas)
		_lance_g.z_index = 1
		_lance_g.visible = false
		add_child(_lance_g)
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
	if _lance_g != null and MAIN_G.has(direction):   # héros Gemini de face / de dos : la lance dessinée avance depuis la main
		var main: Vector2 = MAIN_G[direction]
		_lance_g.rotation = 0.0 if direction == "bas" else PI
		_lance_g.position = main
		_lance_g.modulate = lance.modulate
		_lance_g.visible = true
		var avance := create_tween()
		avance.tween_property(_lance_g, "position", main + vecteur * AVANCE_G, 0.09)
		avance.tween_interval(0.08)
		avance.tween_property(_lance_g, "position", main, 0.09)
	await tween.finished
	zone.monitoring = false
	lance.visible = false
	if _lance_g != null:
		_lance_g.visible = false
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


# Animations de la recrue à l'épée : marche 4 images, repos 4, coup d'épée 6 (l'arc de l'épée est dans les images).
func _creer_animations_recrue() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var marche: Texture2D = load(RECRUE_MARCHE)
	var repos: Texture2D = load(RECRUE_REPOS)
	var coup: Texture2D = load(RECRUE_COUP)
	for d in DIRECTIONS:
		var k: int = LIGNE_RECRUE[d]
		frames.add_animation("marche_" + d)
		frames.set_animation_speed("marche_" + d, 8.0)
		frames.set_animation_loop("marche_" + d, true)
		for col in 4:
			frames.add_frame("marche_" + d, _decoupe_recrue(marche, col, k))
		frames.add_animation("repos_" + d)
		frames.set_animation_speed("repos_" + d, 4.0)
		frames.set_animation_loop("repos_" + d, true)
		for col in 4:
			frames.add_frame("repos_" + d, _decoupe_recrue(repos, col, k))
		frames.add_animation("attaque_" + d)
		frames.set_animation_speed("attaque_" + d, 22.0)   # 6 images en ~0,27 s : la durée du coup
		frames.set_animation_loop("attaque_" + d, false)
		for col in 6:
			frames.add_frame("attaque_" + d, _decoupe_recrue(coup, col, k))
	return frames


func _decoupe_recrue(texture: Texture2D, col: int, ligne: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * CASE_RECRUE.x, ligne * CASE_RECRUE.y, CASE_RECRUE.x, CASE_RECRUE.y)
	return atlas


# Animations du héros Pixel Crawler : marche 6 images, repos 4, estoc 8 (la lance est dans les images), touché 4.
func _creer_animations_lpc() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var planche: Texture2D = load(HEROS_LPC)
	# (nom, 1re ligne, nombre d'images, images/s, en boucle)
	for a in [["marche", 0, 8, 12.0, true], ["repos", 4, 2, 2.0, true], ["attaque", 8, 8, 30.0, false], ["course", 12, 8, 14.0, true]]:
		for d in DIRECTIONS:
			var nom: String = a[0] + "_" + d
			frames.add_animation(nom)
			frames.set_animation_speed(nom, a[3])
			frames.set_animation_loop(nom, a[4])
			for col in a[2]:
				var atlas := AtlasTexture.new()
				atlas.atlas = planche
				atlas.region = Rect2(col * CASE_LPC.x, (a[1] + LIGNE_LPC[d]) * CASE_LPC.y, CASE_LPC.x, CASE_LPC.y)
				frames.add_frame(nom, atlas)
	return frames


func _creer_animations_pc() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var planche: Texture2D = load(HEROS_PC)
	for d in DIRECTIONS:
		var k: int = LIGNE_PC[d]
		frames.add_animation("marche_" + d)
		frames.set_animation_speed("marche_" + d, 10.0)
		frames.set_animation_loop("marche_" + d, true)
		for col in 6:
			frames.add_frame("marche_" + d, _decoupe_pc(planche, col, k))
		frames.add_animation("repos_" + d)
		frames.set_animation_speed("repos_" + d, 4.0)
		frames.set_animation_loop("repos_" + d, true)
		for col in 4:
			frames.add_frame("repos_" + d, _decoupe_pc(planche, col, 4 + k))
		frames.add_animation("attaque_" + d)
		frames.set_animation_speed("attaque_" + d, 30.0)   # 8 images en ~0,27 s : la durée du coup de lance
		frames.set_animation_loop("attaque_" + d, false)
		for col in 8:
			frames.add_frame("attaque_" + d, _decoupe_pc(planche, col, 8 + k))
	return frames


func _decoupe_pc(texture: Texture2D, col: int, ligne: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * CASE_PC.x, ligne * CASE_PC.y, CASE_PC.x, CASE_PC.y)
	return atlas


# Animations du héros Gemini : planche de cases 48x32 (lignes : marche bas/haut/gauche/droite, repos, estoc bas/haut/gauche/droite, dégâts).
func _creer_animations_g() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var planche: Texture2D = load(HEROS_G)
	for k in DIRECTIONS.size():
		var d: String = DIRECTIONS[k]
		frames.add_animation("marche_" + d)
		frames.set_animation_speed("marche_" + d, 12.0)   # cycle de 8 images : un pied se lève, puis l'autre (Outils/traiter_heros_gemini.py)
		frames.set_animation_loop("marche_" + d, true)
		for col in (6 if d == "gauche" or d == "droite" else 8):   # de profil : cycle de 6 images (pieds toujours au sol), de face / de dos : 8
			frames.add_frame("marche_" + d, _decoupe_g(planche, col, k))
		frames.add_animation("repos_" + d)
		frames.set_animation_loop("repos_" + d, true)
		frames.add_frame("repos_" + d, _decoupe_g(planche, k, 4))
		frames.add_animation("attaque_" + d)
		frames.set_animation_speed("attaque_" + d, 12.0)   # 3 images en ~0,25 s : la durée du coup de lance
		frames.set_animation_loop("attaque_" + d, false)
		for col in 3:
			frames.add_frame("attaque_" + d, _decoupe_g(planche, col, 5 + k))
	return frames


func _decoupe_g(texture: Texture2D, col: int, ligne: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * CASE_G.x, ligne * CASE_G.y, CASE_G.x, CASE_G.y)
	return atlas


# Renvoie l'image (colonne, ligne) d'une planche de cases 32x32.
func _decoupe(texture: Texture2D, col: int, ligne: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * 32, ligne * 32, 32, 32)
	return atlas
