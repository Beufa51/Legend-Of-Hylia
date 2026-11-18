extends StaticBody2D
class_name Sablier
## LE SABLIER (lettre `h`, plume D4 de l'aile droite) : un coup de lance le RETOURNE.
##   1er coup : il RETIENT L'INSTANT. Une copie violette de chaque bloc reste à sa place, les plots qui changeront
##              sont cerclés de violet, et le sable se met à couler (`duree` secondes).
##   Quand le sable est écoulé (ou si on le frappe à nouveau) : TOUT REVIENT À CET INSTANT (blocs, plots, trous)...
##              sauf toi : tu restes là où tu es. C'est toute l'astuce.
## La salle (Room) fait le travail : marquer_temps(), rembobiner(). Le sablier ne gère que son image, ses sons et le compte à rebours.
## Images : Assets/Gemini/tuiles/sablier_1..5.png (Outils/traiter_sablier.py) : 1 repos, 2 moitié, 3 frappé, 4 rembobine, 5 éteint.

enum { REPOS, COULE, REMBOBINE, ENDORMI }

const SON_RETIENT := "res://Assets/Ninja_adventure/Audio/Sounds/Magic & Skill/Magic3.wav"
const SON_TIC := "res://Assets/Sons/tic.wav"
const SON_REMBOBINE := "res://Assets/Sons/rembobine.wav"
const VIOLET := Color(0.78, 0.42, 1.0)

var salle: Node2D
var etat := REPOS
var duree := 8.0
var _reste := 0.0
var _images: Array[Texture2D] = []
var _sprite: Sprite2D
var _halo: PointLight2D
var _anneau: Node2D           # le compte à rebours : un anneau violet qui se vide autour du socle
var _attente := 0.0           # la lance touche pendant plusieurs images : un seul effet par coup
var _temps := 0.0
var _prochain_tic := 0.0


func initialiser(une_salle: Node2D, images: Array[Texture2D], duree_sable: float) -> void:
	salle = une_salle
	_images = images
	duree = duree_sable
	add_to_group("frappable")
	_anneau = Node2D.new()
	_anneau.position = Vector2(8, 13)
	_anneau.draw.connect(_dessiner_anneau)
	add_child(_anneau)
	_sprite = Sprite2D.new()
	_sprite.texture = images[0]
	_sprite.centered = false
	_sprite.position = Vector2(0, 16 - images[0].get_height())   # le socle sur la case, le verre dépasse vers le haut
	add_child(_sprite)
	_halo = Lumiere.creer(VIOLET, 0.35, 0.55)
	_halo.position = Vector2(8, -6)
	add_child(_halo)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(14, 14)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)


func _process(delta: float) -> void:
	_attente = maxf(0.0, _attente - delta)
	_temps += delta
	match etat:
		REPOS:   # il attend : le sable violet luit doucement (« frappe-moi »)
			var v := 0.5 + 0.5 * sin(_temps * 2.6)
			_sprite.modulate = Color(1.0 + 0.15 * v, 1.0 + 0.1 * v, 1.0 + 0.2 * v)
			_halo.energy = 0.25 + 0.25 * v
		COULE:
			_reste -= delta
			_sprite.texture = _images[0] if _reste > duree * 0.5 else _images[1]
			# tic-tac : de plus en plus serré à la fin
			_prochain_tic -= delta
			if _prochain_tic <= 0.0:
				_prochain_tic = 1.0 if _reste > 2.5 else (0.5 if _reste > 1.0 else 0.25)
				_jouer(SON_TIC, -12.0 if _reste > 2.5 else -8.0, 1.0 if _reste > 2.5 else 1.25)
			var urgence := 1.0 - clampf(_reste / 2.5, 0.0, 1.0)
			_halo.energy = 0.6 + 0.5 * urgence * (0.5 + 0.5 * sin(_temps * 18.0))
			_anneau.queue_redraw()
			if _reste <= 0.0:
				salle.rembobiner()


## Appelé par la lance.
func frapper() -> void:
	if _attente > 0.0 or etat == REMBOBINE or etat == ENDORMI:
		return
	_attente = 0.45
	if etat == REPOS:
		_retenir()
	elif etat == COULE:
		salle.rembobiner()   # frappé pendant que le sable coule : on remonte le temps tout de suite


func _retenir() -> void:
	etat = COULE
	_reste = duree
	_prochain_tic = 1.0
	_jouer(SON_RETIENT, -4.0, 0.8)
	_sprite.texture = _images[2]   # l'éclair violet
	_sprite.modulate = Color(1, 1, 1)
	var t := create_tween()
	t.tween_property(_sprite, "scale", Vector2(1.15, 0.9), 0.06)
	t.tween_property(_sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(0.25).timeout
	if etat == COULE:
		_sprite.texture = _images[0]
	salle.marquer_temps()


## La salle remonte le temps : le sable remonte (image 4), puis le sablier revient au repos.
func remonter() -> void:
	etat = REMBOBINE
	_anneau.queue_redraw()
	_jouer(SON_REMBOBINE, -3.0, 1.0)
	_sprite.texture = _images[3]
	_halo.energy = 1.4
	var t := create_tween()
	t.tween_property(_sprite, "modulate", Color(1.6, 1.2, 1.9), 0.15)
	t.tween_property(_sprite, "modulate", Color(1, 1, 1), 0.7)
	await get_tree().create_timer(0.9).timeout
	if etat == REMBOBINE:
		etat = REPOS
		_sprite.texture = _images[0]


## Remise à zéro (touche R, retour dans la salle) : le sablier se rendort au repos, sans rien rembobiner.
func annuler() -> void:
	if etat == ENDORMI:
		return
	etat = REPOS
	_sprite.texture = _images[0]
	_anneau.queue_redraw()


## Salle réussie : le sable s'éteint, le sablier ne sert plus.
func endormir() -> void:
	etat = ENDORMI
	remove_from_group("frappable")
	_sprite.texture = _images[4]
	_sprite.modulate = Color(1, 1, 1)
	_halo.energy = 0.0
	_anneau.queue_redraw()


func en_cours() -> bool:
	return etat == COULE


func _dessiner_anneau() -> void:
	if etat != COULE:
		return
	# ellipse au sol (vue de 3/4) : la part restante du sable, qui se vide dans le sens des aiguilles d'une montre
	var part := clampf(_reste / duree, 0.0, 1.0)
	var points := PackedVector2Array()
	var n := int(40 * part) + 2
	for i in n:
		var a := -PI / 2.0 + TAU * part * float(i) / float(n - 1)
		points.append(Vector2(cos(a) * 11.0, sin(a) * 5.0))
	_anneau.draw_polyline(points, Color(VIOLET, 0.35), 4.0)
	_anneau.draw_polyline(points, Color(1.0, 0.85, 1.0, 0.95), 1.5)


func _jouer(chemin: String, volume_db: float, hauteur: float) -> void:
	if not ResourceLoader.exists(chemin) and not FileAccess.file_exists(chemin):
		return
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = volume_db
	lecteur.pitch_scale = hauteur
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
