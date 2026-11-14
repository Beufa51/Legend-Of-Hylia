extends CharacterBody2D
class_name Pnj
# Un habitant du village (personnage non joueur). Il se promène un peu autour de sa place (s'il a des images de marche),
# s'arrête et se tourne vers le joueur quand il approche, et parle quand on appuie sur Espace/J près de lui
# (le coup de lance est remplacé par la parole).
# Planches (Assets/Heros, fabriquées par Outils/preparer_pnj_pixelcrawler.py) :
#   pnj_<Nom>.png        4 poses fixes de 32 px (bas, haut, gauche, droite)
#   pnj_<Nom>_repos.png  animation « au repos » : 4 images ; 1 rangée (regard à droite, miroir pour la gauche) ou 3 rangées (bas, haut, côté)
#   pnj_<Nom>_marche.png animation de marche : 6 images ; mêmes rangées
# Sans les deux dernières (ancien habitant), il reste planté sur place et tourne seulement la tête.

const DOSSIER := "res://Assets/Ninja_adventure/Actor/Character/%s/SeparateAnim/Idle.png"
const HEROS := "res://Assets/Heros/pnj_%s.png"
const REPOS := "res://Assets/Heros/pnj_%s_repos.png"
const MARCHE := "res://Assets/Heros/pnj_%s_marche.png"
const DIRECTIONS := ["bas", "haut", "gauche", "droite"]
const PORTEE_PAROLE := 26.0   # px : distance maximale pour parler
const PORTEE_REGARD := 70.0   # px : il tourne la tête vers le joueur en dessous de cette distance
const VITESSE := 22.0         # px/s en promenade
const RAYON_X := 60.0         # il ne s'éloigne pas de plus de ça de sa place (px)
const RAYON_Y := 30.0

var nom_affiche := ""
var minijeu := ""           # si non vide : une fois la conversation finie, ce mini-jeu démarre (voir minijeu.gd)
var versions: Array = []     # [{condition, texte, pose}] : voir ecran.gd (dialogues conditionnés par les drapeaux)
var _sprite: Sprite2D
var _direction := 0           # index dans DIRECTIONS
var _chrono := 3.0            # avant de regarder ailleurs / de repartir en promenade
var _ecran := Vector2i.ZERO   # case de la grille de l'écran où il vit (inutile d'animer les autres)
var _anime := false           # vrai s'il a des images de repos et de marche
var _tex_repos: Texture2D
var _tex_marche: Texture2D
var _origine := Vector2.ZERO  # sa place : il se promène autour
var _cible := Vector2.ZERO
var _marche := false
var _gauche := false          # regarde à gauche (miroir)
var _vue := 2                 # rangée de la planche à 3 vues : 0 bas, 1 haut, 2 côté
var _rangees := 1             # 1 ou 3 rangées dans les planches animées
var _temps := 0.0
var fixe := false             # un garde qui ne bouge pas de sa place (direction écrite avec un « ! » dans `pnjs`, ex. « haut! »)
var _delai_marche := 0.0      # durée max d'une promenade (au cas où il se coince)


func initialiser(perso: String, nom: String, dialogues: Array, direction: String, ecran: Vector2i) -> void:
	nom_affiche = nom
	versions = dialogues
	_ecran = ecran
	_direction = maxi(DIRECTIONS.find(direction), 0)
	_gauche = _direction == 2
	_origine = position
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("pnj")
	collision_layer = 1   # il bloque le joueur
	var forme := RectangleShape2D.new()
	forme.size = Vector2(10, 6)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	add_child(collision)
	_sprite = Sprite2D.new()
	if ResourceLoader.exists(HEROS % perso):
		_sprite.texture = load(HEROS % perso)
		_sprite.position = Vector2(0, -10)   # case de 32 px : les pieds au niveau de la collision
		if ResourceLoader.exists(REPOS % perso) and ResourceLoader.exists(MARCHE % perso):
			_tex_repos = load(REPOS % perso)
			_tex_marche = load(MARCHE % perso)
			_rangees = maxi(1, _tex_repos.get_height() / 32)
			_anime = true
	else:
		_sprite.texture = load(DOSSIER % perso)
		_sprite.position = Vector2(0, -5)
	_sprite.hframes = 4
	_sprite.frame = _direction
	add_child(_sprite)
	if _anime:
		_orienter([Vector2(0, 1), Vector2(0, -1), Vector2(-1, 0), Vector2(1, 0)][_direction])
		_afficher_repos()
		_montrer(0)
	_chrono = 1.0 + randf() * 2.5


func _afficher_repos() -> void:
	_sprite.texture = _tex_repos
	_sprite.hframes = 4
	_sprite.vframes = _rangees
	_sprite.flip_h = _gauche and (_vue == 2 or _rangees == 1)


func _afficher_marche() -> void:
	_sprite.texture = _tex_marche
	_sprite.hframes = 6
	_sprite.vframes = _rangees
	_sprite.flip_h = _gauche and (_vue == 2 or _rangees == 1)


# Regarde dans la direction `v` : côté (miroir à gauche), haut ou bas (planches à 3 vues) ; une planche à 1 rangée n'a que le côté.
func _orienter(v: Vector2) -> void:
	if _rangees >= 3 and absf(v.y) > absf(v.x):
		_vue = 1 if v.y < 0.0 else 0
	else:
		_vue = 2 if _rangees >= 3 else 0
		_gauche = v.x < 0.0
	_sprite.flip_h = _gauche and (_vue == 2 or _rangees == 1)


func _montrer(image: int) -> void:
	_sprite.frame = (_vue if _rangees >= 3 else 0) * _sprite.hframes + image


func _process(delta: float) -> void:
	if _ecran != Etat.salle_courante:
		return
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	var proche := joueur != null and joueur.global_position.distance_to(global_position) < PORTEE_REGARD
	if _anime:
		_temps += delta
		_animer(delta, joueur, proche)
		return
	if proche:
		_regarder(joueur.global_position)
		return
	_chrono -= delta
	if _chrono <= 0.0:   # au repos, il jette un coup d'œil de temps en temps
		_chrono = 3.0 + randf() * 5.0
		_direction = randi() % 4
		_sprite.frame = _direction


# Habitant animé : repos (il respire), promenade lente autour de sa place, arrêt et regard vers le joueur quand il approche.
func _animer(delta: float, joueur: Node2D, proche: bool) -> void:
	var occupe := Etat.en_dialogue or (proche and joueur.global_position.distance_to(global_position) < PORTEE_REGARD * 0.8)
	if occupe:
		if _marche:
			_arreter()
		if joueur:
			_orienter(joueur.global_position - global_position)
		_montrer(int(_temps * 3.0) % 4)
		return
	if _marche:
		_delai_marche -= delta
		var v := _cible - position
		if v.length() < 2.0 or _delai_marche <= 0.0:
			_arreter()
		else:
			velocity = v.normalized() * VITESSE
			_orienter(v)
			move_and_slide()
			if get_slide_collision_count() > 0:   # un obstacle : il s'arrête là
				_arreter()
			else:
				_montrer(int(_temps * 8.0) % 6)
		return
	_montrer(int(_temps * 3.0) % 4)
	_chrono -= delta
	if _chrono <= 0.0 and fixe:
		_chrono = 2.0   # il reste à son poste
	elif _chrono <= 0.0:
		_cible = _origine + Vector2(randf_range(-RAYON_X, RAYON_X), randf_range(-RAYON_Y, RAYON_Y))
		_delai_marche = 5.0
		_marche = true
		_orienter(_cible - position)
		_afficher_marche()
		_montrer(0)


func _arreter() -> void:
	_marche = false
	velocity = Vector2.ZERO
	_chrono = 0.8 + randf() * 2.2   # il repart vite : l'habitant ne reste pas figé
	_afficher_repos()


func _regarder(point: Vector2) -> void:
	var v := point - global_position
	if _anime:
		if _marche:
			_arreter()
		_orienter(v)
		return
	_direction = (3 if v.x > 0 else 2) if absf(v.x) > absf(v.y) else (0 if v.y > 0 else 1)
	_sprite.frame = _direction


func peut_parler(joueur: Node2D) -> bool:
	return joueur.global_position.distance_to(global_position) < PORTEE_PAROLE


# La version du dialogue à dire maintenant : la première dont la condition est vraie.
func _version_courante() -> Dictionary:
	for v in versions:
		var c: String = v["condition"]
		var ok := true
		if c.begins_with("!"):
			ok = not Etat.est(c.substr(1))
		elif c != "":
			ok = Etat.est(c)
		if ok:
			return v
	return versions[0]


func parler(joueur: Node2D) -> void:
	_regarder(joueur.global_position)
	var v := _version_courante()
	var pose: String = v["pose"]
	if pose != "":
		Etat.dialogue_fini.connect(func(): Etat.noter(pose), CONNECT_ONE_SHOT)
	if minijeu != "":
		Etat.dialogue_fini.connect(func(): Etat.minijeu_demande.emit(minijeu), CONNECT_ONE_SHOT)
	Etat.dialogue_demande.emit(nom_affiche, v["texte"])
