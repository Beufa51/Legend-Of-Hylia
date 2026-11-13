extends Node2D
class_name Dalle
# Une DALLE DE COULEUR (aile droite, lettre `z`), comme dans les énigmes de Zelda :
# chaque fois que le joueur pose le pied dessus, elle se RETOURNE : rouge -> bleue, bleue -> rouge.
# Le but : rendre TOUTES les dalles de la salle bleues (repasser sur une dalle bleue la remet en rouge !).
# La salle (room.gd) suit les pas du joueur et appelle retourner(), remettre(), valider().
# Dessinée en code (pas d'image) : cadre de pierre, dalle biseautée, gemme au centre.

const ROUGE := Color(0.78, 0.2, 0.18)
const BLEU := Color(0.2, 0.45, 0.9)
const OR := Color(1.0, 0.82, 0.3)
const CADRE := Color(0.2, 0.18, 0.22)
const SON := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Move2.wav"

var bleue := false
var validee := false     # énigme résolue : la dalle reste bleue, on peut marcher dessus librement
var _face: Node2D        # tout le dessin (centré, pour l'animation de retournement)
var _corps: ColorRect
var _clair: Array[ColorRect] = []   # biseau éclairé (haut, gauche)
var _sombre: Array[ColorRect] = []  # biseau dans l'ombre (bas, droite)
var _panneau: ColorRect
var _gemme: Polygon2D
var _reflet: ColorRect


func initialiser(case: Vector2i) -> void:
	position = Vector2(case * 16)
	_face = Node2D.new()
	_face.position = Vector2(8, 8)   # au centre de la case : la dalle se retourne sur elle-même
	add_child(_face)
	_rect(CADRE, Vector2(0, 0), Vector2(16, 16))
	_corps = _rect(ROUGE, Vector2(1, 1), Vector2(14, 14))
	_clair.append(_rect(ROUGE, Vector2(1, 1), Vector2(14, 1)))
	_clair.append(_rect(ROUGE, Vector2(1, 1), Vector2(1, 14)))
	_sombre.append(_rect(ROUGE, Vector2(1, 14), Vector2(14, 1)))
	_sombre.append(_rect(ROUGE, Vector2(14, 1), Vector2(1, 14)))
	_panneau = _rect(ROUGE, Vector2(4, 4), Vector2(8, 8))
	_gemme = Polygon2D.new()
	_gemme.polygon = PackedVector2Array([Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0)])
	_face.add_child(_gemme)
	_reflet = _rect(Color(1, 1, 1, 0.5), Vector2(2, 2), Vector2(2, 1))
	_colorer(ROUGE, false)


func _rect(c: Color, pos: Vector2, taille: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos - Vector2(8, 8)
	r.size = taille
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.add_child(r)
	return r


func _colorer(base: Color, gemme_or: bool) -> void:
	_corps.color = base
	for r in _clair:
		r.color = base.lightened(0.35)
	for r in _sombre:
		r.color = base.darkened(0.45)
	_panneau.color = base.darkened(0.22)
	_gemme.color = OR if gemme_or else base.lightened(0.55)


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
	t.tween_callback(_colorer.bind(BLEU if bleue else ROUGE, false))
	t.tween_property(_face, "scale:x", 1.0, 0.07)


# Remet la dalle rouge (touche R).
func remettre() -> void:
	if validee:
		return
	bleue = false
	_face.scale = Vector2.ONE
	_colorer(ROUGE, false)


# Énigme résolue : la dalle reste bleue, sa gemme devient dorée.
func valider(anime := true) -> void:
	validee = true
	bleue = true
	_colorer(BLEU, true)
	if anime:
		_face.scale = Vector2(1.3, 1.3)
		create_tween().tween_property(_face, "scale", Vector2.ONE, 0.25)
