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
	monde = load("res://Scenes/world.tscn").instantiate()
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
func marcher(case: Vector2i, x_d_abord := true) -> void:
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
		await get_tree().create_timer(0.15).timeout


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
