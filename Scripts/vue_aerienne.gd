class_name VueAerienne
extends RefCounted
## Cinématique de fin d'aile : en sortant du donjon, on voit du ciel le plan des salles parcourues, qui forme une AILE ;
## les 5 plumes s'allument en or une à une, dans l'ordre où on les a gagnées. (L'aile seule : le corps du coq et l'assemblage
## sont gardés pour la grande cinématique du parvis.) Sorti de world.gd pour l'alléger.
## Utilisation : await VueAerienne.new(self).jouer("gauche")   (self = le Node `world`)
## Les constantes (CIEL_*, PIVOTS, sons...) et les petits outils (_sprite, _texture, _jouer_son) restent dans world.gd.

var monde: Node


func _init(le_monde: Node) -> void:
	monde = le_monde


# Fabrique le plan du donjon vu du ciel : 1 pixel par case, sol clair, murs sombres (seulement
# les murs proches d'un sol, pour que la FORME des salles se voie), transparent autour.
# Renvoie {"carte": texture, "contour": texture (lisere doré de la silhouette), "plumes": 5 textures (le sol de chaque plume en or),
# "coin": case (0,0) de la grille sur l'image}.
func _plan_vu_du_ciel() -> Dictionary:
	var salles: Array[Room] = []
	var bas := Vector2i(1000, 1000)    # plus petite case de la grille
	var haut := Vector2i(-1000, -1000) # plus grande case de la grille
	for enfant in monde.get_children():
		if enfant is Room:   # (chaque aile est dans sa propre scène : toutes les salles en font partie)
			salles.append(enfant)
			bas = Vector2i(mini(bas.x, enfant.grille.x), mini(bas.y, enfant.grille.y))
			haut = Vector2i(maxi(haut.x, enfant.grille.x), maxi(haut.y, enfant.grille.y))
	var cases := Vector2i(25, 14)   # cases par salle
	var plume_de_salle := func(salle: Room) -> int:   # 1..5 si la salle est un écran de plume (colonne = numéro, au-dessus de l'épine), sinon 0
		return absi(salle.grille.x) if salle.grille.y < 0 and absi(salle.grille.x) >= 1 and absi(salle.grille.x) <= 5 else 0
	var marge := 4
	var taille := (haut - bas + Vector2i.ONE) * cases + Vector2i(marge, marge) * 2
	# 1 = sol, 2 = mur
	var plan := PackedByteArray()
	plan.resize(taille.x * taille.y)
	for salle in salles:
		var base := (salle.grille - bas) * cases + Vector2i(marge, marge)
		for y in salle.layout.size():
			for x in salle.layout[y].length():
				if not "#R".contains(salle.layout[y][x]):
					plan[(base.y + y) * taille.x + base.x + x] = 1
	for y in taille.y:
		for x in taille.x:
			if plan[y * taille.x + x] == 0 and _voisin(plan, taille, x, y, 2, 1):
				plan[y * taille.x + x] = 2
	var carte := Image.create(taille.x, taille.y, false, Image.FORMAT_RGBA8)
	var contour := Image.create(taille.x, taille.y, false, Image.FORMAT_RGBA8)
	for y in taille.y:
		for x in taille.x:
			var v := plan[y * taille.x + x]
			if v == 1:
				carte.set_pixel(x, y, monde.CIEL_SOL)
			elif v == 2:
				carte.set_pixel(x, y, monde.CIEL_MUR)
			elif _voisin(plan, taille, x, y, 1, 2):   # le reste est transparent (on voit l'herbe dessous)
				contour.set_pixel(x, y, monde.CIEL_OR)
	# Le sol de chaque plume en or (une image par plume : elles s'allument l'une après l'autre)
	var or_clair := Color(monde.CIEL_OR.r, monde.CIEL_OR.g, monde.CIEL_OR.b, 0.92)
	var plumes: Array[Texture2D] = []
	for n in range(1, 6):
		var img := Image.create(taille.x, taille.y, false, Image.FORMAT_RGBA8)
		for salle in salles:
			if plume_de_salle.call(salle) != n:
				continue
			var base := (salle.grille - bas) * cases + Vector2i(marge, marge)
			for y in salle.layout.size():
				for x in salle.layout[y].length():
					if not "#R".contains(salle.layout[y][x]):
						img.set_pixel(base.x + x, base.y + y, or_clair)
		plumes.append(ImageTexture.create_from_image(img))
	return {
		"plumes": plumes,
		"carte": ImageTexture.create_from_image(carte),
		"contour": ImageTexture.create_from_image(contour),
		"coin": Vector2(-bas * cases + Vector2i(marge, marge)),
		"taille": Vector2(taille),
	}


# Y a-t-il une case de valeur `valeur` à moins de `rayon` cases de (x, y) ?
func _voisin(plan: PackedByteArray, taille: Vector2i, x: int, y: int, rayon: int, valeur: int) -> bool:
	for dy in range(-rayon, rayon + 1):
		for dx in range(-rayon, rayon + 1):
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and ny >= 0 and nx < taille.x and ny < taille.y and plan[ny * taille.x + nx] == valeur:
				return true
	return false


const SON_NOTE := "res://Assets/Ninja_adventure/Audio/Sounds/Bonus/Coin.wav"
const NOTES := [0.6, 0.675, 0.75, 0.9, 1.0]   # une note de plus en plus haute par plume (gamme des cloches)


func _note(hauteur: float) -> void:
	var flux = load(SON_NOTE)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.pitch_scale = hauteur
	monde.add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)


func jouer(aile_vue: String) -> void:
	if monde.en_transition:
		return
	monde.en_transition = true
	Etat.noter("vue_aerienne_" + aile_vue)
	monde._hud.visible = false
	monde.joueur.set_physics_process(false)
	monde.joueur.velocity = Vector2.ZERO

	# 1) Fondu au noir ; pendant ce temps, on fabrique le plan vu du ciel
	monde._jouer_son(monde.SON_ENVOL)
	var t := monde.create_tween()
	t.tween_property(monde._fondu, "modulate:a", 1.0, 0.6)
	if monde._musique:
		t.parallel().tween_property(monde._musique, "volume_db", -40.0, 0.6)
	await t.finished
	var plan := _plan_vu_du_ciel()
	var calque := CanvasLayer.new()
	calque.layer = 2
	monde.add_child(calque)
	var herbe := ColorRect.new()
	herbe.color = monde.CIEL_HERBE
	herbe.size = Vector2(monde.TAILLE_SALLE)
	calque.add_child(herbe)
	# Le plan de l'aile, centré à l'écran, d'abord éteint
	var zoom := 1.6
	var carte: Sprite2D = monde._sprite(plan["carte"], (Vector2(monde.TAILLE_SALLE) - plan["taille"] * zoom) / 2.0, calque)
	carte.scale = Vector2(zoom, zoom)
	carte.modulate = Color(0.55, 0.55, 0.68)
	var lisere: Sprite2D = monde._sprite(plan["contour"], Vector2.ZERO, carte)
	lisere.modulate.a = 0.0
	var plumes: Array[Sprite2D] = []
	for texture in plan["plumes"]:
		var plume: Sprite2D = monde._sprite(texture, Vector2.ZERO, carte)
		plume.modulate.a = 0.0
		plumes.append(plume)
	# Le joueur : un point qui clignote, à la sortie du vestibule
	var racine: Vector2 = plan["coin"] + Vector2(12.5, 7)
	var point := ColorRect.new()
	point.color = Color(1.0, 0.25, 0.2)
	point.size = Vector2(2, 2)
	point.position = plan["coin"] + Vector2(11.5, 14 + 13)
	carte.add_child(point)
	var clignote := monde.create_tween().set_loops()
	clignote.tween_property(point, "modulate:a", 0.2, 0.3)
	clignote.tween_property(point, "modulate:a", 1.0, 0.3)
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.95, 0.8)
	flash.size = Vector2(monde.TAILLE_SALLE)
	flash.modulate.a = 0.0
	calque.add_child(flash)

	# 2) Vu du ciel : le plan des salles apparaît (éteint)
	t = monde.create_tween()
	t.tween_property(monde._fondu, "modulate:a", 0.0, 1.0)
	await t.finished
	await monde.get_tree().create_timer(1.2).timeout

	# 3) Les 5 plumes s'allument en or, une à une, dans l'ordre de l'aile : une note de plus en plus haute chacune
	for n in plumes.size():
		_note(NOTES[n])
		t = monde.create_tween()
		t.tween_property(plumes[n], "modulate:a", 1.0, 0.35)
		flash.modulate.a = 0.12
		t.parallel().tween_property(flash, "modulate:a", 0.0, 0.35)
		await monde.get_tree().create_timer(0.8).timeout

	# 4) L'aile entière : liseré doré qui pulse, jingle, éclat
	clignote.kill()
	point.visible = false
	monde._jouer_son(monde.JINGLE_BLASON, -2.0)
	flash.modulate.a = 0.5
	t = monde.create_tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.7)
	t.parallel().tween_property(lisere, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property(carte, "modulate", Color(1.15, 1.1, 1.0), 0.7)
	var pulse := monde.create_tween().set_loops()
	pulse.tween_property(lisere, "modulate", Color(1.5, 1.4, 1.0), 0.5)
	pulse.tween_property(lisere, "modulate", Color(1, 1, 1), 0.5)
	await monde.get_tree().create_timer(3.4).timeout

	# 5) Fondu au noir, retour au village devant l'entrée de la Forteresse
	pulse.kill()
	t = monde.create_tween()
	t.tween_property(monde._fondu, "modulate:a", 1.0, 0.6)
	await t.finished
	calque.queue_free()
	monde._changer_de_scene("@village:" + monde._temple(), Vector2i(12, 12), "Tu ressors de la Forteresse avec le symbole de l'aile. Les stèles du parvis l'attendent !")
