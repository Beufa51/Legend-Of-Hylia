extends StaticBody2D
class_name Porte
# Une porte fermée. Une seule Porte couvre toutes les cases voisines de sa lettre (`D`, `H` ou `E`).
# Deux façons de la dessiner :
# - ARCHE ANIMÉE (pack donjon Craftpix) : une liste d'images (herse qui se relève, porte de bois qui s'ouvre) ;
#   une fois ouverte, l'arche reste visible (dernière image) ;
# - ANCIENNE GRILLE (une seule image porte_LxH.png, voir Outils/traiter_gemini.py) : elle se relève puis disparaît.
# Une porte À SERRURE (lettre `E`) s'ouvre quand le joueur la touche avec la bonne clé (voir activer_serrure).

const SON_OUVERTURE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact5.wav"
const SON_SERRURE := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Accept.wav"
const SON_REFUS := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Cancel.wav"
const CADENAS := "res://Assets/Gemini/tuiles/cadenas.png"   # Outils/fabriquer_runes_sol.py
const DUREE_ANIMATION := 0.6

var _collision: CollisionShape2D
var _sprite: Sprite2D
var _taille := Vector2.ZERO
var _images: Array[Texture2D] = []   # vide = ancienne grille
var ouverte := false
# Serrure
var _drapeau_cle := ""
var _drapeau_serrure := ""
var _cadenas: Sprite2D   # gros cadenas doré sur la porte : « il faut une clé », sans texte
var _refus_t := 0.0


# `taille` : taille de la porte en pixels (multiple de 16) ; `texture` : son image (fermée) ;
# `images` : les étapes de l'ouverture (arche animée), facultatif.
func initialiser(taille: Vector2, texture: Texture2D, images: Array[Texture2D] = []) -> void:
	_taille = taille
	_images = images
	_sprite = Sprite2D.new()
	_sprite.texture = images[0] if not images.is_empty() else texture
	_sprite.centered = false
	add_child(_sprite)
	var forme := RectangleShape2D.new()
	forme.size = taille
	_collision = CollisionShape2D.new()
	_collision.shape = forme
	_collision.position = taille / 2.0
	add_child(_collision)


# Porte à serrure : quand le joueur la touche, si le drapeau `cle` est levé (il a la clé), le drapeau
# `serrure` est levé (la salle ouvre alors la porte) ; sinon un message.
func activer_serrure(cle: String, serrure: String) -> void:
	_drapeau_cle = cle
	_drapeau_serrure = serrure
	var zone := Area2D.new()
	zone.collision_layer = 0
	zone.collision_mask = 1
	var forme := RectangleShape2D.new()
	forme.size = _taille + Vector2(4, 8)   # un peu plus grande que la porte : le joueur la touche
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = _taille / 2.0 + Vector2(0, 2)
	zone.add_child(collision)
	add_child(zone)
	zone.body_entered.connect(_touchee)
	var tex = load(CADENAS)
	if tex != null:
		_cadenas = Sprite2D.new()
		_cadenas.texture = tex
		_cadenas.position = Vector2(_taille.x / 2.0, _taille.y - 9)   # bas de la porte, au milieu (là où les battants se rejoignent)
		_cadenas.z_index = 1
		add_child(_cadenas)


func _touchee(corps: Node) -> void:
	if ouverte or not corps.is_in_group("joueur"):
		return
	if Etat.est(_drapeau_cle):
		_jouer(SON_SERRURE, -4.0)
		_faire_sauter_cadenas()
		Etat.poser(_drapeau_serrure)
	elif Time.get_ticks_msec() / 1000.0 - _refus_t > 0.8:
		# Pas de clé : le cadenas tremble et claque (aucun texte)
		_refus_t = Time.get_ticks_msec() / 1000.0
		_jouer(SON_REFUS, -6.0)
		if _cadenas != null:
			var x0 := _cadenas.position.x
			var tween := create_tween()
			for dx in [-2.0, 2.0, -1.0, 1.0, 0.0]:
				tween.tween_property(_cadenas, "position:x", x0 + dx, 0.05)


# La clé tourne : le cadenas saute, tournoie et disparaît.
func _faire_sauter_cadenas() -> void:
	if _cadenas == null:
		return
	var c := _cadenas
	_cadenas = null
	var tween := create_tween().set_parallel()
	tween.tween_property(c, "position", c.position + Vector2(10, -6), 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(c, "rotation", 2.5, 0.45)
	tween.chain().tween_property(c, "position:y", c.position.y + 14, 0.25).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(c, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(c.queue_free)


# La porte s'ouvre : elle ne bloque plus. `instantane` : sans bruit ni animation (salle déjà résolue au chargement).
func ouvrir(instantane := false) -> void:
	if ouverte:
		return
	ouverte = true
	_collision.set_deferred("disabled", true)
	if _cadenas != null:   # ouverte au chargement (ou par un autre drapeau) : plus de cadenas
		_cadenas.queue_free()
		_cadenas = null
	if not _images.is_empty():
		if instantane:
			_sprite.texture = _images[-1]
			return
		_secouer_et_sonner()
		# l'arche joue ses images (la herse se relève, les battants s'ouvrent) et reste ouverte
		var tween := create_tween()
		tween.tween_method(func(t: float): _sprite.texture = _images[mini(int(t), _images.size() - 1)],
			0.0, float(_images.size()) - 0.01, DUREE_ANIMATION)
		return
	if instantane:
		queue_free()
		return
	_secouer_et_sonner()
	# Ancienne grille : elle se relève (rétrécit vers le haut, ou vers le côté si elle est haute et étroite)
	var tween := create_tween()
	if _taille.x >= _taille.y:
		tween.tween_property(_sprite, "scale:y", 0.0, 0.7).set_ease(Tween.EASE_IN)
	else:
		tween.tween_property(_sprite, "scale:x", 0.0, 0.7).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func _secouer_et_sonner() -> void:
	Etat.secousse.emit()
	_jouer(SON_OUVERTURE, -2.0)


func _jouer(chemin: String, volume_db: float) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = volume_db
	get_parent().add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
