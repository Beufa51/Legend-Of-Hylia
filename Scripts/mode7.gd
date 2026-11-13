extends CanvasLayer
class_name Mode7
# VUE « MODE 7 » (comme sur la SNES) : un sol vu en perspective, survolé par une caméra.
# Le sol est une carte 2D dessinée dans un SubViewport : herbe, forêt, le grand chemin, et surtout les BÂTIMENTS
# vus du ciel (Outils/fabriquer_plans_mode7.py) : le CORPS du donjon (bâtiment en forme de coq) et les deux AILES
# (le vrai plan de leurs salles). Un shader projette cette carte en perspective (ciel, brume au loin).
# La séquence : les deux ailes se SOULÈVENT (leur ombre s'agrandit), pivotent d'un quart de tour, volent jusqu'au corps,
# se reposent et s'emboîtent ; de haut, les bâtiments dessinent le coq complet.
# jouer() est une fonction « await » : elle rend la main quand la séquence est finie.

const TAILLE_ECRAN := Vector2(400, 224)
const TAILLE_CARTE := Vector2i(1024, 768)
const DOSSIER := "res://Assets/Gemini/embleme/"
const HERBE := Color(0.32, 0.55, 0.26)
const CHEMIN := Color(0.78, 0.68, 0.48)
const FORET := Color(0.16, 0.34, 0.18)
const CIEL_HAUT := Color(0.35, 0.55, 0.95)
const CIEL_BAS := Color(0.85, 0.9, 1.0)
const SON_ENVOL := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Launch.wav"
const SON_PIVOT := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Whoosh.wav"
const SON_EMBOITE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact5.wav"
const JINGLE := "res://Assets/Ninja_adventure/Audio/Jingles/Secret2.wav"
# Le corps (plan_corps.png, 488x264) est posé ici sur la carte ; les ailes s'accrochent à ses épaules (PIVOTS, en
# pixels du corps). RACINES = centre de la salle d'entrée de chaque aile dans son plan (valeurs de plans_mode7.json).
const ORIGINE_CORPS := Vector2(268, 128)
const PIVOTS := {"gauche": Vector2(196, 122), "droite": Vector2(292, 122)}
const RACINES := {"gauche": Vector2(25, 154), "droite": Vector2(275, 154)}
const DEPARTS := {"gauche": Vector2(230, 250), "droite": Vector2(794, 250)}   # les temples des ailes (à l'ouest et à l'est du corps)
const ECHELLE_EMBOITEE := Vector2(0.4, 1.0)   # forme finale d'une aile (épine raccourcie, plumes entières)
const ECHELLE_SOL := Vector2(0.75, 0.75)      # taille des ailes posées près de leurs temples
const CENTRE := Vector2(512, 256)             # centre du coq (la caméra tourne autour)

const SHADER := """
shader_type canvas_item;
uniform sampler2D carte : filter_nearest, repeat_disable;
uniform vec2 taille_carte = vec2(1024.0, 768.0);
uniform vec2 camera = vec2(512.0, 700.0);   // où est la caméra, sur la carte (en pixels)
uniform float angle = 0.0;                   // vers où elle regarde (0 = vers le haut de la carte)
uniform float hauteur = 0.1;                 // altitude (plus grand = on voit de plus haut)
uniform float horizon = 0.3;                 // part de l'écran occupée par le ciel
uniform float echelle = 160.0;               // taille du sol (plus petit = sol plus gros à l'écran)
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
		float brume = clamp((dist - 2.4) / 4.0, 0.0, 0.6);
		COLOR = mix(sol, ciel_bas, brume);
	}
}
"""

var _materiau: ShaderMaterial
var _ailes := {}     # "gauche"/"droite" -> Node2D (racine de l'aile) ; son enfant "ombre" donne l'impression de hauteur
var _eclair: ColorRect
var _vue: SubViewport


func _ready() -> void:
	layer = 2
	# 1) La carte vue du ciel, dessinée dans un SubViewport
	var vue := SubViewport.new()
	_vue = vue
	vue.size = TAILLE_CARTE
	vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vue.disable_3d = true
	add_child(vue)
	_rect(vue, Vector2.ZERO, Vector2(TAILLE_CARTE), HERBE)
	_rect(vue, Vector2(496, 380), Vector2(32, 388), CHEMIN)            # le grand chemin qui vient du village (au sud)
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 7
	for i in 260:                                                      # forêt tout autour (taches sombres)
		var p := Vector2(hasard.randf() * TAILLE_CARTE.x, hasard.randf() * TAILLE_CARTE.y)
		if p.distance_to(CENTRE) > 330 and absf(p.x - 512) > 40:
			_rect(vue, p, Vector2(22, 18), FORET)
	_sprite(vue, "plan_corps", ORIGINE_CORPS + Vector2(6, 8), Vector2.ZERO, Color(0, 0, 0, 0.3))   # ombre du corps
	_sprite(vue, "plan_corps", ORIGINE_CORPS, Vector2.ZERO, Color.WHITE)
	for cote in ["gauche", "droite"]:
		var aile := Node2D.new()
		aile.position = DEPARTS[cote]
		aile.scale = ECHELLE_SOL
		vue.add_child(aile)
		var ombre := _sprite(aile, "plan_aile_" + cote, Vector2.ZERO, -RACINES[cote], Color(0, 0, 0, 0.0))
		ombre.name = "ombre"
		_sprite(aile, "plan_aile_" + cote, Vector2.ZERO, -RACINES[cote], Color.WHITE)
		_ailes[cote] = aile
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
	var ecran := ColorRect.new()
	ecran.size = TAILLE_ECRAN
	ecran.material = _materiau
	add_child(ecran)
	_eclair = ColorRect.new()
	_eclair.size = TAILLE_ECRAN
	_eclair.color = Color(1.0, 0.95, 0.8)
	_eclair.modulate.a = 0.0
	add_child(_eclair)
	_orbite(0.0, 560.0, 0.2)


func _rect(parent: Node, pos: Vector2, taille: Vector2, couleur: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = taille
	r.color = couleur
	parent.add_child(r)


func _sprite(parent: Node, nom: String, pos: Vector2, decalage: Vector2, couleur: Color) -> Sprite2D:
	var s := Sprite2D.new()
	var chemin := DOSSIER + nom + ".png"
	s.texture = load(chemin) if ResourceLoader.exists(chemin) else ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(chemin)))
	s.centered = false
	s.position = pos
	s.offset = decalage
	s.modulate = couleur
	parent.add_child(s)
	return s


# --- Caméra : elle TOURNE AUTOUR du coq en le regardant toujours -------------------------------
# `a` = angle autour du coq (0 = au sud), `r` = distance (pixels de la carte), `h` = altitude.
func _orbite(a: float, r: float, h: float) -> void:
	_materiau.set_shader_parameter("camera", CENTRE + Vector2(sin(a), cos(a)) * r)
	_materiau.set_shader_parameter("angle", -a)
	_materiau.set_shader_parameter("hauteur", h)


func _etape(k: float, de: Vector3, vers: Vector3) -> void:
	var v := de.lerp(vers, k)
	_orbite(v.x, v.y, v.z)


# Fait évoluer la caméra de `de` à `vers` (Vector3 : angle, distance, altitude) en `duree` secondes.
func _voler(de: Vector3, vers: Vector3, duree: float) -> Tween:
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(_etape.bind(de, vers), 0.0, 1.0, duree)
	return t


# --- Les ailes ------------------------------------------------------------------------------
# Une aile à la hauteur `h` (0 = posée au sol, 1 = soulevée) : elle grossit un peu et son ombre s'éloigne d'elle.
func _poser_aile(cote: String, h: float, echelle: Vector2) -> void:
	var aile: Node2D = _ailes[cote]
	aile.scale = echelle * (1.0 + 0.18 * h)
	var ombre: Sprite2D = aile.get_node("ombre")
	ombre.position = (Vector2(14, 22) * h).rotated(-aile.rotation) / aile.scale   # l'ombre tombe toujours vers le bas à droite
	ombre.modulate.a = 0.35 * h


func _soulever(h: float, cote: String) -> void:
	_poser_aile(cote, h, ECHELLE_SOL)


func _remodeler(k: float, cote: String) -> void:
	_poser_aile(cote, 1.0, ECHELLE_SOL.lerp(ECHELLE_EMBOITEE, k))


func _reposer(h: float, cote: String) -> void:
	_poser_aile(cote, h, ECHELLE_EMBOITEE)


func _son(chemin: String, volume_db := 0.0) -> void:
	var flux = load(chemin)
	if flux == null:
		return
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = flux
	lecteur.volume_db = volume_db
	add_child(lecteur)
	lecteur.play()


# La séquence complète (environ 15 secondes).
func jouer() -> void:
	# 1) On rase le grand chemin vers le corps du coq ; les deux ailes reposent au loin, près de leurs temples
	Etat.annoncer("Vu du ciel : le corps du donjon... et, au loin, ses deux ailes.")
	await _voler(Vector3(0.0, 560.0, 0.2), Vector3(0.0, 420.0, 0.45), 3.0).finished
	# 2) Les ailes s'arrachent du sol
	_son(SON_ENVOL, -2.0)
	Etat.annoncer("Le sol gronde : les deux ailes du donjon se soulèvent !")
	var t := create_tween().set_parallel()
	for cote in _ailes:
		t.tween_method(_soulever.bind(cote), 0.0, 1.0, 1.4)
	_voler(Vector3(0.0, 420.0, 0.45), Vector3(0.0, 420.0, 0.46), 1.4)
	await t.finished
	# 3) Elles pivotent d'un quart de tour et volent jusqu'aux épaules du coq
	_son(SON_PIVOT)
	t = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for cote in _ailes:
		var aile: Node2D = _ailes[cote]
		t.tween_property(aile, "position", ORIGINE_CORPS + PIVOTS[cote], 3.0)
		t.tween_property(aile, "rotation", -PI / 2.0 if cote == "gauche" else PI / 2.0, 3.0)
		t.tween_method(_remodeler.bind(cote), 0.0, 1.0, 3.0)
	_voler(Vector3(0.0, 420.0, 0.46), Vector3(0.12, 410.0, 0.5), 3.0)
	await t.finished
	# 4) Elles se reposent : clac, les trois bâtiments ne font plus qu'un
	t = create_tween().set_parallel()
	for cote in _ailes:
		t.tween_method(_reposer.bind(cote), 1.0, 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await t.finished
	_son(SON_EMBOITE)
	_son(JINGLE, -2.0)
	_eclair.modulate.a = 0.8
	create_tween().tween_property(_eclair, "modulate:a", 0.0, 0.6)
	# 5) On monte très haut : de là-haut, les bâtiments dessinent le COQ
	Etat.annoncer("Vu de très haut, les bâtiments dessinent... le grand COQ du blason !")
	await _voler(Vector3(0.12, 410.0, 0.5), Vector3(0.0, 450.0, 0.8), 3.0).finished
	# 6) Fondu vers une VRAIE vue de dessus (sans perspective) : le coq de bâtiments, bien net
	var dessus := Sprite2D.new()
	dessus.texture = _vue.get_texture()
	dessus.region_enabled = true
	dessus.region_rect = Rect2(110, 40, 804, 420)      # le coq complet (corps + ailes), avec un peu d'herbe autour
	dessus.centered = false
	dessus.scale = Vector2.ONE * minf(TAILLE_ECRAN.x / 804.0, TAILLE_ECRAN.y / 420.0)
	dessus.position = (TAILLE_ECRAN - Vector2(804, 420) * dessus.scale) / 2.0
	dessus.modulate.a = 0.0
	add_child(dessus)
	move_child(_eclair, -1)
	create_tween().tween_property(dessus, "modulate:a", 1.0, 1.2)
	await get_tree().create_timer(3.5).timeout
