extends Area2D
class_name Ramassable
# Un objet à ramasser en le touchant (ici : la plume dorée). Dessiné en code, flotte doucement.
# Quand le joueur le touche, il lève le drapeau `drapeau` et affiche `texte`.

var drapeau := ""
var texte := ""
var _pris := false


func initialiser(nom_drapeau: String, message: String) -> void:
	drapeau = nom_drapeau
	texte = message
	collision_layer = 0
	collision_mask = 1
	var forme := CircleShape2D.new()
	forme.radius = 7.0
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)
	# Une petite plume dorée : losange allongé + reflet
	var corps := Polygon2D.new()
	corps.polygon = PackedVector2Array([Vector2(8, 0), Vector2(13, 8), Vector2(8, 16), Vector2(3, 8)])
	corps.color = Color(1.0, 0.78, 0.2)
	add_child(corps)
	var reflet := Polygon2D.new()
	reflet.polygon = PackedVector2Array([Vector2(8, 2), Vector2(10, 8), Vector2(8, 13), Vector2(7, 8)])
	reflet.color = Color(1.0, 0.95, 0.65)
	add_child(reflet)
	body_entered.connect(_sur_contact)
	var flotte := create_tween().set_loops()
	flotte.tween_property(self, "position:y", position.y - 2.0, 0.7)
	flotte.tween_property(self, "position:y", position.y + 2.0, 0.7)


func _sur_contact(corps: Node) -> void:
	if _pris or not corps.is_in_group("joueur"):
		return
	_pris = true
	Etat.poser(drapeau)
	Etat.annoncer(texte)
	queue_free()
