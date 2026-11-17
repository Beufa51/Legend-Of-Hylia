extends Node
class_name EditeurDecor
# ÉDITEUR DE DÉCOR (mode développeur, touche F2 ; seulement quand on lance le jeu depuis Godot).
# Tu déplaces toi-même miroirs, statues, coqs, pots, cloches... avec la souris :
#   - clic sur un objet = le PRENDRE, clic sur une case vide = le POSER (la salle se recharge tout de suite) ;
#   - clic droit ou Échap = annuler la prise ; Suppr (sur un objet survolé) = le supprimer ;
#   - panneau de droite = ajouter un nouvel objet ; boutons du haut = annuler le dernier changement / revenir au plan d'origine.
# Les changements sont écrits dans `res://ajustements_decor.json` (un plan par écran) et relus au chargement de chaque salle.
# ATTENTION : seul le PLAN (les lettres) bouge. Les réglages donnés en coordonnées (chemin de runes, retour des sentinelles...)
# ne suivent pas : déplace plutôt les objets « libres ». Pour rendre les changements définitifs dans les générateurs
# (Outils/generer_*.py), demande à Claude de les intégrer, puis supprime le fichier json.

const FICHIER := "res://ajustements_decor.json"
const TUILE := 16

# Objets qu'on peut déplacer / poser (une lettre = une case dans le plan du donjon).
const OBJETS := {
	"M": "miroir /", "N": "miroir \\", "S": "statue chevalier", "O": "statue coq", "C": "coq chanteur",
	"I": "stèle à inscription", "V": "pot", "U": "pot sonore", "B": "brasero allumé", "L": "brasero à allumer",
	"l": "foyer", "X": "bloc", "P": "marque / bouton", "K": "cristal", "Q": "coffre", "J": "levier",
	"G": "plume dorée", "W": "fragment d'aile", "Y": "réceptacle", "1": "cloche 1", "2": "cloche 2",
	"3": "cloche 3", "4": "cloche 4", "5": "cloche 5", "^": "sentinelle haut", "v": "sentinelle bas",
	"<": "sentinelle gauche", ">": "sentinelle droite", "r": "départ du reflet", "a": "dalle du reflet",
}

static var _cache = null              # contenu du json (vidé à chaque écriture)
static var _histo: Array = []         # changements précédents (pour « Annuler ») : {scene, nom, avant}
static var reouvrir := false          # vrai = l'éditeur se rouvre après le rechargement de la salle

var monde: Node2D
var actif := false
var _main := ""                       # lettre tenue à la souris ("" = rien)
var _origine := Vector2i(-1, -1)      # case d'où l'objet a été pris (-1 = pris dans le panneau)
var _plan: Array = []                 # plan modifiable de la salle (liste de textes)
var _salle: Ecran
var _surcouche: Node2D
var _etiquettes: Array = []
var _fantome: Label
var _cadre: ColorRect
var _ui: CanvasLayer
var _info: Label
var _palette: Control
var _haut: Control   # barre du haut (boutons) : un clic dessus ne doit pas toucher le décor


static func creer(le_monde: Node2D) -> EditeurDecor:
	var e := EditeurDecor.new()
	e.monde = le_monde
	return e


# --- Lecture / écriture du fichier ------------------------------------------------------------

static func _lire() -> Dictionary:
	if _cache == null:
		_cache = {}
		if FileAccess.file_exists(FICHIER):
			var f := FileAccess.open(FICHIER, FileAccess.READ)
			var donnees = JSON.parse_string(f.get_as_text())
			if donnees is Dictionary:
				_cache = donnees
	return _cache


static func _ecrire(donnees: Dictionary) -> void:
	var f := FileAccess.open(FICHIER, FileAccess.WRITE)
	if f == null:
		push_warning("Éditeur de décor : impossible d'écrire " + FICHIER)
		return
	f.store_string(JSON.stringify(donnees, "\t"))
	f.close()
	_cache = null


# Appelé par chaque écran quand il entre dans la scène : prend le plan ajusté s'il existe.
static func surcharger(ecran: Ecran) -> void:
	if ecran.owner == null or ecran.owner.scene_file_path == "":
		return
	var scene: Dictionary = _lire().get(ecran.owner.scene_file_path.get_file(), {})
	var plan = scene.get(String(ecran.name), null)
	if plan is Array and plan.size() == 14:
		for ligne in plan:
			if not (ligne is String) or ligne.length() != 25:
				return
		ecran.layout = PackedStringArray(plan)


# --- Activation ---------------------------------------------------------------------------------

func _ready() -> void:
	if reouvrir:
		reouvrir = false
		_activer.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			if actif:
				_desactiver()
			else:
				_activer()
			get_viewport().set_input_as_handled()
			return
		if actif and event.keycode == KEY_ESCAPE:
			_annuler_prise()
			get_viewport().set_input_as_handled()
			return
		if actif and event.keycode == KEY_DELETE and _main == "":
			_supprimer(_case_souris())
			return


# Les clics sont lus ici (avant l'interface) : un autre élément plein écran du jeu pouvait avaler le clic
# avant `_unhandled_input`. On ignore seulement les clics sur la barre du haut et la liste de droite.
func _input(event: InputEvent) -> void:
	if not actif or not (event is InputEventMouseButton and event.pressed):
		return
	for zone in [_haut, _palette]:
		if zone and zone.get_global_rect().has_point(event.position):
			return
	if event.button_index == MOUSE_BUTTON_LEFT:
		_clic(_case_souris())
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_annuler_prise()
		get_viewport().set_input_as_handled()


func _activer() -> void:
	_salle = null
	for e in monde.get_children():
		if e is Room and e.grille == monde.salle_actuelle:
			_salle = e
	if _salle == null:
		Etat.annoncer("Éditeur de décor : seulement dans une salle de donjon.")
		return
	actif = true
	monde.joueur.set_physics_process(false)
	monde.joueur.velocity = Vector2.ZERO
	_plan = Array(_salle.layout)
	_creer_interface()
	_rafraichir()


func _desactiver() -> void:
	actif = false
	_main = ""
	if _ui:
		_ui.queue_free()
		_ui = null
	if _surcouche:
		_surcouche.queue_free()
		_surcouche = null
	_etiquettes.clear()
	monde.joueur.set_physics_process(not monde.en_transition)


func _creer_interface() -> void:
	# Étiquettes (une lettre sur chaque objet déplaçable) : dans le monde, au-dessus de tout.
	_surcouche = Node2D.new()
	_surcouche.z_index = 200
	_salle.add_child(_surcouche)
	_cadre = ColorRect.new()
	_cadre.size = Vector2(TUILE, TUILE)
	_surcouche.add_child(_cadre)
	_fantome = Label.new()
	_fantome.add_theme_font_size_override("font_size", 8)
	_fantome.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	_fantome.add_theme_color_override("font_outline_color", Color.BLACK)
	_fantome.add_theme_constant_override("outline_size", 3)
	_fantome.visible = false
	_surcouche.add_child(_fantome)
	# Panneau fixe (haut + liste d'objets à droite).
	_ui = CanvasLayer.new()
	_ui.layer = 11
	monde.add_child(_ui)
	var haut := PanelContainer.new()
	haut.position = Vector2(2, 1)
	_haut = haut
	_ui.add_child(haut)
	var ligne := HBoxContainer.new()
	haut.add_child(ligne)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 7)
	_info.custom_minimum_size = Vector2(150, 0)
	ligne.add_child(_info)
	for b in [["Annuler", _annuler_dernier], ["Origine", _plan_origine], ["Quitter", _desactiver]]:
		var bouton := Button.new()
		bouton.text = b[0]
		bouton.add_theme_font_size_override("font_size", 7)
		bouton.focus_mode = Control.FOCUS_NONE
		bouton.pressed.connect(b[1])
		ligne.add_child(bouton)
	var defil := ScrollContainer.new()
	defil.position = Vector2(300, 22)
	defil.custom_minimum_size = Vector2(96, 196)
	defil.size = Vector2(96, 196)
	_ui.add_child(defil)
	var liste := VBoxContainer.new()
	defil.add_child(liste)
	for lettre in OBJETS:
		var bouton := Button.new()
		bouton.text = "%s  %s" % [lettre, OBJETS[lettre]]
		bouton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bouton.add_theme_font_size_override("font_size", 7)
		bouton.focus_mode = Control.FOCUS_NONE
		bouton.pressed.connect(_prendre_du_panneau.bind(lettre))
		liste.add_child(bouton)
	_palette = defil


# Redessine les étiquettes d'après le plan courant.
func _rafraichir() -> void:
	for e in _etiquettes:
		e.queue_free()
	_etiquettes.clear()
	for y in _plan.size():
		for x in _plan[y].length():
			var c: String = _plan[y][x]
			if OBJETS.has(c):
				var l := Label.new()
				l.text = c
				l.position = Vector2(x * TUILE + 3, y * TUILE - 1)
				l.add_theme_font_size_override("font_size", 8)
				l.add_theme_color_override("font_color", Color(1, 1, 1))
				l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
				l.add_theme_constant_override("outline_size", 4)
				_surcouche.add_child(l)
				_etiquettes.append(l)
	_texte_info()


func _texte_info() -> void:
	if _main == "":
		_info.text = "%s : clic = prendre, Suppr = supprimer" % _salle.name
	else:
		_info.text = "« %s » : clic = poser, clic droit = annuler" % OBJETS.get(_main, _main)


func _process(_delta: float) -> void:
	if not actif or _salle == null:
		return
	var survol := _case_souris()
	_cadre.visible = _dans_plan(survol)
	_cadre.position = Vector2(survol.x * TUILE, survol.y * TUILE)
	if _main == "":
		_cadre.color = Color(1, 0.9, 0.2, 0.3) if OBJETS.has(_lettre(survol)) else Color(1, 1, 1, 0.08)
	else:
		_cadre.color = Color(0.2, 1, 0.3, 0.4) if _lettre(survol) == "." else Color(1, 0.2, 0.2, 0.4)
	if _main != "":
		var c := survol
		_fantome.visible = true
		_fantome.text = _main
		_fantome.position = Vector2(c.x * TUILE + 3, c.y * TUILE - 1)
	else:
		_fantome.visible = false


func _case_souris() -> Vector2i:
	var local := _salle.get_local_mouse_position()
	return Vector2i(floori(local.x / TUILE), floori(local.y / TUILE))


func _dans_plan(c: Vector2i) -> bool:
	return c.y >= 0 and c.y < _plan.size() and c.x >= 0 and c.x < _plan[c.y].length()


func _lettre(c: Vector2i) -> String:
	return _plan[c.y][c.x] if _dans_plan(c) else ""


func _poser_lettre(c: Vector2i, lettre: String) -> void:
	var ligne: String = _plan[c.y]
	_plan[c.y] = ligne.substr(0, c.x) + lettre + ligne.substr(c.x + 1)


func _clic(c: Vector2i) -> void:
	if not _dans_plan(c):
		return
	var l := _lettre(c)
	if _main == "":
		if OBJETS.has(l):
			_main = l
			_origine = c
			_poser_lettre(c, ".")
			_rafraichir()
		elif l != ".":
			Etat.annoncer("Cet élément (mur, porte, tapis...) ne se déplace pas ici.")
	else:
		if l == ".":
			_poser_lettre(c, _main)
			_main = ""
			_enregistrer_et_recharger()
		else:
			Etat.annoncer("Case occupée : choisis une case vide.")


func _prendre_du_panneau(lettre: String) -> void:
	_annuler_prise()
	_main = lettre
	_origine = Vector2i(-1, -1)
	_texte_info()


func _annuler_prise() -> void:
	if _main != "" and _origine.x >= 0:
		_poser_lettre(_origine, _main)   # l'objet repart d'où il venait
	_main = ""
	if actif:
		_rafraichir()


func _supprimer(c: Vector2i) -> void:
	if _dans_plan(c) and OBJETS.has(_lettre(c)):
		_poser_lettre(c, ".")
		_enregistrer_et_recharger()


# --- Enregistrement ----------------------------------------------------------------------------

func _cle_scene() -> String:
	return monde.scene_file_path.get_file()


func _enregistrer_et_recharger() -> void:
	var donnees := _lire().duplicate(true)
	var scene: Dictionary = donnees.get(_cle_scene(), {})
	_histo.append({"scene": _cle_scene(), "nom": String(_salle.name), "avant": scene.get(String(_salle.name), null)})
	scene[String(_salle.name)] = _plan.duplicate()
	donnees[_cle_scene()] = scene
	_ecrire(donnees)
	_recharger()


func _annuler_dernier() -> void:
	if _histo.is_empty():
		Etat.annoncer("Rien à annuler.")
		return
	var h: Dictionary = _histo.pop_back()
	_restaurer(h["scene"], h["nom"], h["avant"])


func _plan_origine() -> void:
	_restaurer(_cle_scene(), String(_salle.name), null)   # null = on enlève l'ajustement : la salle reprend le plan de la scène


func _restaurer(cle_scene: String, nom: String, plan) -> void:
	var donnees := _lire().duplicate(true)
	var scene: Dictionary = donnees.get(cle_scene, {})
	if plan == null:
		scene.erase(nom)
	else:
		scene[nom] = plan
	donnees[cle_scene] = scene
	_ecrire(donnees)
	_recharger()


# Recharge la scène (le héros reste où il est, la partie est gardée) et rouvre l'éditeur.
func _recharger() -> void:
	reouvrir = true
	Etat.memoriser_position(monde.joueur.position)
	monde.get_tree().reload_current_scene()
