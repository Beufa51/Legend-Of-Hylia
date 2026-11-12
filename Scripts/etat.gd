extends Node
# Mémoire de la partie (autoload "Etat" : accessible partout sous le nom Etat).
# Les "drapeaux" sont des mots (ex. "plume1") qu'on lève quand une énigme est résolue ;
# les portes écoutent ces drapeaux pour s'ouvrir.
# SAUVEGARDE : les drapeaux et la dernière position sûre du joueur sont écrits dans
# user://sauvegarde.json à chaque changement (sur le web, le navigateur les garde aussi).

signal drapeau_change(nom: String)   # un drapeau vient d'être levé
signal message(texte: String)        # un message à afficher à l'écran
signal secousse                      # l'écran tremble (une porte s'ouvre...)
signal dialogue_demande(nom: String, lignes: PackedStringArray)   # un habitant parle (boîte de dialogue)
signal passage(ecran: String, case: Vector2i)   # le joueur franchit une porte : il arrive dans l'écran `ecran`, sur la case `case`
signal repere(retour: Vector2)       # une sentinelle a vu le joueur : un garde le ramène à `retour`

const FICHIER := "user://sauvegarde.json"

var drapeaux := {}
var en_dialogue := false              # vrai pendant une conversation (le joueur est figé)
var salle_courante := Vector2i.ZERO   # case de la grille où se trouve la caméra (mise à jour par world.gd)
var position_sauvee := Vector2.ZERO   # où reprendre la partie (Vector2.ZERO = nouvelle partie)
var scene_sauvee := ""                # dans quelle scène (donjon ou village) reprendre la partie


func _ready() -> void:
	charger()


func poser(nom: String) -> void:
	if nom == "" or drapeaux.get(nom, false):
		return
	drapeaux[nom] = true
	sauver()
	drapeau_change.emit(nom)


# Lève un drapeau EN SILENCE (pas de jingle, les portes ne sont pas prévenues) : pour se souvenir
# d'un événement déjà vu (ex. une cinématique).
func noter(nom: String) -> void:
	drapeaux[nom] = true
	sauver()


func est(nom: String) -> bool:
	return nom != "" and drapeaux.get(nom, false)


func annoncer(texte: String) -> void:
	message.emit(texte)


# Retient l'endroit où reprendre la partie (appelé quand le joueur entre dans une salle).
func memoriser_position(pos: Vector2) -> void:
	position_sauvee = pos
	scene_sauvee = get_tree().current_scene.scene_file_path
	sauver()


func sauver() -> void:
	var fichier := FileAccess.open(FICHIER, FileAccess.WRITE)
	if fichier == null:
		push_warning("Sauvegarde impossible : " + FICHIER)
		return
	fichier.store_string(JSON.stringify({
		"drapeaux": drapeaux.keys(),
		"x": position_sauvee.x,
		"y": position_sauvee.y,
		"scene": scene_sauvee,
	}))


func charger() -> void:
	if not FileAccess.file_exists(FICHIER):
		return
	var donnees = JSON.parse_string(FileAccess.get_file_as_string(FICHIER))
	if not donnees is Dictionary:
		return
	for nom in donnees.get("drapeaux", []):
		drapeaux[nom] = true
	position_sauvee = Vector2(donnees.get("x", 0.0), donnees.get("y", 0.0))
	# (les premières sauvegardes n'avaient pas de scène : elles venaient forcément du donjon)
	scene_sauvee = donnees.get("scene", "res://Scenes/world.tscn" if position_sauvee != Vector2.ZERO else "")


# Nouvelle partie : tout oublier (mode développeur).
func effacer() -> void:
	drapeaux.clear()
	position_sauvee = Vector2.ZERO
	scene_sauvee = ""
	if FileAccess.file_exists(FICHIER):
		DirAccess.remove_absolute(FICHIER)
