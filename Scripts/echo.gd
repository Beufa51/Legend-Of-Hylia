extends Reflet
class_name Echo
# L'ÉCHO (aile droite, plume D4) : ton ombre violette, que TU enregistres.
#   1er appui sur E : tu poses une BALISE (anneau violet) et tout ce que tu fais est enregistré (jauge autour de tes pieds, 12 s maxi).
#   2e appui sur E  : ton écho apparaît sur la balise et REFAIT TES PAS EN BOUCLE pendant que tu fais autre chose.
#   Un nouvel enregistrement remplace l'ancien écho (c'est au 2e appui que l'ancien disparaît).
# Il traverse tout (c'est un souvenir) ; il appuie sur les boutons `P` et se tient sur les dalles `a` comme toi.
# Si tu t'arrêtes là où tu avais commencé, il reste en place sans interruption (un « poids » sur un bouton).
# Sinon il rejoue le trajet, reste un instant à la fin, s'efface 0,5 s et recommence.

const DUREE_MAX := 12.0    # secondes d'enregistrement
const DUREE_MIN := 0.5     # en dessous, on annule (double appui par erreur)
const PAUSE_FIN := 0.8     # il reste à la fin de son trajet avant de recommencer
const PAUSE_BOUCLE := 0.5  # il est invisible (et n'appuie sur rien) entre deux tours
const CACHE := Vector2(-1000, -1000)
const SON_MAGIE := "res://Assets/Ninja_adventure/Audio/Sounds/Magic & Skill/Magic2.wav"
const SON_REFUS := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Cancel.wav"

static var present := false   # vrai quand une salle d'écho est chargée (le bouton E tactile n'apparaît que là)

enum Etat_echo { REPOS, ENREGISTRE, REJOUE }

var _etat := Etat_echo.REPOS
var _lecture: Array = []      # le trajet que l'écho rejoue
var _piste: Array = []        # [temps, position dans la salle, animation, retournée]
var _t := 0.0                 # temps écoulé (enregistrement ou lecture)
var _i := 0                   # lecture : image courante
var _balise := Vector2.ZERO   # début de l'enregistrement (dans la salle)
var _continu := false         # fin == début : pas d'interruption
var _attente := 0.0           # lecture : temps passé à la fin du trajet
var _marque: Node2D
var _visible := false


func initialiser(une_salle: Room, case_depart: Vector2i, joueur: Node2D, sombre: bool) -> void:
	super(une_salle, case_depart, joueur, sombre)
	present = true
	collision_mask = 0
	var mat := _sprite.material as ShaderMaterial
	mat.set_shader_parameter("couleur_sombre", Vector3(0.22, 0.10, 0.40))
	mat.set_shader_parameter("couleur_claire", Vector3(0.82, 0.62, 1.0))
	mat.set_shader_parameter("couleur_contour", Vector3(0.95, 0.85, 1.0))
	if _lumiere != null:
		_lumiere.color = Color(0.75, 0.5, 1.0)
	_marque = Node2D.new()
	_marque.z_index = 1
	_marque.draw.connect(_dessiner)
	salle.add_child.call_deferred(_marque)
	if not Etat.est("echo_explique"):
		Etat.noter("echo_explique")
		Etat.annoncer("E : pose ton écho. Marche, puis rappuie sur E : il refera tes pas.")


func _exit_tree() -> void:
	present = false


func reinitialiser() -> void:
	_etat = Etat_echo.REPOS
	_piste.clear()
	_lecture.clear()
	_t = 0.0
	_montrer(false)
	velocity = Vector2.ZERO
	if _joueur != null:
		_avant = _joueur.global_position
	if _marque != null:
		_marque.queue_redraw()


func _montrer(oui: bool, avec_souffle := true) -> void:
	_visible = oui
	if _sprite != null:
		_sprite.visible = oui
	if _lumiere != null:
		_lumiere.visible = oui
	if not oui:
		position = CACHE
	elif avec_souffle:
		_sprite.scale = Vector2(0.6, 1.4)
		create_tween().tween_property(_sprite, "scale", Vector2.ONE, 0.25)


func _son(chemin: String, hauteur: float, db: float) -> void:
	if not ResourceLoader.exists(chemin):
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = load(chemin)
	lecteur.pitch_scale = hauteur
	lecteur.volume_db = db
	salle.add_child(lecteur)
	lecteur.finished.connect(lecteur.queue_free)
	lecteur.play()


func _physics_process(delta: float) -> void:
	if salle == null or salle.grille != Etat.salle_courante or delta <= 0.0:
		if _joueur != null:
			_avant = _joueur.global_position
		return
	# le joueur a été téléporté (retour au début, touche R) : on oublie tout
	if (_joueur.global_position - _avant).length() > SAUT_MAXI:
		reinitialiser()
		return
	_avant = _joueur.global_position
	if Input.is_action_just_pressed("echo") and not Etat.en_dialogue:
		if _etat == Etat_echo.ENREGISTRE:
			_arreter()
		else:
			_commencer()
	if _etat == Etat_echo.ENREGISTRE:
		_enregistrer(delta)
	elif _etat == Etat_echo.REJOUE:
		_rejouer(delta)
	_marque.queue_redraw()


# ---------- enregistrement ----------

func _commencer() -> void:
	_etat = Etat_echo.ENREGISTRE
	_piste.clear()
	_t = 0.0
	_balise = _joueur.global_position - salle.global_position
	_son(SON_MAGIE, 1.5, -14.0)


func _enregistrer(delta: float) -> void:
	_t += delta
	var spr: AnimatedSprite2D = _joueur.sprite
	_piste.append([_t, _joueur.global_position - salle.global_position, spr.animation, spr.flip_h])
	if _t >= DUREE_MAX:
		_arreter()


func _arreter() -> void:
	if _t < DUREE_MIN or _piste.size() < 4:
		_piste.clear()   # enregistrement trop court : on garde l'ancien écho s'il existe
		_etat = Etat_echo.REJOUE if not _lecture.is_empty() else Etat_echo.REPOS
		_son(SON_REFUS, 1.0, -12.0)
		return
	_lecture = _piste.duplicate()
	_piste.clear()
	_continu = (_lecture[0][1] as Vector2).distance_to(_lecture[_lecture.size() - 1][1]) < 8.0
	_t = 0.0
	_i = 0
	_attente = 0.0
	_etat = Etat_echo.REJOUE
	_montrer(true)
	position = _lecture[0][1]
	_son(SON_MAGIE, 0.9, -10.0)


# ---------- lecture ----------

func _rejouer(delta: float) -> void:
	var duree: float = _lecture[_lecture.size() - 1][0]
	_t += delta
	if _t <= duree:
		# on avance jusqu'à l'image du moment
		while _i < _lecture.size() - 1 and _lecture[_i + 1][0] <= _t:
			_i += 1
		_poser(_lecture[_i])
		return
	if _continu:
		# fin == début : il reste en place, sans interruption
		_t = 0.0
		_i = 0
		return
	_attente += delta
	if _attente < PAUSE_FIN:
		return
	if _attente < PAUSE_FIN + PAUSE_BOUCLE:
		if _visible:
			_montrer(false)
		return
	# nouveau tour
	_t = 0.0
	_i = 0
	_attente = 0.0
	_montrer(true)
	_poser(_lecture[0])


func _poser(image: Array) -> void:
	if not _visible:
		_montrer(true)
	position = image[1]
	if _sprite.sprite_frames.has_animation(image[2]) and _sprite.animation != image[2]:
		_sprite.play(image[2])
	_sprite.flip_h = image[3]


# ---------- dessin : balise, trajet, jauge ----------

func _dessiner() -> void:
	if not is_physics_processing():
		return
	var violet := Color(0.8, 0.6, 1.0)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
	if _etat == Etat_echo.ENREGISTRE:
		# balise + traînée de ce qui est enregistré + jauge de temps autour des pieds
		_anneau(_balise, 1.0, pulse)
		var dernier := Vector2(-999, -999)
		for p in _piste:
			var pos: Vector2 = p[1] + Vector2(0, 5)
			if pos.distance_to(dernier) >= 6.0:
				dernier = pos
				_marque.draw_circle(pos, 1.1, Color(violet, 0.45))
		var pieds: Vector2 = _joueur.global_position - salle.global_position + Vector2(0, 6)
		var reste := 1.0 - _t / DUREE_MAX
		_marque.draw_arc(pieds, 11.0, -PI / 2, -PI / 2 + TAU * reste, 24, Color(violet, 0.9 if reste > 0.25 else 0.5 + 0.5 * pulse), 1.6)
	elif _etat == Etat_echo.REJOUE and not _lecture.is_empty():
		# la balise (départ) et le trajet qu'il refait, en filigrane
		_anneau(_lecture[0][1], 0.5, pulse)
		var dernier := Vector2(-999, -999)
		for p in _lecture:
			var pos: Vector2 = p[1] + Vector2(0, 5)
			if pos.distance_to(dernier) >= 7.0:
				dernier = pos
				_marque.draw_circle(pos, 1.0, Color(violet, 0.22))


func _anneau(centre: Vector2, force: float, pulse: float) -> void:
	var c := centre + Vector2(0, 6)
	var violet := Color(0.8, 0.6, 1.0)
	_marque.draw_arc(c, 6.5 + pulse, 0, TAU, 20, Color(violet, 0.75 * force), 1.4)
	_marque.draw_arc(c, 3.0, 0, TAU, 12, Color(violet, 0.4 * force), 1.0)


func disparaitre() -> void:
	_etat = Etat_echo.REPOS
	super()
	if _marque != null:
		_marque.queue_free()
		_marque = null
