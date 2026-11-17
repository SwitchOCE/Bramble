class_name GlassBox
extends Control
## A box drawn the way a stage.css rule draws one: its shape, border, background layers and
## shadows, from the rule's pulled declarations (layout.json's css/<file>/<selector>/<property>).
## The box's border box is (0, 0) to box_size; shadows draw outside it. Children draw on top, so
## a box's words and icons are its children. Call refresh() after changing a field.

const SHADER: Shader = preload("res://src/glass/glass_box.gdshader")
const MAX_STOPS: int = 10

## The border box, in pixels.
var box_size: Vector2 = Vector2(100, 100)
## Corner radii: top left, top right, bottom right, bottom left. Half the size makes a circle.
var radii: Vector4 = Vector4.ZERO
## A convex polygon for the outline instead of radii, clockwise, and the polygon inside its border.
var polygon_outer: PackedVector2Array = PackedVector2Array()
var polygon_inner: PackedVector2Array = PackedVector2Array()
var border_width: float = 0.0
var border_colour: Color = Color.TRANSPARENT
## The padding box when it is not the border box less the border, as for .slot::after's inset.
var padding_override: Rect2 = Rect2()
## CSS background layers, top first, as css_values.py reads them.
var layers: Array = []
var blend_modes: Array = []
## An image for a layer the page sets inline, such as a portrait: {"kind": "image", "file": ...}.
var image_texture: Texture2D
## CSS box-shadow list.
var shadows: Array = []

var _material: ShaderMaterial


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Reads border, border-radius, background, background-blend-mode and box-shadow from one rule,
## leaving out what the rule does not set. Later calls add to or override earlier ones.
func use_css(file: String, selector: String) -> GlassBox:
	var border: Variant = GlassPieces.rule_or(file, selector, "border", null)
	if border is Dictionary:
		var b: Dictionary = border
		border_width = b["width"]
		border_colour = Color.html(str(b["colour"]))
	var border_w: Variant = GlassPieces.rule_or(file, selector, "border-width", null)
	if border_w is float or border_w is int:
		border_width = _f(border_w)
	var radius: Variant = GlassPieces.rule_or(file, selector, "border-radius", null)
	if radius != null:
		radii = GlassBox.css_radii(radius, box_size)
	var bg: Variant = GlassPieces.rule_or(file, selector, "background", null)
	if bg is Array:
		layers = bg
		blend_modes = []
	var blend: Variant = GlassPieces.rule_or(file, selector, "background-blend-mode", null)
	if blend is Array:
		blend_modes = blend
	var shadow: Variant = GlassPieces.rule_or(file, selector, "box-shadow", null)
	if shadow is Array:
		shadows = shadow
	return self


## border-radius as px, a percentage of the box, or four of either.
static func css_radii(value: Variant, box: Vector2) -> Vector4:
	var parts: Array = value if value is Array else [value]
	var px: Array[float] = []
	for part: Variant in parts:
		var text: String = str(part)
		if text.ends_with("%"):
			px.append(text.to_float() / 100.0 * minf(box.x, box.y))
		elif text.ends_with("em"):
			# an em radius needs the font size; the caller sets radii itself (.btn .pip)
			px.append(0.0)
		else:
			px.append(_f(part))
	while px.size() < 4:
		px.append(px[px.size() % 2] if px.size() >= 2 else px[0])
	return Vector4(px[0], px[1], px[2], px[3])


## The hexagon the cards, slots and spells share: shoulders at s of the height from top and bottom.
static func hexagon(rect: Rect2, s: float) -> PackedVector2Array:
	var p: Vector2 = rect.position
	var w: float = rect.size.x
	var h: float = rect.size.y
	return PackedVector2Array(
		[
			p + Vector2(w / 2.0, 0.0),
			p + Vector2(w, h * s),
			p + Vector2(w, h * (1.0 - s)),
			p + Vector2(w / 2.0, h),
			p + Vector2(0.0, h * (1.0 - s)),
			p + Vector2(0.0, h * s),
		]
	)


## The clip-path polygon (percentages) of a CSS rule, in a rect.
static func css_polygon(points: Array, rect: Rect2) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for point: Array in points:
		var x: float = point[0]
		var y: float = point[1]
		out.append(rect.position + Vector2(x / 100.0 * rect.size.x, y / 100.0 * rect.size.y))
	return out


func padding_rect() -> Rect2:
	if padding_override.has_area():
		return padding_override
	return Rect2(Vector2(border_width, border_width), box_size - Vector2.ONE * 2.0 * border_width)


func refresh() -> void:
	size = box_size
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		material = _material
	var m: ShaderMaterial = _material
	var pad: Rect2 = padding_rect()
	m.set_shader_parameter("box_size", box_size)
	m.set_shader_parameter("radii", radii)
	m.set_shader_parameter("shape", 1 if polygon_outer.size() > 0 else 0)
	m.set_shader_parameter("poly_count", polygon_outer.size())
	m.set_shader_parameter("poly_outer", _padded(polygon_outer))
	m.set_shader_parameter(
		"poly_inner", _padded(polygon_inner if polygon_inner.size() > 0 else polygon_outer)
	)
	m.set_shader_parameter(
		"padding_rect", Vector4(pad.position.x, pad.position.y, pad.size.x, pad.size.y)
	)
	m.set_shader_parameter("border_width", border_width)
	m.set_shader_parameter("border_colour", border_colour)
	_set_layers(m, pad)
	_set_shadows(m)
	queue_redraw()


func _padded(points: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = points.duplicate()
	while out.size() < 8:
		out.append(Vector2.ZERO)
	return out


func _set_layers(m: ShaderMaterial, pad: Rect2) -> void:
	m.set_shader_parameter("has_top", false)
	m.set_shader_parameter("has_image", false)
	m.set_shader_parameter("has_bottom", false)
	m.set_shader_parameter("base_colour", Color.TRANSPARENT)
	var n: int = layers.size()
	for i: int in n:
		var layer: Dictionary = layers[i]
		var kind: String = layer["kind"]
		if kind == "colour":
			m.set_shader_parameter("base_colour", Color.html(str(layer["colour"])))
		elif kind == "radial":
			# the last layer is the bottom one; any other gradient is the top one
			_set_gradient(m, "bottom" if i == n - 1 and n > 1 else "top", layer, pad)
		elif kind == "image":
			var tex: Texture2D = image_texture
			if layer.has("file"):
				tex = GlassPieces.texture(str(layer["file"]))
			if tex == null:
				continue
			m.set_shader_parameter("has_image", true)
			m.set_shader_parameter("image", tex)
			var rect: Rect2 = GlassBox.image_rect(layer, tex.get_size(), pad)
			m.set_shader_parameter(
				"image_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y)
			)
			var mode: String = str(blend_modes[i]) if i < blend_modes.size() else "normal"
			m.set_shader_parameter("image_multiply", mode == "multiply")


## Where a background image lands in the padding box: its size ("cover", "auto" or [width %,
## "auto"]) and its position (percentages, CSS's: the image's point at p% meets the box's p%).
static func image_rect(layer: Dictionary, tex_size: Vector2, pad: Rect2) -> Rect2:
	var drawn: Vector2 = tex_size
	var mode: Variant = layer.get("size", "auto")
	if mode is Array:
		var pct: Array = mode
		var w: float = _f(pct[0]) / 100.0 * pad.size.x
		drawn = Vector2(w, w * tex_size.y / tex_size.x)
	elif str(mode) == "cover":
		var k: float = maxf(pad.size.x / tex_size.x, pad.size.y / tex_size.y)
		drawn = tex_size * k
	var at: Array = layer.get("position", [50.0, 50.0])
	var fx: float = _f(at[0]) / 100.0
	var fy: float = _f(at[1]) / 100.0
	return Rect2(pad.position + (pad.size - drawn) * Vector2(fx, fy), drawn)


func _set_gradient(m: ShaderMaterial, slot: String, layer: Dictionary, pad: Rect2) -> void:
	var at: Array = layer["at"]
	var centre: Vector2 = pad.position + pad.size * Vector2(_f(at[0]), _f(at[1])) / 100.0
	var radii_px: Vector2 = GlassBox.gradient_radii(layer, centre - pad.position, pad.size)
	var colours: PackedColorArray = PackedColorArray()
	var stops: PackedFloat32Array = PackedFloat32Array()
	var raw_stops: Array = layer["stops"]
	for entry: Array in GlassBox.gradient_stops(raw_stops):
		colours.append(Color.html(str(entry[0])))
		stops.append(_f(entry[1]) / 100.0)
	while colours.size() < MAX_STOPS:
		colours.append(colours[colours.size() - 1])
		stops.append(stops[stops.size() - 1])
	m.set_shader_parameter("has_" + slot, true)
	m.set_shader_parameter(slot + "_centre", centre)
	m.set_shader_parameter(slot + "_radii", radii_px)
	m.set_shader_parameter(slot + "_count", mini(MAX_STOPS, raw_stops.size()))
	m.set_shader_parameter(slot + "_colours", colours)
	m.set_shader_parameter(slot + "_stops", stops)


## A radial gradient's ending shape in px: explicit percentages of the box, or farthest-corner.
## A farthest-corner ellipse keeps the shape closest-side would give it (CSS Images 3).
static func gradient_radii(layer: Dictionary, c: Vector2, box: Vector2) -> Vector2:
	var ending: Variant = layer.get("size", "farthest-corner")
	if ending is Array:
		var pct: Array = ending
		return Vector2(_f(pct[0]) / 100.0 * box.x, _f(pct[1]) / 100.0 * box.y)
	var far: Vector2 = Vector2(maxf(c.x, box.x - c.x), maxf(c.y, box.y - c.y))
	if str(layer.get("shape", "ellipse")) == "circle":
		var r: float = far.length()
		return Vector2(r, r)
	var near: Vector2 = Vector2(minf(c.x, box.x - c.x), minf(c.y, box.y - c.y))
	near = Vector2(maxf(near.x, 0.001), maxf(near.y, 0.001))
	var k: float = sqrt(pow(far.x / near.x, 2.0) + pow(far.y / near.y, 2.0))
	return near * k


## Colour stops with every position filled in, as percentages: an unset first stop is 0, an unset
## last is 100, unset ones between are spread evenly, and none is before the one ahead of it.
static func gradient_stops(raw: Array) -> Array:
	var out: Array = []
	for entry: Array in raw:
		out.append([entry[0], entry[1]])
	if out[0][1] == null:
		out[0][1] = 0.0
	if out[out.size() - 1][1] == null:
		out[out.size() - 1][1] = 100.0
	var last: float = 0.0
	var i: int = 0
	while i < out.size():
		if out[i][1] == null:
			var j: int = i
			while out[j][1] == null:
				j += 1
			var from: float = out[i - 1][1]
			var to: float = out[j][1]
			for k: int in range(i, j):
				out[k][1] = from + (to - from) * _f(k - i + 1) / _f(j - i + 1)
		last = maxf(last, _f(out[i][1]))
		out[i][1] = last
		i += 1
	return out


func _set_shadows(m: ShaderMaterial) -> void:
	var geoms: PackedVector4Array = PackedVector4Array()
	var colours: PackedColorArray = PackedColorArray()
	m.set_shader_parameter("inset_spread", 0.0)
	for raw: Dictionary in shadows:
		var colour: Color = Color.html(str(raw["colour"]))
		if raw["inset"]:
			m.set_shader_parameter("inset_spread", _f(raw["spread"]))
			m.set_shader_parameter("inset_colour", colour)
			continue
		geoms.append(Vector4(_f(raw["x"]), _f(raw["y"]), _f(raw["blur"]), _f(raw["spread"])))
		colours.append(colour)
	m.set_shader_parameter("shadow_count", colours.size())
	while geoms.size() < 3:
		geoms.append(Vector4.ZERO)
		colours.append(Color.TRANSPARENT)
	m.set_shader_parameter("shadow_geom", geoms)
	m.set_shader_parameter("shadow_colours", colours)


## How far the shadows reach outside the border box.
func reach() -> float:
	var out: float = 2.0
	for raw: Dictionary in shadows:
		if raw["inset"]:
			continue
		var x: float = raw["x"]
		var y: float = raw["y"]
		var blur: float = raw["blur"]
		var spread: float = raw["spread"]
		out = maxf(out, maxf(absf(x), absf(y)) + spread + blur * 1.5 + 2.0)
	return out


func _draw() -> void:
	var r: float = reach()
	draw_rect(Rect2(-Vector2.ONE * r, box_size + Vector2.ONE * 2.0 * r), Color.WHITE)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
