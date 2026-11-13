extends StaticBody2D
class_name Coffre
# Un COFFRE (lettre `Q`) : un coup de lance l'ouvre (animation du pack donjon Craftpix). Il lève son
# drapeau (ex. une clé : la porte à serrure `E` qui attend ce drapeau pourra s'ouvrir) et l'objet trouvé
# s'élève au-dessus du coffre. Déjà ouvert (partie sauvegardée) : il reste ouvert et vide.

const SON := "res://Assets/Ninja_adventure/Audio/Sounds/Bonus/PowerUp1.wav"
const DECALAGE := Vector2(-2, -6)   # image 20x22 : la case 16x16 est en bas au centre

var drapeau := ""
var texte := ""
var _sprite: Sprite2D
var _images: Array[Texture2D] = []
var _objet: Texture2D
var ouvert := false


func initialiser(nom_drapeau: String, message: String, images: Array[Texture2D], objet: Texture2D) -> void:
	drapeau = nom_drapeau
	texte = message
	_images = images
	_objet = objet
	add_to_group("frappable")
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.position = DECALAGE
	_sprite.texture = images[0]
	add_child(_sprite)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(14, 12)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 9)
	add_child(collision)
	if Etat.est(drapeau):
		ouvert = true
		_sprite.texture = images[-1]


# Appelé par la lance.
func frapper() -> void:
	if ouvert:
		return
	ouvert = true
	var flux = load(SON)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		lecteur.volume_db = -4.0
		add_child(lecteur)
		lecteur.play()
	var tween := create_tween()
	tween.tween_method(func(t: float): _sprite.texture = _images[mini(int(t), _images.size() - 1)], 0.0, float(_images.size()) - 0.01, 0.4)
	# L'objet trouvé monte au-dessus du coffre, brille un instant, puis disparaît
	if _objet != null:
		var objet := Sprite2D.new()
		objet.texture = _objet
		objet.position = Vector2(8, 0)
		objet.z_index = 2
		add_child(objet)
		var t2 := create_tween()
		t2.tween_property(objet, "position", Vector2(8, -14), 0.5)
		t2.tween_interval(1.0)
		t2.tween_property(objet, "modulate:a", 0.0, 0.3)
		t2.tween_callback(objet.queue_free)
	Etat.poser(drapeau)
	if texte != "":
		Etat.annoncer(texte % Etat.nombre_insignes() if "%d" in texte else texte)   # (%d = nombre d'insignes de la Garde trouvés)
