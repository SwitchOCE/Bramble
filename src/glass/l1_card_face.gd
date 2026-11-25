class_name L1CardFace
extends Control
## The lead, art window and edge shared by unit cards and the spells in the hand.

const SHADER: Shader = preload("res://src/glass/l1_card_face.gdshader")
const SHADOW_SHADER: Shader = preload("res://src/glass/card_shadow.gdshader")

static var _lead: GradientTexture1D
static var _gilt: GradientTexture1D
static var _masks: Dictionary[bool, Texture2D] = {}

var _edge: float


static func draw_size() -> Vector2:
	return Vector2(L1Layout.number("card.w"), L1Layout.number("card.h"))


static func point_angle() -> float:
	return deg_to_rad(L1Layout.number("board.point_angle"))


static func unit_outline(box: Vector2) -> PackedVector2Array:
	return GlassBox.hexagon(Rect2(Vector2.ZERO, box), box.x * tan(point_angle()) / (2.0 * box.y))


func build(box: Vector2, art: Texture2D, circle: bool = false) -> void:
	size = box
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var reference: Vector2 = Vector2.ONE * draw_size().x if circle else draw_size()
	var scale_to_size: float = box.x / reference.x
	var crop: Rect2 = L1Layout.rect("hand.spell.art" if circle else "card.art")
	var source: Vector2 = GlassPieces.card_units()
	var angle: float = point_angle()
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("face_size", reference)
	mat.set_shader_parameter("face_scale", scale_to_size)
	mat.set_shader_parameter("slopes", Vector2(sin(angle), cos(angle)))
	mat.set_shader_parameter("circle", circle)
	mat.set_shader_parameter(
		"lead_width", L1Layout.number("hand.spell.ring" if circle else "card.lead.width")
	)
	mat.set_shader_parameter("has_art", art != null)
	mat.set_shader_parameter("art", art)
	mat.set_shader_parameter(
		"crop",
		Vector4(
			crop.position.x / source.x,
			crop.position.y / source.y,
			crop.size.x / source.x,
			crop.size.y / source.y
		)
	)
	if not circle:
		mat.set_shader_parameter(
			"bevel_stops",
			Vector2(
				L1Layout.number("card.bevel.top_stop"), L1Layout.number("card.bevel.bottom_stop")
			)
		)
		mat.set_shader_parameter(
			"bevel_alpha",
			Vector2(
				L1Layout.number("card.bevel.top_alpha"), L1Layout.number("card.bevel.bottom_alpha")
			)
		)
	var depth: float = L1Layout.number("card.edge.depth")
	var line: float = depth if circle else L1Layout.number("card.edge.line")
	mat.set_shader_parameter("edge_offsets", Vector2(depth, line))
	_edge = depth * scale_to_size
	material = mat
	set_gilt(false)
	if circle:
		mat.set_shader_parameter("edge_line", Color.TRANSPARENT)


## Gilt lead and edge for a golden card, with its glint running along the gilt every few seconds
## (phase: a share of the glint's period, so golden cards do not glint together).
func set_gilt(on: bool, phase: float = 0.0) -> void:
	var mat: ShaderMaterial = material as ShaderMaterial
	var glint: Color = L1Layout.colour("light.golden.glint_colour")
	glint.a = L1Layout.number("light.golden.glint.strength") if on else 0.0
	mat.set_shader_parameter("glint_colour", glint)
	mat.set_shader_parameter("glint", glint_timing(phase))
	var key: String = "card.gilt" if on else "card.lead"
	var angle: float = deg_to_rad(L1Layout.number(key + ".angle"))
	mat.set_shader_parameter("lead_direction", Vector2(sin(angle), -cos(angle)))
	mat.set_shader_parameter("lead_ramp", _lead_ramp(on))
	mat.set_shader_parameter("edge_top", Color("7a4a18") if on else Color("2a2f2d"))
	mat.set_shader_parameter("edge_bottom", Color("3e240b") if on else Color("0b0d0c"))
	var line: Color = Color("ffd68c") if on else Color("aabeb9")
	line.a = L1Layout.number("card.gilt.line_alpha" if on else "card.edge.line_alpha")
	mat.set_shader_parameter("edge_line", line)


static func glint_timing(phase: float) -> Vector4:
	return Vector4(
		L1Layout.number("light.golden.glint.period"),
		L1Layout.number("light.golden.glint.sweep"),
		L1Layout.number("light.golden.glint.width"),
		phase
	)


## How far round the outline (clockwise on screen from the bottom point, 0 to 1) a point of the
## face lies, as the face shader measures it for the glint.
static func way_round(at: Vector2, box: Vector2) -> float:
	var c: Vector2 = (at - box / 2.0) / (box / 2.0)
	return fposmod((atan2(c.y, c.x) - PI / 2.0) / TAU, 1.0)


func _draw() -> void:
	draw_rect(Rect2(-Vector2.ONE, size + Vector2(2.0, _edge + 2.0)), Color.WHITE)


static func _lead_ramp(gilt: bool) -> GradientTexture1D:
	if _lead == null:
		_lead = _ramp(
			[
				0.0,
				L1Layout.number("card.lead.dark_stop"),
				L1Layout.number("card.lead.black_stop"),
				1.0
			],
			[Color("4a4f4c"), Color("232726"), Color("0e1110"), Color("262a29")]
		)
		_gilt = _ramp(
			[
				0.0,
				L1Layout.number("card.gilt.highlight_stop"),
				L1Layout.number("card.gilt.mid_stop"),
				L1Layout.number("card.gilt.gold_stop"),
				L1Layout.number("card.gilt.dark_stop"),
				1.0
			],
			[
				Color("9a5e25"),
				Color("ffe39a"),
				Color("c08636"),
				Color("f2c467"),
				Color("8d521f"),
				Color("ffdf8f")
			]
		)
	return _gilt if gilt else _lead


static func _ramp(stops: PackedFloat32Array, colours: PackedColorArray) -> GradientTexture1D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = stops
	gradient.colors = colours
	var tex: GradientTexture1D = GradientTexture1D.new()
	tex.gradient = gradient
	return tex


## A solid, antialiased silhouette for the existing shadow and triple foil shaders.
static func silhouette(circle: bool = false) -> Texture2D:
	if not _masks.has(circle):
		var box: Vector2 = GlassPieces.card_units()
		var shape: String
		if circle:
			box.y = box.x
			shape = (
				'<circle cx="%s" cy="%s" r="%s" fill="white"/>'
				% [box.x / 2.0, box.x / 2.0, box.x / 2.0]
			)
		else:
			var points: PackedStringArray = []
			for p: Vector2 in unit_outline(box):
				points.append("%.3f,%.3f" % [p.x, p.y])
			shape = '<polygon points="%s" fill="white"/>' % " ".join(points)
		var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s">%s</svg>'
		var mask: Image = Image.new()
		mask.load_svg_from_string(svg % [box.x, box.y, shape])
		mask.generate_mipmaps()
		_masks[circle] = ImageTexture.create_from_image(mask)
	return _masks[circle]


static func slab_shadow(raised: bool, circle: bool, k: float) -> Dictionary:
	var key: String = "card.shadow.rest"
	if raised:
		key = "hand.spell.shadow" if circle else "card.shadow.raised"
	return {
		"x": L1Layout.number(key + ".x") * k,
		"y": L1Layout.number(key + ".y") * k,
		"blur": L1Layout.number(key + ".blur") * k,
		"colour": Color(0, 0, 0, L1Layout.number(key + ".alpha")),
	}


static func draw_shadow(on: Control, spec: Dictionary, box: Vector2, circle: bool = false) -> void:
	var blur: float = spec["blur"]
	var margin: Vector2 = Vector2.ONE * (blur * 1.5 + 2.0)
	var offset: Vector2 = Vector2(GlassPieces.as_float(spec["x"]), GlassPieces.as_float(spec["y"]))
	var rect: Rect2 = Rect2(offset - margin, box + 2.0 * margin)
	var mat: ShaderMaterial = on.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = SHADOW_SHADER
		on.material = mat
	mat.set_shader_parameter("uv_scale", rect.size / box)
	mat.set_shader_parameter("uv_offset", -margin / box)
	# CSS blur radius is twice the Gaussian's standard deviation.
	mat.set_shader_parameter("sigma_uv", Vector2.ONE * blur / 2.0 / box)
	mat.set_shader_parameter("shadow_colour", spec["colour"])
	on.draw_texture_rect(silhouette(circle), rect, false)
