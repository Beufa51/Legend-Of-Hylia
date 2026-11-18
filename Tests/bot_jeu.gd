extends Node
## BOT DE TEST : joue VRAIMENT (touches simulées, physique réelle, rendu réel) et photographie la partie.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://Tests/bot_jeu.tscn -- <scénario>
## Scénarios : gouffre (Plume 3b : pousse les 3 blocs, traverse le pont)
## Images dans user://bot/ (une toutes les 4 images) ; le journal dit à quelle image chaque événement a eu lieu.
var monde
var salle
var _image := 0
var _echec := false


func _ready() -> void:
	_lancer.call_deferred()


func _process(_delta: float) -> void:
	_image += 1
	if _image % 8 == 0 and _image < 3200 and monde != null:
		DirAccess.make_dir_recursive_absolute("user://bot")
		get_tree().root.get_texture().get_image().save_png("user://bot/f%04d.png" % _image)


func _lancer() -> void:
	var a := OS.get_cmdline_user_args()
	var scenario := "gouffre" if a.is_empty() else a[0]
	Etat.sauvegarde_active = false
	var ecran := "Plume3b" if a.size() < 2 else a[1]
	Etat.arrivee_ecran = ecran
	Etat.arrivee_case = Vector2i(12, 12) if a.size() < 4 else Vector2i(int(a[2]), int(a[3]))
	var scene := OS.get_environment("BOT_SCENE")   # ex. BOT_SCENE=res://Scenes/aile_droite.tscn (par défaut : l'aile gauche)
	monde = load(scene if scene != "" else "res://Scenes/world.tscn").instantiate()
	add_child(monde)
	await get_tree().create_timer(2.0).timeout
	for e in monde.get_children():
		if e is Ecran and e.name == ecran:
			salle = e
	print("salle : ", salle.name, " joueur ", monde.joueur.position)
	await call("_scenario_" + scenario)
	print("=== BOT TERMINÉ (image %d) : %s ===" % [_image, "ÉCHEC" if _echec else "OK"])
	get_tree().quit(1 if _echec else 0)


func _pos(case: Vector2i) -> Vector2:
	return salle.position + Vector2(case * Ecran.TUILE) + Vector2(8, 3)


## Marche (touches réellement enfoncées) jusqu'à la case, d'abord en x puis en y (ou l'inverse).
func marcher(case: Vector2i, x_d_abord := true, pause := 0.15) -> void:
	var cible := _pos(case)
	var axes := [0, 1] if x_d_abord else [1, 0]
	for axe in axes:
		var sens: float = signf(cible[axe] - monde.joueur.position[axe])
		if sens == 0.0 or absf(cible[axe] - monde.joueur.position[axe]) < 2.0:
			continue
		var action: String
		if axe == 0:
			action = "move_right" if sens > 0 else "move_left"
		else:
			action = "move_down" if sens > 0 else "move_up"
		Input.action_press(action)
		var t := 0.0
		while t < 9.0 and (cible[axe] - monde.joueur.position[axe]) * sens > 2.0:
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
		Input.action_release(action)
		if t >= 9.0:
			print("!! bloqué en marchant vers ", case, " : joueur ", monde.joueur.position)
			_echec = true
		if pause > 0.0:
			await get_tree().create_timer(pause).timeout


## Scénario « glace » (`-- glace <Ecran> <x> <y> <coups>`, avec BOT_SCENE=res://Scenes/aile_droite.tscn) : joue une suite de coups
## séparés par des virgules : H B G D = une touche de direction (glisser, ou pousser le bloc qui est devant), A = coup de lance,
## h b g d (minuscule) = touche MAINTENUE 0,6 s (pousser un bloc depuis une case de sol, comme dans le jeu).
## Exemple : -- glace PlumeD3b 12 11 H,H,D,B,G,G,H,G,H
func _scenario_glace() -> void:
	var a := OS.get_cmdline_user_args()
	var touches := {"H": "move_up", "B": "move_down", "G": "move_left", "D": "move_right", "h": "move_up", "b": "move_down", "g": "move_left", "d": "move_right"}
	for coup in a[4].split(","):
		if coup == "A":
			Input.action_press("attack")
			await get_tree().create_timer(0.1).timeout
			Input.action_release("attack")
			await get_tree().create_timer(0.8).timeout
		else:
			Input.action_press(touches[coup])
			await get_tree().create_timer(0.12 if coup == coup.to_upper() else 0.6).timeout
			Input.action_release(touches[coup])
			await get_tree().create_timer(0.1).timeout
			while monde.joueur._glisse:
				await get_tree().physics_frame
			await get_tree().create_timer(0.7).timeout   # un bloc qui glisse, des plots qui changent
		print("  ", coup, " -> case ", salle.case_des_pieds(monde.joueur.global_position), " (image ", _image, ")")
	await get_tree().create_timer(1.0).timeout
	var drap := String(salle.drapeau_porte)
	print("drapeau ", drap, " : ", Etat.est(drap) if drap != "" else "-")
	if drap != "" and not Etat.est(drap):
		_echec = true


func comblees() -> int:
	var n := 0
	for trou in salle._eaux_a_combler.values():
		if trou["pont"] != null:
			n += 1
	return n


func _scenario_gouffre() -> void:
	var vu := 0
	# A (17,8) : 2 poussées vers le haut
	await marcher(Vector2i(17, 9), false)
	await marcher(Vector2i(17, 7), false)
	await get_tree().create_timer(1.0).timeout
	print("après A : cases comblées ", comblees(), " (image ", _image, ")")
	# B (14,8) : 3 à droite puis 3 en haut
	await marcher(Vector2i(13, 9), false)
	await marcher(Vector2i(13, 8), true)
	await marcher(Vector2i(16, 8), true)
	await marcher(Vector2i(16, 9), false)
	await marcher(Vector2i(17, 9), true)
	await marcher(Vector2i(17, 6), false)
	await get_tree().create_timer(1.0).timeout
	print("après B : cases comblées ", comblees(), " (image ", _image, ")")
	# C (20,9) : 3 à gauche puis 5 en haut
	await marcher(Vector2i(18, 10), false)
	await marcher(Vector2i(21, 10), true)
	await marcher(Vector2i(21, 9), false)
	await marcher(Vector2i(18, 9), true)
	await marcher(Vector2i(18, 10), false)
	await marcher(Vector2i(17, 10), true)
	await marcher(Vector2i(17, 5), false)
	await get_tree().create_timer(1.5).timeout
	print("après C : cases comblées ", comblees(), " pont fini ", salle._pont_fini, " (image ", _image, ")")
	if comblees() != 3 or not salle._pont_fini:
		_echec = true
	# on traverse jusqu'au nord (cloche 3 en (17,2))
	await marcher(Vector2i(17, 3), false)
	print("arrivée au nord : joueur ", monde.joueur.position, " (visé ", _pos(Vector2i(17, 3)), ")")
	if absf(monde.joueur.position.y - _pos(Vector2i(17, 3)).y) > 6.0:
		_echec = true


## Scénario « bruit » (Plume 4c, `-- bruit Plume4c 12 11`) : sans bruit le passage est surveillé ; on longe la rangée du bas (hors du regard),
## on brise le pot sonore de l'est, on COURT jusqu'au passage puis on contourne la sentinelle par le côté : jamais repéré.
func _scenario_bruit() -> void:
	await marcher(Vector2i(17, 11), true)
	await marcher(Vector2i(17, 8), false)
	print("avant le bruit : repéré ", salle._repere, " ; pots sonores ", salle._pots_sonores.size())
	Input.action_press("move_up")   # on regarde le pot (il bloque : on reste en place)
	await get_tree().create_timer(0.3).timeout
	Input.action_release("move_up")
	Input.action_press("attack")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("attack")
	await get_tree().create_timer(0.35).timeout
	print("pot brisé : bruit restant ", snappedf(salle._bruit_reste, 0.1), " s ; la sentinelle regarde ", salle._sentinelles[0].direction, " (image ", _image, ")")
	if salle._sentinelles[0].direction != Vector2i.RIGHT:
		_echec = true
	var t0 := Time.get_ticks_msec()
	Input.action_press("run")
	await marcher(Vector2i(13, 8), true, 0.0)
	await marcher(Vector2i(13, 4), false, 0.0)
	await marcher(Vector2i(11, 4), true, 0.0)
	await marcher(Vector2i(11, 2), false, 0.0)
	Input.action_release("run")
	print("hors du passage après %d ms ; repéré : %s ; joueur %s" % [Time.get_ticks_msec() - t0, salle._repere, monde.joueur.position])
	if salle._repere:
		_echec = true
	await get_tree().create_timer(3.0).timeout   # la sentinelle se retourne : on est à côté d'elle, elle ne nous voit pas
	print("après le retour du regard : repéré ", salle._repere, " ; regarde ", salle._sentinelles[0].direction, " ; le pot s'est reformé : ", salle._occupe.get(Vector2i(17, 7)) is PotSonore)
	if salle._repere or not (salle._occupe.get(Vector2i(17, 7)) is PotSonore):
		_echec = true


## Scénario « flamme » (Plume 4d, `-- flamme Plume4d 12 11`) : on allume le brasero de gauche (fixe la sentinelle de gauche), on longe le bas jusqu'au pot sonore
## de droite, on le brise (la sentinelle de droite se retourne 3,6 s), on COURT au passage : jamais repéré.
func _scenario_flamme() -> void:
	var gche = salle._sentinelles[0]
	var drte = salle._sentinelles[1]
	Input.action_press("run")
	await marcher(Vector2i(3, 11), true, 0.0)
	Input.action_release("run")
	Input.action_press("move_up")   # on regarde le brasero (il bloque : on reste en place)
	await get_tree().create_timer(0.3).timeout
	Input.action_release("move_up")
	Input.action_press("attack")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("attack")
	await get_tree().create_timer(0.4).timeout
	print("brasero allumé : ", salle._braseros[0].allume, " ; gauche regarde ", gche.direction, " ; droite regarde ", drte.direction, " (image ", _image, ")")
	if not salle._braseros[0].allume or gche.direction != Vector2i.LEFT or drte.direction != Vector2i.LEFT:
		_echec = true
	Input.action_press("run")
	await marcher(Vector2i(20, 11), true, 0.0)
	await marcher(Vector2i(20, 10), false, 0.0)
	Input.action_release("run")
	Input.action_press("move_right")   # on regarde le pot sonore
	await get_tree().create_timer(0.3).timeout
	Input.action_release("move_right")
	Input.action_press("attack")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("attack")
	await get_tree().create_timer(0.35).timeout
	print("pot brisé : bruit restant ", snappedf(salle._bruit_reste, 0.1), " s ; gauche ", gche.direction, " ; droite ", drte.direction, " (image ", _image, ")")
	if drte.direction != Vector2i.RIGHT or gche.direction != Vector2i.LEFT:
		_echec = true
	var t0 := Time.get_ticks_msec()
	Input.action_press("run")
	await marcher(Vector2i(12, 10), true, 0.0)
	await marcher(Vector2i(12, 4), false, 0.0)
	Input.action_release("run")
	print("au passage après %d ms ; repéré : %s ; joueur %s" % [Time.get_ticks_msec() - t0, salle._repere, monde.joueur.position])
	if salle._repere:
		_echec = true
	await get_tree().create_timer(4.0).timeout   # la sentinelle de droite revient : on est déjà derrière le passage
	print("après le retour du regard : repéré ", salle._repere, " ; droite regarde ", drte.direction)
	if salle._repere:
		_echec = true


## Scénario « heros » : le héros marche dans les 4 directions puis donne un coup de lance dans chacune ; photos dans user://bot/heros_*.png
func _scenario_heros() -> void:
	DirAccess.make_dir_recursive_absolute("user://bot")
	var touches := {"bas": "move_down", "haut": "move_up", "gauche": "move_left", "droite": "move_right"}
	var n := 0
	for d in ["bas", "haut", "gauche", "droite"]:
		Input.action_press(touches[d])
		await get_tree().create_timer(0.35).timeout
		_photo("heros_%02d_marche_%s" % [n, d])
		Input.action_release(touches[d])
		await get_tree().create_timer(0.2).timeout
		_photo("heros_%02d_repos_%s" % [n + 1, d])
		Input.action_press("attack")
		await get_tree().process_frame
		Input.action_release("attack")
		await get_tree().create_timer(0.11).timeout
		_photo("heros_%02d_estoc_%s" % [n + 2, d])
		await get_tree().create_timer(0.5).timeout
		n += 3


func _photo(nom: String) -> void:
	var image := get_tree().root.get_texture().get_image()
	var ecran: Vector2 = monde.joueur.global_position - (monde.camera.position - Vector2(200, 112))   # position du héros à l'écran (400x224)
	var zone := Rect2i(int(ecran.x) - 40, int(ecran.y) - 44, 80, 60).intersection(Rect2i(0, 0, image.get_width(), image.get_height()))
	image.get_region(zone).save_png("user://bot/%s.png" % nom)


## Scénario « profil » : marche vers la droite puis la gauche, une photo tous les 0,07 s (pour juger les pas)
func _scenario_profil() -> void:
	DirAccess.make_dir_recursive_absolute("user://bot")
	for d in ["droite", "gauche"]:
		var touche := "move_right" if d == "droite" else "move_left"
		Input.action_press(touche)
		await get_tree().create_timer(0.3).timeout
		for i in 8:
			_photo("profil_%s_%02d" % [d, i])
			await get_tree().create_timer(0.07).timeout
		Input.action_release(touche)
		await get_tree().create_timer(0.3).timeout
