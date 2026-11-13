extends SceneTree
## TEST DE CHARGEMENT (sans fenêtre) : charge chaque scène du jeu, laisse tourner quelques images
## et vérifie des règles simples (plans 25x14, grilles uniques, drapeaux de portes non vides...).
## Lancer depuis le dossier du projet :
##   godot --headless --path . -s res://Tests/verifier_scenes.gd
## Code de sortie 0 = tout est bon ; 1 = au moins une erreur (listées dans la console).
## La sauvegarde du joueur n'est PAS touchée (on coupe Etat.sauver pendant le test).

const SCENES := [
	"res://Scenes/village.tscn",
	"res://Scenes/world.tscn",
	"res://Scenes/aile_droite.tscn",
	"res://Scenes/corps.tscn",
]
const COLONNES := 25
const RANGEES := 14

var _erreurs: Array[String] = []


func _initialize() -> void:
	await process_frame
	var etat: Node = root.get_node_or_null("Etat")
	if etat == null:
		_erreurs.append("Autoload Etat introuvable (project.godot).")
	else:
		etat.sauvegarde_active = false
	for chemin in SCENES:
		await _tester_scene(chemin)
	await _tester_tactile()
	_conclure()


func _tester_scene(chemin: String) -> void:
	var paquet := load(chemin) as PackedScene
	if paquet == null:
		_erreurs.append("%s : chargement impossible" % chemin)
		return
	var scene := paquet.instantiate()
	root.add_child(scene)
	for i in 5:
		await process_frame
	var grilles := {}
	var nb := 0
	for e in scene.get_children():
		if not _est_ecran(e):
			continue
		nb += 1
		if grilles.has(e.grille):
			_erreurs.append("%s : %s et %s ont la même case %s" % [chemin, grilles[e.grille], e.name, e.grille])
		grilles[e.grille] = e.name
		_verifier_plan(chemin, e)
	# on visite chaque écran (comme le mode développeur F1) : crée les objets, lance les scripts de la salle
	if scene.has_method("_teleporter"):
		for e in scene.get_children():
			if _est_ecran(e):
				scene._teleporter(e)
				for i in 3:
					await process_frame
	# vue aérienne (cinématique de fin d'aile) : fabrication du plan + début de la séquence
	if chemin.ends_with("world.tscn"):
		var vue = load("res://Scripts/vue_aerienne.gd").new(scene)
		var plan: Dictionary = vue._plan_vu_du_ciel()
		if not (plan.has("carte") and plan.has("contour") and plan.has("coin")):
			_erreurs.append("%s : plan vu du ciel incomplet" % chemin)
		vue.jouer("gauche")
		await create_timer(5.0).timeout
	# Plume 1 : pousser les 3 blocs sur les 3 marques doit lever le drapeau de la porte
	if chemin.ends_with("world.tscn"):
		var salle = scene.get_node_or_null("Plume1")
		if salle == null or salle._blocs.size() != 3 or salle._plaques.size() != 3:
			_erreurs.append("Plume1 : il faut 3 blocs et 3 marques")
		else:
			salle.reinitialiser()
			for bloc in salle._blocs:
				for i in 6:
					await bloc.pousser(Vector2i.LEFT)
			if not root.get_node("Etat").est("p1_plaque"):
				_erreurs.append("Plume1 : les 3 blocs sont sur les marques mais la porte ne s'ouvre pas")
			else:
				print("OK  Plume1 : 3 blocs sur 3 marques = porte ouverte")
			root.get_node("Etat").drapeaux.erase("p1_plaque")
	# Plume 2a (tête de coq) : un mauvais brasero éteint tout ; dans l'ordre du tracé, la porte s'ouvre
	if chemin.ends_with("world.tscn"):
		var salle2 = scene.get_node_or_null("Plume2a")
		await process_frame
		await process_frame
		if salle2 == null or salle2._braseros.size() != 12:
			_erreurs.append("Plume2a : il faut 12 braseros")
		else:
			var premier: Vector2 = salle2._braseros[0].position / 16.0
			if Vector2i(premier) != Vector2i(6, 10) or Vector2i(salle2._braseros[11].position / 16.0) != Vector2i(12, 7):
				_erreurs.append("Plume2a : les braseros ne sont pas dans l'ordre du tracé")
			salle2._braseros[3].frapper()   # mauvais ordre
			if salle2._braseros[3].allume:
				_erreurs.append("Plume2a : un brasero hors ordre ne doit pas s'allumer")
			for b in salle2._braseros:
				b.frapper()
			if not root.get_node("Etat").est("p2_braseros"):
				_erreurs.append("Plume2a : tracé complet mais la porte ne s'ouvre pas")
			else:
				print("OK  Plume2a : tête de coq complète = porte ouverte")
			root.get_node("Etat").drapeaux.erase("p2_braseros")
	if nb == 0:
		_erreurs.append("%s : aucun écran trouvé" % chemin)
	print("OK  %s  (%d écrans)" % [chemin, nb])
	scene.queue_free()
	await process_frame


# (on évite de nommer la classe Ecran ici : elle utilise l'autoload Etat, pas encore prêt quand ce script se compile)
func _est_ecran(n: Node) -> bool:
	return "layout" in n and "grille" in n


# Contrôles tactiles : un doigt à gauche = joystick, un doigt sur le bouton A = attack.
func _tester_tactile() -> void:
	var t = load("res://Scripts/tactile.gd").new()
	root.add_child(t)
	await process_frame
	t.visible = true
	var toucher := func(index: int, pos: Vector2, appuye: bool) -> void:
		var e := InputEventScreenTouch.new()
		e.index = index
		e.position = pos
		e.pressed = appuye
		t._input(e)
	var glisser := func(index: int, pos: Vector2) -> void:
		var e := InputEventScreenDrag.new()
		e.index = index
		e.position = pos
		t._input(e)
	toucher.call(0, Vector2(60, 150), true)
	glisser.call(0, Vector2(90, 150))
	await process_frame
	if not Input.is_action_pressed("move_right"):
		_erreurs.append("Tactile : le joystick vers la droite n'appuie pas move_right")
	glisser.call(0, Vector2(60, 120))
	await process_frame
	if not Input.is_action_pressed("move_up") or Input.is_action_pressed("move_right"):
		_erreurs.append("Tactile : le joystick vers le haut est incorrect")
	toucher.call(0, Vector2(60, 120), false)
	await process_frame
	if Input.is_action_pressed("move_up"):
		_erreurs.append("Tactile : lâcher le joystick ne relâche pas move_up")
	var a: Vector2 = t._centre_bouton("A")
	toucher.call(1, a, true)
	await process_frame
	if not Input.is_action_pressed("attack"):
		_erreurs.append("Tactile : le bouton A n'appuie pas attack")
	toucher.call(1, a, false)
	await process_frame
	if Input.is_action_pressed("attack"):
		_erreurs.append("Tactile : relâcher A ne relâche pas attack")
	print("OK  contrôles tactiles")
	t.queue_free()


func _verifier_plan(chemin: String, e: Node) -> void:
	if e.layout.size() != RANGEES:
		_erreurs.append("%s/%s : %d rangées au lieu de %d" % [chemin, e.name, e.layout.size(), RANGEES])
		return
	for i in e.layout.size():
		if e.layout[i].length() != COLONNES:
			_erreurs.append("%s/%s : la rangée %d fait %d colonnes (attendu %d)" % [chemin, e.name, i, e.layout[i].length(), COLONNES])


func _conclure() -> void:
	if _erreurs.is_empty():
		print("=== TOUT EST BON ===")
		quit(0)
	else:
		for t in _erreurs:
			printerr("ERREUR : ", t)
		printerr("=== %d erreur(s) ===" % _erreurs.size())
		quit(1)
