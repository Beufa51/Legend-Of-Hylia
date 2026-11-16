extends SceneTree
## Mesure où passe le temps au démarrage : godot --headless --path . -s res://Tests/chrono_demarrage.gd
func _initialize() -> void:
	root.get_node("Etat").sauvegarde_active = false
	var t0 := Time.get_ticks_msec()
	var paquet: PackedScene = load("res://Scenes/village.tscn")
	var t1 := Time.get_ticks_msec()
	var monde = paquet.instantiate()
	var t2 := Time.get_ticks_msec()
	root.add_child(monde)
	var t3 := Time.get_ticks_msec()
	print("load .tscn : %d ms | instantiate : %d ms | add_child (_ready de tout) : %d ms" % [t1 - t0, t2 - t1, t3 - t2])
	await process_frame
	await process_frame
	print("2 images de plus : %d ms" % (Time.get_ticks_msec() - t3))
	quit(0)
