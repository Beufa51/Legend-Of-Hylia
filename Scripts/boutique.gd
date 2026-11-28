extends CanvasLayer
class_name Boutique
# La BOUTIQUE de Rosine (village est). Créée par world.gd hors donjon ; s'ouvre quand Rosine finit de parler
# (sa ligne dans `pnjs` se termine par « | boutique » : Etat.minijeu_demande("boutique")).
# Haut / bas : choisir   Espace / J / A : acheter   Échap / Maj / B : partir. Souris / doigt : toucher un article, le retoucher = acheter.
# Les meubles achetés vont dans la MALLE de la maison du héros (Etat.decors, x = -1) ; l'agrandissement lève « maison_agrandie ».

const SON_CHOIX := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Move2.wav"
const SON_ACHAT := "res://Assets/Ninja_adventure/Audio/Sounds/Bonus/Coin.wav"
const SON_NON := "res://Assets/Ninja_adventure/Audio/Sounds/Menu/Cancel.wav"
const ICONE_RUBIS := "res://Assets/Ninja_adventure/Items/Resource/GemGreen.png"
const OR := Color(0.98, 0.84, 0.4)
const VISIBLES := 6        # lignes de la liste visibles à la fois
const HAUTEUR_LIGNE := 20

var _ouverte := false
var _choix := 0
var _haut := 0             # première ligne visible (la liste défile)
var _achats := 0           # achats faits pendant cette visite
var _panneau: Panel
var _lignes: Array = []    # [Panel, TextureRect, Label nom, Label prix]
var _rubis: Label
var _texte: Label
var _fleche_haut: Label
var _fleche_bas: Label


func _ready() -> void:
	layer = 5
	Etat.minijeu_demande.connect(func(id): if id == "boutique": ouvrir())
	_panneau = Panel.new()
	_panneau.position = Vector2(36, 14)
	_panneau.size = Vector2(328, 196)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.16, 0.95)
	style.set_border_width_all(2)
	style.border_color = OR
	style.set_corner_radius_all(3)
	_panneau.add_theme_stylebox_override("panel", style)
	_panneau.visible = false
	add_child(_panneau)
	var titre := _label(Vector2(10, 4), Vector2(200, 14), 10, OR)
	titre.text = "Les meubles de Rosine"
	var gemme := TextureRect.new()
	gemme.texture = load(ICONE_RUBIS)
	gemme.position = Vector2(258, 3)
	_panneau.add_child(gemme)
	_rubis = _label(Vector2(276, 4), Vector2(48, 14), 10, Color.WHITE)
	for k in VISIBLES:
		var ligne := Panel.new()
		ligne.position = Vector2(8, 22 + k * HAUTEUR_LIGNE)
		ligne.size = Vector2(312, HAUTEUR_LIGNE - 2)
		ligne.gui_input.connect(_clic_ligne.bind(k))
		_panneau.add_child(ligne)
		var icone := TextureRect.new()
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.position = Vector2(3, 1)
		icone.size = Vector2(16, 16)
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ligne.add_child(icone)
		var nom := _label(Vector2(24, 2), Vector2(200, 14), 10, Color.WHITE)
		_panneau.remove_child(nom)
		ligne.add_child(nom)
		var prix := _label(Vector2(214, 2), Vector2(92, 14), 10, OR)
		prix.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_panneau.remove_child(prix)
		ligne.add_child(prix)
		_lignes.append([ligne, icone, nom, prix])
	_fleche_haut = _label(Vector2(158, 13), Vector2(12, 10), 8, OR)
	_fleche_haut.text = "▲"
	_fleche_bas = _label(Vector2(158, 140), Vector2(12, 10), 8, OR)
	_fleche_bas.text = "▼"
	_texte = _label(Vector2(10, 150), Vector2(308, 26), 9, Color(0.85, 0.87, 0.95))
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var aide := _label(Vector2(10, 178), Vector2(230, 12), 8, Color(0.55, 0.58, 0.7))
	aide.text = "Espace : acheter     Échap : partir"
	var partir := Panel.new()   # bouton « Partir » (souris / doigt)
	partir.position = Vector2(266, 176)
	partir.size = Vector2(54, 14)
	var style_bouton := StyleBoxFlat.new()
	style_bouton.bg_color = Color(0.2, 0.2, 0.36)
	style_bouton.set_border_width_all(1)
	style_bouton.border_color = OR
	style_bouton.set_corner_radius_all(2)
	partir.add_theme_stylebox_override("panel", style_bouton)
	partir.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: fermer())
	_panneau.add_child(partir)
	var texte_partir := _label(Vector2(0, 0), Vector2(54, 14), 9, Color.WHITE)
	texte_partir.text = "Partir"
	texte_partir.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panneau.remove_child(texte_partir)
	partir.add_child(texte_partir)


func _label(pos: Vector2, taille: Vector2, police: int, couleur: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = taille
	l.add_theme_font_size_override("font_size", police)
	l.add_theme_color_override("font_color", couleur)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panneau.add_child(l)
	return l


func ouvrir() -> void:
	if _ouverte:
		return
	_ouverte = true
	_achats = 0
	Etat.en_dialogue = true
	Etat.en_menu = true
	var joueur := get_tree().get_first_node_in_group("joueur")
	if joueur:
		joueur.set_physics_process(false)
		joueur.sprite.play("repos_" + joueur.direction)
	_panneau.visible = true
	_afficher()


func fermer() -> void:
	if not _ouverte:
		return
	_ouverte = false
	_panneau.visible = false
	_jouer(SON_CHOIX)
	await get_tree().create_timer(0.15).timeout   # (la touche qui ferme ne doit pas donner un coup de lance)
	Etat.en_dialogue = false
	Etat.en_menu = false
	var joueur := get_tree().get_first_node_in_group("joueur")
	if joueur:
		joueur.set_physics_process(true)
	if _achats > 0:
		Etat.annoncer("Tes achats t'attendent dans la malle, chez toi. Frappe-la avec ta lance pour décorer !")


# --- Les articles ------------------------------------------------------------------------------------

func _articles() -> Array:
	var liste := []
	for id in Decors.ORDRE:
		if id == Decors.AGRANDIR and Etat.est(Decors.DRAPEAU_AGRANDIE):
			continue   # déjà fait : l'article disparaît
		liste.append(id)
	return liste


func _nom(id: String) -> String:
	return "Agrandir la maison" if id == Decors.AGRANDIR else Decors.CATALOGUE[id]["nom"]


func _prix(id: String) -> int:
	return Decors.PRIX_AGRANDIR if id == Decors.AGRANDIR else Decors.CATALOGUE[id]["prix"]


func _complet(id: String) -> bool:
	return id != Decors.AGRANDIR and Decors.nombre(id) >= Decors.CATALOGUE[id]["max"]


func _afficher() -> void:
	var articles := _articles()
	_choix = clampi(_choix, 0, articles.size() - 1)
	if _choix < _haut:
		_haut = _choix
	elif _choix >= _haut + VISIBLES:
		_haut = _choix - VISIBLES + 1
	_rubis.text = str(Etat.rubis)
	for k in VISIBLES:
		var l: Array = _lignes[k]
		var i := _haut + k
		l[0].visible = i < articles.size()
		if i >= articles.size():
			continue
		var id: String = articles[i]
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.36, 0.95) if i == _choix else Color(0.1, 0.11, 0.2, 0.6)
		style.set_border_width_all(1 if i == _choix else 0)
		style.border_color = OR
		l[0].add_theme_stylebox_override("panel", style)
		l[1].texture = load("res://Assets/Gemini/tuiles/v_maison_bleue.png") if id == Decors.AGRANDIR else _charger(Decors.CATALOGUE[id]["image"])
		var nom := _nom(id)
		if id != Decors.AGRANDIR:
			nom += "   %d/%d" % [Decors.nombre(id), Decors.CATALOGUE[id]["max"]]
		l[2].text = nom
		var complet := _complet(id)
		l[2].modulate = Color(1, 1, 1, 0.45) if complet else Color.WHITE
		l[3].text = "vendu !" if complet else "%d rubis" % _prix(id)
		l[3].add_theme_color_override("font_color", Color(0.6, 0.62, 0.7) if complet else (OR if Etat.rubis >= _prix(id) else Color(1, 0.45, 0.4)))
	_fleche_haut.visible = _haut > 0
	_fleche_bas.visible = _haut + VISIBLES < articles.size()
	var choisi: String = articles[_choix]
	if choisi == Decors.AGRANDIR:
		_texte.text = "Des ouvriers du village abattent les murs de côté : ta maison devient deux fois plus large !"
	else:
		_texte.text = Decors.CATALOGUE[choisi]["texte"]


func _charger(image: String) -> Texture2D:
	var chemin := Ecran.DOSSIER + image + ".png"
	return load(chemin) if ResourceLoader.exists(chemin) else null


func _acheter() -> void:
	var articles := _articles()
	var id: String = articles[_choix]
	if _complet(id):
		_jouer(SON_NON)
		_texte.text = "Tu en as déjà assez ! Ta maison n'est pas une boutique."
		return
	if not Etat.depenser_rubis(_prix(id)):
		_jouer(SON_NON)
		_texte.text = "Il te manque %d rubis. Coupe des herbes, casse des pots... et reviens !" % (_prix(id) - Etat.rubis)
		return
	_jouer(SON_ACHAT)
	_achats += 1
	if id == Decors.AGRANDIR:
		Etat.poser(Decors.DRAPEAU_AGRANDIE)
		_afficher()
		_texte.text = "Marché conclu ! Ta maison est plus grande. Va voir !"
		return
	Etat.decors.append({"id": id, "x": -1, "y": -1})
	Etat.sauver()
	_afficher()
	_texte.text = "Merci ! « %s » sera livré dans la malle de ta maison." % _nom(id)


# --- Entrées -------------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not _ouverte:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("run"):
		get_viewport().set_input_as_handled()
		fermer()
	elif event.is_action_pressed("move_down", true) or event.is_action_pressed("move_up", true):
		get_viewport().set_input_as_handled()
		_choix = posmod(_choix + (1 if event.is_action_pressed("move_down", true) else -1), _articles().size())
		_jouer(SON_CHOIX)
		_afficher()
	elif event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_acheter()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()   # (le reste des touches est ignoré pendant les achats)


func _clic_ligne(event: InputEvent, k: int) -> void:
	if not _ouverte or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var i := _haut + k
	if i == _choix:
		_acheter()
	else:
		_choix = i
		_jouer(SON_CHOIX)
		_afficher()


func _jouer(chemin: String) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = -10.0
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)
