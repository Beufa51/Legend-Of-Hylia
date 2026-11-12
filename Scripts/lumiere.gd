extends RefCounted
class_name Lumiere
# Fabrique des lumières rondes (PointLight2D) pour les salles sombres.

static var _texture: GradientTexture2D


# Une lumière ronde : `echelle` 1.0 = environ 64 pixels de rayon.
static func creer(couleur: Color, echelle: float, energie: float) -> PointLight2D:
	if _texture == null:
		var degrade := Gradient.new()
		degrade.set_color(0, Color(1, 1, 1, 1))
		degrade.set_color(1, Color(1, 1, 1, 0))
		_texture = GradientTexture2D.new()
		_texture.gradient = degrade
		_texture.width = 128
		_texture.height = 128
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
	var lumiere := PointLight2D.new()
	lumiere.texture = _texture
	lumiere.color = couleur
	lumiere.energy = energie
	lumiere.texture_scale = echelle
	return lumiere
