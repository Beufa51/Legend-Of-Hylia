extends Node2D
class_name Symbole
# Petit SYMBOLE (cercle, carré, triangle, losange, croix) posé sur les objets de couleur des énigmes
# (plots orange/bleu, dalles rouge/bleue, plaques des cloches) : on les distingue sans voir les couleurs
# (daltonisme). Contour sombre + remplissage clair, lisible sur tous les fonds.

enum Forme { CERCLE, CARRE, TRIANGLE, LOSANGE, CROIX }

var forme: int = Forme.CERCLE
var rayon := 2.5
var clair := Color(1, 1, 1, 0.9)


static func creer(une_forme: int, position_locale: Vector2, un_rayon := 2.5) -> Symbole:
	var s := Symbole.new()
	s.forme = une_forme
	s.position = position_locale
	s.rayon = un_rayon
	s.z_index = 1
	return s


func _draw() -> void:
	_tracer(rayon + 1.0, Color(0.05, 0.04, 0.1, 0.9))
	_tracer(rayon, clair)


func _tracer(r: float, c: Color) -> void:
	match forme:
		Forme.CERCLE:
			draw_circle(Vector2.ZERO, r, c)
		Forme.CARRE:
			draw_rect(Rect2(Vector2(-r, -r), Vector2(r, r) * 2.0), c)
		Forme.TRIANGLE:
			draw_colored_polygon(PackedVector2Array([Vector2(0, -r), Vector2(r, r), Vector2(-r, r)]), c)
		Forme.LOSANGE:
			draw_colored_polygon(PackedVector2Array([Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)]), c)
		Forme.CROIX:
			var e := maxf(r * 0.38, 0.8)
			draw_rect(Rect2(Vector2(-r, -e), Vector2(r * 2.0, e * 2.0)), c)
			draw_rect(Rect2(Vector2(-e, -r), Vector2(e * 2.0, r * 2.0)), c)
