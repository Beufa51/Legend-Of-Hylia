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
