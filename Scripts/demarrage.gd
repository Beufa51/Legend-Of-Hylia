extends Node
# Scène de démarrage (scène principale du projet) : affiche l'écran titre, puis envoie le joueur.
# « Continuer » -> la scène où il était ; « Nouvelle partie » -> efface la sauvegarde et va au village.
# (Plus tard : réveil dans la maison du héros, puis l'intro.)

const NOUVELLE_PARTIE := "res://Scenes/village.tscn"


func _ready() -> void:
	var titre := EcranTitre.new()
	add_child(titre)
	titre.choisi.connect(_demarrer)


func _demarrer(continuer: bool) -> void:
	var cible := NOUVELLE_PARTIE
	if continuer and Etat.scene_sauvee != "" and ResourceLoader.exists(Etat.scene_sauvee):
		cible = Etat.scene_sauvee
	else:
		Etat.effacer()   # nouvelle partie : on repart de zéro (efface aussi la sauvegarde manuelle)
	get_tree().change_scene_to_file.call_deferred(cible)
