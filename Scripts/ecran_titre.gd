extends CanvasLayer
class_name EcranTitre
# Écran titre : fond du village au crépuscule, titre doré, menu Continuer / Nouvelle partie.
# Émet `choisi(continuer)` ; c'est Scripts/demarrage.gd qui lance la bonne scène.

signal choisi(continuer: bool)

const OR := Color(0.98, 0.84, 0.4)
const FOND := "res://Assets/Titre/fond_titre.jpg"
const VIDEO := "res://Assets/Titre/intro.ogv"   # intro en boucle ; sans elle, on garde l'image fixe

var _boutons: Array[Button] = []
var _menu: VBoxContainer
var _confirmation: VBoxContainer
var _bouton_non: Button


func _ready() -> void:
	layer = 10

	# Fond : image du village (plein écran, recadrée pour remplir le 400x224).
	var fond := TextureRect.new()
	fond.texture = load(FOND)
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	# Intro vidéo par-dessus l'image : elle tourne en boucle (l'image reste visible si la vidéo manque).
	if ResourceLoader.exists(VIDEO):
		var video := VideoStreamPlayer.new()
		video.stream = load(VIDEO)
		video.expand = true   # remplit tout l'écran
		video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		video.finished.connect(video.play)   # boucle
		add_child(video)
		video.play()

	# Léger voile sombre pour que le texte ressorte.
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.25)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(voile)

	# Titre doré avec contour sombre.
	var titre := Label.new()
	titre.text = Noms.TITRE_JEU
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.position = Vector2(0, 30)
	titre.size = Vector2(400, 40)
	titre.add_theme_font_size_override("font_size", 22)
	titre.add_theme_color_override("font_color", OR)
	titre.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.02))
	titre.add_theme_constant_override("outline_size", 4)
	add_child(titre)

	# Menu : « Continuer » seulement s'il existe une partie sauvegardée.
	var menu := VBoxContainer.new()
	menu.position = Vector2(140, 130)
	menu.size = Vector2(120, 70)
	add_child(menu)
	_menu = menu
	if Etat.scene_sauvee != "":
		_ajouter_bouton(menu, "Continuer", func() -> void: choisi.emit(true))
	_ajouter_bouton(menu, "Nouvelle partie", _nouvelle_partie)
	if _boutons.size() > 0:
		_boutons[0].grab_focus()

	# Confirmation (affichée seulement si une sauvegarde existe et serait effacée).
	_confirmation = VBoxContainer.new()
	_confirmation.position = Vector2(100, 120)
	_confirmation.size = Vector2(200, 80)
	_confirmation.visible = false
	add_child(_confirmation)
	var question := Label.new()
	question.text = "Effacer la partie sauvegardée ?"
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.add_theme_color_override("font_color", OR)
	question.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.02))
	question.add_theme_constant_override("outline_size", 3)
	_confirmation.add_child(question)
	_bouton_non = _ajouter_bouton(_confirmation, "Non, continuer", _annuler_confirmation)
	_ajouter_bouton(_confirmation, "Oui, effacer", func() -> void: choisi.emit(false))


# « Nouvelle partie » : s'il existe une sauvegarde, on demande d'abord confirmation (Non par défaut).
func _nouvelle_partie() -> void:
	if Etat.scene_sauvee == "" and not Etat.a_sauvegarde_manuelle():
		choisi.emit(false)
		return
	_menu.visible = false
	_confirmation.visible = true
	_bouton_non.grab_focus()


func _annuler_confirmation() -> void:
	_confirmation.visible = false
	_menu.visible = true
	_boutons[0].grab_focus()


func _ajouter_bouton(parent: Node, texte: String, action: Callable) -> Button:
	var bouton := Button.new()
	bouton.text = texte
	bouton.custom_minimum_size = Vector2(120, 22)
	bouton.pressed.connect(action)
	parent.add_child(bouton)
	_boutons.append(bouton)
	return bouton
