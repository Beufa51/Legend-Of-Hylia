extends Reflet
class_name Echo
# L'ÉCHO (aile droite, plume D4) : une ombre violette du héros qui REFAIT EXACTEMENT ses gestes avec RETARD_ECHO secondes de retard.
# Il part de la case `e` (là où le joueur entre), traverse tout (c'est un souvenir : rien ne l'arrête) et appuie sur les boutons `P`
# et les dalles `a` comme le joueur. Une traînée de petits points montre le chemin qu'il va suivre (ce que tu viens de faire).
# Le principe : tu poses ton écho sur un bouton... et pendant qu'il le tient, toi tu passes.

const RETARD_ECHO := 2.0
const CACHE := Vector2(-1000, -1000)   # tant que l'écho n'est pas apparu, il n'appuie sur rien

var _historique: Array = []   # [temps, position dans la salle, animation, retournée]
var _temps := 0.0
var _visible := false
var _trace: Node2D


func initialiser(une_salle: Room, case_depart: Vector2i, joueur: Node2D, sombre: bool) -> void:
	super(une_salle, case_depart, joueur, sombre)
	collision_mask = 0            # un souvenir ne se cogne à rien
	var mat := _sprite.material as ShaderMaterial
	mat.set_shader_parameter("couleur_sombre", Vector3(0.22, 0.10, 0.40))
	mat.set_shader_parameter("couleur_claire", Vector3(0.82, 0.62, 1.0))
	mat.set_shader_parameter("couleur_contour", Vector3(0.95, 0.85, 1.0))
	if _lumiere != null:
		_lumiere.color = Color(0.75, 0.5, 1.0)
	# la traînée : le chemin que l'écho va suivre (dessinée dans le repère de la salle)
	_trace = Node2D.new()
	_trace.z_index = 1
	_trace.draw.connect(_dessiner_trace)
	salle.add_child.call_deferred(_trace)


func reinitialiser() -> void:
	_historique.clear()
	_temps = 0.0
	_montrer(false)
	velocity = Vector2.ZERO
	if _joueur != null:
		_avant = _joueur.global_position
	if _trace != null:
		_trace.queue_redraw()


func _montrer(oui: bool) -> void:
	_visible = oui
	if _sprite != null:
		_sprite.visible = oui
	if _lumiere != null:
		_lumiere.visible = oui
	if not oui:
		position = CACHE
	else:
		# il apparaît dans un petit souffle
		_sprite.scale = Vector2(0.6, 1.4)
		create_tween().tween_property(_sprite, "scale", Vector2.ONE, 0.25)


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
	_temps += delta
	var spr: AnimatedSprite2D = _joueur.sprite
	_historique.append([_temps, _joueur.global_position - salle.global_position, spr.animation, spr.flip_h])
	# on rejoue ce que le joueur faisait il y a RETARD_ECHO secondes
	var etat = null
	while not _historique.is_empty() and _historique[0][0] <= _temps - RETARD_ECHO:
		etat = _historique.pop_front()
	if etat != null:
		if not _visible:
			_montrer(true)
		position = etat[1]
		if _sprite.sprite_frames.has_animation(etat[2]) and _sprite.animation != etat[2]:
			_sprite.play(etat[2])
		_sprite.flip_h = etat[3]
	_trace.queue_redraw()


# Petits points violets sur le chemin que l'écho va suivre (un tous les ~6 px), de plus en plus pâles vers le joueur.
func _dessiner_trace() -> void:
	if not is_physics_processing() or _historique.is_empty():
		return
	var dernier := Vector2(-999, -999)
	var n := _historique.size()
	for i in n:
		var p: Vector2 = _historique[i][1] + Vector2(0, 5)
		if p.distance_to(dernier) < 6.0:
			continue
		dernier = p
		var a := 0.55 * (1.0 - float(i) / n) + 0.12
		_trace.draw_circle(p, 1.2, Color(0.8, 0.6, 1.0, a))


func disparaitre() -> void:
	super()
	if _trace != null:
		_trace.queue_free()
		_trace = null
