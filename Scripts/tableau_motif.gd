extends Node2D
class_name TableauMotif
# STÈLE DU MOTIF (lettre `m`, plume D2b) : une pierre dressée où est gravé le DESSIN à reproduire avec les dalles
# de couleur (petites cases bleues et rouges). Chaque petite case s'éclaire et prend un liseré doré quand la dalle
# correspondante au sol a la bonne couleur : on voit sa progression sans aucun texte. Dessin complet = la pierre luit en or.
# Créée par room.gd (`_poser_tableau`), redessinée à chaque pas sur une dalle.

const PAS := 4          # une petite case du dessin = 3 px + 1 px de joint
const PIERRE := Color(0.36, 0.38, 0.44)
const PIERRE_CLAIRE := Color(0.52, 0.55, 0.62)
const PIERRE_SOMBRE := Color(0.18, 0.19, 0.24)
const BLEU := Color(0.32, 0.55, 1.0)
const ROUGE := Color(0.85, 0.25, 0.22)
const OR := Color(1.0, 0.82, 0.3)

var salle: Node          # la Room (pour lire ses dalles)
var origine := Vector2i.ZERO   # coin haut-gauche du champ de dalles
var taille := Vector2i.ONE     # nombre de colonnes / rangées du champ
var motif := {}                # { case : true } cases qui doivent être BLEUES
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()   # léger : quelques rectangles, seulement dans la salle affichée


func _draw() -> void:
	var w := taille.x * PAS + 5
	var h := taille.y * PAS + 5
	# La pierre : posée sur la case (bas = bas de la case), dépasse vers le haut
	var bas := 16.0
	var haut := bas - h - 8
	var g := 8.0 - w / 2.0
	draw_rect(Rect2(g - 3, bas - 4, w + 6, 4), PIERRE_SOMBRE)                 # socle
	draw_rect(Rect2(g - 2, bas - 6, w + 4, 2), PIERRE)
	draw_rect(Rect2(g, haut, w, bas - 6 - haut), PIERRE)                      # dalle dressée
	draw_rect(Rect2(g, haut, w, 1), PIERRE_CLAIRE)
	draw_rect(Rect2(g, haut, 1, bas - 6 - haut), PIERRE_CLAIRE)
	draw_rect(Rect2(g + w - 1, haut, 1, bas - 6 - haut), PIERRE_SOMBRE)
	draw_rect(Rect2(g + 2, haut + 2, w - 4, h - 1), PIERRE_SOMBRE)            # creux gravé
	var fini := true
	var gx := g + 3.5
	var gy := haut + 3.5
	for y in taille.y:
		for x in taille.x:
			var c := origine + Vector2i(x, y)
			var veut_bleu: bool = motif.has(c)
			var dalle = salle._dalles.get(c) if salle != null else null
			var juste: bool = dalle != null and dalle.bleue == veut_bleu
			fini = fini and juste
			var coul := BLEU if veut_bleu else ROUGE
			var r := Rect2(gx + x * PAS - 0.5, gy + y * PAS - 0.5, 3, 3)
			if juste:
				draw_rect(r.grow(0.5), OR * Color(1, 1, 1, 0.75))
				draw_rect(r, coul.lightened(0.25))
			else:
				draw_rect(r, coul.darkened(0.15) if veut_bleu else coul.darkened(0.4))
	if fini:   # dessin complet : la pierre luit en or
		var a := 0.25 + 0.15 * sin(_t * 3.0)
		draw_rect(Rect2(g - 1, haut - 1, w + 2, bas - 5 - haut), Color(OR.r, OR.g, OR.b, a), false, 1.0)
