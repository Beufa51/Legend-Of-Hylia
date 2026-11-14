extends Node
## Outil : fait MARCHER le joueur (position modifiée pas à pas) d'un écran à l'autre et capture à la fin.
##   godot ... res://Tests/capturer_marche.tscn -- <scene.tscn> <EcranDepart> <x> <y> <dx> <dy> <nb_pas> [drapeaux]   (dx, dy en pixels par pas)
func _ready() -> void:
	_lancer.call_deferred()


func _lancer() -> void:
	var a := OS.get_cmdline_user_args()
	Etat.sauvegarde_active = false
	if a.size() > 7:
		for d in a[7].split(","):
			Etat.noter(d)
	Etat.arrivee_ecran = a[1]
	Etat.arrivee_case = Vector2i(int(a[2]), int(a[3]))
	var monde = load(a[0]).instantiate()
	add_child(monde)
	await get_tree().create_timer(1.5).timeout
	for i in int(a[6]):
		monde.joueur.position += Vector2(float(a[4]), float(a[5]))
		await get_tree().process_frame
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	DirAccess.make_dir_recursive_absolute("user://captures")
	get_tree().root.get_texture().get_image().save_png("user://captures/marche.png")
	print("camera ", monde.camera.position, " joueur ", monde.joueur.position, " salle ", monde.salle_actuelle)
	get_tree().quit(0)
