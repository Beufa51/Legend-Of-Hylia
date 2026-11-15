extends Node2D
class_name Pics
# Des PICS (lettre `Z`) qui sortent du sol et rentrent, en boucle (images du pack donjon Craftpix).
# Pics sortis + pieds du joueur dessus = il est renvoyé au début de la salle (pas de dégâts : `room.gd`).
# Cycle de `periode` secondes : rentrés la 1re moitié, ils sortent, restent sortis, puis rentrent.
# `decalage` (0 à 1) : le cycle commence plus tard, pour que les rangées de pics ne sortent pas ensemble.

const SON := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Slash.wav"

var periode := 2.4
var decalage := 0.0
var dangereux := false   # vrai quand les pics sont sortis
var son := false         # cette rangée de pics fait du bruit en sortant (une seule par groupe, sinon c'est trop fort)
var _sprite: Sprite2D
var _images: Array[Texture2D] = []
var _temps := 0.0
var fixe := false        # toujours sortis (mur de pics) : seul un bloc poussé dedans les écrase
var image_ecrase: Texture2D   # dalle écrasée par un bloc (planche Gemini pics_ecrase.png)
var _ecrase := false
var coince := false      # un bloc est entré dans la bande : le mécanisme est bloqué, les pics restent rentrés
var _poussiere: CPUParticles2D


func initialiser(images: Array[Texture2D], une_periode: float, un_decalage: float, avec_son: bool) -> void:
	_images = images
	periode = une_periode
	decalage = un_decalage
	son = avec_son
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.position = Vector2(0, -8)   # image 16x24 : les pointes dépassent au-dessus de la case
	_sprite.texture = images[0]
	add_child(_sprite)


func _process(delta: float) -> void:
	_temps += delta
	if coince:
		dangereux = false
		_sprite.texture = image_ecrase if _ecrase and image_ecrase != null else _images[0]
		return
	if fixe:
		dangereux = true
		_sprite.texture = _images[4]
		return
	var t := fposmod(_temps / periode - decalage, 1.0)   # 0 -> 1 sur un cycle
	# image : rentrés, petites pointes (avertissement), sortie, sortis, rentrée
	var image := 0
	if t < 0.35:
		image = 0
	elif t < 0.45:
		image = 2      # les pointes apparaissent (pas encore dangereuses) : attention !
	elif t < 0.5:
		image = 3
	elif t < 0.9:
		image = 4
	elif t < 0.95:
		image = 3
	else:
		image = 2
	var avant := dangereux
	dangereux = image >= 3
	if dangereux and not avant and son and get_parent().grille == Etat.salle_courante:
		var flux = load(SON)
		if flux != null:
			var lecteur := AudioStreamPlayer.new()
			lecteur.stream = flux
			lecteur.volume_db = -14.0
			add_child(lecteur)
			lecteur.play()
			lecteur.finished.connect(lecteur.queue_free)
	_sprite.texture = _images[image]


# Un bloc a coincé la bande : les pics rentrent d'un coup en grinçant (petit tremblement), un peu de poussière, et ne ressortent plus.
func coincer(sous_le_bloc: bool) -> void:
	coince = true
	dangereux = false
	_sprite.texture = _images[0]
	_sprite.modulate = Color(0.78, 0.74, 0.7)   # mécanisme grippé : métal terni
	var tw := create_tween()
	for i in 4:
		tw.tween_property(_sprite, "position:x", 1.0 if i % 2 == 0 else -1.0, 0.04)
	tw.tween_property(_sprite, "position:x", 0.0, 0.04)
	if sous_le_bloc:
		ecraser()
		return
	_poussiere = CPUParticles2D.new()
	_poussiere.position = Vector2(8, 10)
	_poussiere.amount = 6
	_poussiere.one_shot = true
	_poussiere.explosiveness = 0.9
	_poussiere.lifetime = 0.6
	_poussiere.direction = Vector2(0, -1)
	_poussiere.spread = 70.0
	_poussiere.initial_velocity_min = 8.0
	_poussiere.initial_velocity_max = 18.0
	_poussiere.gravity = Vector2(0, 20)
	_poussiere.scale_amount_min = 1.0
	_poussiere.scale_amount_max = 2.0
	_poussiere.color = Color(0.7, 0.66, 0.6, 0.7)
	add_child(_poussiere)
	_poussiere.emitting = true


# Le bloc est passé sur cette dalle : pointes tordues, pierre fendue (reste visible si le bloc continue plus loin).
func ecraser() -> void:
	_ecrase = true
	_sprite.modulate = Color.WHITE


# R : la bande se remet en marche.
func decoincer() -> void:
	coince = false
	_ecrase = false
	_sprite.modulate = Color.WHITE
	if _poussiere != null:
		_poussiere.queue_free()
		_poussiere = null
