extends CanvasLayer
class_name EcranTitre
# Écran titre : fond du village au crépuscule, titre doré, menu Continuer / Nouvelle partie.
# Émet `choisi(continuer)` ; c'est Scripts/demarrage.gd qui lance la bonne scène.

signal choisi(continuer: bool)

const OR := Color(0.98, 0.84, 0.4)
const FOND := "res://Assets/Titre/fond_titre.jpg"

var _boutons: Array[Button] = []


func _ready() -> void:
	layer = 10

	# Fond : image du village (plein écran, recadrée pour remplir le 400x224).
	var fond := TextureRect.new()
	fond.texture = load(FOND)
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

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
	if Etat.scene_sauvee != "":
		_ajouter_bouton(menu, "Continuer", func() -> void: choisi.emit(true))
	_ajouter_bouton(menu, "Nouvelle partie", func() -> void: choisi.emit(false))
	if _boutons.size() > 0:
		_boutons[0].grab_focus()


func _ajouter_bouton(parent: Node, texte: String, action: Callable) -> void:
	var bouton := Button.new()
	bouton.text = texte
	bouton.custom_minimum_size = Vector2(120, 22)
	bouton.pressed.connect(action)
	parent.add_child(bouton)
	_boutons.append(bouton)
