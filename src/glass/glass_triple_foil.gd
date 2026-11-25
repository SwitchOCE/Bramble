class_name GlassTripleFoil
extends Control
## STAND-IN: triple-only face light fitted to the L1 silhouette and stat rims.
## Time is shared with the rim.

const SHADER: Shader = preload("res://src/glass/card_triple_foil.gdshader")
const PERIOD: float = 3.2
const TRAVEL: float = 0.66
const SPACING: float = 0.42
const SLOPE: float = 0.65
const BAND_WIDTH: float = 0.12
const STRENGTH: float = 0.68
const STAT_CLEARANCE: float = 1.5
const STAT_FEATHER: float = 8.0
const COLOUR_DIAGONAL_RATE: float = 9.0
const COLOUR_X_RATE: float = 5.0
const COLOUR_A: Color = Color("a2f5ff")
const COLOUR_B: Color = Color("ffb8ed")


static func apply(card: GlassCard, triple: bool) -> GlassTripleFoil:
	var foil: GlassTripleFoil = card.get_node_or_null("TripleFoil")
	if foil == null and triple:
		foil = GlassTripleFoil.new()
		foil.name = "TripleFoil"
		foil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter("spacing", SPACING)
		mat.set_shader_parameter("slope", SLOPE)
		mat.set_shader_parameter("band_width", BAND_WIDTH)
		mat.set_shader_parameter("strength", STRENGTH)
		mat.set_shader_parameter("stat_feather", STAT_FEATHER)
		mat.set_shader_parameter("colour_diagonal_rate", COLOUR_DIAGONAL_RATE)
		mat.set_shader_parameter("colour_x_rate", COLOUR_X_RATE)
		mat.set_shader_parameter("colour_a", COLOUR_A)
		mat.set_shader_parameter("colour_b", COLOUR_B)
		# Keep the original foil's coordinate scale and clear the new rims.
		var units: Vector2 = GlassPieces.card_units()
		var k: float = units.y / L1Layout.number("card.h")
		var rim: float = L1Layout.number("card.stat.rim") + L1Layout.number("card.stat.outline")
		mat.set_shader_parameter("card_units", units)
		for stat: String in ["attack", "health"]:
			var disc: Vector3 = GlassCard.stat_disc(stat)
			disc.z = maxf(disc.z * STAT_CLEARANCE, disc.z + rim)
			mat.set_shader_parameter(stat + "_disc", disc * k)
		foil.material = mat
		var mask: Texture2D = L1CardFace.silhouette()
		foil.size = GlassCard.card_size(card.card_height)
		foil.draw.connect(
			func() -> void: foil.draw_texture_rect(mask, Rect2(Vector2.ZERO, foil.size), false)
		)
		card.add_child(foil)
	if foil != null:
		foil.visible = triple
	return foil


func set_phase(seconds: float) -> void:
	var mat: ShaderMaterial = material as ShaderMaterial
	# A cosine travel reverses smoothly: the diagonals sweep down and back up each period.
	mat.set_shader_parameter("travel", TRAVEL * cos(TAU * seconds / PERIOD))
