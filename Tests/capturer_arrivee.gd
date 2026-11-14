extends Node
## Outil : simule l'ARRIVÉE dans une scène depuis une autre (comme _changer_de_scene) et prend une capture après 1,5 s.
##   godot ... res://Tests/capturer_arrivee.tscn -- <scene.tscn> <Ecran> <x> <y> [drapeau1,drapeau2]
func _ready() -> void:
	_lancer.call_deferred()


func _lancer() -> void:
	var a := OS.get_cmdline_user_args()
	Etat.sauvegarde_active = false
	if a.size() > 4:
		for d in a[4].split(","):
			Etat.noter(d)
	Etat.arrivee_ecran = a[1]
	Etat.arrivee_case = Vector2i(int(a[2]), int(a[3]))
	var monde = load(a[0]).instantiate()
	add_child(monde)
	await get_tree().create_timer(2.0).timeout
	DirAccess.make_dir_recursive_absolute("user://captures")
	get_tree().root.get_texture().get_image().save_png("user://captures/arrivee_%s.png" % a[1])
	print("camera ", monde.camera.position, " joueur ", monde.joueur.position)
	get_tree().quit(0)
