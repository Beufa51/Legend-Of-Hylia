extends Node
## Test de la cinématique d'assemblage (Scripts/assemblage.gd) : la joue en accéléré et vérifie qu'elle se termine sans erreur.
## Lancer : godot --headless --path . res://Tests/verifier_assemblage.tscn   (scène, pour avoir les autoloads ; code de sortie 0 = bon)
## Option : -- capture   -> prend des captures d'écran (il faut un vrai rendu : xvfb-run, pas --headless) dans user://captures/

func _ready() -> void:
	_lancer.call_deferred()


func _lancer() -> void:
	var monde := Node2D.new()
	add_child(monde)
	var capture := "capture" in OS.get_cmdline_user_args()
	var a := Assemblage.new()
	a.monde = monde
	monde.add_child(a)
	if capture:
		DirAccess.make_dir_recursive_absolute("user://captures")
		var instants := [0.3, 1.8, 3.5, 5.5, 8.0, 14.5, 19.0, 21.0, 27.0, 29.0, 30.2, 33.0, 36.5, 40.5, 44.0, 47.5, 50.5, 52.8]
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		a.set_process(false)
		for x in instants:
			a._i_evt = 0
			while a._i_evt < a._evenements.size() and a._evenements[a._i_evt][0] <= x:
				a._i_evt += 1   # (on saute les événements : on veut seulement l'image)
			a.t = x
			a._secousse = 0.0
			a._evaluer(x)
			await get_tree().process_frame
			await get_tree().process_frame
			var img := get_tree().root.get_texture().get_image()
			img.save_png("user://captures/t%04.1f.png" % x)
		print("captures dans ", ProjectSettings.globalize_path("user://captures"))
		get_tree().quit(0)
		return
	Engine.time_scale = 25.0
	var debut := Time.get_ticks_msec()
	await a.termine
	Engine.time_scale = 1.0
	print("OK  assemblage : terminé en %d ms (x25), t = %.1f" % [Time.get_ticks_msec() - debut, a.t])
	get_tree().quit(0)
