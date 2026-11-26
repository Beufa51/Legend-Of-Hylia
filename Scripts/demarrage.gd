extends Node
# Scène de démarrage (scène principale du projet) : affiche l'écran titre, puis envoie le joueur.
# « Continuer » -> la scène où il était (pas d'intro, pour ne pas la revoir à chaque fois) ;
# « Nouvelle partie » -> efface la sauvegarde, joue l'intro vidéo, puis va au village.
# (Plus tard : réveil dans la maison du héros ; vidéo d'accueil sur l'écran titre.)

const NOUVELLE_PARTIE := "res://Scenes/village.tscn"
const INTRO := "res://Assets/Titre/intro.ogv"

var _fini := false   # évite de changer de scène deux fois (fin naturelle + passage manuel)


func _ready() -> void:
	var titre := EcranTitre.new()
	add_child(titre)
	titre.choisi.connect(_demarrer)


func _demarrer(continuer: bool) -> void:
	if continuer and Etat.scene_sauvee != "" and ResourceLoader.exists(Etat.scene_sauvee):
		get_tree().change_scene_to_file.call_deferred(Etat.scene_sauvee)
		return
	Etat.effacer()   # nouvelle partie : on repart de zéro (efface aussi la sauvegarde manuelle)
	_jouer_intro()


# Intro vidéo plein écran. Espace / Entrée / clic = passer. Sans fichier vidéo, on passe tout de suite.
func _jouer_intro() -> void:
	var calque := CanvasLayer.new()
	calque.layer = 10
	add_child(calque)

	var fond := ColorRect.new()
	fond.color = Color.BLACK
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	calque.add_child(fond)

	if not ResourceLoader.exists(INTRO):
		_aller_au_village()
		return

	var video := VideoStreamPlayer.new()
	video.stream = load(INTRO)
	video.expand = true
	video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video.finished.connect(_aller_au_village)
	calque.add_child(video)
	video.play()

	# Zone invisible qui capte les touches et les clics pour passer l'intro.
	var passer := Control.new()
	passer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	passer.mouse_filter = Control.MOUSE_FILTER_STOP
	passer.gui_input.connect(_sur_passer)
	calque.add_child(passer)
	passer.grab_focus()


func _sur_passer(evenement: InputEvent) -> void:
	var pressé: bool = evenement.is_action_pressed("ui_accept")
	if evenement is InputEventMouseButton and evenement.pressed:
		pressé = true
	elif evenement is InputEventKey and evenement.pressed and not evenement.echo:
		pressé = true
	if pressé:
		_aller_au_village()


func _aller_au_village() -> void:
	if _fini:
		return
	_fini = true
	get_tree().change_scene_to_file.call_deferred(NOUVELLE_PARTIE)
