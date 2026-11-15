extends Node
## Outil : prend des captures d'écran réelles de quelques écrans (audit visuel). Lancer sous Xvfb :
##   xvfb-run -a godot --path . --rendering-driver opengl3 --audio-driver Dummy res://Tests/capturer_ecrans.tscn -- <scene.tscn> <Ecran1,Ecran2> [drapeau1,drapeau2]
## Les captures vont dans user://captures/<Ecran>.png. Le jeu n'est PAS sauvegardé (Etat.sauvegarde_active = faux).

func _ready() -> void:
	_lancer.call_deferred()


var _attente := 0.5


func _lancer() -> void:
	if OS.get_environment("ATTENTE") != "":
		_attente = float(OS.get_environment("ATTENTE"))
	var args := OS.get_cmdline_user_args()
	Etat.sauvegarde_active = false
	if args.size() > 2:
		for d in args[2].split(","):
			Etat.noter(d)
	var monde = load(args[0]).instantiate()
	add_child(monde)
	for i in 4:
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute("user://captures")
	for nom in args[1].split(","):
		var ecran = monde.get_node_or_null(nom)
		if ecran == null:
			print("écran introuvable : ", nom)
			continue
		if OS.get_environment("PONT") != "" and nom == "Plume3b":
			# variable PONT=1 : pousse les 3 blocs pour montrer le pont fini
			var plan := [[Vector2i(17, 8), [Vector2i.UP, 2]], [Vector2i(14, 8), [Vector2i.RIGHT, 3, Vector2i.UP, 3]], [Vector2i(20, 9), [Vector2i.LEFT, 3, Vector2i.UP, 5]]]
			for etape in plan:
				for bloc in ecran._blocs:
					if bloc.case == etape[0]:
						for k in range(0, etape[1].size(), 2):
							for i in etape[1][k + 1]:
								await bloc.pousser(etape[1][k])
		monde._teleporter(ecran)
		monde._menu_dev = null
		for i in 8:
			await get_tree().process_frame
		await get_tree().create_timer(_attente).timeout
		get_tree().root.get_texture().get_image().save_png("user://captures/%s.png" % nom)
		print("capture ", nom)
	get_tree().quit(0)
