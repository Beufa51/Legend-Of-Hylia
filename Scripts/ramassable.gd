extends Area2D
class_name Ramassable
# Un objet à ramasser en le touchant (ici : la plume dorée). Il flotte doucement et brille.
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
	# La plume dorée : image plume_doree.png (Outils/fabriquer_objets.py), avec une lueur qui pulse
	var image := Sprite2D.new()
	image.texture = load("res://Assets/Gemini/tuiles/plume_doree.png")
	if image.texture == null:   # image pas encore importée par Godot : lecture directe du fichier
		image.texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://Assets/Gemini/tuiles/plume_doree.png")))
	image.centered = false
	add_child(image)
	var lueur := Lumiere.creer(Color(1.0, 0.85, 0.4), 0.45, 0.8)
	lueur.position = Vector2(8, 8)
	add_child(lueur)
	var pulse := create_tween().set_loops()
	pulse.tween_property(image, "modulate", Color(1.35, 1.3, 1.1), 0.6)
	pulse.tween_property(image, "modulate", Color(1, 1, 1), 0.6)
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
