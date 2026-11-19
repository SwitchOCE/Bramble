class_name GlassTripleFoil
extends Control
## Triple-only face light. All tuneable look/motion values live here; time is shared with the rim.

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

static var _masks: Dictionary = {}


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
		mat.set_shader_parameter("card_units", GlassPieces.card_units())
		for stat: String in ["attack", "health"]:
			var disc: Vector3 = GlassPieces.disc(card.tier, stat)
			disc.z *= STAT_CLEARANCE
			mat.set_shader_parameter(stat + "_disc", disc)
		foil.material = mat
		var mask: Texture2D = _face_mask(card.tier)
		foil.size = GlassCard.card_size(card.card_height)
		foil.draw.connect(
			func() -> void: foil.draw_texture_rect(mask, Rect2(Vector2.ZERO, foil.size), false)
		)
		card.add_child(foil)
	if foil != null:
		foil.visible = triple
	return foil


## The frame has a transparent art window. Fill between its alpha edges on each scanline so
## the foil covers the face too, retaining the actual frame contour and its antialiasing.
static func _face_mask(tier: int) -> Texture2D:
	if not _masks.has(tier):
		var mask: Image = GlassPieces.frame(tier).get_image()
		if mask.is_compressed():
			mask.decompress()
		mask.convert(Image.FORMAT_RGBA8)
		for y: int in mask.get_height():
			var left: int = 0
			var right: int = mask.get_width() - 1
			while left <= right and mask.get_pixel(left, y).a == 0.0:
				left += 1
			while right > left and mask.get_pixel(right, y).a == 0.0:
				right -= 1
			if right > left:
				mask.fill_rect(Rect2i(left + 1, y, right - left - 1, 1), Color.WHITE)
		# Replace the imported frame mipmaps too: their art window was still transparent.
		mask.generate_mipmaps()
		_masks[tier] = ImageTexture.create_from_image(mask)
	return _masks[tier]


func set_phase(seconds: float) -> void:
	var mat: ShaderMaterial = material as ShaderMaterial
	# A cosine travel reverses smoothly: the diagonals sweep down and back up each period.
	mat.set_shader_parameter("travel", TRAVEL * cos(TAU * seconds / PERIOD))
