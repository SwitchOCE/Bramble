class_name GlassText
extends Control
## One line of text as the mock-ups' CSS lays it out: a line box of line-height normal (or a set
## line height), the baseline where a browser puts it, and -webkit-text-stroke painted under the
## fill (paint-order: stroke fill). Its size is its line box, so a parent can centre it as flex or
## grid would. Set the fields, then call refresh().

## Godot's outline_size N strokes N/4 px out from the glyphs (FreeType radius N x 16 in 26.6
## units); CSS's -webkit-text-stroke W shows W/2 outside them. So N = 2 W.
const OUTLINE_PER_STROKE: float = 2.0

var words: String = ""
var weight: int = 400
var font_px: float = 16.0
## "display" (Alegreya) or "body" (Alegreya Sans).
var family: String = "body"
var colour: Color = Color.WHITE
## -webkit-text-stroke: its full width, centred on the glyphs' edges, so half shows outside.
var stroke_width: float = 0.0
var stroke_colour: Color = Color.TRANSPARENT
## letter-spacing in pixels, after every letter as browsers add it.
var spacing: float = 0.0
## line-height as a multiple of the size; 0 is "normal".
var line_height: float = 0.0
## text-shadow, as css_values.py reads it (x, y, blur, colour); drawn as a soft outline.
var shadow: Dictionary = {}
## Lining figures, as card.css's font-variant-numeric: lining-nums.
var lining: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Sets the font fields from a pulled font shorthand {weight, size, family}.
func use_font(spec: Dictionary) -> GlassText:
	weight = _i(spec["weight"])
	family = str(spec["family"])
	var spec_px: Variant = spec["size"]
	if spec_px is float or spec_px is int:
		font_px = _f(spec_px)
	var lh: Variant = spec.get("line_height")
	if lh != null:
		line_height = _f(lh)
	return self


func font() -> Font:
	if family == "display":
		return GlassPieces.display_font(weight, lining)
	return GlassPieces.body_font(weight)


func px() -> int:
	return roundi(font_px)


## The line box: as wide as the words, as tall as the line.
func line_size() -> Vector2:
	var f: Font = font()
	var width: float = f.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px()).x
	return Vector2(width + spacing * words.length(), _line_height())


func _line_height() -> float:
	if line_height > 0.0:
		return line_height * font_px
	var line: Vector3 = GlassPieces.css_line(family, px())
	return line.x + line.y + line.z


## The baseline's distance below the line box's top. With a set line height the leading is split
## evenly above and below the font's ascent and descent.
func baseline() -> float:
	var line: Vector3 = GlassPieces.css_line(family, px())
	var content: float = line.x + line.y
	return (_line_height() - content) / 2.0 + line.x


func refresh() -> GlassText:
	size = line_size()
	queue_redraw()
	return self


func _draw() -> void:
	var f: Font = font()
	var at: Vector2 = Vector2(0.0, baseline())
	if not shadow.is_empty():
		var blur: float = shadow.get("blur", 0.0)
		var offset: Vector2 = Vector2(_f(shadow.get("x", 0.0)), _f(shadow.get("y", 0.0)))
		var tint: Color = Color.html(str(shadow["colour"]))
		# STAND-IN for the CSS text-shadow blur: soft outlines of falling strength.
		for pass_i: int in 3:
			var reach: float = blur * (1.0 - 0.3 * pass_i)
			_text(
				f,
				at + offset,
				tint * Color(1, 1, 1, 0.3 + 0.15 * pass_i),
				maxi(1, roundi(reach * 2.0))
			)
	if stroke_width > 0.0:
		_text(f, at, stroke_colour, roundi(stroke_width * OUTLINE_PER_STROKE))
	_text(f, at, colour, 0)


func _text(f: Font, at: Vector2, tint: Color, outline: int) -> void:
	if spacing == 0.0:
		if outline > 0:
			f.draw_string_outline(
				get_canvas_item(), at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px(), outline, tint
			)
		else:
			f.draw_string(get_canvas_item(), at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px(), tint)
		return
	# each letter where the whole line's shaping puts it (keeping kerning), plus the spacing so far
	for i: int in words.length():
		var ch: String = words[i]
		var before: float = (
			f.get_string_size(words.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, px()).x
		)
		var p: Vector2 = Vector2(at.x + before + spacing * i, at.y)
		if outline > 0:
			f.draw_string_outline(
				get_canvas_item(), p, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px(), outline, tint
			)
		else:
			f.draw_string(get_canvas_item(), p, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px(), tint)


## A ready text node from a stage.css rule's font, color and -webkit-text-stroke.
static func from_rule(file: String, selector: String, text_words: String) -> GlassText:
	var t: GlassText = GlassText.new()
	t.words = text_words
	var spec: Variant = GlassPieces.rule_or(file, selector, "font", null)
	if spec is Dictionary:
		var font_spec: Dictionary = spec
		t.use_font(font_spec)
	var c: Variant = GlassPieces.rule_or(file, selector, "color", null)
	if c != null:
		t.colour = Color.html(str(c))
	var stroke: Variant = GlassPieces.rule_or(file, selector, "-webkit-text-stroke", null)
	if stroke is Dictionary:
		var s: Dictionary = stroke
		t.stroke_width = _f(s["width"])
		t.stroke_colour = Color.html(str(s["colour"]))
	return t


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _b(v: Variant) -> bool:
	return GlassPieces.as_bool(v)
