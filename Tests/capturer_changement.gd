extends Node
## Outil : charge une scène, déclenche un CHANGEMENT DE SCÈNE (porte vers le village / le donjon) et capture l'écran pendant et après le fondu.
##   godot ... res://Tests/capturer_changement.tscn -- <scene.tscn> <cible @scene:Ecran> <x> <y> [drapeaux]
## (Le travail est fait par un objet RefCounted : il survit au remplacement de la scène courante.)

class Runner extends RefCounted:
	func run(arbre: SceneTree, a: PackedStringArray) -> void:
		arbre.change_scene_to_file(a[0])
		await arbre.create_timer(1.5).timeout
		arbre.current_scene._changer_de_scene(a[1], Vector2i(int(a[2]), int(a[3])), "")
		DirAccess.make_dir_recursive_absolute("user://captures")
		for i in 6:
			await arbre.create_timer(0.5).timeout
			arbre.root.get_texture().get_image().save_png("user://captures/chg_%d.png" % i)
			print("t=", (i + 1) * 0.5, " scène ", arbre.current_scene.name if arbre.current_scene else "aucune")
		arbre.quit(0)


var _runner


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	Etat.sauvegarde_active = false
	if a.size() > 4:
		for d in a[4].split(","):
			Etat.noter(d)
	_runner = Runner.new()
	Engine.set_meta("runner", _runner)   # garde l'objet en vie
	_runner.run(get_tree(), a)
