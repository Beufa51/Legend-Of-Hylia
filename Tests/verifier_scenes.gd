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
	await _tester_garde_et_steles()
	await _tester_donjon_final()
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
			# les 3 blocs sont en bas (rangée 10) : on les pousse vers le haut sur les marques du triangle
			for bloc in salle._blocs:
				var poussees := 4 if bloc.case.x == 12 else 2
				for i in poussees:
					await bloc.pousser(Vector2i.UP)
			if not root.get_node("Etat").est("p1_plaque"):
				_erreurs.append("Plume1 : les 3 blocs sont sur les marques mais la porte ne s'ouvre pas")
			else:
				print("OK  Plume1 : 3 blocs sur 3 marques = porte ouverte")
			root.get_node("Etat").drapeaux.erase("p1_plaque")
	# Plume 2a (lance enflammée) : sans feu un brasero ne s'allume pas ; avec le feu, oui ; l'eau éteint la lance
	if chemin.ends_with("world.tscn"):
		var salle2 = scene.get_node_or_null("Plume2a")
		var heros = scene.get("joueur")
		await process_frame
		if salle2 == null or heros == null or salle2._braseros.size() != 6:
			_erreurs.append("Plume2a : il faut 6 braseros à allumer")
		else:
			salle2._braseros[0].frapper()
			if salle2._braseros[0].allume:
				_erreurs.append("Plume2a : un brasero ne doit pas s'allumer sans lance enflammée")
			heros.global_position = salle2.to_global(Vector2(8 * 16 + 8, 6 * 16 + 8) - Vector2(0, 5))   # sur une flaque
			heros.prendre_feu()
			salle2._surveiller_flaques()
			if heros.a_feu():
				_erreurs.append("Plume2a : une flaque doit éteindre la lance")
			heros.prendre_feu()
			for b in salle2._braseros:
				b.frapper()
			if not root.get_node("Etat").est("p2_braseros"):
				_erreurs.append("Plume2a : 6 braseros allumés mais la porte ne s'ouvre pas")
			else:
				print("OK  Plume2a : lance enflammée, 6 braseros = porte ouverte")
			heros.eteindre_feu()
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


# Village : le garde de l'aile droite (tant que l'aile gauche n'est pas réussie), les deux stèles-pattes, la forêt qui s'ouvre.
func _tester_garde_et_steles() -> void:
	var etat = root.get_node("Etat")
	var paquet := load("res://Scenes/village.tscn") as PackedScene
	# 1) aile gauche NON réussie : façade fermée (G) et un garde devant
	etat.drapeaux.erase("fragment_gauche")
	var v1 := paquet.instantiate()
	root.add_child(v1)
	await process_frame
	var droit1 = v1.get_node("TempleDroit")
	var gardes1 := 0
	for c in droit1.get_children():
		if c.has_method("parler"):
			gardes1 += 1
	if droit1.layout[0][0] != "G" or gardes1 != 1 or droit1.passages.size() != 0:
		_erreurs.append("Garde : porte fermée attendue (façade G, 1 garde, aucun passage) : %s / %d / %d" % [droit1.layout[0][0], gardes1, droit1.passages.size()])
	# 2) stèles : sans fragment, rien ; avec, le symbole se dépose ; les deux = la forêt s'ouvre
	var parvis = v1.get_node("Parvis")
	if parvis.case_stele("gauche") != Vector2i(6, 3) or parvis.case_stele("droite") != Vector2i(14, 3):
		_erreurs.append("Stèles : cases inattendues %s %s" % [parvis.case_stele("gauche"), parvis.case_stele("droite")])
	v1.peut_changer_scene = false
	v1.joueur.direction = "haut"
	await v1._ceremonie_stele("gauche")
	if etat.est("stele_gauche"):
		_erreurs.append("Stèles : la gauche s'est déposée sans le fragment")
	etat.noter("fragment_gauche")
	etat.noter("fragment_droite")
	await v1._ceremonie_stele("gauche")
	if not etat.est("stele_gauche") or etat.est("corps_revele"):
		_erreurs.append("Stèles : après la gauche seule, stele_gauche doit être posé et la forêt fermée")
	await v1._ceremonie_stele("droite")
	if not etat.est("stele_droite") or not etat.est("corps_revele"):
		_erreurs.append("Stèles : les deux symboles déposés doivent ouvrir la forêt (corps_revele)")
	v1.queue_free()
	await process_frame
	# 3) rechargé avec les drapeaux : garde parti, porte ouverte (J, 3 passages), parvis ouvert au nord, stèles allumées
	var v2 := paquet.instantiate()
	root.add_child(v2)
	await process_frame
	var droit2 = v2.get_node("TempleDroit")
	var gardes2 := 0
	for c in droit2.get_children():
		if c.has_method("parler"):
			gardes2 += 1
	if droit2.layout[0][0] != "J" or gardes2 != 0 or droit2.passages.size() != 3:
		_erreurs.append("Garde : porte ouverte attendue après l'aile gauche (J, 0 garde, 3 passages)")
	var parvis2 = v2.get_node("Parvis")
	if parvis2.layout[0][12] != ":" or v2.get_node_or_null("Queue") == null:
		_erreurs.append("Parvis : le chemin du nord doit être ouvert et l'écran Queue présent")
	if not v2.get_node("Queue").layout[0][0] == "H":
		_erreurs.append("Queue : façade H attendue")
	print("OK  garde, stèles-pattes, forêt qui s'ouvre")
	for nom in ["stele_gauche", "stele_droite", "corps_revele", "fragment_gauche", "fragment_droite"]:
		etat.drapeaux.erase(nom)
	v2.queue_free()
	await process_frame


# Donjon final : vestibule (queue) -> couloir -> arène.
func _tester_donjon_final() -> void:
	var scene := (load("res://Scenes/corps.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var attendu := {"Vestibule": Vector2i(0, 2), "Couloir": Vector2i(0, 1), "Arene": Vector2i(0, 0)}
	for nom in attendu:
		var e = scene.get_node_or_null(nom)
		if e == null or e.grille != attendu[nom]:
			_erreurs.append("Donjon final : écran %s manquant ou mal placé" % nom)
	if scene.get_node("Vestibule").passages.size() != 3 or scene.get_node("Arene").passages.size() != 0:
		_erreurs.append("Donjon final : le vestibule doit avoir 3 passages vers la queue, l'arène aucun")
	print("OK  donjon final : vestibule, couloir, arène")
	scene.queue_free()
	await process_frame


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
