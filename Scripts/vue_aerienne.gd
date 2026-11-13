class_name VueAerienne
extends RefCounted
## Cinématique de fin d'aile : en sortant du donjon, on voit du ciel que le plan des salles forme une aile,
## qui pivote et s'emboîte sur le corps du donjon. Sorti de world.gd pour l'alléger.
## Utilisation : await VueAerienne.new(self).jouer("gauche")   (self = le Node `world`)
## Les constantes (CIEL_*, PIVOTS, sons...) et les petits outils (_sprite, _texture, _jouer_son) restent dans world.gd.

var monde: Node


func _init(le_monde: Node) -> void:
	monde = le_monde


# Fabrique le plan du donjon vu du ciel : 1 pixel par case, sol clair, murs sombres (seulement
# les murs proches d'un sol, pour que la FORME des salles se voie), transparent autour.
# Renvoie {"carte": texture, "contour": texture (lisere doré de la silhouette), "coin": case (0,0) de la grille sur l'image}.
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
	return {
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


func jouer(aile_vue: String) -> void:
	if monde.en_transition:
		return
	monde.en_transition = true
	Etat.noter("vue_aerienne_" + aile_vue)
	monde._hud.visible = false
	monde.joueur.set_physics_process(false)
	monde.joueur.velocity = Vector2.ZERO
	var droite := aile_vue == "droite"

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
	# Le corps du donjon (le grand blason de pierre), invisible au début
	var origine: Vector2 = monde.CENTRE_BLASON - monde.TAILLE_BLASON / 2.0
	var socle: Sprite2D = monde._sprite(monde._texture(monde.DOSSIER_BLASON + "blason_socle.png"), origine, calque)
	socle.modulate.a = 0.0
	if Etat.est("fragment_" + ("gauche" if droite else "droite")):
		monde._sprite(monde._texture(monde.DOSSIER_BLASON + "blason_aile_" + ("gauche" if droite else "droite") + ".png"), Vector2.ZERO, socle)
	# Le plan de l'aile : son point d'accroche (pivot) = le centre de l'Entrée (racine de l'aile)
	var racine: Vector2 = plan["coin"] + Vector2(12.5, 7)
	var carte: Sprite2D = monde._sprite(plan["carte"], Vector2.ZERO, calque)
	carte.offset = -racine
	var zoom := 1.6
	carte.scale = Vector2(zoom, zoom)
	carte.position = Vector2(monde.TAILLE_SALLE) / 2.0 + (racine - plan["taille"] / 2.0) * zoom   # plan centré à l'écran
	var lisere: Sprite2D = monde._sprite(plan["contour"], Vector2.ZERO, carte)
	lisere.offset = -racine
	lisere.modulate.a = 0.0
	# Le joueur : un point qui clignote, à la sortie du vestibule
	var point := ColorRect.new()
	point.color = Color(1.0, 0.25, 0.2)
	point.size = Vector2(2, 2)
	point.position = plan["coin"] + Vector2(11.5, 14 + 13) - racine
	carte.add_child(point)
	var clignote := monde.create_tween().set_loops()
	clignote.tween_property(point, "modulate:a", 0.2, 0.3)
	clignote.tween_property(point, "modulate:a", 1.0, 0.3)
	# L'aile du blason (rouge), qui remplacera le plan une fois emboîtée
	var pivot: Vector2 = monde.PIVOTS[aile_vue]
	var aile: Sprite2D = monde._sprite(monde._texture(monde.DOSSIER_BLASON + "blason_aile_" + aile_vue + ".png"), origine, calque)
	aile.modulate.a = 0.0
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.95, 0.8)
	flash.size = Vector2(monde.TAILLE_SALLE)
	flash.modulate.a = 0.0
	calque.add_child(flash)

	# 2) Vu du ciel : on découvre le plan des salles parcourues
	t = monde.create_tween()
	t.tween_property(monde._fondu, "modulate:a", 0.0, 1.0)
	await t.finished
	Etat.annoncer("Vu du ciel, les salles que tu as parcourues dessinent...")
	await monde.get_tree().create_timer(2.6).timeout
	monde._jouer_son(monde.SON_REVELATION)
	t = monde.create_tween()
	t.tween_property(lisere, "modulate:a", 1.0, 0.5)
	Etat.annoncer("... une AILE ! L'entrée en est la racine, chaque plume en est une plume.")
	var pulse := monde.create_tween().set_loops()
	pulse.tween_property(lisere, "modulate", Color(1.5, 1.4, 1.0), 0.5)
	pulse.tween_property(lisere, "modulate", Color(1, 1, 1), 0.5)
	await monde.get_tree().create_timer(3.2).timeout

	# 3) On prend de la hauteur : le corps du donjon apparaît, l'aile s'en approche (encore à la verticale)
	var accroche: Vector2 = origine + pivot   # où la racine de l'aile s'emboîte sur le corps
	var petit := 0.62
	t = monde.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(carte, "scale", Vector2(petit, petit), 1.6)
	t.parallel().tween_property(carte, "position", accroche + Vector2(18 if droite else -18, 22), 1.6)
	t.parallel().tween_property(socle, "modulate:a", 1.0, 1.6)
	Etat.annoncer("... et elle doit rejoindre le corps du donjon.")
	await t.finished
	await monde.get_tree().create_timer(0.6).timeout

	# 4) L'aile pivote d'un quart de tour autour de sa racine et s'emboîte
	monde._jouer_son(monde.SON_PIVOT)
	t = monde.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(carte, "rotation", PI / 2 if droite else -PI / 2, 1.2)
	# en pivotant, le plan prend la forme de l'aile du blason (plus court le long de l'épine, plumes plus longues)
	t.parallel().tween_property(carte, "scale", monde.ECHELLE_AILE, 1.2)
	t.parallel().tween_property(carte, "position", accroche, 1.2)
	await t.finished

	# 5) Clac ! Éclair, secousse : le plan devient l'aile rouge du blason
	clignote.kill()
	pulse.kill()
	monde._jouer_son(monde.SON_EMBOITE)
	monde._jouer_son(monde.JINGLE_BLASON, -2.0)
	flash.modulate.a = 0.85
	t = monde.create_tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.6)
	t.parallel().tween_property(carte, "modulate:a", 0.0, 0.8)
	t.parallel().tween_property(aile, "modulate:a", 1.0, 0.8)
	var secousse := monde.create_tween()
	for i in 6:
		secousse.tween_property(calque, "offset", Vector2(randf_range(-3, 3), randf_range(-2, 2)), 0.04)
	secousse.tween_property(calque, "offset", Vector2.ZERO, 0.05)
	var autre := "gauche" if droite else "droite"
	if Etat.est("fragment_" + autre):
		Etat.annoncer("Les deux ailes ont rejoint le corps du donjon ! L'épreuve finale t'attend.")
	else:
		Etat.annoncer("L'aile " + aile_vue + " a rejoint le corps du donjon ! Il manque encore l'aile " + autre + ".")
	await monde.get_tree().create_timer(4.5).timeout

	# 6) Fondu au noir, retour dans le vestibule (le corps du donjon n'est pas encore construit)
	t = monde.create_tween()
	t.tween_property(monde._fondu, "modulate:a", 1.0, 0.6)
	await t.finished
	calque.queue_free()
	# Retour au village, devant le temple (la scène change : la musique et l'état sont rechargés)
	monde._changer_de_scene("@village:" + monde._temple(), Vector2i(12, 7), "Tu ressors du temple, l'aile à la main. Retourne voir le capitaine Aubrac !")
