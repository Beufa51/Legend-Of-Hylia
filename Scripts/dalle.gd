extends Node2D
class_name Dalle
# Une DALLE FRAGILE (aile droite, lettre `z`) : on peut marcher dessus UNE seule fois.
# Le joueur pose le pied dessus -> elle s'illumine ; il la quitte -> elle se fissure et s'effondre (un trou).
# Retomber dans un trou = chute (retour au bas de la salle). Le but : passer sur TOUTES les dalles.
# La salle (room.gd) suit les pas du joueur et appelle marquer(), effondrer(), reparer(), raffermir().
# Dessinée en code (pas d'image).

const TUILE := 16
const PIERRE := Color(0.66, 0.6, 0.5)
const BORD := Color(0.38, 0.33, 0.28)
const FISSURE := Color(0.25, 0.21, 0.17)
const LUEUR := Color(1.0, 0.85, 0.45)
const SON_CRAQUE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact2.wav"

enum { INTACTE, MARQUEE, TROU }
var etat := INTACTE
var solide := false   # vrai quand l'énigme est résolue : la dalle ne s'effondre plus
var _dalle: Node2D
var _trou: Node2D
var _lueur: ColorRect


func initialiser(case: Vector2i) -> void:
	position = Vector2(case * TUILE)
	# La dalle : pierre claire, bord sombre, quelques fissures (elle a l'air fragile)
	_dalle = Node2D.new()
	add_child(_dalle)
	_rect(_dalle, Vector2(0, 0), Vector2(16, 16), BORD)
	_rect(_dalle, Vector2(1, 1), Vector2(14, 14), PIERRE)
	_rect(_dalle, Vector2(1, 1), Vector2(14, 2), PIERRE.lightened(0.2))
	var fissure := Line2D.new()
	fissure.points = PackedVector2Array([Vector2(3, 4), Vector2(7, 7), Vector2(6, 11), Vector2(10, 13)])
	fissure.width = 1.0
	fissure.default_color = FISSURE
	_dalle.add_child(fissure)
	var fissure2 := Line2D.new()
	fissure2.points = PackedVector2Array([Vector2(7, 7), Vector2(12, 5)])
	fissure2.width = 1.0
	fissure2.default_color = FISSURE
	_dalle.add_child(fissure2)
	_lueur = _rect(_dalle, Vector2(1, 1), Vector2(14, 14), Color(LUEUR, 0.0))
	# Le trou : noir, avec la paroi du haut éclairée (on voit la profondeur)
	_trou = Node2D.new()
	add_child(_trou)
	_rect(_trou, Vector2(0, 0), Vector2(16, 16), Color(0.02, 0.02, 0.04))
	_rect(_trou, Vector2(0, 0), Vector2(16, 4), Color(0.22, 0.18, 0.15))
	_rect(_trou, Vector2(0, 4), Vector2(16, 2), Color(0.1, 0.08, 0.08))
	_trou.visible = false


func _rect(parent: Node, pos: Vector2, taille: Vector2, c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = taille
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


# Le joueur pose le pied dessus : elle s'illumine.
func marquer() -> void:
	if etat != INTACTE or solide:
		return
	etat = MARQUEE
	_lueur.color = Color(LUEUR, 0.55)


# Le joueur la quitte : elle tremble, se fissure, puis tombe (le trou compte TOUT DE SUITE).
func effondrer() -> void:
	if etat != MARQUEE or solide:
		return
	etat = TROU
	var flux = load(SON_CRAQUE)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		lecteur.volume_db = -10.0
		lecteur.pitch_scale = randf_range(0.8, 1.0)
		add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)
	_trou.visible = true
	move_child(_trou, 0)   # le trou sous la dalle qui tombe
	var t := create_tween()
	t.tween_property(_dalle, "position", Vector2(1, 0), 0.04)
	t.tween_property(_dalle, "position", Vector2(-1, 0), 0.04)
	t.tween_property(_dalle, "position", Vector2.ZERO, 0.04)
	t.tween_property(_dalle, "scale", Vector2(0.2, 0.2), 0.22)
	t.parallel().tween_property(_dalle, "position", Vector2(6.4, 7.0), 0.22)
	t.parallel().tween_property(_dalle, "modulate:a", 0.0, 0.22)


# Remet la dalle intacte (touche R, chute).
func reparer() -> void:
	etat = INTACTE
	_dalle.position = Vector2.ZERO
	_dalle.scale = Vector2.ONE
	_dalle.modulate.a = 1.0
	_trou.visible = false
	_lueur.color = Color(LUEUR, 0.0)


# Énigme résolue : la dalle redevient intacte et ne s'effondrera plus (on peut revenir en arrière).
func raffermir() -> void:
	reparer()
	solide = true
	_lueur.color = Color(LUEUR, 0.18)
