extends Node
class_name MiniJeu
# Base de tous les MINI-JEUX (stand de tir, chasse aux poules...). Un mini-jeu est un petit nœud posé dans un écran
# (export `minijeu` de l'écran). Un habitant le lance : sa ligne dans `pnjs` a une 4e partie « | id ».
# La conversation se termine -> Etat.minijeu_demande(id) -> `_commencer()`.
# Chaque mini-jeu écrit 3 choses : `_depart()`, `_maj(delta)` (appelée à chaque image) et, quand c'est fini, appelle `_terminer(...)`.
# Le chrono `_temps` (secondes depuis le départ) et le texte affiché en haut de l'écran (`_texte_hud()`) sont fournis ici.

const SON_FIN := "res://Assets/Ninja_adventure/Audio/Jingles/Success2.wav"

var id := ""
var ecran            # l'écran qui contient le jeu (Ecran) ; sans type pour éviter les dépendances circulaires
var en_cours := false
var _temps := 0.0
var _hud: CanvasLayer
var _etiquette: Label


func initialiser(e) -> void:
	ecran = e


func _ready() -> void:
	Etat.minijeu_demande.connect(_demande)


func _demande(demande: String) -> void:
	if demande == id and not en_cours and ecran.grille == Etat.salle_courante:
		_commencer()


func _commencer() -> void:
	en_cours = true
	_temps = 0.0
	_creer_hud()
	_depart()


func _process(delta: float) -> void:
	if not en_cours:
		return
	if ecran.grille != Etat.salle_courante:   # le joueur est parti : le jeu s'arrête
		_abandonner()
		return
	_temps += delta
	_maj(delta)
	if en_cours:
		_etiquette.text = _texte_hud()


# --- À redéfinir dans chaque mini-jeu -----------------------------------------------------------------------
func _depart() -> void:
	pass


func _maj(_delta: float) -> void:
	pass


func _texte_hud() -> String:
	return ""


func _nettoyer() -> void:   # appelé à la fin ou à l'abandon : retirer ce que le jeu a posé
	pass


# --- Fin de partie ------------------------------------------------------------------------------------------
func _abandonner() -> void:
	en_cours = false
	_hud.visible = false
	_nettoyer()
	Etat.annoncer("Tu as quitté le jeu.")


# `valeur` : le score ; `plus_grand` : vrai si plus grand = meilleur (points), faux pour un temps ;
# `seuils` : [bronze, argent, or] (pour un temps : du plus lent au plus rapide) ; `unite` : texte après le score.
func _terminer(valeur: float, plus_grand: bool, seuils: Array, nom_ruban: String, unite: String) -> void:
	en_cours = false
	_hud.visible = false
	var rang := -1   # 0 bronze, 1 argent, 2 or
	for i in seuils.size():
		if (valeur >= seuils[i]) if plus_grand else (valeur <= seuils[i]):
			rang = i
	var record := Etat.noter_record(id, valeur, plus_grand)
	var texte := "Score : %s %s." % [_nombre(valeur), unite]
	if rang >= 0:
		texte += " Ruban " + ["de bronze", "d'argent", "d'or"][rang] + " !"
		Etat.poser("ruban_%s_%s" % [nom_ruban, ["bronze", "argent", "or"][rang]])
	if record:
		texte += " Nouveau record !"
	else:
		texte += " Record : %s %s." % [_nombre(Etat.records[id]), unite]
	Etat.annoncer(texte)
	_jouer(SON_FIN)


func _nombre(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v


# --- Outils ---------------------------------------------------------------------------------------------------
func _creer_hud() -> void:
	if _hud == null:
		_hud = CanvasLayer.new()
		_hud.layer = 3
		add_child(_hud)
		_etiquette = Label.new()
		_etiquette.position = Vector2(0, 6)
		_etiquette.size = Vector2(400, 16)
		_etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_etiquette.add_theme_font_size_override("font_size", 10)
		_etiquette.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		_etiquette.add_theme_color_override("font_outline_color", Color.BLACK)
		_etiquette.add_theme_constant_override("outline_size", 4)
		_hud.add_child(_etiquette)
	_hud.visible = true


func _jouer(chemin: String, volume_db := -4.0) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = volume_db
	add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)


# Position (dans l'écran) du centre d'une case (x, y)
func _centre_case(c: Vector2i) -> Vector2:
	return Vector2(c * 16) + Vector2(8, 8)


# Le joueur est-il à moins de `distance` px de ce point (coordonnées de l'écran) ?
func _joueur_pres(point: Vector2, distance: float) -> bool:
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	return joueur != null and joueur.global_position.distance_to(ecran.to_global(point)) < distance
