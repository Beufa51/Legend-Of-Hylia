extends StaticBody2D
class_name Chanteur
# La statue du coq chanteur (lettre C du plan) : quand on la frappe avec la lance,
# elle "chante" la mélodie de la salle, et chaque cloche s'illumine quand sa note passe.

var salle: Node2D
var _sprite: Sprite2D
var _lumiere: PointLight2D
var _dernier_coup := -1000
var _disque: Node2D            # disque solaire derrière la tête (seulement si la statue attend le soleil)
var _temps := 0.0
var _au_soleil := false
var _img_disque: Sprite2D      # disque Gemini (Outils/traiter_disque.py) ; sans images, repli : disque dessiné en code
var _tex_eteint: Texture2D
var _tex_allume: Texture2D


func initialiser(une_salle: Node2D, texture: Texture2D, dans_le_noir: bool) -> void:
	salle = une_salle
	add_to_group("frappable")
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.centered = false
	_sprite.position = Vector2(-3, 16 - 34)   # l'image fait 22x34 px : posée sur sa case
	add_child(_sprite)
	_lumiere = Lumiere.creer(Color(1.0, 0.6, 0.5), 0.7, 0.4 if dans_le_noir else 0.0)
	_lumiere.position = Vector2(8, 0)
	add_child(_lumiere)
	# Collision sur TOUTE la statue (sa case + sa tête qui dépasse au-dessus) :
	# on peut la frapper par le bas, par les côtés ou par le haut.
	var forme := RectangleShape2D.new()
	forme.size = Vector2(16, 30)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 0)
	add_child(collision)


func frapper() -> void:
	var maintenant := Time.get_ticks_msec()
	if maintenant - _dernier_coup < 400:
		return
	_dernier_coup = maintenant
	# Petit sursaut de la statue, puis la salle joue la mélodie (si elle le peut)
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", 16 - 34 - 3, 0.08)
	tween.tween_property(_sprite, "position:y", 16 - 34, 0.1)
	salle.statue_frappee()


# La statue ne chante qu'au soleil (salle 5e) : un HALO SOLAIRE éteint (bronze terne) entoure sa tête,
# comme les réceptacles des autres salles : le joueur comprend que le rayon doit venir ici.
func attendre_soleil(eteinte: Texture2D = null, allumee: Texture2D = null) -> void:
	_tex_eteint = eteinte
	_tex_allume = allumee
	_disque = Node2D.new()
	_disque.position = Vector2(8, -27)   # au-dessus de la tête : le disque dépasse de la statue (avant il était caché derrière)
	_disque.draw.connect(_dessiner_halo)
	add_child(_disque)
	move_child(_disque, 0)   # derrière la statue
	if _tex_eteint != null and _tex_allume != null:
		_img_disque = Sprite2D.new()
		_img_disque.texture = _tex_eteint
		_disque.add_child(_img_disque)


func _dessiner_halo() -> void:
	if _img_disque != null:
		return
	var centre := Vector2.ZERO
	if _au_soleil:
		for i in 12:   # rayons dorés
			var a := TAU * i / 12.0 + _temps * 0.6
			_disque.draw_line(centre + Vector2.from_angle(a) * 9.0, centre + Vector2.from_angle(a) * (13.0 if i % 2 == 0 else 11.0), Color(1.0, 0.85, 0.35, 0.9), 1.5)
		_disque.draw_circle(centre, 9.0, Color(1.0, 0.78, 0.25))
		_disque.draw_circle(centre, 6.5, Color(1.0, 0.93, 0.6))
	else:
		for i in 8:    # rayons éteints, courts
			var a := TAU * i / 8.0
			_disque.draw_line(centre + Vector2.from_angle(a) * 9.0, centre + Vector2.from_angle(a) * 11.0, Color(0.55, 0.42, 0.22, 0.8), 1.0)
		_disque.draw_circle(centre, 9.0, Color(0.22, 0.18, 0.14))
		_disque.draw_circle(centre, 8.0, Color(0.5, 0.38, 0.18))
		_disque.draw_circle(centre, 6.0, Color(0.36, 0.27, 0.13))


# Le rayon arrive (ou repart) : le halo s'allume, la statue se dresse un instant.
func soleil(allume: bool) -> void:
	_au_soleil = allume
	if _disque == null:
		return
	_disque.modulate = Color.WHITE
	if _img_disque != null:
		_img_disque.texture = _tex_allume if allume else _tex_eteint
	_disque.queue_redraw()
	_lumiere.energy = 0.9 if allume else 0.0
	if allume:
		var tween := create_tween()
		_disque.scale = Vector2.ONE * 1.5
		tween.tween_property(_disque, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
		tween.parallel().tween_property(_sprite, "position:y", 16 - 34 - 4, 0.12)
		tween.tween_property(_sprite, "position:y", 16 - 34, 0.2)


# Frappée sans soleil : le halo vacille, comme une braise qui cherche la lumière.
func reclamer_soleil() -> void:
	if _disque == null:
		return
	var tween := create_tween()
	for i in 3:
		tween.tween_property(_disque, "modulate", Color(2.0, 1.6, 0.8), 0.07)
		tween.tween_property(_disque, "modulate", Color.WHITE, 0.1)


# Éteint : le halo respire doucement ; allumé : ses rayons tournent lentement.
func _process(delta: float) -> void:
	if _disque == null:
		return
	_temps += delta
	if _au_soleil:
		if _img_disque != null:
			_img_disque.rotation = _temps * 0.35   # les rayons d'or tournent lentement
		_disque.queue_redraw()
	else:
		var p := 0.5 + 0.5 * sin(_temps * 3.0)
		_disque.self_modulate = Color(1.0 + 0.6 * p, 1.0 + 0.45 * p, 1.0 + 0.1 * p)
