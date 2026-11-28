extends Node
## Test de la BOUTIQUE de Rosine et de la MAISON À DÉCORER (malle, mode décoration, agrandissement, sauvegarde des décors).
## Lancer : godot --headless --path . res://Tests/verifier_maison.tscn   (code de sortie 0 = tout est bon)

var _erreurs := 0


func _verifier(condition: bool, texte: String) -> void:
	if condition:
		print("  ok : ", texte)
	else:
		print("  ECHEC : ", texte)
		_erreurs += 1


func _ecran(monde: Node, nom: String) -> Ecran:
	for e in monde.get_children():
		if e is Ecran and e.name == nom:
			return e
	return null


func _index(id: String) -> int:
	for i in Etat.decors.size():
		if Etat.decors[i]["id"] == id:
			return i
	return -1


func _ready() -> void:
	Etat.sauvegarde_active = false
	Etat.decors = []
	Etat.drapeaux.erase("decors_init")
	Etat.drapeaux.erase("maison_agrandie")
	Etat.rubis = 400
	var monde: Node = load("res://Scenes/village.tscn").instantiate()
	add_child(monde)
	await get_tree().create_timer(0.5).timeout
	var joueur = monde.joueur
	var maison: Interieur = _ecran(monde, "InterieurHeros")
	_verifier(maison != null and maison.decorable, "la maison du héros est décorable")
	_verifier(maison._malle != null, "la malle à décors existe")
	_verifier(Etat.decors.size() == Decors.DEPART.size(), "les meubles de Maman sont des décors déplaçables (%d)" % Etat.decors.size())
	_verifier(maison._calque_decors.get_child_count() > 0, "les décors sont dessinés")

	# --- boutique ---
	var boutique: Boutique = null
	for n in monde.get_children():
		if n is Boutique:
			boutique = n
	_verifier(boutique != null, "la boutique existe au village")
	Etat.minijeu_demande.emit("boutique")
	await get_tree().process_frame
	_verifier(boutique._ouverte and Etat.en_dialogue and Etat.en_menu, "Rosine ouvre la boutique (joueur figé)")
	boutique._choix = boutique._articles().find("armoire")
	boutique._acheter()
	_verifier(Etat.rubis == 400 - Decors.CATALOGUE["armoire"]["prix"] and Decors.nombre("armoire") == 1, "acheter l'armoire : rubis payés (%d), armoire dans la malle" % Etat.rubis)
	var avant := Etat.rubis
	boutique._acheter()
	_verifier(Etat.rubis == avant and Decors.nombre("armoire") == 1, "une 2e armoire est refusée (maximum atteint)")
	Etat.rubis = 3
	boutique._choix = boutique._articles().find("lit_bleu")
	boutique._acheter()
	_verifier(Etat.rubis == 3 and Decors.nombre("lit_bleu") == 0, "trop cher : refusé")
	boutique.fermer()
	await get_tree().create_timer(0.3).timeout
	_verifier(not Etat.en_dialogue and not Etat.en_menu, "on quitte la boutique, le joueur reprend la main")

	# --- mode décoration ---
	joueur.global_position = maison.global_position + Vector2(12 * 16 + 8, 9 * 16 + 3)
	await get_tree().create_timer(0.3).timeout
	maison._malle.frapper()
	await get_tree().process_frame
	var deco: Decoration = null
	for n in maison.get_children():
		if n is Decoration:
			deco = n
	_verifier(deco != null and Etat.en_menu, "un coup de lance sur la malle ouvre le mode décoration")
	var ia := _index("armoire")
	_verifier(deco._main == ia, "on a en main l'armoire qui attendait dans la malle")
	_verifier(not maison.peut_poser(ia, Vector2i(8, 5)), "refusé : sur le lit")
	_verifier(not maison.peut_poser(ia, Vector2i(9, 5)), "refusé : sur la case du réveil")
	_verifier(not maison.peut_poser(ia, Vector2i(12, 8)), "refusé : devant la porte")
	deco._curseur = Vector2i(12, 6)
	_verifier(maison.peut_poser(ia, deco._curseur), "permis : au milieu de la pièce")
	deco._action()
	_verifier(Etat.decors[ia]["x"] == 12 and Etat.decors[ia]["y"] == 6 and deco._main == -1, "l'armoire est posée")
	var corps := maison._calque_decors.get_children().filter(func(n): return n is StaticBody2D)
	_verifier(corps.size() >= 4, "les meubles posés bloquent le passage (%d corps)" % corps.size())
	var ic := _index("chaise")
	deco._curseur = Vector2i(9, 9)
	deco._action()
	_verifier(deco._main == ic and Etat.decors[ic]["x"] == -1, "on prend la chaise sous le curseur")
	deco._curseur = Vector2i(13, 9)
	deco._fermer()
	await get_tree().create_timer(0.3).timeout
	_verifier(Etat.decors[ic]["x"] == 9 and Etat.decors[ic]["y"] == 9, "en quittant, la chaise tenue retourne à sa place")
	_verifier(not Etat.en_dialogue and not Etat.en_menu, "le joueur reprend la main")

	# --- on ne s'enferme jamais : un mur de meubles entre la porte et le reste est refusé ---
	var mur := {Vector2i(12, 8): true}
	for y in range(5, 10):
		mur[Vector2i(11, y)] = true
		mur[Vector2i(13, y)] = true
	_verifier(not maison._vitales_atteignables(mur), "un mur de meubles autour de la porte est détecté (on ne s'enferme pas)")
	_verifier(maison._vitales_atteignables({}), "maison vide : tout est atteignable")

	# --- agrandissement ---
	Etat.rubis = 200
	Etat.minijeu_demande.emit("boutique")
	await get_tree().process_frame
	boutique._choix = boutique._articles().find(Decors.AGRANDIR)
	boutique._acheter()
	boutique.fermer()
	await get_tree().create_timer(0.4).timeout
	_verifier(Etat.est(Decors.DRAPEAU_AGRANDIE) and Etat.rubis == 200 - Decors.PRIX_AGRANDIR, "la maison agrandie est achetée")
	_verifier(maison.layout[7][3] == "." and maison.layout[7][22] == ".", "la maison est plus large (nouveau plan)")
	_verifier(maison._malle != null and is_instance_valid(maison._malle), "la malle est toujours là")
	_verifier(boutique._articles().find(Decors.AGRANDIR) == -1, "l'agrandissement n'est plus en vente")
	Etat.decors.append({"id": "lit_bleu", "x": -1, "y": -1})
	_verifier(maison.peut_poser(Etat.decors.size() - 1, Vector2i(19, 5)), "un lit tient dans la nouvelle partie de la maison")

	# --- sauvegarde : les décors reviennent en entiers ---
	var f := FileAccess.open("user://test_decors.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"drapeaux": [], "decors": [{"id": "chaise", "x": 9.0, "y": 9.0}, {"id": "inconnu", "x": 1, "y": 1}], "version": 2}))
	f.close()
	Etat.charger("user://test_decors.json")
	DirAccess.remove_absolute("user://test_decors.json")
	_verifier(Etat.decors.size() == 1 and typeof(Etat.decors[0]["x"]) == TYPE_INT, "décors relus de la sauvegarde (entiers, inconnus ignorés)")

	print("=== TOUT EST BON ===" if _erreurs == 0 else "=== %d ÉCHEC(S) ===" % _erreurs)
	get_tree().quit(1 if _erreurs > 0 else 0)
