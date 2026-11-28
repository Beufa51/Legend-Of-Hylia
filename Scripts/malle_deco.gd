extends StaticBody2D
class_name MalleDeco
# La MALLE À DÉCORS de la maison du héros (lettre Z de interieur.gd) : l'image est posée par l'intérieur,
# ce corps reçoit le coup de lance (méthode `frapper`, comme les pots) et ouvre le mode décoration.
# Elle « respire » un peu quand elle contient des décors pas encore placés (pour qu'on pense à l'ouvrir).

var interieur: Interieur
var _lueur: Sprite2D
var _attente := 0.0   # la lance touche à chaque image : on n'ouvre qu'une fois


func _ready() -> void:
	var forme := RectangleShape2D.new()
	forme.size = Vector2(32, 32)
	var collision := CollisionShape2D.new()
	collision.shape = forme
	add_child(collision)
	# petite lueur dorée au-dessus du couvercle (des décors attendent dedans)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1, 0.85, 0.4, 0.55), Color(1, 0.85, 0.4, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 40
	tex.height = 28
	_lueur = Sprite2D.new()
	_lueur.texture = tex
	_lueur.position = Vector2(0, -6)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_lueur.material = mat
	add_child(_lueur)


func _process(delta: float) -> void:
	_attente = maxf(_attente - delta, 0.0)
	var en_attente := false
	for d in Etat.decors:
		if d["x"] < 0:
			en_attente = true
			break
	_lueur.visible = en_attente
	if en_attente:
		_lueur.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 300.0)


func frapper() -> void:
	if _attente > 0.0 or interieur == null:
		return
	_attente = 1.0
	interieur.ouvrir_decoration()
