extends CharacterBody2D
class_name Gardien
# Le GARDIEN du corps du coq (fin du jeu, scène corps.tscn, salle « Arene »).
# Quand le héros s'approche, il lui propose un CHOIX :
#   - « Combattre » : combat de boss. Sa garde est parfaite : un coup de lance de face ne lui fait rien.
#     Il marche vers le héros, se prépare (il brille), puis FONCE en ligne droite. S'il percute un mur ou une statue,
#     il reste ÉTOURDI quelques secondes : c'est le moment de le frapper. 6 coups. À mi-vie (phase 2) il va plus vite
#     et chaque choc contre un mur fait tomber des pierres du plafond (une ombre au sol prévient).
#     Le héros a 5 cœurs (player.gd) ; à 0, le Gardien l'aide à se relever et propose à nouveau le choix.
#   - « Baisser ma lance » : un garde ne choisit pas toujours la violence. Le Gardien est touché par ce choix.
# Les DEUX issues réussissent l'épreuve (drapeau `epreuve_reussie`, + `fin_combat` ou `fin_paix`), puis la fin du jeu.
# Images : pack Ninja Adventure, Actor/Boss/GiantBlueSamurai (cases 96x48 et 96x96).

const DOSSIER := "res://Assets/Ninja_adventure/Actor/Boss/GiantBlueSamurai/"
const SONS := "res://Assets/Ninja_adventure/Audio/Sounds/"
const MUSIQUE_COMBAT := "res://Assets/Musique/24_battle_theme_iv.ogg"
const MUSIQUE_FIN := "res://Assets/Musique/28_holy_sanctuary.ogg"
const PV_MAX := 6
const PV_PHASE2 := 3           # à partir de là : phase 2 (plus rapide, pierres qui tombent)
const DISTANCE_CHOIX := 80.0      # le Gardien parle quand le héros s'approche à cette distance
const CASE_DEPART_HEROS := Vector2i(12, 11)
const COEURS_HEROS := 5          # = COEURS_MAX de player.gd

enum { ATTENTE, PARLE, MARCHE, PREPARE, CHARGE, ETOURDI, KO, FINI }
var etat := ATTENTE
var pv := PV_MAX
var _temps := 0.0              # temps passé dans l'état actuel
var _dir_charge := Vector2.ZERO
var _invulnerable := 0.0       # après un coup reçu
var _dernier_clang := 0.0      # anti-répétition du bruit « garde parfaite »
var _deja_parle := false       # le grand discours n'est fait qu'une fois
var _conseil_donne := false
var _depart := Vector2.ZERO
var _joueur: CharacterBody2D
var _sprite: AnimatedSprite2D
var _hud: CanvasLayer
var _coeurs: Array[TextureRect] = []
var _barre: ColorRect
var _cadre_barre: ColorRect


func _ready() -> void:
	add_to_group("gardien")
	_depart = position
	collision_layer = 1
	collision_mask = 1
	var forme := RectangleShape2D.new()
	forme.size = Vector2(30, 14)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(0, -3)
	add_child(collision)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _animations()
	_sprite.offset = Vector2(0, -24)   # les pieds du samouraï sur la boîte de collision
	add_child(_sprite)
	_sprite.play("repos")
	_creer_hud()
	await get_tree().process_frame
	_joueur = get_tree().get_first_node_in_group("joueur")
	add_collision_exception_with(_joueur)   # il fonce à travers le héros (et le blesse au passage)
	_joueur.coeurs_change.connect(_sur_coeurs)
	if Etat.est("epreuve_reussie"):   # partie reprise après la fin : le Gardien veille, paisible
		etat = FINI
		_sprite.modulate = Color(0.8, 0.85, 1.0)


# --- Images ------------------------------------------------------------------------------------
func _animations() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	_ajouter(f, "repos", "Idle.png", 6, 48, 6.0, true)
	_ajouter(f, "marche", "Walk.png", 6, 48, 8.0, true)
	_ajouter(f, "touche", "Hit.png", 4, 48, 10.0, false)
	_ajouter(f, "etourdi", "Hit.png", 4, 48, 3.0, true)
	_ajouter(f, "prepare_d", "ChargeRight.png", 3, 96, 6.0, false)
	_ajouter(f, "prepare_g", "ChargeLeft.png", 3, 96, 6.0, false)
	_ajouter(f, "charge_d", "AttackRight.png", 4, 96, 12.0, true)
	_ajouter(f, "charge_g", "AttackLeft.png", 4, 96, 12.0, true)
	return f


# Les cases de 48 px de haut sont « rehaussées » à 96 px (marge en haut) : toutes les images ont la même taille.
func _ajouter(f: SpriteFrames, nom: String, fichier: String, n: int, haut: int, vitesse: float, boucle: bool) -> void:
	var tex: Texture2D = load(DOSSIER + fichier)
	f.add_animation(nom)
	f.set_animation_speed(nom, vitesse)
	f.set_animation_loop(nom, boucle)
	for i in n:
		var a := AtlasTexture.new()
		a.atlas = tex
		a.region = Rect2(i * 96, 0, 96, haut)
		if haut == 48:
			a.margin = Rect2(0, 34, 0, 48)
		f.add_frame(nom, a)


# --- Comportement --------------------------------------------------------------------------------
# Le Gardien ne quitte jamais l'arène : l'ouverture du bas mène au couloir du corps du coq, mais lui reste dans sa salle.
func _borner_a_l_arene() -> void:
	position.y = minf(position.y, 11 * 16.0 + 8.0)


func _physics_process(delta: float) -> void:
	if _joueur == null or Etat.en_dialogue:
		return
	_temps += delta
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_dernier_clang = maxf(_dernier_clang - delta, 0.0)
	var vers_joueur: Vector2 = _joueur.global_position - global_position
	var phase2 := pv <= PV_PHASE2
	match etat:
		ATTENTE:
			if vers_joueur.length() < DISTANCE_CHOIX:
				_proposer_choix()
		MARCHE:
			_sprite.play("marche")
			velocity = vers_joueur.normalized() * (46.0 if phase2 else 32.0)
			move_and_slide()
			_toucher_le_heros()
			if _temps > (1.3 if phase2 else 2.0):
				_changer(PREPARE)
				_sprite.play("prepare_d" if vers_joueur.x >= 0 else "prepare_g")
				_son("Whoosh & Slash/Whoosh2.wav", -4.0)
		PREPARE:
			# il brille de plus en plus : il va foncer !
			var eclat := 1.0 + 0.6 * absf(sin(_temps * 18.0))
			_sprite.modulate = Color(eclat, eclat, 1.0)
			if _temps > (0.45 if phase2 else 0.75):
				_sprite.modulate = Color.WHITE
				_dir_charge = vers_joueur.normalized()
				_sprite.play("charge_d" if _dir_charge.x >= 0 else "charge_g")
				_son("Whoosh & Slash/Launch.wav", -2.0)
				_changer(CHARGE)
		CHARGE:
			var choc := move_and_collide(_dir_charge * (250.0 if phase2 else 200.0) * delta)
			_toucher_le_heros()
			if choc != null:
				_percuter(phase2)
			elif _temps > 1.8:
				_changer(MARCHE)
		ETOURDI:
			_sprite.play("etourdi")
			_sprite.modulate = Color(0.75, 0.75, 1.0) if int(_temps * 6.0) % 2 == 0 else Color.WHITE
			if _temps > (1.8 if phase2 else 2.4):
				_sprite.modulate = Color.WHITE
				_changer(MARCHE)
	_borner_a_l_arene()


func _changer(nouvel: int) -> void:
	etat = nouvel
	_temps = 0.0


# Contact avec le héros pendant qu'il marche ou fonce : 1 cœur.
func _toucher_le_heros() -> void:
	var d: Vector2 = _joueur.global_position - global_position
	if absf(d.x) < 20.0 and absf(d.y) < 14.0:
		_joueur.blesser(global_position)


# Il fonce dans un mur ou une statue : il reste étourdi (et en phase 2, des pierres tombent).
func _percuter(phase2: bool) -> void:
	_changer(ETOURDI)
	_son("Hit & Impact/Impact5.wav", 0.0)
	Etat.secousse.emit()
	if not _conseil_donne:
		_conseil_donne = true
		Etat.annoncer("Il s'est assommé contre le mur ! Frappe-le maintenant !")
	if phase2:
		for i in 3:
			var p: Vector2 = _joueur.global_position + Vector2(randf_range(-40, 40), randf_range(-30, 30))
			p = p.clamp(Vector2(40, 40), Vector2(360, 180))
			if i == 0:
				p = _joueur.global_position   # une pierre vise toujours le héros : il faut bouger !
			var r := Rocher.new()
			r.position = p
			r.cible = _joueur
			get_parent().add_child(r)


# Coup de lance (player.gd appelle frapper() sur tout ce que touche la lance).
func frapper() -> void:
	if etat in [ATTENTE, PARLE, KO, FINI]:
		return
	if etat != ETOURDI:
		if _dernier_clang <= 0.0:   # garde parfaite : la lance rebondit
			_dernier_clang = 0.5
			_son("Hit & Impact/Impact.wav", -2.0)
			_joueur.repousser((_joueur.global_position - global_position).normalized() * 160.0)
			if not _conseil_donne:
				Etat.annoncer("Sa garde est parfaite ! Fais-le foncer contre un mur...")
		return
	if _invulnerable > 0.0:
		return
	_invulnerable = 0.5
	pv -= 1
	_son("Hit & Impact/Hit3.wav", 0.0)
	_maj_barre()
	var t := create_tween()
	_sprite.modulate = Color(2.0, 0.6, 0.6)
	t.tween_property(_sprite, "modulate", Color.WHITE, 0.3)
	if pv <= 0:
		_vaincu()
	elif pv == PV_PHASE2:
		Etat.annoncer("Le Gardien se relève, plus rapide ! Gare aux pierres qui tombent !")
		_changer(MARCHE)


# --- Le choix ------------------------------------------------------------------------------------
func _proposer_choix() -> void:
	_changer(PARLE)
	_sprite.play("repos")
	var lignes: PackedStringArray
	if not _deja_parle:
		lignes = [
			"Recrue... Tu as rassemblé les deux ailes du coq. Rares sont ceux qui arrivent jusqu'ici.",
			"Je suis le Gardien du blason. Depuis des siècles, je mets à l'épreuve ceux qui veulent servir la Garde.",
			"Ta lance est prête, je le vois. Alors dis-moi : que fais-tu face à moi ?"]
	else:
		lignes = ["Te revoilà debout. Alors, recrue... que choisis-tu cette fois ?"]
	_deja_parle = true
	Etat.choix_fait.connect(_sur_choix, CONNECT_ONE_SHOT)
	Etat.choix_demande.emit("Le Gardien", lignes, PackedStringArray(["Combattre", "Baisser ma lance"]))


func _sur_choix(index: int) -> void:
	await Etat.dialogue_fini   # la boîte du choix finit de se fermer (sinon elle « fermerait » aussi la réplique suivante)
	if index == 0:
		_commencer_combat()
	else:
		_paix()


func _commencer_combat() -> void:
	pv = PV_MAX
	_maj_barre()
	_hud.visible = true
	_joueur.soigner()
	_musique(MUSIQUE_COMBAT)
	Etat.annoncer("En garde !")
	_changer(MARCHE)


func _paix() -> void:
	etat = FINI
	_son("Magic & Skill/Magic1.wav", -4.0)
	Etat.dialogue_fini.connect(_fin.bind("paix"), CONNECT_ONE_SHOT)
	Etat.dialogue_demande.emit("Le Gardien", PackedStringArray([
		"... Tu baisses ta lance ?",
		"Beaucoup de recrues ont foncé sur moi sans réfléchir. Toi, tu as choisi de comprendre avant de frapper.",
		"Un garde ne choisit pas toujours la violence pour tout résoudre. C'est la plus difficile des leçons.",
		"Tu as réussi l'épreuve, recrue. Retourne au village : le capitaine t'attend."]))


func _vaincu() -> void:
	etat = FINI
	velocity = Vector2.ZERO
	_hud.visible = false
	_sprite.play("touche")
	_sprite.modulate = Color(0.8, 0.85, 1.0)
	_son("Hit & Impact/Impact5.wav", 0.0)
	Etat.secousse.emit()
	for r in get_tree().get_nodes_in_group("rocher"):
		r.queue_free()
	await get_tree().create_timer(1.2).timeout
	Etat.dialogue_fini.connect(_fin.bind("combat"), CONNECT_ONE_SHOT)
	Etat.dialogue_demande.emit("Le Gardien", PackedStringArray([
		"Hm... Tu as vu ma faiblesse : je fonce sans réfléchir. Toi, tu as observé, puis frappé au bon moment.",
		"C'est cela, la force d'un garde : pas la colère, le discernement.",
		"Tu as réussi l'épreuve, recrue. Retourne au village : le capitaine t'attend."]))


# Le héros n'a plus de cœurs : le Gardien l'aide à se relever, et le choix revient.
func _sur_coeurs(coeurs: int, _maxi: int) -> void:
	_maj_coeurs(coeurs)
	if coeurs > 0 or etat == FINI:
		return
	etat = KO
	_hud.visible = false
	for r in get_tree().get_nodes_in_group("rocher"):
		r.queue_free()
	_joueur.set_physics_process(false)
	_son("Hit & Impact/Hit1.wav", 0.0)
	Etat.annoncer("Tu es à terre... Le Gardien t'aide à te relever.")
	var noir := ColorRect.new()
	noir.color = Color.BLACK
	noir.size = Vector2(400, 224)
	noir.modulate.a = 0.0
	_hud.add_child(noir)
	_hud.visible = true
	for enfant in _hud.get_children():
		enfant.visible = enfant == noir
	var t := create_tween()
	t.tween_property(noir, "modulate:a", 1.0, 0.8)
	await t.finished
	position = _depart
	pv = PV_MAX
	_joueur.global_position = get_parent().global_position + Vector2(CASE_DEPART_HEROS * 16) + Vector2(8, 3)
	_joueur.direction = "haut"
	_joueur.soigner()
	_musique(get_parent().musique)
	await get_tree().create_timer(0.5).timeout
	t = create_tween()
	t.tween_property(noir, "modulate:a", 0.0, 0.8)
	await t.finished
	noir.queue_free()
	_hud.visible = false
	for enfant in _hud.get_children():
		enfant.visible = true
	_joueur.set_physics_process(true)
	_changer(ATTENTE)


# --- Fin du jeu ----------------------------------------------------------------------------------
func _fin(issue: String) -> void:
	Etat.noter("fin_" + issue)
	Etat.poser("epreuve_reussie")
	_musique(MUSIQUE_FIN)
	await get_tree().create_timer(1.5).timeout
	var ecran := CanvasLayer.new()
	ecran.layer = 6
	get_parent().add_child(ecran)
	var noir := ColorRect.new()
	noir.color = Color(0.03, 0.03, 0.08)
	noir.size = Vector2(400, 224)
	noir.modulate.a = 0.0
	ecran.add_child(noir)
	var texte := Label.new()
	texte.size = Vector2(360, 200)
	texte.position = Vector2(20, 12)
	texte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texte.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texte.add_theme_font_size_override("font_size", 10)
	texte.add_theme_color_override("font_color", Color(0.98, 0.86, 0.45))
	var morale := "Tu as vaincu le Gardien par l'observation et le courage." if issue == "combat" \
		else "Tu as baissé ta lance : un garde ne choisit pas toujours la violence."
	texte.text = "L'ÉPREUVE DE LA GARDE EST RÉUSSIE\n\n" + morale + "\n\nLes deux ailes et le corps du coq sont réunis.\nAu village, on prépare ton adoubement...\n\n(Espace pour continuer)"
	texte.modulate.a = 0.0
	noir.add_child(texte)
	_joueur.set_physics_process(false)
	var t := create_tween()
	t.tween_property(noir, "modulate:a", 1.0, 1.5)
	t.tween_property(texte, "modulate:a", 1.0, 1.0)
	await t.finished
	while not Input.is_action_just_pressed("attack"):
		await get_tree().process_frame
	# Retour au village, devant la caserne : le capitaine a de nouvelles répliques (drapeau epreuve_reussie)
	get_parent()._ramener("@village:VillageEst", Vector2i(18, 7), "Le capitaine Aubrac t'attend devant la caserne !")


# --- HUD du combat : cœurs du héros (en haut à gauche) + vie du Gardien (en haut au milieu) ---------
func _creer_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 3
	_hud.visible = false
	add_child(_hud)
	var planche: Texture2D = load("res://Assets/Ninja_adventure/Ui/Receptacle/Heart.png")
	for i in COEURS_HEROS:
		var c := TextureRect.new()
		var a := AtlasTexture.new()
		a.atlas = planche
		a.region = Rect2(64, 0, 16, 16)
		c.texture = a
		c.position = Vector2(4 + i * 14, 4)
		_hud.add_child(c)
		_coeurs.append(c)
	_cadre_barre = ColorRect.new()
	_cadre_barre.color = Color(0.05, 0.05, 0.1, 0.85)
	_cadre_barre.position = Vector2(140, 6)
	_cadre_barre.size = Vector2(120, 8)
	_hud.add_child(_cadre_barre)
	_barre = ColorRect.new()
	_barre.color = Color(0.85, 0.2, 0.25)
	_barre.position = Vector2(1, 1)
	_barre.size = Vector2(118, 6)
	_cadre_barre.add_child(_barre)
	var nom := Label.new()
	nom.text = "Le Gardien"
	nom.position = Vector2(140, 14)
	nom.size = Vector2(120, 12)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.add_theme_font_size_override("font_size", 8)
	_hud.add_child(nom)


func _maj_coeurs(coeurs: int) -> void:
	for i in _coeurs.size():
		# Heart.png : 5 images de 16 px, de vide (0) à plein (4)
		(_coeurs[i].texture as AtlasTexture).region = Rect2(64 if i < coeurs else 0, 0, 16, 16)


func _maj_barre() -> void:
	_barre.size.x = 118.0 * maxf(pv, 0) / PV_MAX


func _son(chemin: String, volume_db: float) -> void:
	var flux = load(SONS + chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = volume_db
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)


func _musique(chemin: String) -> void:
	var monde = get_parent()
	if monde.has_method("_changer_musique"):
		monde._changer_musique(chemin)


# --- Pierre qui tombe du plafond (phase 2) : une ombre grandit 0,9 s, puis la pierre s'écrase. ---------
class Rocher extends Node2D:
	var cible: Node2D
	var _t := 0.0
	var _pierre: Sprite2D

	func _ready() -> void:
		add_to_group("rocher")
		z_index = 2
		_pierre = Sprite2D.new()
		_pierre.texture = load("res://Assets/Gemini/tuiles/v_roche.png")
		_pierre.position = Vector2(0, -160)
		add_child(_pierre)

	func _process(delta: float) -> void:
		_t += delta
		_pierre.position.y = lerpf(-160.0, -4.0, clampf((_t - 0.4) / 0.5, 0.0, 1.0))
		queue_redraw()
		if _t >= 0.9 and _t - delta < 0.9:   # la pierre touche le sol
			var lecteur := AudioStreamPlayer.new()
			lecteur.stream = load("res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact2.wav")
			add_child(lecteur)
			lecteur.play()
			if is_instance_valid(cible) and cible.global_position.distance_to(global_position) < 12.0:
				cible.blesser(global_position)
		if _t > 1.4:
			modulate.a = maxf(0.0, 1.0 - (_t - 1.4) * 3.0)
		if _t > 1.8:
			queue_free()

	func _draw() -> void:
		var r := lerpf(3.0, 9.0, clampf(_t / 0.9, 0.0, 1.0))
		draw_circle(Vector2(0, 2), r, Color(0, 0, 0, 0.35))
