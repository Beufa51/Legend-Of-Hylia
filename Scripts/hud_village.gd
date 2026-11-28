extends CanvasLayer
class_name HudVillage
# Affichage du village : les cœurs du héros (en haut à gauche) et le compteur de rubis. Créé par world.gd hors donjon.

const MAX_COEURS := 8
var _coeurs: Array[TextureRect] = []
var _label: Label
var _icone_rubis: TextureRect
var _joueur: Node


func _init() -> void:
	layer = 3


func demarrer(joueur: Node) -> void:
	_joueur = joueur
	var plein: Texture2D = load("res://Assets/Gemini/tuiles/icone_coeur_plein.png")
	for i in MAX_COEURS:
		var c := TextureRect.new()
		c.texture = plein
		c.position = Vector2(4 + i * 15, 4)
		add_child(c)
		_coeurs.append(c)
	_icone_rubis = TextureRect.new()
	_icone_rubis.texture = load("res://Assets/Ninja_adventure/Items/Resource/GemGreen.png")
	_icone_rubis.position = Vector2(4, 19)
	add_child(_icone_rubis)
	_label = Label.new()
	_label.position = Vector2(22, 18)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 3)
	add_child(_label)
	joueur.coeurs_change.connect(_maj_coeurs)
	Etat.rubis_change.connect(_maj_rubis)
	_maj_coeurs(joueur.coeurs, joueur.coeurs_max())
	_maj_rubis(Etat.rubis)


func _maj_coeurs(coeurs: int, maxi: int) -> void:
	for i in _coeurs.size():
		_coeurs[i].visible = i < maxi
		_coeurs[i].modulate = Color.WHITE if i < coeurs else Color(0.15, 0.1, 0.12, 0.7)   # cœur vide = silhouette sombre


func _maj_rubis(total: int) -> void:
	_label.text = "x %d" % total
	_icone_rubis.scale = Vector2(1.5, 1.5)
	create_tween().tween_property(_icone_rubis, "scale", Vector2.ONE, 0.2)
