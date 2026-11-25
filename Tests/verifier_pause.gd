extends Node
## Test du menu pause et de la carte (pause.gd, carte.gd).
## Lancer : godot --headless --path . res://Tests/verifier_pause.tscn -- [scene] [Ecran1,Ecran2...]
## Avec un vrai rendu (xvfb-run ... --rendering-driver opengl3) et la variable CAPTURE=1 : écrit des captures dans user://pause/.
## Code de sortie 0 = tout est bon.

var _erreurs := 0


func _verifier(condition: bool, texte: String) -> void:
	if condition:
		print("  ok : ", texte)
	else:
		print("  ECHEC : ", texte)
		_erreurs += 1


func _touche(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	e = InputEventAction.new()
	e.action = action
	e.pressed = false
	Input.parse_input_event(e)
	await get_tree().process_frame


func _capture(nom: String) -> void:
	if OS.get_environment("CAPTURE") == "":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://pause")
	get_viewport().get_texture().get_image().save_png("user://pause/%s.png" % nom)


func _ready() -> void:
	Etat.sauvegarde_active = false
	var args := OS.get_cmdline_user_args()
	var chemin := args[0] if args.size() > 0 else "res://Scenes/village.tscn"
	var visites: PackedStringArray = args[1].split(",") if args.size() > 1 else PackedStringArray()
	for nom in visites:
		Etat.visites[chemin + "|" + nom] = true
	var monde: Node = load(chemin).instantiate()
	add_child(monde)
	await get_tree().process_frame
	await get_tree().process_frame
	var pause: Pause = null
	for e in monde.get_children():
		if e is Pause:
			pause = e
	_verifier(pause != null, "le monde a un menu pause")
	if pause == null:
		get_tree().quit(1)
		return
	_verifier(not get_tree().paused, "le jeu tourne au départ")
	# ouverture par l'action « pause »
	await _touche("pause")
	_verifier(get_tree().paused and Etat.en_pause and pause.visible, "l'action pause gèle le jeu et ouvre le menu")
	await _capture("menu")
	# bas -> « Carte », valider
	await _touche("move_down")
	await _touche("attack")
	_verifier(pause._carte.visible, "la page Carte s'ouvre")
	await get_tree().process_frame
	await _capture("carte")
	await _touche("pause")
	_verifier(pause._menu.visible and not pause._carte.visible, "pause (ou retour) revient au menu depuis la carte")
	# commandes
	await _touche("move_down")
	await _touche("attack")
	_verifier(pause._commandes.visible, "la page Commandes s'ouvre")
	await _capture("commandes")
	await _touche("ui_cancel")
	_verifier(pause._menu.visible, "retour au menu depuis les commandes")
	# fermeture
	await _touche("pause")
	await get_tree().create_timer(0.4).timeout
	_verifier(not get_tree().paused and not Etat.en_pause and not pause.visible, "pause referme le menu et relance le jeu")
	# une 2e pause marche aussi
	await _touche("pause")
	_verifier(get_tree().paused, "on peut remettre en pause")
	await _touche("attack")   # « Reprendre »
	await get_tree().create_timer(0.4).timeout
	_verifier(not get_tree().paused, "« Reprendre » relance le jeu")
	print("=== ", "TOUT EST BON" if _erreurs == 0 else "%d ECHEC(S)" % _erreurs, " ===")
	get_tree().quit(_erreurs)
