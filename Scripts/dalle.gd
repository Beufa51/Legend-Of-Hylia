extends Node2D
class_name Dalle
# Une DALLE DE COULEUR (aile droite, lettre `z`), comme dans les énigmes de Zelda :
# chaque fois que le joueur pose le pied dessus, elle se RETOURNE : rouge -> bleue, bleue -> rouge.
# Le but : rendre TOUTES les dalles de la salle bleues (repasser sur une dalle bleue la remet en rouge !).
# La salle (room.gd) suit les pas du joueur et appelle retourner(), remettre(), valider().
# Images Gemini : dalle_rouge / dalle_bleue / dalle_doree (Outils/traiter_plots.py).

const SON := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Move2.wav"

var bleue := false
var bleue_depart := false   # lettre `y` : dalle déjà BLEUE au départ (il faut l'éviter, ou passer dessus deux fois)
var validee := false     # énigme résolue : la dalle reste bleue, on peut marcher dessus librement
var _face: Node2D        # le dessin (centré, pour l'animation de retournement)
var _image: Sprite2D
var textures: Array[Texture2D] = []   # [rouge, bleue, dorée], fournies par room.gd (images Gemini)


func initialiser(case: Vector2i, deja_bleue := false) -> void:
	bleue_depart = deja_bleue
	bleue = deja_bleue
	position = Vector2(case * 16)
	_face = Node2D.new()
	_face.position = Vector2(8, 8)   # au centre de la case : la dalle se retourne sur elle-même
	add_child(_face)
	_image = Sprite2D.new()
	_face.add_child(_image)
	_colorer(bleue, false)


func _colorer(en_bleu: bool, gemme_or: bool) -> void:
	if textures.size() < 3:
		return
	_image.texture = textures[2] if gemme_or else (textures[1] if en_bleu else textures[0])


# Le joueur pose le pied dessus : la dalle se retourne (animation + petit bruit, aigu si elle devient bleue).
func retourner() -> void:
	if validee:
		return
	bleue = not bleue
	var flux = load(SON)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		lecteur.volume_db = -8.0
		lecteur.pitch_scale = 1.25 if bleue else 0.8
		add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)
	var t := create_tween()
	t.tween_property(_face, "scale:x", 0.0, 0.07)
	t.tween_callback(_colorer.bind(bleue, false))
	t.tween_property(_face, "scale:x", 1.0, 0.07)


# Remet la dalle dans son état de départ (touche R) : rouge, ou bleue pour une dalle `y`.
func remettre() -> void:
	if validee:
		return
	bleue = bleue_depart
	_face.scale = Vector2.ONE
	modulate = Color.WHITE
	_colorer(bleue, false)


# Aide (après 50 s d'inactivité) : une dalle encore ROUGE pulse 3 fois.
func signaler() -> void:
	if validee or bleue:
		return
	var t := create_tween().set_loops(3)
	t.tween_property(self, "modulate", Color(1.9, 1.5, 1.5), 0.35)
	t.tween_property(self, "modulate", Color.WHITE, 0.35)


# Énigme résolue : la dalle reste bleue, sa gemme devient dorée.
func valider(anime := true) -> void:
	validee = true
	bleue = true
	_colorer(true, true)
	if anime:
		_face.scale = Vector2(1.3, 1.3)
		create_tween().tween_property(_face, "scale", Vector2.ONE, 0.25)
