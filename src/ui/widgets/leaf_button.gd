extends Button
## A leaf-shaped button (.wc-leaf). The leaf is drawn to the button's size with an even ink line,
## as the mock's SVG does; an icon, a label and an optional acorn cost sit on it. The Button's own
## text stays set (for tests and accessibility) but is invisible; the face shows it.

enum Colour { BIRCH, MOSS, FROST, ACORN }

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

## The leaf from the mock's 300 x 100 box: two cubic curves.
const P0: Vector2 = Vector2(10, 50)
const P1: Vector2 = Vector2(70, 4)
const P2: Vector2 = Vector2(200, 0)
const P3: Vector2 = Vector2(292, 46)
const P4: Vector2 = Vector2(200, 96)
const P5: Vector2 = Vector2(70, 96)
const SEGMENTS: int = 20
const LINE: float = 6.5
const SHADOW_DROP: float = 13.0

var colour: Colour = Colour.BIRCH:
	set(value):
		colour = value
		_apply_colours()
		queue_redraw()
## Tip on the left, stem on the right (the Back button).
var flipped: bool = false

var _was_disabled: bool = false
var _face: HBoxContainer
var _icon: TextureRect
var _label: Label
var _sub: Label
var _cost_pill: PanelContainer
var _cost_label: Label


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	pressed.connect(Sfx.tap)
	set_meta("drawn_face", true)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_theme_font_size_override("font_size", 1)
	var clear: Color = Color.TRANSPARENT
	for state: String in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_focus_color",
		"font_disabled_color",
		"font_hover_pressed_color"
	]:
		add_theme_color_override(state, clear)
	_face = HBoxContainer.new()
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.alignment = BoxContainer.ALIGNMENT_CENTER
	_face.add_theme_constant_override("separation", 14)
	add_child(_face)
	_icon = TextureRect.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.custom_minimum_size = Vector2(50, 50)
	_icon.visible = false
	_face.add_child(_icon)
	var words: VBoxContainer = VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", -6)
	_face.add_child(words)
	_label = UiTheme.head("", UiTheme.FONT_LEAF)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_child(_label)
	_sub = UiTheme.label("", UiTheme.FONT_SMALL)
	_sub.add_theme_font_override("font", UiTheme.bold_font())
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.visible = false
	words.add_child(_sub)
	_cost_pill = PanelContainer.new()
	_cost_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cost_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pill: StyleBoxFlat = UiTheme.flat_box(UiTheme.INK, Color.TRANSPARENT, 0, 40)
	pill.content_margin_left = 8
	pill.content_margin_right = 16
	pill.content_margin_top = 4
	pill.content_margin_bottom = 4
	_cost_pill.add_theme_stylebox_override("panel", pill)
	var pill_row: HBoxContainer = HBoxContainer.new()
	pill_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_row.add_theme_constant_override("separation", 2)
	_cost_pill.add_child(pill_row)
	var acorn: TextureRect = TextureRect.new()
	acorn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	acorn.texture = Icons.icon("acorn", 40.0)
	acorn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	acorn.custom_minimum_size = Vector2(40, 40)
	acorn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill_row.add_child(acorn)
	_cost_label = UiTheme.number("", 34, UiTheme.ACORN)
	pill_row.add_child(_cost_label)
	_cost_pill.visible = false
	_face.add_child(_cost_pill)
	resized.connect(_place_face)
	ready.connect(_place_face)
	_apply_colours()


## Sets what the leaf says. `cost` below 0 hides the acorn pill.
func set_face(words: String, icon_name: String = "", cost: int = -1, note: String = "") -> void:
	text = words
	_label.text = words
	_icon.visible = not icon_name.is_empty()
	if _icon.visible:
		_icon.texture = Icons.icon(icon_name, 50.0)
	_sub.text = note
	_sub.visible = not note.is_empty()
	_cost_pill.visible = cost >= 0
	_cost_label.text = str(cost)
	_place_face()


## The size of the big label (End turn is larger).
func set_label_size(font_size: int) -> void:
	_label.add_theme_font_size_override("font_size", font_size)


func _place_face() -> void:
	var left: float = size.x * (0.17 if flipped else 0.11)
	var right: float = size.x * (0.1 if flipped else 0.16)
	# The pointed leaf narrows below its centre: keep a second line clear of its lower rim.
	_face.position = Vector2(left, -size.y * 0.05 if _sub.visible else 0.0)
	_face.size = Vector2(size.x - left - right, size.y)


func _apply_colours() -> void:
	var ink: Color = UiTheme.CREAM if colour == Colour.MOSS else UiTheme.INK
	if disabled:
		ink = UiTheme.MUTE
	_label.add_theme_color_override("font_color", ink)
	_sub.add_theme_color_override("font_color", ink)


func _fill() -> Color:
	var base: Color = UiTheme.BIRCH
	match colour:
		Colour.MOSS:
			base = UiTheme.MOSS
		Colour.FROST:
			base = UiTheme.FROST
		Colour.ACORN:
			base = UiTheme.ACORN
	if disabled:
		return base.lerp(UiTheme.LIME, 0.65)
	if button_pressed or is_hovered():
		return base.lightened(0.1)
	return base


## The leaf's outline at this button's size, from the mock's curves.
func _outline() -> PackedVector2Array:
	var scale_by: Vector2 = Vector2(size.x / 300.0, size.y / 100.0)
	var points: PackedVector2Array = []
	for i: int in SEGMENTS:
		points.append(_cubic(P0, P1, P2, P3, float(i) / SEGMENTS) * scale_by)
	for i: int in SEGMENTS:
		points.append(_cubic(P3, P4, P5, P0, float(i) / SEGMENTS) * scale_by)
	if flipped:
		for i: int in points.size():
			points[i].x = size.x - points[i].x
	return points


static func _cubic(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	var ab: Vector2 = a.lerp(b, t)
	var bc: Vector2 = b.lerp(c, t)
	var cd: Vector2 = c.lerp(d, t)
	return ab.lerp(bc, t).lerp(bc.lerp(cd, t), t)


func _draw() -> void:
	if _was_disabled != disabled:
		_was_disabled = disabled
		_apply_colours()
	var points: PackedVector2Array = _outline()
	var pressed_down: bool = is_pressed() or get_draw_mode() == DRAW_PRESSED
	var drop: float = 0.0 if pressed_down else SHADOW_DROP
	if drop > 0.0 and not disabled:
		var shadow: PackedVector2Array = []
		for point: Vector2 in points:
			shadow.append(point + Vector2(0, drop))
		draw_colored_polygon(shadow, Color(0.08, 0.05, 0.02, 0.45))
	var offset: Vector2 = Vector2.ZERO
	draw_set_transform(offset)
	draw_colored_polygon(points, _fill())
	var closed: PackedVector2Array = points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, UiTheme.INK, LINE, true)
	var stem_from: Vector2 = Vector2(2.0 / 300.0 * size.x, 0.52 * size.y)
	var stem_to: Vector2 = Vector2(40.0 / 300.0 * size.x, 0.5 * size.y)
	if flipped:
		stem_from.x = size.x - stem_from.x
		stem_to.x = size.x - stem_to.x
	draw_line(stem_from, stem_to, UiTheme.INK, LINE, true)
