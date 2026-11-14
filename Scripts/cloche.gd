extends StaticBody2D
class_name Cloche
# Une cloche de bronze à frapper avec la lance : elle joue SA note (énigme "le chant du coq").
# Lettres du plan : 1 à 5 = numéro de la note (1 = la plus grosse = la plus grave).
# Images : cloche_support.png + cloche_1..5.png (fabriquées par Outils/fabriquer_objets.py).

# Son de base (pack Ninja Adventure) : un "ding" très pur, qu'on joue plus ou moins aigu.
const SON_NOTE := "res://Assets/Ninja_adventure/Audio/Sounds/Bonus/Coin.wav"
# Hauteur de chaque note (gamme pentatonique : do ré mi sol la), plus grave que le son de base
const HAUTEURS := [0.6, 0.675, 0.75, 0.9, 1.0]
# Teintes appliquées à l'image (au-dessus de 1 = plus lumineux)
const ECLAT := Color(1.8, 1.7, 1.3)
const ROUGE := Color(1.6, 0.45, 0.4)
const DOREE := Color(1.3, 1.2, 0.85)
const NORMALE := Color(1, 1, 1)
# Couleur propre à chaque note (rouge, orange, vert, bleu, violet) : on RECONNAÎT la cloche qui s'allume sans aucun texte
const COULEURS := [Color(1.0, 0.3, 0.25), Color(1.0, 0.62, 0.15), Color(0.35, 0.9, 0.35), Color(0.3, 0.6, 1.0), Color(0.75, 0.4, 1.0)]

var salle: Node2D   # la salle (Room) : on la prévient quand la cloche est frappée
var note := 1       # 1 à 5
var _pivot: Node2D  # la cloche se balance autour de ce point (le crochet)
var _image: Sprite2D
var _repos := NORMALE        # teinte au repos (dorée une fois l'énigme résolue)
var _lumiere: PointLight2D
var _plaque: Sprite2D
var _base_lumiere := 0.0     # lumière au repos (un peu dans le noir, pour la repérer)
var _dernier_coup := -1000   # en millisecondes : un coup de lance ne compte qu'une fois
var _tween: Tween


func initialiser(une_salle: Node2D, sa_note: int, dans_le_noir: bool, support: Texture2D, image: Texture2D) -> void:
	salle = une_salle
	note = sa_note
	add_to_group("frappable")
	# Plaque de couleur au sol (image Gemini), puis la cloche sur son portique (22x34, aligné en bas)
	var plaque := Sprite2D.new()
	plaque.texture = support
	plaque.centered = false
	plaque.position = Vector2(1, 9)
	add_child(plaque)
	_plaque = plaque
	_pivot = Node2D.new()
	_pivot.position = Vector2(8, 13)   # la cloche se balance autour de sa base
	add_child(_pivot)
	_image = Sprite2D.new()
	_image.texture = image
	_image.centered = false
	_image.position = Vector2(-11, -34)
	_pivot.add_child(_image)
	# Lumière : éteinte en salle claire, petite lueur en salle sombre
	_base_lumiere = 0.35 if dans_le_noir else 0.0
	_lumiere = Lumiere.creer(COULEURS[clampi(note - 1, 0, 4)].lerp(Color(1, 0.85, 0.5), 0.5), 0.6, _base_lumiere)
	_lumiere.position = Vector2(8, 9)
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
	# La lance ne passe pas à travers un bloc ou une grille : il faut avoir la cloche en ligne de vue
	if not _en_ligne_de_vue():
		return
	sonner(ECLAT)
	salle.cloche_frappee(note)


# Vrai si rien de solide (bloc, grille, mur) ne se trouve entre le joueur et la cloche.
func _en_ligne_de_vue() -> bool:
	var joueur := get_tree().get_first_node_in_group("joueur")
	if joueur == null:
		return true
	var requete := PhysicsRayQueryParameters2D.create(joueur.global_position, global_position + Vector2(8, 8))
	requete.collision_mask = 1
	requete.exclude = [get_rid(), joueur.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(requete).is_empty()


# Joue la note, balance la cloche et l'illumine un instant de la teinte donnée.
func sonner(teinte: Color) -> void:
	_jouer_note()
	if _tween:
		_tween.kill()
	_pivot.scale = Vector2.ONE
	var c: Color = COULEURS[clampi(note - 1, 0, 4)]
	_image.modulate = teinte if teinte != ECLAT else c.lerp(Color(1, 1, 1), 0.35) * 1.7
	plaque_eclat(c)
	_lumiere.energy = 1.2
	_tween = create_tween()
	_tween.tween_property(_pivot, "scale", Vector2(1.12, 0.9), 0.07)
	_tween.tween_property(_pivot, "scale", Vector2(0.95, 1.05), 0.12)
	_tween.tween_property(_pivot, "scale", Vector2(1, 1), 0.12)
	_tween.tween_interval(0.15)
	_tween.tween_callback(_au_repos)


# Mauvaise note : la cloche rougit (sans rejouer sa note).
func rougir() -> void:
	if _tween:
		_tween.kill()
	_pivot.scale = Vector2.ONE
	_image.modulate = ROUGE
	_tween = create_tween()
	_tween.tween_interval(0.5)
	_tween.tween_callback(_au_repos)


# Énigme résolue : la cloche reste dorée et lumineuse.
func dorer() -> void:
	_repos = DOREE
	_base_lumiere = 0.6
	_au_repos()


# La plaque de couleur s'illumine quand la cloche sonne.
func plaque_eclat(c: Color) -> void:
	if _plaque != null:
		_plaque.modulate = NORMALE if c == NORMALE else Color(1.5, 1.5, 1.5)


func _au_repos() -> void:
	plaque_eclat(NORMALE)
	_image.modulate = _repos
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
