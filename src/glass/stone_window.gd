class_name StoneWindow
extends Control
## The screens' stone window (stage.js stone(), with stage.css #field and #light): three lights,
## each an arch over a transom and a pane below it, cut out of tiled stone; the field picture and
## its light show through the holes, edged with lead; a sill shades the bottom of the screen.
## geom is recruit.html's geom() (GlassPieces.recruit_geom()): it gives ys, T0, T1, sill, cL, cR
## and sideW. Every other number is the stone() source's, pulled into layout.json as stage.stone.*.

const FIELD_SHADER: Shader = preload("res://src/glass/field.gdshader")
## Points per Bezier curve when an arch is turned into a polygon.
const CURVE_STEPS: int = 24

var geom: Dictionary = {}

var _holes: Array[PackedVector2Array] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func build(stage_geom: Dictionary) -> void:
	geom = stage_geom
	size = Vector2(GlassPieces.number("stage.width"), GlassPieces.number("stage.height"))
	_holes = holes(geom)
	var mask: Control = Control.new()
	mask.name = "Holes"
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mask.size = size
	mask.draw.connect(func() -> void: _draw_holes(mask))
	add_child(mask)
	mask.add_child(_field())
	var light: GlassBox = GlassBox.new()
	light.name = "Light"
	light.box_size = size
	light.use_css("stage", "#light").refresh()
	mask.add_child(light)
	var lead: Control = Control.new()
	lead.name = "Lead"
	lead.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lead.size = size
	lead.draw.connect(func() -> void: _draw_lead(lead))
	mask.add_child(lead)
	var edge: Control = Control.new()
	edge.name = "Edge"
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.size = size
	edge.draw.connect(func() -> void: _draw_edge(edge))
	add_child(edge)


func _field() -> TextureRect:
	var field: TextureRect = TextureRect.new()
	field.name = "Field"
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.texture = GlassPieces.texture("ui/quarries.jpg")
	field.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	field.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	field.size = size
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = FIELD_SHADER
	for f: Dictionary in GlassPieces.rule("stage", "#field", "filter"):
		mat.set_shader_parameter(
			"brightness" if f["fn"] == "brightness" else "saturation", _f(f["amount"])
		)
	field.material = mat
	return field


## The holes: for each light, its arch (down to T0) and its pane (T1 to the sill), as outlines
## in the order stage.js draws them.
static func holes(g: Dictionary) -> Array[PackedVector2Array]:
	var side_w: float = g["sideW"]
	var margin: float = GlassPieces.number("stage.stone.margin")
	var right: float = GlassPieces.number("stage.width") - margin
	var side_start: float = GlassPieces.number("stage.stone.side_arch_start")
	var side_top: float = GlassPieces.number("stage.stone.side_arch_top")
	var lights: Array = [
		[margin, margin + side_w, side_start, side_top],
		[g["cL"], g["cR"], g["ys"], GlassPieces.number("stage.stone.centre_arch_top")],
		[right - side_w, right, side_start, side_top],
	]
	var out: Array[PackedVector2Array] = []
	var t0: float = g["T0"]
	var t1: float = g["T1"]
	var sill: float = g["sill"]
	for light: Array in lights:
		var x0: float = light[0]
		var x1: float = light[1]
		out.append(arch(x0, x1, _f(light[2]), _f(light[3]), t0))
		out.append(
			PackedVector2Array(
				[Vector2(x0, t1), Vector2(x1, t1), Vector2(x1, sill), Vector2(x0, sill)]
			)
		)
	return out


## stage.js arch(): up the left side from yb to ys, two Beziers to the point at ya, down to yb.
## The control points are rounded to 0.1 px as the page's f() does.
static func arch(x0: float, x1: float, ys: float, ya: float, yb: float) -> PackedVector2Array:
	var w: float = x1 - x0
	var xm: float = (x0 + x1) / 2.0
	var h: float = ys - ya
	var k_start: float = GlassPieces.number("stage.stone.arch.k_start")
	var k_mid: float = GlassPieces.number("stage.stone.arch.k_mid")
	var k_top: float = GlassPieces.number("stage.stone.arch.k_top")
	var out: PackedVector2Array = PackedVector2Array([Vector2(x0, yb), Vector2(x0, ys)])
	var c1: Vector2 = Vector2(x0, snappedf(ys - k_start * h, 0.1))
	var c2: Vector2 = Vector2(snappedf(xm - k_mid * w, 0.1), snappedf(ya + k_top * h, 0.1))
	_bezier(out, Vector2(x0, ys), c1, c2, Vector2(xm, ya))
	var c3: Vector2 = Vector2(snappedf(xm + k_mid * w, 0.1), snappedf(ya + k_top * h, 0.1))
	var c4: Vector2 = Vector2(x1, snappedf(ys - k_start * h, 0.1))
	_bezier(out, Vector2(xm, ya), c3, c4, Vector2(x1, ys))
	out.append(Vector2(x1, yb))
	return out


static func _bezier(
	out: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2
) -> void:
	for i: int in range(1, CURVE_STEPS + 1):
		var t: float = _f(i) / CURVE_STEPS
		out.append(a.bezier_interpolate(b, c, d, t))


func _draw() -> void:
	# the stone: stone.jpg tiled from the stage's corner at the pattern's size, then shaded
	var tex: Texture2D = GlassPieces.texture("ui/stone.jpg")
	var tile: float = GlassPieces.number("stage.stone.tile")
	var y: float = 0.0
	while y < size.y:
		var x: float = 0.0
		while x < size.x:
			draw_texture_rect(tex, Rect2(x, y, tile, tile), false)
			x += tile
		y += tile
	var shade: Color = GlassPieces.colour("stage.stone.shade")
	shade.a = GlassPieces.number("stage.stone.shade_opacity")
	draw_rect(Rect2(Vector2.ZERO, size), shade)


func _draw_holes(on: Control) -> void:
	for hole: PackedVector2Array in _holes:
		on.draw_colored_polygon(hole, Color.WHITE)


## The leading inside each hole: the page strokes the outline with wide lines clipped to the hole,
## so half of each width shows: a dark band, a brown band, then two dash patterns over the brown.
func _draw_lead(on: Control) -> void:
	var outer_w: float = GlassPieces.number("stage.stone.lead.outer_w")
	var inner_w: float = GlassPieces.number("stage.stone.lead.inner_w")
	for hole: PackedVector2Array in _holes:
		var ring: PackedVector2Array = _closed(hole)
		on.draw_polyline(ring, GlassPieces.colour("stage.stone.lead.outer"), outer_w)
		on.draw_polyline(ring, GlassPieces.colour("stage.stone.lead.inner"), inner_w)
		for pattern: String in ["dash", "tick"]:
			var dash_on: float = GlassPieces.number("stage.stone.lead.%s_on" % pattern)
			var dash_off: float = GlassPieces.number("stage.stone.lead.%s_off" % pattern)
			var tint: Color = GlassPieces.colour("stage.stone.lead." + pattern)
			for piece: PackedVector2Array in dashes(ring, dash_on, dash_off):
				on.draw_polyline(piece, tint, inner_w)


## The dark edge round each hole, its faint highlight up and left, and the sill's shading.
func _draw_edge(on: Control) -> void:
	var hi: Color = GlassPieces.colour("stage.stone.highlight.colour")
	hi.a = GlassPieces.number("stage.stone.highlight.opacity")
	var shift: Vector2 = Vector2(
		GlassPieces.number("stage.stone.highlight.x"), GlassPieces.number("stage.stone.highlight.y")
	)
	for hole: PackedVector2Array in _holes:
		var ring: PackedVector2Array = _closed(hole)
		on.draw_polyline(
			ring,
			GlassPieces.colour("stage.stone.edge.colour"),
			GlassPieces.number("stage.stone.edge.w")
		)
		var moved: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in ring:
			moved.append(p + shift)
		on.draw_polyline(moved, hi, GlassPieces.number("stage.stone.highlight.w"), true)
	_draw_sill(on)


## The sill: a vertical gradient from the sill to the bottom of the screen, as stage.js's
## #sillg stops give it (non-premultiplied, as SVG interpolates).
func _draw_sill(on: Control) -> void:
	var top: float = geom["sill"]
	var h: float = size.y - top
	var first: Color = GlassPieces.colour("stage.stone.sill.top")
	first.a = GlassPieces.number("stage.stone.sill.top_opacity")
	var stops: Array = [
		[0.0, first],
		[GlassPieces.number("stage.stone.sill.a"), Color(0, 0, 0, 0)],
		[
			GlassPieces.number("stage.stone.sill.b"),
			Color(0, 0, 0, GlassPieces.number("stage.stone.sill.b_opacity"))
		],
		[1.0, Color(0, 0, 0, GlassPieces.number("stage.stone.sill.end_opacity"))],
	]
	for i: int in stops.size() - 1:
		var y0: float = top + _f(stops[i][0]) * h
		var y1: float = top + _f(stops[i + 1][0]) * h
		var c0: Color = stops[i][1]
		var c1: Color = stops[i + 1][1]
		on.draw_polygon(
			PackedVector2Array(
				[Vector2(0, y0), Vector2(size.x, y0), Vector2(size.x, y1), Vector2(0, y1)]
			),
			PackedColorArray([c0, c0, c1, c1])
		)


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = points.duplicate()
	out.append(points[0])
	return out


## An SVG stroke-dasharray of "on off" along a path: the drawn pieces, each a polyline.
static func dashes(
	path: PackedVector2Array, dash_on: float, dash_off: float
) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var period: float = dash_on + dash_off
	var walked: float = 0.0
	var piece: PackedVector2Array = PackedVector2Array()
	for i: int in path.size() - 1:
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var length: float = a.distance_to(b)
		var t: float = 0.0
		while t < length:
			var phase: float = fmod(walked + t, period)
			var drawing: bool = phase < dash_on
			var left: float = (dash_on - phase) if drawing else (period - phase)
			var step: float = minf(left, length - t)
			var p0: Vector2 = a.lerp(b, t / length)
			var p1: Vector2 = a.lerp(b, (t + step) / length)
			if drawing:
				if piece.is_empty():
					piece.append(p0)
				piece.append(p1)
				if step >= left - 0.0001:
					out.append(piece)
					piece = PackedVector2Array()
			t += step
		walked += length
	if piece.size() > 1:
		out.append(piece)
	return out


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
