extends CanvasLayer
class_name Mode7
# VUE « MODE 7 » (comme sur la SNES) : un sol vu en perspective, survolé par une caméra.
# Le sol est une petite carte 2D dessinée dans un SubViewport (herbe, chemin, forêt, le corps du coq et ses deux ailes) ;
# un shader la projette en perspective sur tout l'écran (ciel en haut, brume au loin).
# Utilisé par world.gd::_ceremonie_stele : les deux ailes glissent sur le sol et rejoignent le corps.
# jouer() est une fonction « await » : elle rend la main quand la séquence est finie.

const TAILLE_ECRAN := Vector2(400, 224)
const TAILLE_CARTE := Vector2i(512, 384)
const DOSSIER_BLASON := "res://Assets/Gemini/embleme/"
const HERBE := Color(0.32, 0.55, 0.26)
const CHEMIN := Color(0.78, 0.68, 0.48)
const FORET := Color(0.16, 0.34, 0.18)
const CIEL_HAUT := Color(0.35, 0.55, 0.95)
const CIEL_BAS := Color(0.85, 0.9, 1.0)
const SON_VENT := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Launch.wav"
const SON_EMBOITE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact5.wav"
const JINGLE := "res://Assets/Ninja_adventure/Audio/Jingles/Secret2.wav"

const SHADER := """
shader_type canvas_item;
uniform sampler2D carte : filter_nearest, repeat_disable;
uniform vec2 taille_carte = vec2(512.0, 384.0);
uniform vec2 camera = vec2(256.0, 360.0);   // où est la caméra, sur la carte (en pixels)
uniform float angle = 0.0;                   // vers où elle regarde (0 = vers le haut de la carte)
uniform float hauteur = 0.1;                 // altitude (plus grand = on voit de plus haut)
uniform float horizon = 0.3;                 // part de l'écran occupée par le ciel
uniform float echelle = 140.0;               // taille du sol
uniform vec4 herbe : source_color = vec4(0.32, 0.55, 0.26, 1.0);
uniform vec4 ciel_haut : source_color = vec4(0.35, 0.55, 0.95, 1.0);
uniform vec4 ciel_bas : source_color = vec4(0.85, 0.9, 1.0, 1.0);
void fragment() {
	float y = UV.y - horizon;
	if (y <= 0.0) {
		COLOR = mix(ciel_haut, ciel_bas, UV.y / max(horizon, 0.001));
	} else {
		float dist = hauteur / y;                          // distance du point de sol vu à cet endroit de l'écran
		vec2 local = vec2((UV.x - 0.5) * dist * 1.78, -dist) * echelle;
		float c = cos(angle);
		float s = sin(angle);
		vec2 monde = camera + vec2(local.x * c - local.y * s, local.x * s + local.y * c);
		vec2 uv = monde / taille_carte;
		vec4 sol = herbe;
		if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
			sol = texture(carte, uv);
		}
		float brume = clamp((dist - 0.9) / 2.5, 0.0, 0.75);
		COLOR = mix(sol, ciel_bas, brume);
	}
}
"""

var _ecran: ColorRect
var _materiau: ShaderMaterial
var _aile_g: Sprite2D
var _aile_d: Sprite2D
var _eclair: ColorRect


func _ready() -> void:
	layer = 2
	# 1) La carte vue du ciel, dessinée dans un SubViewport
	var vue := SubViewport.new()
	vue.size = TAILLE_CARTE
	vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vue.disable_3d = true
	add_child(vue)
	_rect(vue, Vector2.ZERO, Vector2(TAILLE_CARTE), HERBE)
	_rect(vue, Vector2(240, 230), Vector2(32, 154), CHEMIN)          # le grand chemin qui vient du village (en bas)
	for i in 90:                                                     # forêt tout autour (taches sombres)
		var p := Vector2(randf() * TAILLE_CARTE.x, randf() * TAILLE_CARTE.y)
		if p.distance_to(Vector2(256, 160)) > 150 and absf(p.x - 256) > 24:
			_rect(vue, p, Vector2(14, 12), FORET)
	var origine := Vector2(134, 94)                                  # le blason (244x132) au centre de la carte
	_sprite(vue, "blason_socle", origine)
	_aile_g = _sprite(vue, "blason_aile_gauche", origine + Vector2(-230, 60))
	_aile_d = _sprite(vue, "blason_aile_droite", origine + Vector2(230, 60))
	# 2) L'écran : un rectangle plein écran avec le shader de perspective
	_materiau = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = SHADER
	_materiau.shader = shader
	_materiau.set_shader_parameter("carte", vue.get_texture())
	_materiau.set_shader_parameter("taille_carte", Vector2(TAILLE_CARTE))
	_materiau.set_shader_parameter("herbe", HERBE)
	_materiau.set_shader_parameter("ciel_haut", CIEL_HAUT)
	_materiau.set_shader_parameter("ciel_bas", CIEL_BAS)
	_ecran = ColorRect.new()
	_ecran.size = TAILLE_ECRAN
	_ecran.material = _materiau
	add_child(_ecran)
	_eclair = ColorRect.new()
	_eclair.size = TAILLE_ECRAN
	_eclair.color = Color(1.0, 0.95, 0.8)
	_eclair.modulate.a = 0.0
	add_child(_eclair)
	_orbite(0.0, 230.0, 0.06)


func _rect(parent: Node, pos: Vector2, taille: Vector2, couleur: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = taille
	r.color = couleur
	parent.add_child(r)


func _sprite(parent: Node, nom: String, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	var chemin := DOSSIER_BLASON + nom + ".png"
	s.texture = load(chemin) if ResourceLoader.exists(chemin) else ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(chemin)))
	s.centered = false
	s.position = pos
	parent.add_child(s)
	return s


# Place la caméra : position sur la carte, direction du regard, altitude.
func _regler(camera: Vector2, angle: float, hauteur: float) -> void:
	_materiau.set_shader_parameter("camera", camera)
	_materiau.set_shader_parameter("angle", angle)
	_materiau.set_shader_parameter("hauteur", hauteur)


# La caméra TOURNE AUTOUR du coq (centre de la carte) en le regardant toujours :
# `a` = angle autour du coq (0 = au sud), `r` = distance (pixels de la carte), `h` = altitude.
const CENTRE := Vector2(256, 160)


func _orbite(a: float, r: float, h: float) -> void:
	_regler(CENTRE + Vector2(sin(a), cos(a)) * r, -a, h)


func _etape(k: float, de: Vector3, vers: Vector3) -> void:
	var v := de.lerp(vers, k)
	_orbite(v.x, v.y, v.z)


# Fait évoluer la caméra de `de` à `vers` (Vector3 : angle, distance, altitude) en `duree` secondes.
func _voler(de: Vector3, vers: Vector3, duree: float) -> void:
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(_etape.bind(de, vers), 0.0, 1.0, duree)
	await t.finished


func _son(chemin: String, volume_db := 0.0) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = volume_db
	add_child(lecteur)
	lecteur.play()


# La séquence complète (environ 12 secondes).
func jouer() -> void:
	# On rase le sol en remontant le chemin vers le corps du coq...
	Etat.annoncer("Le sol tremble... La forêt s'écarte !")
	await _voler(Vector3(0.0, 230.0, 0.06), Vector3(0.0, 130.0, 0.1), 3.0)
	# ... on prend de la hauteur en tournant : les deux ailes arrivent des temples, à gauche et à droite
	_son(SON_VENT, -4.0)
	Etat.annoncer("Les deux ailes quittent leurs temples...")
	var arrivee := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	arrivee.tween_property(_aile_g, "position", Vector2(134, 94), 3.2)
	arrivee.parallel().tween_property(_aile_d, "position", Vector2(134, 94), 3.2)
	await _voler(Vector3(0.0, 130.0, 0.1), Vector3(-0.45, 135.0, 0.2), 3.2)
	# Clac : les trois parties ne font plus qu'un
	_son(SON_EMBOITE)
	_son(JINGLE, -2.0)
	_eclair.modulate.a = 0.8
	create_tween().tween_property(_eclair, "modulate:a", 0.0, 0.6)
	Etat.annoncer("Les ailes et le corps ne font plus qu'un : le grand COQ est complet !")
	# Un tour au-dessus du coq, en montant encore
	await _voler(Vector3(-0.45, 135.0, 0.2), Vector3(0.6, 150.0, 0.3), 4.0)
	await get_tree().create_timer(0.8).timeout
