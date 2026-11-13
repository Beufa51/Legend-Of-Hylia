extends StaticBody2D
class_name Cristal
# Un cristal à frapper avec la lance : il s'allume et lève un drapeau (ouvre une porte, par exemple).
# Image : cristal bleu sur socle de pierre (planche Gemini des plots) ; frappé, il passe à l'orange doré avec un éclat. Il reste allumé.
# Dans une salle à PLOTS (aile droite), c'est un COMMUTATEUR : chaque coup inverse les plots
# orange et bleus, et le cristal prend la couleur des plots levés.

const SON := "res://Assets/Ninja_adventure/Audio/Sounds/Magic & Skill/Magic2.wav"

var drapeau := ""
var texte := ""
var actif := false
var _sprite: Sprite2D
var _halo: PointLight2D       # lueur : douce tant qu'il attend, vive une fois frappé
var _temps := 0.0
var _images := {}             # "bleu" / "orange" -> image du cristal sur son socle (Assets/Gemini/tuiles/cristal_u|o.png)
var _salle: Room = null       # salle à plots : le cristal est un commutateur
var _attente := 0.0           # la lance touche pendant plusieurs images : un seul basculement par coup


func initialiser(nom_drapeau: String, message: String, salle_a_plots: Room = null) -> void:
	_salle = salle_a_plots
	drapeau = nom_drapeau
	texte = message
	add_to_group("frappable")
	# image du cristal sur son socle de pierre (16x18 : on la remonte de 2 px pour que le socle soit sur la case)
	_images["bleu"] = _charger("cristal_u")
	_images["orange"] = _charger("cristal_o")
	_sprite = Sprite2D.new()
	_sprite.texture = _images["bleu"]
	_sprite.centered = false
	_sprite.position = Vector2(0, -2)
	add_child(_sprite)
	_halo = Lumiere.creer(Color(0.45, 0.7, 1.0), 0.55, 0.5)
	_halo.position = Vector2(8, 5)
	add_child(_halo)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(12, 14)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)


func _process(delta: float) -> void:
	_attente = maxf(0.0, _attente - delta)
	_temps += delta
	if not actif:   # en attente : le cristal respire doucement (« frappe-moi »)
		var v := 0.5 + 0.5 * sin(_temps * 3.0)
		_sprite.modulate = Color(1.0 + 0.25 * v, 1.0 + 0.25 * v, 1.0 + 0.25 * v)
		_halo.energy = 0.35 + 0.35 * v


func _charger(nom: String) -> Texture2D:
	var chemin := "res://Assets/Gemini/tuiles/%s.png" % nom
	if ResourceLoader.exists(chemin):
		return load(chemin)
	return ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(chemin)))


# Couleur du commutateur : celle des plots levés.
func colorer(orange_leves: bool) -> void:
	_sprite.texture = _images["orange" if orange_leves else "bleu"]
	_halo.color = Color(1.0, 0.62, 0.25) if orange_leves else Color(0.45, 0.7, 1.0)


# Appelé par la lance.
func frapper() -> void:
	if _salle != null:   # commutateur des plots
		if _attente > 0.0:
			return
		_attente = 0.45
		_jouer_son()
		_salle.basculer_plots()
		return
	if actif:
		return
	actif = true
	_sprite.texture = _images["orange"]   # allumé : il passe à l'orange doré
	_halo.color = Color(1.0, 0.75, 0.3)
	_halo.energy = 1.0
	_halo.texture_scale = 1.1
	_sprite.modulate = Color(2.5, 2.2, 1.6)   # éclat blanc au moment du coup...
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.5)   # ...qui retombe
	_jouer_son()
	Etat.poser(drapeau)
	if texte != "":
		Etat.annoncer(texte)


func _jouer_son() -> void:
	var flux = load(SON)
	if flux != null:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		lecteur.volume_db = -3.0
		get_parent().add_child(lecteur)
		lecteur.play()
		lecteur.finished.connect(lecteur.queue_free)
