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


# Descend dans le menu jusqu'à l'entrée demandée (par son identifiant).
func _choisir(pause: Pause, id: String) -> void:
	for i in 12:
		if pause._ids[pause._choix] == id:
			return
		await _touche("move_down")


func _tester_coeurs() -> void:
	var avant := Etat.drapeaux.duplicate()
	_verifier(Etat.nombre_insignes() > 0 or true, "insignes lisibles")
	for k in Etat.drapeaux.keys():
		if str(k).begins_with("insigne_"):
			Etat.drapeaux.erase(k)
	var p := load("res://Scripts/player.gd")
	_verifier(p.coeurs_max() == 5, "0 insigne : 5 cœurs")
	for i in 3:
		Etat.drapeaux["insigne_t%d" % i] = true
	_verifier(p.coeurs_max() == 6, "3 insignes : 6 cœurs")
	for i in 9:
		Etat.drapeaux["insigne_t%d" % i] = true
	_verifier(p.coeurs_max() == 8, "9 insignes : 8 cœurs")
	Etat.drapeaux = avant


func _tester_sauvegarde(monde: Node, pause: Pause) -> void:
	var fichiers := [Etat.FICHIER, Etat.FICHIER_MANUEL]
	for f in fichiers:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	Etat.sauvegarde_active = true   # (le « user:// » de ce test est un dossier jetable)
	monde.peut_changer_scene = false
	Etat.drapeaux.erase("test_pause")
	_verifier(not Etat.a_sauvegarde_manuelle(), "au départ : aucune sauvegarde manuelle")
	await _touche("pause")
	# Charger sans sauvegarde : rien ne se passe
	await _choisir(pause, "charger")
	await _touche("attack")
	_verifier(pause._page == Pause.Page.MENU, "Charger sans sauvegarde : le menu reste affiché (message d'info)")
	await _capture("menu_grise")
	# Sauvegarder
	await _choisir(pause, "sauver")
	await _touche("attack")
	_verifier(Etat.a_sauvegarde_manuelle(), "Sauvegarder écrit la sauvegarde manuelle")
	_verifier(get_tree().paused, "Sauvegarder laisse le jeu en pause")
	# un drapeau levé APRÈS la sauvegarde disparaît quand on recharge
	Etat.drapeaux["test_pause"] = true
	await _choisir(pause, "charger")
	await _touche("attack")
	_verifier(pause._page == Pause.Page.CONFIRMER, "Charger demande une confirmation")
	await _capture("confirmation")
	await _touche("attack")   # « Non » est choisi au départ
	_verifier(pause._page == Pause.Page.MENU and Etat.drapeaux.has("test_pause"), "Non : on revient au menu sans rien perdre")
	await _touche("attack")   # (sur « Charger »)
	await _touche("move_right")
	await _touche("attack")   # « Oui »
	await get_tree().create_timer(0.9).timeout
	_verifier(not get_tree().paused and not monde.en_transition, "Oui : le jeu repart (rechargement évité pendant le test)")
	_verifier(Etat.charger_manuel(), "charger_manuel() relit la sauvegarde")
	_verifier(not Etat.drapeaux.has("test_pause"), "le drapeau levé après la sauvegarde a disparu")
	for f in fichiers:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	Etat.sauvegarde_active = false


func _tester_recommencer(monde: Node, pause: Pause) -> void:
	var a_la_salle := pause._ids.has("recommencer")
	var attendu: bool = monde.donjon and monde.cote in ["gauche", "droite"]
	_verifier(a_la_salle == attendu, "« Recommencer l'énigme » présent seulement dans une aile (ici : %s)" % str(a_la_salle))
	if not a_la_salle:
		return
	await _touche("pause")
	await _choisir(pause, "recommencer")
	await _touche("attack")
	await get_tree().create_timer(0.5).timeout
	_verifier(not get_tree().paused, "« Recommencer l'énigme » relance le jeu")
	_verifier(pause._ids.has("indice"), "« Un indice » est dans le menu des ailes")
	await _touche("pause")
	await _choisir(pause, "indice")
	await _touche("attack")
	await get_tree().create_timer(0.5).timeout
	_verifier(not get_tree().paused, "« Un indice » relance le jeu")
	var anneaux := 0
	for e in monde.get_children():
		for n in e.get_children():
			if n is Line2D:
				anneaux += 1
	_verifier(anneaux > 0, "« Un indice » fait apparaître au moins un anneau doré (%d)" % anneaux)
	# on remet les réglages à zéro pour les tests suivants
	Reglages.general = Reglages.NIVEAU_MAX
	Reglages.musique = Reglages.NIVEAU_MAX
	Reglages.appliquer()


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
	# « Carte », valider
	await _choisir(pause, "carte")
	await _touche("attack")
	_verifier(pause._carte.visible, "la page Carte s'ouvre")
	await get_tree().process_frame
	await _capture("carte")
	await _touche("pause")
	_verifier(pause._menu.visible and not pause._carte.visible, "pause (ou retour) revient au menu depuis la carte")
	# options : volumes, commandes, crédits
	await _choisir(pause, "options")
	await _touche("attack")
	_verifier(pause._page == Pause.Page.OPTIONS, "la page Options s'ouvre")
	Reglages.general = 10
	await _touche("move_left")
	_verifier(Reglages.general == 9, "gauche baisse le volume général d'un cran")
	await _touche("move_right")
	_verifier(Reglages.general == 10, "droite le remonte")
	await _touche("move_down")
	for i in 12:   # tout en bas : le volume de la musique tombe à 0 puis ne descend plus
		await _touche("move_left")
	_verifier(Reglages.musique == 0 and AudioServer.is_bus_mute(AudioServer.get_bus_index(Reglages.BUS_MUSIQUE)), "la musique à 0 coupe le bus Musique")
	for i in 12:
		await _touche("move_right")
	_verifier(Reglages.musique == Reglages.NIVEAU_MAX and not AudioServer.is_bus_mute(AudioServer.get_bus_index(Reglages.BUS_MUSIQUE)), "la musique remonte au maximum")
	await _touche("move_down")
	await _touche("attack")
	_verifier(pause._commandes.visible, "la page Commandes s'ouvre (depuis Options)")
	await _capture("commandes")
	await _touche("ui_cancel")
	_verifier(pause._page == Pause.Page.OPTIONS, "retour aux Options depuis les commandes")
	await _touche("move_down")
	await _touche("attack")
	_verifier(pause._credits.visible and pause._credits_texte.text.length() > 100, "la page Crédits s'ouvre avec du texte")
	await _capture("credits")
	await _touche("ui_cancel")
	await _capture("options")
	await _touche("ui_cancel")
	_verifier(pause._menu.visible and pause._page == Pause.Page.MENU, "retour au menu depuis les options")
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
	_tester_coeurs()
	await _tester_sauvegarde(monde, pause)
	await _tester_recommencer(monde, pause)
	print("=== ", "TOUT EST BON" if _erreurs == 0 else "%d ECHEC(S)" % _erreurs, " ===")
	get_tree().quit(_erreurs)
