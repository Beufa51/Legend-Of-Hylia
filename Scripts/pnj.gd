extends StaticBody2D
class_name Pnj
# Un habitant du village (personnage non joueur). Il reste à sa place, tourne la tête vers le joueur
# quand il approche, et parle quand on appuie sur Espace/J près de lui (le coup de lance est remplacé par la parole).
# Planche du pack : Idle.png = 4 images de 16x16 côte à côte (bas, haut, gauche, droite).

const DOSSIER := "res://Assets/Ninja_adventure/Actor/Character/%s/SeparateAnim/Idle.png"
const DIRECTIONS := ["bas", "haut", "gauche", "droite"]
const PORTEE_PAROLE := 26.0   # px : distance maximale pour parler
const PORTEE_REGARD := 70.0   # px : il tourne la tête vers le joueur en dessous de cette distance

var nom_affiche := ""
var minijeu := ""           # si non vide : une fois la conversation finie, ce mini-jeu démarre (voir minijeu.gd)
var versions: Array = []     # [{condition, texte, pose}] : voir ecran.gd (dialogues conditionnés par les drapeaux)
var _sprite: Sprite2D
var _direction := 0           # index dans DIRECTIONS
var _chrono := 3.0            # avant de regarder ailleurs, au repos
var _ecran := Vector2i.ZERO   # case de la grille de l'écran où il vit (inutile d'animer les autres)


func initialiser(perso: String, nom: String, dialogues: Array, direction: String, ecran: Vector2i) -> void:
	nom_affiche = nom
	versions = dialogues
	_ecran = ecran
	_direction = maxi(DIRECTIONS.find(direction), 0)
	add_to_group("pnj")
	collision_layer = 1   # il bloque le joueur
	var forme := RectangleShape2D.new()
	forme.size = Vector2(10, 6)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	add_child(collision)
	_sprite = Sprite2D.new()
	_sprite.texture = load(DOSSIER % perso)
	_sprite.hframes = 4
	_sprite.position = Vector2(0, -5)
	_sprite.frame = _direction
	add_child(_sprite)
	_chrono = 2.0 + randf() * 4.0


func _process(delta: float) -> void:
	if _ecran != Etat.salle_courante:
		return
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	if joueur and joueur.global_position.distance_to(global_position) < PORTEE_REGARD:
		_regarder(joueur.global_position)
		return
	_chrono -= delta
	if _chrono <= 0.0:   # au repos, il jette un coup d'œil de temps en temps
		_chrono = 3.0 + randf() * 5.0
		_direction = randi() % 4
		_sprite.frame = _direction


func _regarder(point: Vector2) -> void:
	var v := point - global_position
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
