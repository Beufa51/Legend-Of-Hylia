extends StaticBody2D
class_name Cloche
# Une cloche de bronze à frapper avec la lance : elle joue SA note (énigme "le chant du coq").
# Lettres du plan : 1 à 5 = numéro de la note (1 = la plus grosse = la plus grave).
# Dessinée en code. Elle s'illumine quand elle sonne.

# Son de base (pack Ninja Adventure) : un "ding" très pur, qu'on joue plus ou moins aigu.
const SON_NOTE := "res://Assets/Ninja_adventure/Audio/Sounds/Bonus/Coin.wav"
# Hauteur de chaque note (gamme pentatonique : do ré mi sol la), plus grave que le son de base
const HAUTEURS := [0.6, 0.675, 0.75, 0.9, 1.0]
const BRONZE := Color(0.72, 0.5, 0.2)
const BRONZE_CLAIR := Color(0.95, 0.78, 0.42)
const ECLAT := Color(1.0, 0.97, 0.7)
const ROUGE := Color(0.9, 0.2, 0.15)

var salle: Node2D   # la salle (Room) : on la prévient quand la cloche est frappée
var note := 1       # 1 à 5
var _pivot: Node2D  # la cloche se balance autour de ce point
var _corps: Polygon2D
var _reflet: Polygon2D
var _lumiere: PointLight2D
var _base_lumiere := 0.0     # lumière au repos (un peu dans le noir, pour la repérer)
var _dernier_coup := -1000   # en millisecondes : un coup de lance ne compte qu'une fois
var _tween: Tween


func initialiser(une_salle: Node2D, sa_note: int, dans_le_noir: bool) -> void:
	salle = une_salle
	note = sa_note
	add_to_group("frappable")
	# Support en bois : deux montants + une poutre
	for x in [1, 13]:
		_rect(Vector2(x, 2), Vector2(2, 13), Color(0.36, 0.22, 0.12))
	_rect(Vector2(1, 1), Vector2(14, 2), Color(0.45, 0.29, 0.15))
	# La cloche (plus grosse pour les notes graves)
	_pivot = Node2D.new()
	_pivot.position = Vector2(8, 3)
	_pivot.scale = Vector2.ONE * (1.0 - (note - 1) * 0.08)
	add_child(_pivot)
	_corps = Polygon2D.new()
	_corps.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(2, 0), Vector2(4, 2), Vector2(4, 7),
		Vector2(6, 10), Vector2(-6, 10), Vector2(-4, 7), Vector2(-4, 2)])
	_corps.color = BRONZE
	_pivot.add_child(_corps)
	_reflet = Polygon2D.new()
	_reflet.polygon = PackedVector2Array([Vector2(-3, 2), Vector2(-2, 2), Vector2(-2, 8), Vector2(-4, 9)])
	_reflet.color = BRONZE_CLAIR
	_pivot.add_child(_reflet)
	var battant := Polygon2D.new()
	battant.polygon = PackedVector2Array([Vector2(-1, 10), Vector2(1, 10), Vector2(1, 12), Vector2(-1, 12)])
	battant.color = Color(0.3, 0.2, 0.1)
	_pivot.add_child(battant)
	# Lumière : éteinte en salle claire, petite lueur en salle sombre
	_base_lumiere = 0.35 if dans_le_noir else 0.0
	_lumiere = Lumiere.creer(Color(1.0, 0.85, 0.5), 0.6, _base_lumiere)
	_lumiere.position = Vector2(8, 8)
	add_child(_lumiere)
	# Collision (couche 1 : la lance la détecte, le joueur ne passe pas)
	var forme := RectangleShape2D.new()
	forme.size = Vector2(14, 14)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	collision.position = Vector2(8, 8)
	add_child(collision)


# Appelé par la lance (plusieurs fois pendant un même coup : on ne compte que le premier).
func frapper() -> void:
	var maintenant := Time.get_ticks_msec()
	if maintenant - _dernier_coup < 400:
		return
	_dernier_coup = maintenant
	sonner(ECLAT)
	salle.cloche_frappee(note)


# Joue la note, balance la cloche et l'illumine un instant de la couleur donnée.
func sonner(couleur: Color) -> void:
	_jouer_note()
	if _tween:
		_tween.kill()
	_pivot.rotation = 0.0
	_corps.color = couleur
	_lumiere.energy = 1.2
	_tween = create_tween()
	_tween.tween_property(_pivot, "rotation", 0.35, 0.08)
	_tween.tween_property(_pivot, "rotation", -0.25, 0.14)
	_tween.tween_property(_pivot, "rotation", 0.0, 0.12)
	_tween.tween_interval(0.15)
	_tween.tween_callback(_au_repos)


# Mauvaise note : la cloche rougit (sans rejouer sa note).
func rougir() -> void:
	if _tween:
		_tween.kill()
	_pivot.rotation = 0.0
	_corps.color = ROUGE
	_tween = create_tween()
	_tween.tween_interval(0.5)
	_tween.tween_callback(_au_repos)


# Énigme résolue : la cloche reste dorée et lumineuse.
func dorer() -> void:
	_base_lumiere = 0.6
	_au_repos()
	_corps.color = BRONZE_CLAIR


func _au_repos() -> void:
	_corps.color = BRONZE_CLAIR if _base_lumiere >= 0.6 else BRONZE
	_lumiere.energy = _base_lumiere


func _jouer_note() -> void:
	var flux = load(SON_NOTE)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.pitch_scale = HAUTEURS[clampi(note - 1, 0, HAUTEURS.size() - 1)]
	lecteur.volume_db = -4.0
	salle.add_child(lecteur)
	lecteur.play()
	lecteur.finished.connect(lecteur.queue_free)


func _rect(pos: Vector2, taille: Vector2, couleur: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = taille
	r.color = couleur
	add_child(r)
