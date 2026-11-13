extends StaticBody2D
class_name Plot
# Un PLOT de couleur (aile droite) : orange (lettre `o`) ou bleu (lettre `u`).
# Au départ, les orange sont LEVÉS (ils bloquent) et les bleus BAISSÉS (on marche dessus).
# Frapper le cristal de la salle inverse tout : les levés se baissent, les baissés se lèvent.
# Un plot ne se lève jamais sous le joueur ou sous un bloc : il attend que la case soit libre.
# Dessiné en code (pas d'image).

const TUILE := 16
const ORANGE := Color(0.88, 0.52, 0.2)
const BLEU := Color(0.3, 0.52, 0.88)
# Pierre du donjon (mêmes tons que les murs et piliers)
const PIERRE_SOMBRE := Color8(52, 52, 70)
const PIERRE_MOYENNE := Color8(72, 72, 93)
const PIERRE_CLAIRE := Color8(105, 101, 132)
const CONTOUR := Color8(19, 18, 28)

var salle: Room
var case: Vector2i
var couleur := ORANGE
var leve := false        # vrai = il bloque le passage
var _veut_lever := false # il doit se lever dès que la case est libre
var _collision: CollisionShape2D
var _haut: Node2D        # dessin du plot levé
var _bas: Node2D         # dessin du plot baissé


func initialiser(une_salle: Room, sa_case: Vector2i, orange: bool) -> void:
	salle = une_salle
	case = sa_case
	position = Vector2(case * TUILE)
	couleur = ORANGE if orange else BLEU
	# Baissé : la dalle de pierre Gemini (cabochon en creux)
	_bas = Node2D.new()
	add_child(_bas)
	var image_bas := Sprite2D.new()
	image_bas.centered = false
	image_bas.texture = salle._image("plot_bas_o" if orange else "plot_bas_u")
	_bas.add_child(image_bas)
	# Levé : le cube de pierre Gemini (gemme orange ou bleue), posé sur la case ; bloc plein de la taille de la case
	_haut = Node2D.new()
	add_child(_haut)
	_rect(_haut, Vector2(0, 12), Vector2(16, 4), Color(0, 0, 0, 0.30))       # ombre au sol
	var image := Sprite2D.new()
	image.centered = false
	image.position = Vector2(0, 0)
	image.texture = salle._image("plot_haut_o" if orange else "plot_haut_u")
	_haut.add_child(image)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(TUILE, TUILE)
	_collision = CollisionShape2D.new()
	_collision.shape = forme
	_collision.position = Vector2(TUILE, TUILE) / 2.0
	add_child(_collision)
	z_index = 0
	regler(orange, true)


func _rect(parent: Node, pos: Vector2, taille: Vector2, c: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = taille
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)


# Lève (vrai) ou baisse (faux) le plot. `tout_de_suite` : sans attendre que la case se libère (début de salle).
func regler(lever: bool, tout_de_suite := false) -> void:
	_veut_lever = lever
	if not lever:
		_poser_etat(false)
	elif tout_de_suite or _case_libre():
		_poser_etat(true)


func _poser_etat(lever: bool) -> void:
	leve = lever
	_haut.visible = lever
	_bas.visible = not lever
	_collision.set_deferred("disabled", not lever)
	if lever:
		salle.occuper(case, self)
	elif salle._occupe.get(case) == self:
		salle.liberer(case)
	# un petit rebond quand il change d'état
	scale = Vector2(1.0, 0.85)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.12)


# Le joueur ou un bloc est-il sur la case ?
func _case_libre() -> bool:
	if salle._occupe.has(case) and salle._occupe[case] != self:
		return false
	var joueur := get_tree().get_first_node_in_group("joueur") as Node2D
	if joueur == null:
		return true
	# la boîte de collision du joueur (8 x 6, sous ses pieds) touche-t-elle la case ?
	var pieds := salle.to_local(joueur.global_position) + Vector2(0, 5)
	var boite := Rect2(pieds - Vector2(4, 3), Vector2(8, 6))
	return not boite.intersects(Rect2(Vector2(case * TUILE), Vector2(TUILE, TUILE)))


func _physics_process(_delta: float) -> void:
	if _veut_lever and not leve and _case_libre():
		_poser_etat(true)
