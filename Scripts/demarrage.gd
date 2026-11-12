extends Node
# Scène de démarrage (scène principale du projet) : envoie le joueur au bon endroit.
# Partie sauvegardée -> la scène où il était ; nouvelle partie -> le village.
# (Plus tard : écran titre, puis réveil dans la maison du héros.)

const NOUVELLE_PARTIE := "res://Scenes/village.tscn"


func _ready() -> void:
	var cible := NOUVELLE_PARTIE
	if Etat.scene_sauvee != "" and ResourceLoader.exists(Etat.scene_sauvee):
		cible = Etat.scene_sauvee
	get_tree().change_scene_to_file.call_deferred(cible)
