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
	await _tester_audio_et_sans_texte()
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
	# Plume 3b : 3 blocs poussés dans le couloir comblent les 3 trous (ponts) ; R rouvre les trous
	if chemin.ends_with("world.tscn"):
		var salle3 = scene.get_node_or_null("Plume3b")
		if salle3 == null or salle3._blocs.size() != 3 or salle3._eaux_a_combler.size() != 63:
			_erreurs.append("Plume3b : il faut 3 blocs et un gouffre de 3x21 cases")
		else:
			salle3.reinitialiser()
			# ordre : A (17,8) d'abord, puis B (14,8), puis C (20,9) (sinon B bute contre A)
			var ordre := {}
			for bloc in salle3._blocs:
				ordre[bloc.case] = bloc
			var plan := [[Vector2i(17, 8), [Vector2i.UP, 2]], [Vector2i(14, 8), [Vector2i.RIGHT, 3, Vector2i.UP, 3]], [Vector2i(20, 9), [Vector2i.LEFT, 3, Vector2i.UP, 5]]]
			for etape in plan:
				var bloc = ordre[etape[0]]
				var pousses: Array = etape[1]
				for k in range(0, pousses.size(), 2):
					for i in pousses[k + 1]:
						await bloc.pousser(pousses[k])
			var combles := 0
			for trou in salle3._eaux_a_combler.values():
				if trou["pont"] != null:
					combles += 1
			# la colonne 17 doit être entièrement comblée (rangées 4 à 6) : on peut traverser
			var colonne_ok := true
			for ry in [4, 5, 6]:
				if salle3._eaux_a_combler[Vector2i(17, ry)]["pont"] == null:
					colonne_ok = false
			if combles != 3 or not colonne_ok:
				_erreurs.append("Plume3b : %d case(s) comblée(s), colonne 17 complète : %s" % [combles, colonne_ok])
			elif not salle3._pont_fini or not root.get_node("Etat").est("pont_3_-2_17"):
				_erreurs.append("Plume3b : le pont fini doit être mémorisé (drapeau pont_3_-2_17)")
			else:
				salle3.reinitialiser()      # un pont FINI ne se défait plus
				var restes := 0
				for trou in salle3._eaux_a_combler.values():
					if trou["pont"] != null:
						restes += 1
				if restes != 3:
					_erreurs.append("Plume3b : R ne doit pas défaire un pont fini")
				# test du reset : on « oublie » le pont
				root.get_node("Etat").drapeaux.erase("pont_3_-2_17")
				salle3._pont_fini = false
				salle3.reinitialiser()
				var ouverts := 0
				for trou in salle3._eaux_a_combler.values():
					if trou["pont"] == null:
						ouverts += 1
				if ouverts != 63:
					_erreurs.append("Plume3b : R doit rouvrir le gouffre")
				else:
					print("OK  Plume3b : 3 blocs comblent une colonne du gouffre, R le rouvre")
		# Plume 3c : le bloc poussé dans la bande de gauche la coince (21 pics rentrés pour de bon), la droite tourne encore ; R la décoince
		if chemin.ends_with("world.tscn"):
			var salle3c = scene.get_node_or_null("Plume3c")
			if salle3c == null or salle3c._blocs.size() != 1 or salle3c._pics.size() != 42 or not salle3c.pics_doux or salle3c.sombre:
				_erreurs.append("Plume3c : il faut 1 bloc, 42 pics doux, salle claire")
			else:
				salle3c.reinitialiser()
				var bloc3c = salle3c._blocs[0]
				if not salle3c._pics[Vector2i(7, 8)].fixe or salle3c._pics[Vector2i(17, 8)].fixe:
					_erreurs.append("Plume3c : la bande de gauche doit être fixe (toujours sortie), pas la droite")
				await bloc3c.pousser(Vector2i.LEFT)
				var coinces := 0
				for c in salle3c._pics:
					if salle3c._pics[c].coince:
						coinces += 1
				if bloc3c.case != Vector2i(8, 6) or coinces != 21 or salle3c._pics[Vector2i(17, 8)].coince:
					_erreurs.append("Plume3c : bloc en %s, %d pics coincés (attendu (8,6), 21)" % [bloc3c.case, coinces])
				else:
					salle3c.reinitialiser()
					if salle3c._pics[Vector2i(7, 8)].coince or bloc3c.case != Vector2i(9, 6):
						_erreurs.append("Plume3c : R doit remettre le bloc et décoincer les pics")
					else:
						salle3c.cloche_frappee(3)
						salle3c.cloche_frappee(1)
						var allumees: bool = salle3c._cloches[3]._active and salle3c._cloches[1]._active and not salle3c._cloches[5]._active
						salle3c.cloche_frappee(2)   # fausse note : tout s'éteint
						if not allumees or salle3c._cloches[3]._active:
							_erreurs.append("Plume3c : les cloches justes doivent rester allumées, et s'éteindre sur une fausse note")
						else:
							print("OK  Plume3c : mur de pics écrasé par le bloc, R le remet ; cloches justes allumées")
	# Plume 4c (le bruit) : 2 pots sonores ; en briser un fait fixer la sentinelle vers lui pendant duree_bruit, puis elle se retourne ; R remet le pot
	if chemin.ends_with("world.tscn"):
		var s4c = scene.get_node_or_null("Plume4c")
		if s4c == null or s4c._pots_sonores.size() != 2 or s4c._sentinelles.size() != 1:
			_erreurs.append("Plume4c : il faut 2 pots sonores et 1 sentinelle")
		else:
			s4c.reinitialiser()
			await process_frame
			var garde = s4c._sentinelles[0]
			s4c._surveiller(0.05)
			var avant: Vector2i = garde.direction
			var pot_est = s4c._occupe.get(Vector2i(17, 7))
			if not (pot_est is PotSonore) or avant != Vector2i.DOWN:
				_erreurs.append("Plume4c : pot sonore en (17,7) et sentinelle tournée vers le bas au départ")
			else:
				pot_est.frapper()
				s4c._surveiller(0.05)
				var pendant: Vector2i = garde.direction
				s4c._surveiller(s4c.duree_bruit)
				s4c._surveiller(0.05)
				var apres: Vector2i = garde.direction
				await process_frame
				s4c._reformer_pot(Vector2i(17, 7))   # (normalement après duree_bruit + 1,5 s : le pot se reforme tout seul)
				if not (s4c._occupe.get(Vector2i(17, 7)) is PotSonore):
					_erreurs.append("Plume4c : un pot sonore brisé doit se reformer (sinon on peut rester coincé)")
				s4c.reinitialiser()
				var revenu = s4c._occupe.get(Vector2i(17, 7))
				if pendant != Vector2i.RIGHT or apres != Vector2i.DOWN or not (revenu is PotSonore):
					_erreurs.append("Plume4c : bruit à l'est -> regard %s (attendu droite), puis %s (attendu bas), pot remis : %s" % [pendant, apres, revenu is PotSonore])
				else:
					print("OK  Plume4c : le pot sonore détourne la sentinelle %.1f s puis elle se retourne ; R remet le pot" % s4c.duree_bruit)
	# Plume 4d (combinaison) : la flamme de gauche fixe SEULEMENT la sentinelle de gauche, le pot de droite SEULEMENT celle de droite (3,6 s)
	if chemin.ends_with("world.tscn"):
		var s4d = scene.get_node_or_null("Plume4d")
		if s4d == null or s4d._sentinelles.size() != 2 or s4d._braseros.size() != 1 or s4d._pots_sonores.size() != 1 or not s4d.sombre:
			_erreurs.append("Plume4d : il faut 2 sentinelles, 1 brasero, 1 pot sonore, salle sombre")
		else:
			s4d.reinitialiser()
			await process_frame
			var gche = s4d._sentinelles[0]
			var drte = s4d._sentinelles[1]
			s4d._surveiller(0.05)
			var etat0: bool = gche.direction == Vector2i.RIGHT and drte.direction == Vector2i.LEFT
			s4d._braseros[0].frapper()
			s4d._surveiller(0.05)
			var etat1: bool = gche.direction == Vector2i.LEFT and drte.direction == Vector2i.LEFT
			s4d._occupe.get(Vector2i(21, 10)).frapper()
			s4d._surveiller(0.05)
			var etat2: bool = gche.direction == Vector2i.LEFT and drte.direction == Vector2i.RIGHT
			s4d._surveiller(s4d.duree_bruit)
			s4d._surveiller(0.05)
			var etat3: bool = gche.direction == Vector2i.LEFT and drte.direction == Vector2i.LEFT
			s4d.reinitialiser()
			if not (etat0 and etat1 and etat2 and etat3):
				_erreurs.append("Plume4d : départ %s, flamme %s, flamme+bruit %s, après le bruit %s (attendu : vrai partout)" % [etat0, etat1, etat2, etat3])
			else:
				print("OK  Plume4d : la flamme fixe la sentinelle proche, le bruit fixe l'autre, puis elle se retourne")
	# Plume 5b (le faux chemin) : au départ le rayon bute sur le pilier devant le réceptacle ; (10,6) + (10,8) l'allument
	if chemin.ends_with("world.tscn"):
		var s5b = scene.get_node_or_null("Plume5b")
		if s5b == null or s5b._miroirs.size() != 5 or s5b._cible == null:
			_erreurs.append("Plume5b : il faut 5 miroirs et un réceptacle")
		else:
			s5b._tracer_rayon()
			var avant: bool = s5b._cible.allumee or s5b._pilier_brule != Vector2i(17, 5)
			for c in [Vector2i(10, 6), Vector2i(10, 8)]:
				s5b._miroirs[c].frapper()
			s5b._tracer_rayon()
			var apres: bool = s5b._cible.allumee and s5b._pilier_brule != Vector2i(17, 5)
			s5b.reinitialiser()
			if avant or not apres:
				_erreurs.append("Plume5b : réceptacle allumé au départ %s, après les 2 miroirs %s (attendu faux puis vrai)" % [avant, apres])
			else:
				print("OK  Plume5b : le faux chemin bute sur le pilier (brûlure dorée) ; 2 miroirs retournés -> réceptacle allumé")
	# Plume 5c : miroir mal réglé au départ (le rayon monte) ; retourné, il s'arrête sur le bloc ; bloc sur le bouton -> réceptacle
	if chemin.ends_with("world.tscn"):
		var s5c = scene.get_node_or_null("Plume5c")
		if s5c == null or s5c._miroirs.size() != 1 or s5c._cible == null or s5c._blocs.size() != 1:
			_erreurs.append("Plume5c : il faut 1 miroir, un réceptacle et 1 bloc")
		else:
			s5c._tracer_rayon()
			var monte: bool = s5c._points_rayon.size() > 1 and s5c._points_rayon[s5c._points_rayon.size() - 1].y < 4 * 16
			s5c._miroirs[Vector2i(18, 4)].frapper()
			s5c._tracer_rayon()
			var bloque: bool = not s5c._cible.allumee
			var bloc = s5c._blocs[0]
			s5c.liberer(bloc.case)
			bloc.case = Vector2i(21, 6)
			bloc.position = Vector2(bloc.case * 16)
			s5c.occuper(bloc.case, bloc)
			s5c.verifier_plaques()
			await process_frame
			s5c._tracer_rayon()
			var apres: bool = s5c._cible.allumee
			s5c.reinitialiser()
			if not monte or not bloque or not apres:
				_erreurs.append("Plume5c : rayon qui monte au départ %s, arrêté par le bloc %s, réceptacle après le bouton %s" % [monte, bloque, apres])
			else:
				print("OK  Plume5c : miroir mal réglé au départ ; retourné, le bloc arrête le rayon ; bloc sur le bouton -> réceptacle")
	# Plume 5d (la boucle) : au départ le rayon ne touche pas le réceptacle ; retourner (10,9), (16,9), (7,9) l'allume
	if chemin.ends_with("world.tscn"):
		var s5d = scene.get_node_or_null("Plume5d")
		if s5d == null or s5d._miroirs.size() != 6 or s5d._cible == null or not s5d.sombre:
			_erreurs.append("Plume5d : il faut 6 miroirs, un réceptacle, salle sombre")
		else:
			s5d._tracer_rayon()
			var avant: bool = s5d._cible.allumee
			for c in [Vector2i(10, 9), Vector2i(16, 9), Vector2i(7, 9)]:
				s5d._miroirs[c].frapper()
			s5d._tracer_rayon()
			if avant or not s5d._cible.allumee:
				_erreurs.append("Plume5d : réceptacle allumé au départ %s, après les 3 miroirs %s (attendu faux puis vrai)" % [avant, s5d._cible.allumee])
			else:
				print("OK  Plume5d : la boucle tourne à l'envers au départ ; 3 miroirs retournés -> réceptacle allumé")
			s5d.reinitialiser()
			s5d._tracer_rayon()
			if s5d._cible.allumee:
				_erreurs.append("Plume5d : après R, le réceptacle devrait être éteint (énigme rejouable)")
			else:
				print("OK  Plume5d : R remet les miroirs et éteint le réceptacle, même résolue")
	# Plume 5e (pointe) : bloc dans le rayon ; dégagé + 3 miroirs retournés -> le soleil touche le coq (disque allumé)
	if chemin.ends_with("world.tscn"):
		var s5e = scene.get_node_or_null("Plume5e")
		if s5e == null or s5e._miroirs.size() != 6 or s5e._chanteur == null or s5e._blocs.size() != 1:
			_erreurs.append("Plume5e : il faut 6 miroirs, la statue du coq et 1 bloc")
		else:
			s5e._tracer_rayon()
			var avant: bool = s5e._statue_au_soleil
			var bloc = s5e._blocs[0]
			s5e.liberer(bloc.case)
			bloc.case = Vector2i(3, 9)
			bloc.position = Vector2(bloc.case * 16)
			s5e.occuper(bloc.case, bloc)
			for c in [Vector2i(14, 10), Vector2i(18, 10), Vector2i(18, 8)]:
				s5e._miroirs[c].frapper()
			s5e._tracer_rayon()
			var apres: bool = s5e._statue_au_soleil
			var disque_ok: bool = s5e._chanteur._au_soleil
			s5e.reinitialiser()
			s5e._tracer_rayon()
			if avant or not apres or not disque_ok or s5e._statue_au_soleil:
				_erreurs.append("Plume5e : soleil sur le coq au départ %s, après solution %s, disque %s, après R %s" % [avant, apres, disque_ok, s5e._statue_au_soleil])
			else:
				print("OK  Plume5e : bloc dégagé + 3 miroirs -> le soleil touche le coq, son disque s'allume ; R remet tout")
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
	# Vestibule gauche : le cristal lance l'énergie dans les runes du sol ; la porte ne s'ouvre qu'une fois les runes dorées
	if chemin.ends_with("world.tscn"):
		var v = scene.get_node_or_null("Vestibule")
		var et = root.get_node("Etat")
		if v == null or v._runes.size() != 5 or v._portes.is_empty():
			_erreurs.append("Vestibule gauche : il faut 5 runes et une porte")
		else:
			et.poser("vestibule_cristal")
			await process_frame
			var trop_tot: bool = v._portes[0].ouverte
			await create_timer(1.0).timeout
			var dorees: bool = v._runes.all(func(r): return r.modulate.a > 0.99)
			if trop_tot or not dorees or not v._portes[0].ouverte:
				_erreurs.append("Vestibule gauche : runes (%s) puis porte (trop tôt %s, ouverte %s)" % [dorees, trop_tot, v._portes[0].ouverte])
			else:
				print("OK  Vestibule gauche : cristal -> runes -> porte")
			et.drapeaux.erase("vestibule_cristal")
	# Vestibule droit : cadenas sur la porte, refus sans clé, icône de clé au HUD, le cadenas saute avec la clé
	if chemin.ends_with("aile_droite.tscn"):
		var v = scene.get_node_or_null("Vestibule")
		var et = root.get_node("Etat")
		var heros = scene.get("joueur")
		if v == null or v._portes_cle.is_empty() or v._portes_cle[0]._cadenas == null:
			_erreurs.append("Vestibule droit : porte à serrure sans cadenas")
		else:
			var p = v._portes_cle[0]
			p._touchee(heros)
			var refus: bool = not p.ouverte
			et.poser("d_cle_vestibule")
			var cle_hud: bool = scene._icone_cle.visible
			p._refus_t = -10.0
			p._touchee(heros)
			await process_frame
			if not (refus and cle_hud and p.ouverte and p._cadenas == null and not scene._icone_cle.visible):
				_erreurs.append("Vestibule droit : refus %s, clé au HUD %s, ouverte %s, cadenas parti %s, clé rangée %s" % [refus, cle_hud, p.ouverte, p._cadenas == null, not scene._icone_cle.visible])
			else:
				print("OK  Vestibule droit : cadenas, clé au HUD, ouverture")
			et.drapeaux.erase("d_cle_vestibule")
			et.drapeaux.erase("d_porte_vestibule")
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
	if parvis.case_stele("gauche") != Vector2i(7, 5) or parvis.case_stele("droite") != Vector2i(15, 5):
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


# Audio (pas, ambiance, niveaux des musiques) et règle « énigmes sans texte » (aucun `indice` dans les ailes du donjon).
func _tester_audio_et_sans_texte() -> void:
	for nom in ["herbe", "terre", "bois", "dalle", "pierre"]:
		if load("res://Assets/Sons/pas_%s.wav" % nom) == null:
			_erreurs.append("Bruit de pas manquant : pas_%s.wav" % nom)
	var amb = load("res://Assets/Sons/ambiance_donjon.wav")
	if not (amb is AudioStreamWAV):
		_erreurs.append("ambiance_donjon.wav introuvable")
	var gains: Dictionary = (load("res://Scripts/niveaux_musiques.gd") as GDScript).get_script_constant_map()["GAINS"]
	if gains.size() < 20:
		_erreurs.append("niveaux_musiques.gd vide (lancer Outils/rogner_musiques.py)")
	for chemin in ["res://Scenes/world.tscn", "res://Scenes/aile_droite.tscn"]:
		var monde: Node = (load(chemin) as PackedScene).instantiate()
		root.add_child(monde)
		await process_frame
		for e in monde.get_children():
			if _est_ecran(e) and e.indice != "":
				_erreurs.append("%s / %s : un indice texte reste (les énigmes sont sans texte)" % [chemin, e.name])
		monde.queue_free()
		await process_frame
	# surface des pas : herbe/terre au village, bois dans la maison, dalle dans le donjon
	var village: Node = (load("res://Scenes/village.tscn") as PackedScene).instantiate()
	root.add_child(village)
	await process_frame
	var vus := {}
	for e in village.get_children():
		if _est_ecran(e):
			vus[e.surface_pas(e.global_position + Vector2(200, 112))] = true
	for attendu in ["herbe", "bois"]:
		if not vus.has(attendu):
			_erreurs.append("Surface de pas « %s » jamais renvoyée au village" % attendu)
	village.queue_free()
	await process_frame
	print("OK  audio (pas, ambiance, niveaux) et énigmes sans texte")


func _conclure() -> void:
	if _erreurs.is_empty():
		print("=== TOUT EST BON ===")
		quit(0)
	else:
		for t in _erreurs:
			printerr("ERREUR : ", t)
		printerr("=== %d erreur(s) ===" % _erreurs.size())
		quit(1)
