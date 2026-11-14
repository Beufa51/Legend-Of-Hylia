class_name Assemblage
extends CanvasLayer
## CINÉMATIQUE D'ASSEMBLAGE (la grande scène du jeu) : les deux symboles sont posés sur les stèles, le château-coq s'éveille,
## S'ENVOLE, rejoint le ciel où ses deux ailes viennent s'emboîter, puis se POSE de nouveau : le coq de pierre est assemblé.
##
## Tout est une FONCTION DU TEMPS `t` (secondes) : chaque image, `_evaluer(t)` place chaque élément ; les sons, éclairs et secousses
## sont des « événements » déclenchés quand `t` les dépasse. Avantages : on peut passer la scène (on saute `t`), la tester, la régler.
## Images (Outils/traiter_coq_cinematique.py) : Assets/Cinematique/{sol,corps,aile_g,aile_d}.png + calques.json (1408x768, coordonnées « image »).
## La scène s'affiche en HAUTE DÉFINITION : pendant ces ~46 s, l'écran n'est plus réduit à 400x224 (content_scale_mode désactivé).
## Utilisation : await Assemblage.jouer(self) depuis world.gd (self = le Node `world`).

signal termine

const OUV := 3.5                      # durée de l'ouverture sur les pattes (avant le temps « ancien » où tout a commencé)
const DUREE := 54.0
const DOSSIER := "res://Assets/Cinematique/"
const TAILLE_IMAGE := Vector2(1408, 768)
const CENTRE := Vector2(704, 384)       # centre de l'image = centre du donjon rond
const MUSIQUE := "res://Assets/Musique/14_traveling_the_sky.ogg"
const SON_VENT := "res://Assets/Ninja_adventure/Audio/Sounds/Ambient/Wind.wav"
const SON_AILES := "res://Assets/Ninja_adventure/Audio/Sounds/Creature/Wings.wav"
const SON_CRI := "res://Assets/Ninja_adventure/Audio/Sounds/Creature/Bird.wav"
const SON_ENVOL := "res://Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Launch.wav"
const SON_CLAC := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact5.wav"
const SON_GRONDE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact.wav"
const SON_POSE := "res://Assets/Ninja_adventure/Audio/Sounds/Hit & Impact/Impact4.wav"
const JINGLE := "res://Assets/Ninja_adventure/Audio/Jingles/Secret2.wav"
const SON_FLAMME := "res://Assets/Ninja_adventure/Audio/Sounds/Elemental/Fire.wav"

# Torches et flammes du château (en pixels de l'image) : elles s'allument une à une au réveil.
const TORCHES := [
	Vector2(555, 546), Vector2(850, 546), Vector2(612, 598), Vector2(795, 598), Vector2(667, 622), Vector2(740, 622),
	Vector2(622, 452), Vector2(785, 452), Vector2(662, 470), Vector2(745, 470),
]
# Chemin d'énergie le long du rempart de l'aile GAUCHE (du bout de l'aile vers la tête) ; la droite en est le miroir.
const CHEMIN_GAUCHE := [
	Vector2(268, 118), Vector2(300, 136), Vector2(370, 150), Vector2(430, 168), Vector2(470, 215), Vector2(520, 268),
	Vector2(585, 282), Vector2(625, 250), Vector2(665, 228), Vector2(704, 218), Vector2(704, 150), Vector2(704, 96),
]
const PATTES := [Vector2(490, 690), Vector2(918, 690)]   # pointes des deux griffes = les stèles du Parvis (gauche, droite)
const PORTE_QUEUE := Vector2(704, 680)   # la porte de la queue, entre les griffes : on la retrouve en arrivant au Parvis
const SON_MAGIE := "res://Assets/Ninja_adventure/Audio/Sounds/Magic & Skill/Magic2.wav"
# Calendrier des ailes (temps « anciens », sans l'ouverture) : [le plan doré apparaît, le symbole quitte la griffe, le symbole touche le plan,
# l'aile a remplacé le plan, début du quart de tour, fin du quart de tour, fin de la glissade (= emboîtement)]
const CALENDRIER := {"g": [14.6, 15.8, 17.2, 18.4, 23.4, 24.6, 25.5], "d": [15.4, 16.6, 18.0, 19.2, 24.4, 25.6, 26.5]}
const DEC_AILE := Vector2(330, 330)       # écart de l'aile en attente par rapport à son épaule (elle se tient à la verticale à côté du corps)

var monde: Node
var t := 0.0
var _fini := false
var _passable := false
var _ancien_mode := Window.CONTENT_SCALE_MODE_VIEWPORT
var _ecran := Vector2(1200, 672)
var _k := 1.0                      # échelle de base : l'image couvre tout l'écran

# Éléments
var _fond: ColorRect
var _ciel: TextureRect
var _vue: Node2D                   # « la caméra » : on déplace / zoome ce nœud
var _terre: Node2D
var _sol: Sprite2D
var _ombre: Sprite2D
var _nuages: Node2D
var _couches: Array[Node2D] = []
var _chateau: Node2D
var _corps: Sprite2D
var _lueurs: Array[Sprite2D] = []
var _aile := {}                    # "g" / "d" -> {pivot, sprite, halo, epaule, cote}
var _energie: Array[Line2D] = []
var _halo_tete: Sprite2D
var _lueurs_pattes: Array[Sprite2D] = []
var _lueur_porte: Sprite2D
var _eclats: Node2D
var _flash: ColorRect
var _noir: ColorRect
var _lecteur_musique: AudioStreamPlayer
var _lecteur_vent: AudioStreamPlayer
var _meta := {}
var _tex_lueur: Texture2D
var _tex_anneau: Texture2D
var _secousse := 0.0               # amplitude de la secousse de caméra (en pixels écran), décroît toute seule
var _defil := 0.0                  # défilement cumulé des nuages
var _evenements: Array = []        # [temps, Callable]
var _i_evt := 0


static func jouer(le_monde: Node) -> void:
	var a := Assemblage.new()
	a.monde = le_monde
	le_monde.add_child(a)
	await a.termine
	a.queue_free()


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var racine := get_tree().root
	_ancien_mode = racine.content_scale_mode
	racine.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED   # haute définition
	await get_tree().process_frame
	await get_tree().process_frame
	_ecran = Vector2(get_viewport().get_visible_rect().size)
	_k = minf(_ecran.x / TAILLE_IMAGE.x, _ecran.y / TAILLE_IMAGE.y)   # l'image entière tient à l'écran ; le sol est prolongé par des copies en miroir
	_lire_meta()
	_construire()
	_preparer_evenements()
	_passable = Etat.est("assemblage_vu")
	_evaluer(0.0)


func _exit_tree() -> void:
	if is_inside_tree():
		get_tree().root.content_scale_mode = _ancien_mode


func _lire_meta() -> void:
	var f := FileAccess.open(DOSSIER + "calques.json", FileAccess.READ)
	if f != null:
		_meta = JSON.parse_string(f.get_as_text())
	if _meta == null or _meta.is_empty():   # valeurs de secours
		_meta = {"aile_g": {"origine": [25, 52]}, "aile_d": {"origine": [852, 52]}, "epaule_g": [575, 270], "epaule_d": [830, 270]}


# --- Construction ------------------------------------------------------------------------------------------------

func _texture(nom: String) -> Texture2D:
	var chemin := nom if nom.begins_with("res://") else DOSSIER + nom
	var tex = load(chemin) if ResourceLoader.exists(chemin) else null
	if tex == null:
		var img := Image.load_from_file(ProjectSettings.globalize_path(chemin))
		if img != null:
			tex = ImageTexture.create_from_image(img)
	return tex


func _additif() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _degrade_radial(couleurs: PackedColorArray, offsets: PackedFloat32Array, taille := 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = couleurs
	g.offsets = offsets
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = taille
	tex.height = taille
	return tex


func _sprite(tex: Texture2D, parent: Node, pos := Vector2.ZERO, centre := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = centre
	s.position = pos
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # image HD : on la lisse au lieu du filtre « pixel » du projet
	parent.add_child(s)
	return s


func _construire() -> void:
	_tex_lueur = _degrade_radial(PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)]), PackedFloat32Array([0.0, 0.4, 1.0]))
	_tex_anneau = _degrade_radial(PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 0.95, 0.7, 1), Color(1, 0.95, 0.7, 0)]),
		PackedFloat32Array([0.0, 0.72, 0.9, 1.0]))
	# fond : vert sombre (la nuit au sol), puis bleu du ciel
	_fond = ColorRect.new()
	_fond.color = Color(0.03, 0.07, 0.05)
	_fond.size = _ecran
	add_child(_fond)
	var gr := Gradient.new()
	gr.colors = PackedColorArray([Color(0.08, 0.12, 0.36), Color(0.25, 0.36, 0.7), Color(0.78, 0.7, 0.72)])
	gr.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = gr
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 4
	gt.height = 256
	_ciel = TextureRect.new()
	_ciel.texture = gt
	_ciel.stretch_mode = TextureRect.STRETCH_SCALE
	_ciel.size = _ecran
	_ciel.modulate.a = 0.0
	add_child(_ciel)
	# la « caméra »
	_vue = Node2D.new()
	add_child(_vue)
	_terre = Node2D.new()
	_vue.add_child(_terre)
	var tex_sol := _texture("sol.png")
	for dy in [-1, 0, 1]:        # le sol est prolongé tout autour par des copies en miroir (raccords invisibles) : plus de bord quand on rétrécit ou recule
		for dx in [-1, 0, 1]:
			var m := _sprite(tex_sol, _terre, Vector2(dx * TAILLE_IMAGE.x, dy * TAILLE_IMAGE.y))
			m.flip_h = dx != 0
			m.flip_v = dy != 0
			if dx == 0 and dy == 0:
				_sol = m
	var tex_corps := _texture("corps.png")
	_ombre = _sprite(tex_corps, _terre)
	_ombre.modulate = Color(0, 0, 0, 0.4)
	# nuages : 3 couches (lointaine, moyenne, proche)
	_nuages = Node2D.new()
	_vue.add_child(_nuages)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for c in 3:
		var couche := Node2D.new()
		_nuages.add_child(couche)
		_couches.append(couche)
		for i in 9 + c * 3:
			var nuage := Node2D.new()
			nuage.position = Vector2(rng.randf_range(-900, 2300), rng.randf_range(0, HAUTEUR_BOUCLE))
			couche.add_child(nuage)
			var taille := rng.randf_range(0.9, 1.7) * (0.8 + c * 0.35)
			for j in 6:
				var b := _sprite(_tex_lueur, nuage, Vector2(rng.randf_range(-170, 170), rng.randf_range(-45, 45)), true)
				b.scale = Vector2(rng.randf_range(0.9, 1.6), rng.randf_range(0.5, 0.9)) * taille
				var clair := 0.72 + c * 0.14
				b.modulate = Color(clair * 0.95, clair, minf(clair * 1.08, 1.0), 0.55 + c * 0.12)
	# le château
	_chateau = Node2D.new()
	_vue.add_child(_chateau)
	_corps = _sprite(tex_corps, _chateau)
	_halo_tete = _sprite(_tex_lueur, _chateau, Vector2(704, 120), true)
	_halo_tete.material = _additif()
	_halo_tete.modulate = Color(0.95, 0.9, 0.35, 0.0)
	_halo_tete.scale = Vector2(1.1, 1.1)
	for p in TORCHES:
		var l := _sprite(_tex_lueur, _chateau, p, true)
		l.material = _additif()
		l.modulate = Color(1.0, 0.62, 0.2, 0.0)
		l.scale = Vector2(0.42, 0.42)
		_lueurs.append(l)
	for p in PATTES:             # les pattes brillent comme les stèles du Parvis
		var lp := _sprite(_tex_lueur, _chateau, p, true)
		lp.material = _additif()
		lp.modulate = Color(1.0, 0.82, 0.35, 0.0)
		lp.scale = Vector2(0.9, 0.9)
		_lueurs_pattes.append(lp)
	_lueur_porte = _sprite(_tex_lueur, _chateau, PORTE_QUEUE, true)
	_lueur_porte.material = _additif()
	_lueur_porte.modulate = Color(1.0, 0.7, 0.3, 0.0)
	_lueur_porte.scale = Vector2(0.8, 0.8)
	# les ailes : un pivot placé à l'épaule ; l'image est décalée pour que l'épaule soit à l'origine du pivot
	for cote in ["g", "d"]:
		var epaule := _pt(_meta["epaule_" + cote])
		var origine := _pt(_meta["aile_" + cote]["origine"])
		var pivot := Node2D.new()
		pivot.visible = false
		_chateau.add_child(pivot)
		var tex := _texture("aile_" + cote + ".png")
		var s := _sprite(tex, pivot, origine - epaule)
		var halo := _sprite(tex, pivot, origine - epaule)
		halo.material = _additif()
		halo.modulate = Color(0.9, 0.75, 0.3, 0.0)
		var sens := -1.0 if cote == "g" else 1.0
		# le PLAN doré des salles parcourues (le vrai plan du donjon, Outils/fabriquer_plans_mode7.py) : c'est de lui que naît l'aile
		var plan := _sprite(_texture("res://Assets/Gemini/embleme/plan_aile_%s.png" % ("gauche" if cote == "g" else "droite")), _chateau,
			epaule + Vector2(sens * DEC_AILE.x, DEC_AILE.y) + Vector2(-sens * 20.0, -275.0), true)
		plan.modulate = Color(1.0, 0.74, 0.3, 0.0)   # (mélange normal : l'or reste de l'or, même devant un nuage clair)
		plan.scale = Vector2(1.45, 1.45)
		plan.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# le symbole du fragment (celui du HUD) qui vole de la griffe jusqu'au plan
		var symbole := _sprite(_texture("res://Assets/Gemini/tuiles/fragment_aile.png"), _chateau, PATTES[0 if cote == "g" else 1] + Vector2(0, -70), true)
		symbole.flip_h = cote == "d"
		symbole.scale = Vector2(2.6, 2.6)
		symbole.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var halo_s := _sprite(_tex_lueur, symbole, Vector2.ZERO, true)
		halo_s.material = _additif()
		halo_s.modulate = Color(1.0, 0.8, 0.3, 0.7)
		halo_s.scale = Vector2(0.22, 0.22)
		_aile[cote] = {"pivot": pivot, "sprite": s, "halo": halo, "epaule": epaule, "cote": sens, "plan": plan, "symbole": symbole}
	# chemins d'énergie (runes qui s'allument) : un trait large et doux + un trait fin brillant par aile
	for i in 4:
		var ligne := Line2D.new()
		ligne.width = 24.0 if i < 2 else 7.0
		ligne.default_color = Color(1.0, 0.8, 0.3, 0.22 if i < 2 else 0.95)
		ligne.material = _additif()
		ligne.joint_mode = Line2D.LINE_JOINT_ROUND
		ligne.begin_cap_mode = Line2D.LINE_CAP_ROUND
		ligne.end_cap_mode = Line2D.LINE_CAP_ROUND
		ligne.antialiased = true
		_chateau.add_child(ligne)
		_energie.append(ligne)
	_eclats = Node2D.new()
	_vue.add_child(_eclats)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.size = _ecran
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_noir = ColorRect.new()
	_noir.color = Color(0, 0, 0, 1)
	_noir.size = _ecran
	_noir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_noir)
	# sons
	_lecteur_musique = _lecteur(MUSIQUE, -6.0, true)
	_lecteur_vent = _lecteur(SON_VENT, -80.0, true)


const HAUTEUR_BOUCLE := 2000.0


func _pt(v) -> Vector2:
	return Vector2(float(v[0]), float(v[1]))


func _lecteur(chemin: String, volume: float, boucle: bool) -> AudioStreamPlayer:
	var l := AudioStreamPlayer.new()
	var flux = load(chemin) if ResourceLoader.exists(chemin) else null
	if flux != null:
		if boucle and "loop" in flux:
			flux.loop = true
		l.stream = flux
	l.volume_db = volume
	add_child(l)
	if flux != null:
		l.play()
	return l


func _son(chemin: String, volume := 0.0, hauteur := 1.0) -> void:
	var flux = load(chemin) if ResourceLoader.exists(chemin) else null
	if flux == null:
		return
	var l := AudioStreamPlayer.new()
	l.stream = flux
	l.volume_db = volume
	l.pitch_scale = hauteur
	add_child(l)
	l.play()
	l.finished.connect(l.queue_free)


# --- Événements (sons, éclairs, secousses, poussière) --------------------------------------------------------------

func _preparer_evenements() -> void:
	var e := _evenements
	# 0) ouverture sur les pattes : les torches s'allument une à une
	for i in 10:
		e.append([0.8 + 0.25 * i, func(): _son(SON_FLAMME, -14.0, 1.0 + 0.04 * randf())])
	e.append([0.5, func(): _son(SON_MAGIE, -4.0, 0.7)])
	e.append([2.0, func(): _gronder(0.8)])
	# 1) le réveil : grondements (temps « anciens » + OUV)
	e.append([OUV + 1.6, func(): _gronder(0.9)])
	e.append([OUV + 2.9, func(): _gronder(1.1)])
	e.append([OUV + 4.2, func(): _gronder(1.4)])
	e.append([OUV + 5.5, func(): _gronder(1.8)])
	e.append([OUV + 5.6, func(): _poussiere(Vector2(480, 700), 28, 90.0); _poussiere(Vector2(930, 700), 28, 90.0)])
	e.append([OUV + 6.2, func(): _poussiere(Vector2(704, 660), 40, 140.0)])
	# 2) le décollage
	e.append([OUV + 7.0, func(): _son(SON_ENVOL, -2.0); _son(SON_AILES, -8.0, 0.7); _secouer(9.0)])
	e.append([OUV + 7.3, func(): _poussiere(Vector2(704, 640), 60, 220.0); _poussiere(Vector2(520, 690), 30, 180.0); _poussiere(Vector2(900, 690), 30, 180.0)])
	e.append([OUV + 10.0, func(): _son(SON_AILES, -10.0, 0.6)])
	# 3) les plans dorés, les symboles, les ailes
	for cote in ["g", "d"]:
		var c: Array = CALENDRIER[cote]
		e.append([OUV + c[0], func(): _son(SON_MAGIE, -6.0, 1.2)])
		e.append([OUV + c[2], func(): _symbole_arrive(cote)])
		e.append([OUV + c[4] + 0.3, func(): _son(SON_AILES, -6.0, 0.8)])
		e.append([OUV + c[5], func(): _son(SON_ENVOL, -8.0, 1.2)])
		e.append([OUV + c[6], func(): _clac(cote)])
	# 4) l'énergie court le long des remparts, le coq s'éveille
	e.append([OUV + 27.8, func(): _son(JINGLE, -2.0)])
	e.append([OUV + 30.3, func(): _eveil_tete()])
	e.append([OUV + 31.4, func(): _son(SON_CRI, 2.0, 0.55)])
	e.append([OUV + 32.2, func(): _son(SON_CRI, 0.0, 0.5)])
	# 5) l'atterrissage, puis on descend jusqu'à la porte de la queue
	e.append([OUV + 33.5, func(): _son(SON_ENVOL, -8.0, 0.55)])
	e.append([OUV + 39.6, func(): _atterrir()])
	e.append([OUV + 42.0, func(): _son(SON_FLAMME, -8.0, 0.8)])
	e.append([OUV + 44.5, func(): _son(SON_MAGIE, -8.0, 0.6)])
	e.sort_custom(func(a, b): return a[0] < b[0])


func _gronder(force: float) -> void:
	_son(SON_GRONDE, -6.0 + force * 2.0, 0.6 + 0.1 * randf())
	_secouer(3.0 + force * 3.0)


func _secouer(force: float) -> void:
	_secousse = maxf(_secousse, force)


func _eclairer(force: float) -> void:
	_flash.modulate.a = maxf(_flash.modulate.a, force)


func _clac(cote: String) -> void:
	var a: Dictionary = _aile[cote]
	var p: Vector2 = a["epaule"]
	_son(SON_CLAC, 2.0)
	_secouer(16.0)
	_eclairer(0.55)
	_anneau(p, 1.0)
	_anneau(p, 1.8, 0.25)
	_etincelles(p, 36)
	_poussiere(p + Vector2(0, 40), 24, 120.0)
	# la COUTURE : une ligne de lumière court sur la jointure aile / épaule, puis un second « clac » plus sec (le verrou)
	var ligne := Line2D.new()
	ligne.points = PackedVector2Array([p + Vector2(0, -120), p + Vector2(0, 70)])
	ligne.width = 12.0
	ligne.default_color = Color(1.0, 0.85, 0.4, 1.0)
	ligne.material = _additif()
	ligne.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ligne.end_cap_mode = Line2D.LINE_CAP_ROUND
	_chateau.add_child(ligne)
	var tw := create_tween()
	tw.tween_property(ligne, "modulate:a", 0.0, 1.6)
	tw.tween_callback(ligne.queue_free)
	get_tree().create_timer(0.32).timeout.connect(func():
		_son(SON_CLAC, -3.0, 1.35)
		_secouer(7.0)
		_etincelles(p + Vector2(0, -20), 18))


# Le symbole du fragment touche le plan doré : un éclat, puis le plan se change en aile de pierre.
func _symbole_arrive(cote: String) -> void:
	var a: Dictionary = _aile[cote]
	var pos: Vector2 = (a["plan"] as Sprite2D).position
	_son(SON_MAGIE, -2.0, 1.0)
	_eclairer(0.25)
	_anneau(pos, 1.6)
	_etincelles(pos, 40)


func _eveil_tete() -> void:
	var tete := Vector2(704, 120)
	_secouer(10.0)
	_eclairer(0.45)
	_anneau(tete, 1.4)
	_anneau(tete, 2.4, 0.3)
	_etincelles(tete, 50)
	_son(SON_CLAC, -2.0, 0.8)


func _atterrir() -> void:
	_son(SON_POSE, 4.0)
	_son(SON_GRONDE, 0.0, 0.5)
	_secouer(22.0)
	_eclairer(0.35)
	_poussiere(Vector2(470, 700), 50, 220.0)
	_poussiere(Vector2(940, 700), 50, 220.0)
	_poussiere(Vector2(704, 690), 60, 260.0)
	_anneau(Vector2(704, 690), 2.6, 0.0)


# Anneau de lumière qui s'élargit (onde de choc). `taille` = échelle finale ; `retard` en s.
func _anneau(pos: Vector2, taille: float, retard := 0.0) -> void:
	var s := _sprite(_tex_anneau, _chateau, pos, true)
	s.material = _additif()
	s.scale = Vector2(0.3, 0.3)
	s.modulate = Color(1, 1, 1, 0.9)
	var tw := create_tween()
	if retard > 0.0:
		tw.tween_interval(retard)
	tw.set_parallel()
	tw.tween_property(s, "scale", Vector2(taille, taille) * 2.2, 1.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, 1.3)
	tw.chain().tween_callback(s.queue_free)


# Un éclat qui jaillit de l'horizon (annonce une aile).
func _eclat_horizon(cote: float) -> void:
	var s := _sprite(_tex_lueur, _vue, CENTRE + Vector2(cote * 1000, 120), true)
	s.material = _additif()
	s.modulate = Color(1, 0.9, 0.5, 0.0)
	s.scale = Vector2(0.2, 0.2)
	var tw := create_tween().set_parallel()
	tw.tween_property(s, "modulate:a", 1.0, 0.5)
	tw.tween_property(s, "scale", Vector2(1.2, 1.2), 0.9)
	tw.chain().tween_property(s, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(s.queue_free)


func _particules(pos: Vector2, nombre: int, vitesse: float, couleur: Color, taille: float, duree: float, ajoute := false) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = nombre
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = duree
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = vitesse * 0.4
	p.initial_velocity_max = vitesse
	p.gravity = Vector2.ZERO
	p.damping_min = vitesse * 0.3
	p.damping_max = vitesse * 0.6
	p.scale_amount_min = taille * 0.5
	p.scale_amount_max = taille
	var g := Gradient.new()
	g.colors = PackedColorArray([couleur, Color(couleur.r, couleur.g, couleur.b, 0.0)])
	p.color_ramp = g
	if ajoute:
		p.material = _additif()
	_eclats.add_child(p)
	p.emitting = true
	get_tree().create_timer(duree + 0.5).timeout.connect(p.queue_free)


func _poussiere(pos: Vector2, nombre: int, vitesse: float) -> void:
	_particules(pos, nombre, vitesse, Color(0.55, 0.5, 0.4, 0.7), 9.0, 2.4)


func _etincelles(pos: Vector2, nombre: int) -> void:
	_particules(pos, nombre, 420.0, Color(1.0, 0.85, 0.35, 1.0), 4.5, 1.2, true)


# --- Courbes de temps --------------------------------------------------------------------------------------------

# Valeur à l'instant `x` parmi des clés [temps, valeur, mode] (mode du segment qui ARRIVE à cette clé : "s" doux, "i" accélère, "o" ralentit, "l" linéaire).
func _kf(x: float, cles: Array) -> float:
	if x <= cles[0][0]:
		return float(cles[0][1])
	for i in range(1, cles.size()):
		if x <= cles[i][0]:
			var a: Array = cles[i - 1]
			var b: Array = cles[i]
			var u: float = (x - float(a[0])) / maxf(0.0001, float(b[0]) - float(a[0]))
			var mode: String = b[2] if b.size() > 2 else "s"
			match mode:
				"s": u = u * u * (3.0 - 2.0 * u)
				"i": u = u * u
				"o": u = 1.0 - (1.0 - u) * (1.0 - u)
			return lerpf(float(a[1]), float(b[1]), u)
	return float(cles[cles.size() - 1][1])


func _depassement(u: float) -> float:   # « ease out back » : arrive un peu trop loin puis se cale
	var c1 := 1.7
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(u - 1.0, 3.0) + c1 * pow(u - 1.0, 2.0)


# --- Boucle -------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _fini or _vue == null:   # (pas fini de se construire)
		return
	if _passable and t > 2.0 and t < DUREE - 2.5 and (Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel")):
		t = DUREE - 2.5   # on saute à la fin (fondu au noir)
		_i_evt = _evenements.size()
	t += delta
	while _i_evt < _evenements.size() and _evenements[_i_evt][0] <= t:
		_evenements[_i_evt][1].call()
		_i_evt += 1
	_secousse = maxf(0.0, _secousse - delta * 14.0)
	_flash.modulate.a = maxf(0.0, _flash.modulate.a - delta * 1.6)
	_evaluer(t)
	if t >= DUREE:
		_terminer()


func _terminer() -> void:
	_fini = true
	Etat.noter("assemblage_vu")
	get_tree().root.content_scale_mode = _ancien_mode
	termine.emit()


func _evaluer(x: float) -> void:
	var gx := x            # temps réel de la scène ; `x` devient le temps « ancien » (0 = début du réveil, après l'ouverture sur les pattes)
	x = x - OUV
	var alt := _kf(x, [[0.0, 0.0], [6.8, 0.0], [14.0, 1.0, "s"], [32.8, 1.0], [39.6, 0.0, "i"]])
	# --- caméra ---
	var zoom := _kf(x, [[0.0, 1.0], [6.0, 1.04], [14.0, 1.0], [17.0, 0.95], [31.0, 0.95], [33.5, 1.0], [41.5, 1.0], [47.5, 2.6, "s"]])
	var foyer := Vector2(CENTRE.x, _kf(x, [[0.0, 384.0], [41.5, 384.0], [47.5, PORTE_QUEUE.y - 30.0, "s"]]))
	# ouverture : plan serré sur les pattes (comme au Parvis), puis la caméra RECULE et révèle le château entier
	var ouv := _kf(gx, [[0.0, 3.0], [1.8, 3.0], [OUV + 3.4, 1.0, "s"]])
	zoom *= ouv
	foyer.y = lerpf(foyer.y, PORTE_QUEUE.y - 40.0, (ouv - 1.0) / 2.0)
	var dec := Vector2.ZERO
	if _secousse > 0.0:
		dec = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _secousse
	var ks := _k * zoom
	_vue.scale = Vector2(ks, ks)
	_vue.position = _ecran * 0.5 - foyer * ks + dec
	# --- ciel / fond ---
	var ciel := _kf(x, [[0.0, 0.0], [8.0, 0.0], [12.0, 1.0], [33.0, 1.0], [37.0, 0.0]])
	_ciel.modulate.a = ciel
	# --- terre : s'éloigne quand on monte (se réduit autour du château), se voile de brume ---
	var e := lerpf(1.0, 0.8, alt)
	_terre.scale = Vector2(e, e)
	_terre.position = CENTRE * (1.0 - e)
	var brume := clampf(alt * 1.6, 0.0, 1.0)
	_terre.modulate = Color(1, 1, 1, 1).lerp(Color(0.5, 0.62, 0.95, 1.0), brume)
	_terre.modulate.a = 1.0 - clampf((alt - 0.3) * 2.6, 0.0, 1.0)
	_ombre.position = Vector2(60, 90) * alt
	_ombre.modulate.a = 0.42 * (1.0 - alt * 0.7)
	# --- nuages ---
	var opac := _kf(x, [[0.0, 0.0], [8.2, 0.0], [11.0, 1.0], [33.0, 1.0], [37.2, 0.0]])
	_nuages.modulate.a = opac
	_nuages.visible = opac > 0.01
	var vit := _kf(x, [[0.0, 0.0], [8.0, 0.0], [11.0, 1100.0], [14.5, 380.0], [16.5, 70.0], [32.0, 70.0], [33.5, -120.0], [36.5, -700.0], [39.6, -1000.0]])
	_defil += vit * get_process_delta_time()
	for c in _couches.size():
		var facteur: float = [0.45, 1.0, 1.7][c]
		_couches[c].position.y = fposmod(_defil * facteur, HAUTEUR_BOUCLE) - HAUTEUR_BOUCLE * 0.5
	# --- château : tremblement, léger agrandissement en montant, flottement ---
	var tremble := _kf(x, [[0.0, 0.0], [3.0, 0.0], [5.0, 1.6], [7.0, 3.0], [8.5, 2.0], [14.0, 0.0]])
	var j := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * tremble
	var haut := clampf(alt * 2.0, 0.0, 1.0)
	var flotte := Vector2(0, sin(x * 1.4) * 6.0 * haut)
	var sc := 1.0 + 0.05 * alt
	_chateau.scale = Vector2(sc, sc)
	_chateau.position = CENTRE * (1.0 - sc) + j + flotte
	# --- torches : s'allument une à une, puis vacillent ---
	for i in _lueurs.size():
		var a := clampf((gx - (0.8 + 0.25 * i)) / 0.5, 0.0, 1.0)
		var vacille := 0.82 + 0.18 * sin(x * 9.0 + i * 1.7)
		var sursaut := clampf(1.0 - absf(x - 39.7) * 1.2, 0.0, 1.0) * 0.6
		_lueurs[i].modulate.a = a * vacille * 0.8 + sursaut * a
		_lueurs[i].scale = Vector2.ONE * (0.42 + 0.35 * sursaut + 0.04 * sin(x * 7.0 + i))
	# --- pattes (lueur des stèles) et porte de la queue ---
	var lueur_pattes := _kf(gx, [[0.0, 0.0], [0.5, 0.95], [OUV + 2.0, 0.95], [OUV + 5.0, 0.15]])
	for i in _lueurs_pattes.size():
		_lueurs_pattes[i].modulate.a = lueur_pattes * (0.8 + 0.2 * sin(gx * 4.0 + i * 2.0))
	_lueur_porte.modulate.a = _kf(x, [[44.0, 0.0], [47.5, 0.85]]) * (0.85 + 0.15 * sin(gx * 6.0))
	# --- ailes ---
	_ailes(x)
	# --- énergie le long des remparts ---
	var prog := _kf(x, [[27.8, 0.0], [30.3, 1.0, "l"]])
	var fondu := _kf(x, [[30.3, 1.0], [30.7, 1.0], [33.0, 0.0]])
	var gauche := PackedVector2Array(CHEMIN_GAUCHE)
	var droite := PackedVector2Array()
	for p in gauche:
		droite.append(Vector2(TAILLE_IMAGE.x - p.x, p.y))
	var pg := _partiel(gauche, prog)
	var pd := _partiel(droite, prog)
	for i in 4:
		_energie[i].points = pg if i % 2 == 0 else pd
		_energie[i].modulate.a = fondu * (0.85 + 0.15 * sin(x * 14.0 + i))
		_energie[i].visible = prog > 0.0 and fondu > 0.0
	# --- halo de la tête ---
	var ha := _kf(x, [[30.0, 0.0], [31.2, 1.0], [34.0, 0.65], [40.0, 0.5]])
	_halo_tete.modulate.a = ha * (0.8 + 0.2 * sin(x * 3.0))
	_halo_tete.scale = Vector2.ONE * (1.1 + 0.5 * clampf(1.0 - absf(x - 31.0), 0.0, 1.0))
	# --- voile noir : ouverture au début, fermeture à la fin ---
	_noir.modulate.a = _kf(gx, [[0.0, 1.0], [1.2, 0.0], [DUREE - 2.2, 0.0], [DUREE - 0.4, 1.0]])
	# --- sons ---
	var vent := _kf(x, [[0.0, -80.0], [8.0, -60.0], [11.0, -12.0], [17.0, -22.0], [32.0, -22.0], [38.0, -50.0], [40.0, -80.0]])
	_lecteur_vent.volume_db = vent
	_lecteur_musique.volume_db = _kf(gx, [[0.0, -40.0], [3.0, -8.0], [DUREE - 4.0, -8.0], [DUREE, -40.0]])


# Début d'une ligne brisée jusqu'à la fraction `p` (0..1) de sa longueur.
func _partiel(points: PackedVector2Array, p: float) -> PackedVector2Array:
	var sortie := PackedVector2Array()
	if p <= 0.0 or points.size() < 2:
		return sortie
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i].distance_to(points[i - 1])
	var reste := total * clampf(p, 0.0, 1.0)
	sortie.append(points[0])
	for i in range(1, points.size()):
		var d := points[i].distance_to(points[i - 1])
		if reste >= d:
			sortie.append(points[i])
			reste -= d
		else:
			sortie.append(points[i - 1].lerp(points[i], reste / maxf(d, 0.001)))
			break
	return sortie


# Les deux ailes : le PLAN DORÉ des salles parcourues apparaît, le symbole du fragment vole de la griffe jusqu'à lui, il se change en aile de pierre
# (qui flotte à la verticale, comme dans le donjon), puis l'aile fait un quart de tour et GLISSE dans l'épaule avec un petit dépassement (verrou).
func _ailes(x: float) -> void:
	for cote in _aile:
		var a: Dictionary = _aile[cote]
		var sens: float = a["cote"]
		var pivot: Node2D = a["pivot"]
		var epaule: Vector2 = a["epaule"]
		var plan: Sprite2D = a["plan"]
		var sym: Sprite2D = a["symbole"]
		var c: Array = CALENDRIER[cote]
		var attente := epaule + Vector2(sens * DEC_AILE.x, DEC_AILE.y)
		var centre_plan := plan.position
		var depart: Vector2 = PATTES[0 if cote == "g" else 1] + Vector2(0, -70)
		# --- le plan doré ---
		var pa := _kf(x, [[c[0], 0.0], [c[0] + 1.0, 0.9], [c[2], 0.9], [c[3], 0.0]])
		plan.visible = pa > 0.01
		plan.modulate.a = pa * (0.78 + 0.22 * sin(x * 9.0))
		plan.scale = Vector2.ONE * lerpf(1.45, 1.3, clampf((x - c[2]) / (c[3] - c[2]), 0.0, 1.0))
		# --- le symbole : flotte au-dessus de la griffe, puis vole vers le plan ---
		sym.visible = x <= c[2] + 0.05
		if x < c[1]:
			sym.position = depart + Vector2(0, sin(x * 3.0 + sens) * 6.0)
			sym.scale = Vector2.ONE * (2.6 + 0.2 * sin(x * 5.0))
		else:
			var u := clampf((x - c[1]) / (c[2] - c[1]), 0.0, 1.0)
			var e := u * u * (3.0 - 2.0 * u)
			sym.position = depart.lerp(centre_plan, e) + Vector2(sens * -80.0 * sin(PI * e), -170.0 * sin(PI * e))
			sym.scale = Vector2.ONE * lerpf(2.6, 1.8, e)
		sym.rotation = 0.25 * sin(x * 4.0)
		# --- l'aile ---
		pivot.visible = x >= c[2]
		if not pivot.visible:
			continue
		var apparait := clampf((x - c[2]) / (c[3] - c[2]), 0.0, 1.0)
		(a["sprite"] as Sprite2D).modulate.a = apparait
		var vertical := -sens * PI / 2.0
		var lueur := 0.0
		if x < c[4]:
			# flotte à la verticale à côté du corps
			pivot.position = attente + Vector2(0, (1.0 - apparait) * 50.0 + sin(x * 1.8 + sens) * 8.0)
			pivot.rotation = vertical
			lueur = 0.35 + 0.15 * sin(x * 6.0)
		elif x < c[5]:
			# quart de tour sur place
			var v := clampf((x - c[4]) / (c[5] - c[4]), 0.0, 1.0)
			v = v * v * (3.0 - 2.0 * v)
			pivot.position = attente + Vector2(0, -DEC_AILE.y * v)
			pivot.rotation = vertical * (1.0 - v)
			lueur = 0.45 + 0.3 * v
		else:
			# glissade dans l'épaule (elle accélère), s'enfonce de 14 px, puis se cale
			var sortie := _kf(x, [[c[5], DEC_AILE.x], [c[6], -14.0, "i"], [c[6] + 0.5, 0.0, "o"]])
			pivot.position = epaule + Vector2(sens * sortie, 0.0)
			pivot.rotation = 0.0
			lueur = 0.75 if x < c[6] else clampf(1.0 - (x - c[6]) / 1.8, 0.0, 1.0) * 0.9
		pivot.scale = Vector2.ONE
		(a["halo"] as Sprite2D).modulate.a = lueur * (0.7 + 0.3 * sin(x * 12.0)) * apparait
