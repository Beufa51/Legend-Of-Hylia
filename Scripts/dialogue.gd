extends CanvasLayer
class_name Dialogue
# Boîte de dialogue en bas de l'écran (créée par world.gd). Écoute Etat.dialogue_demande.
# Le texte s'écrit lettre par lettre ; Espace/J (ou Entrée) : finit la ligne, puis passe à la suivante.
# Pendant le dialogue, le joueur ne bouge pas.
# CHOIX (Etat.choix_demande) : après la dernière ligne, des options s'affichent ; haut/bas pour choisir,
# Espace/J pour valider -> Etat.choix_fait(index).

const SON := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Accept.wav"
const VITESSE := 45.0   # lettres par seconde

var _boite: Panel
var _nom: Label
var _texte: Label
var _suite: Label
var _lignes: PackedStringArray
var _index := 0
var _tween: Tween
var _ouvert := false
var _options: PackedStringArray = []   # options du choix (vide = dialogue simple)
var _choix := 0                        # option sélectionnée
var _en_choix := false                 # les options sont affichées


func _ready() -> void:
	layer = 4   # au-dessus des messages (calque 3)
	_boite = Panel.new()
	_boite.position = Vector2(12, 150)
	_boite.size = Vector2(376, 66)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.16, 0.94)
	style.set_border_width_all(2)
	style.border_color = Color(0.93, 0.78, 0.35)
	style.set_corner_radius_all(3)
	_boite.add_theme_stylebox_override("panel", style)
	_boite.visible = false
	add_child(_boite)
	_nom = _etiquette(Vector2(10, 4), Vector2(356, 14), Color(0.98, 0.84, 0.4))
	_texte = _etiquette(Vector2(10, 19), Vector2(356, 40), Color.WHITE)
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_suite = _etiquette(Vector2(350, 50), Vector2(20, 14), Color(0.98, 0.84, 0.4))
	_suite.text = "▼"
	Etat.dialogue_demande.connect(_ouvrir)
	Etat.choix_demande.connect(_ouvrir_choix)


func _ouvrir_choix(nom: String, lignes: PackedStringArray, options: PackedStringArray) -> void:
	_options = options
	_ouvrir(nom, lignes)


# Affiche les options à la place du texte : « ▶ » devant celle qui est choisie.
func _afficher_options() -> void:
	_en_choix = true
	_suite.visible = false
	var texte := ""
	for i in _options.size():
		texte += ("▶ " if i == _choix else "    ") + _options[i] + "\n"
	_texte.text = texte
	_texte.visible_characters = -1


func _etiquette(pos: Vector2, taille: Vector2, couleur: Color) -> Label:
	var e := Label.new()
	e.position = pos
	e.size = taille
	e.add_theme_font_size_override("font_size", 10)
	e.add_theme_color_override("font_color", couleur)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boite.add_child(e)
	return e


func _ouvrir(nom: String, lignes: PackedStringArray) -> void:
	if _ouvert or lignes.is_empty():
		return
	_ouvert = true
	Etat.en_dialogue = true
	_lignes = lignes
	_index = 0
	_nom.text = nom
	_boite.visible = true
	_geler_joueur(true)
	_afficher_ligne()


func _afficher_ligne() -> void:
	_texte.text = _lignes[_index]
	_texte.visible_characters = 0
	_suite.visible = false
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_texte, "visible_characters", _lignes[_index].length(), _lignes[_index].length() / VITESSE)
	_tween.finished.connect(func(): _suite.visible = true)
	_jouer_son()


func _unhandled_input(event: InputEvent) -> void:
	if _ouvert and _en_choix and (event.is_action_pressed("move_up") or event.is_action_pressed("move_down")):
		get_viewport().set_input_as_handled()
		_choix = posmod(_choix + (1 if event.is_action_pressed("move_down") else -1), _options.size())
		_jouer_son()
		_afficher_options()
		return
	if not _ouvert or not (event.is_action_pressed("attack") or event.is_action_pressed("ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if _en_choix:   # option validée
		var choisi := _choix
		_en_choix = false
		_options = []
		_choix = 0
		_fermer()
		Etat.choix_fait.emit(choisi)
		return
	if _tween and _tween.is_running():   # ligne pas finie : on l'affiche en entier
		_tween.kill()
		_texte.visible_characters = -1
		_suite.visible = true
		return
	_index += 1
	if _index < _lignes.size():
		_afficher_ligne()
	elif not _options.is_empty():
		_afficher_options()
	else:
		_fermer()


func _fermer() -> void:
	_boite.visible = false
	_ouvert = false
	# Petit délai : sinon la touche qui ferme la boîte déclencherait aussitôt un coup de lance
	await get_tree().create_timer(0.15).timeout
	Etat.en_dialogue = false
	_geler_joueur(false)
	Etat.dialogue_fini.emit()


func _geler_joueur(gele: bool) -> void:
	var joueur := get_tree().get_first_node_in_group("joueur")
	if joueur:
		joueur.set_physics_process(not gele)
		if gele:
			joueur.sprite.play("repos_" + joueur.direction)


func _jouer_son() -> void:
	var flux = load(SON)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -14.0
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
