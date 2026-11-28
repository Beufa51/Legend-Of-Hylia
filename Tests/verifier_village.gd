extends Node
## Test du village : herbes et pots à rubis, butin, poules en colère -> KO -> réveil dans le lit.
## Lancer : godot --headless --path . res://Tests/verifier_village.tscn   (code de sortie 0 = tout est bon)

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


func _ready() -> void:
	Etat.sauvegarde_active = false
	Etat.rubis = 0
	var monde: Node = load("res://Scenes/village.tscn").instantiate()
	add_child(monde)
	await get_tree().create_timer(0.5).timeout
	var joueur = monde.joueur
	_verifier(monde.get_children().any(func(n): return n is HudVillage), "le HUD du village (cœurs + rubis) existe")

	# --- herbes et pots ---
	var herbes := get_tree().get_nodes_in_group("cassable").filter(func(n): return n is Herbe)
	var pots := get_tree().get_nodes_in_group("cassable").filter(func(n): return n is Pot and n.butin)
	_verifier(herbes.size() > 30, "des herbes à couper dans le village (%d)" % herbes.size())
	_verifier(pots.size() > 12, "des pots à rubis dans le village (%d)" % pots.size())

	# --- couper une herbe laisse parfois du butin, un rubis ramassé augmente le compteur ---
	var place := _ecran(monde, "PlaceDuCoq")
	var herbe: Herbe = herbes[0]
	herbe.chance_rubis = 1.0
	herbe.chance_coeur = 0.0
	var pos: Vector2 = herbe.global_position + Vector2(8, 8)
	var parent := herbe.get_parent()
	herbe.couper()
	await get_tree().process_frame
	var butins := parent.get_children().filter(func(n): return n is Butin)
	_verifier(butins.size() == 1, "une herbe coupée (100 %%) laisse un rubis (%d)" % butins.size())
	joueur.global_position = pos + Vector2(0, 2)
	await get_tree().create_timer(1.2).timeout
	_verifier(Etat.rubis >= 1, "le rubis est ramassé : compteur = %d" % Etat.rubis)
	var avant_rubis := Etat.rubis
	_verifier(Etat.depenser_rubis(avant_rubis + 5) == false and Etat.rubis == avant_rubis, "dépenser plus que ce qu'on a est refusé")

	# --- les poules en colère assomment le héros, qui se réveille dans son lit ---
	joueur.global_position = place.global_position + Vector2(200, 150)
	await get_tree().create_timer(1.0).timeout
	var poule: Animal = null
	for p in place.get_children():
		if p is Animal and p.is_in_group("poules"):
			poule = p
			break
	_verifier(poule != null, "une poule sur la place")
	poule.global_position = joueur.global_position + Vector2(30, 0)
	poule._declencher_colere()
	await get_tree().create_timer(3.0).timeout
	_verifier(joueur.coeurs < joueur.coeurs_max(), "les coups de bec font perdre des cœurs (%d/%d)" % [joueur.coeurs, joueur.coeurs_max()])
	await get_tree().create_timer(14.0).timeout
	var lit := _ecran(monde, "InterieurHeros")
	_verifier(monde._ko == false and not monde.en_transition, "la séquence d'évanouissement est terminée")
	_verifier(joueur.coeurs == joueur.coeurs_max(), "cœurs rendus au réveil (%d)" % joueur.coeurs)
	_verifier(lit != null and Rect2(lit.global_position, Vector2(Ecran.TAILLE_SALLE)).has_point(joueur.global_position), "le héros est dans la maison (son lit)")

	# --- une poule qui n'est plus dans l'écran du joueur se calme ---
	await get_tree().create_timer(1.0).timeout
	_verifier(poule._colere <= 0.0, "la poule s'est calmée quand le héros a quitté l'écran")
	print("=== TOUT EST BON ===" if _erreurs == 0 else "=== %d ÉCHEC(S) ===" % _erreurs)
	get_tree().quit(1 if _erreurs > 0 else 0)
