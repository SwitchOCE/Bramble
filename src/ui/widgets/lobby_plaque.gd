extends Control
## One player's plaque in the lobby strip: tier knot, name, rosehip health. Moss for you, walnut
## with a red rim and a NEXT tag for the next opponent, dashed and struck through once they're out.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Data := preload("res://src/ui/view_data.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")

var is_me: bool = false
var is_next: bool = false
var is_out: bool = false
var _name: Label
var _knot: Control
var _hip: Control
var _next_tag: Label


func _init(standing: Dictionary, next_up: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_me = Data.b(standing, "is_human", false)
	is_next = next_up
	is_out = not Data.b(standing, "alive", true)
	var ink: Color = UiTheme.INK
	if is_me or is_next:
		ink = UiTheme.CREAM
	elif is_out:
		ink = UiTheme.MUTE
	_knot = ShapeBadge.new("knot_out" if is_out else "knot")
	add_child(_knot)
	var tier: Label = UiTheme.number(str(Data.i(standing, "tier", 1)), UiTheme.FONT_SMALL)
	tier.name = "TierKnot"
	tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier.set_anchors_preset(Control.PRESET_FULL_RECT)
	_knot.add_child(tier)
	var display: String = UiTheme.short_name(Data.s(standing, "name", "?"))
	_name = UiTheme.head(display, UiTheme.FONT_SMALL, ink)
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.set_meta("ellipsis_ok", true)
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_name)
	_hip = ShapeBadge.new("rosehip_out" if is_out else "rosehip")
	add_child(_hip)
	var health: Label = UiTheme.number(
		str(maxi(Data.i(standing, "health", 0), 0)), UiTheme.FONT_SMALL, UiTheme.CREAM
	)
	health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health.set_anchors_preset(Control.PRESET_FULL_RECT)
	health.offset_top = 5.0
	_hip.add_child(health)
	if is_next:
		_next_tag = UiTheme.burned("Next", UiTheme.FONT_SMALL, UiTheme.CREAM)
		var face: StyleBoxFlat = UiTheme.slip_box(UiTheme.HEALTH, 3, 9)
		face.content_margin_top = 0
		face.content_margin_bottom = 0
		_next_tag.add_theme_stylebox_override("normal", face)
		_next_tag.z_index = 2
		add_child(_next_tag)
	resized.connect(_layout)
	ready.connect(_layout)


func wanted_width() -> float:
	var font: Font = _name.get_theme_font("font")
	var words: float = (
		font.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FONT_SMALL).x
	)
	return 5.0 + 46.0 + 8.0 + words + 8.0 + 46.0


func _layout() -> void:
	_knot.position = Vector2(5, (size.y - 46.0) / 2.0)
	_knot.size = Vector2(46, 46)
	_hip.size = Vector2(62, 62)
	_hip.position = Vector2(size.x - 62.0 + 15.0, (size.y - 62.0) / 2.0 - 3.0)
	_name.position = Vector2(59, 0)
	_name.size = Vector2(maxf(size.x - 59.0 - 46.0 - 8.0, 10.0), size.y)
	if _next_tag != null:
		_next_tag.size = _next_tag.get_minimum_size()
		_next_tag.position = Vector2((size.x - _next_tag.size.x) / 2.0, -17.0)
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var radius: int = 38
	if is_out:
		_draw_out(rect, radius)
		return
	if is_next:
		var rim: StyleBoxFlat = UiTheme.flat_box(UiTheme.HEALTH, UiTheme.INK, 0, 44)
		draw_style_box(rim, rect.grow(7))
	var under: StyleBoxFlat = UiTheme.flat_box(UiTheme.CARVE, UiTheme.INK, 5, radius)
	draw_style_box(under, Rect2(Vector2(0, 7), size))
	var fill: Color = UiTheme.BIRCH
	if is_me:
		fill = UiTheme.MOSS
	elif is_next:
		fill = UiTheme.WALNUT
	draw_style_box(UiTheme.flat_box(fill, UiTheme.INK, 5, radius), rect)


func _draw_out(rect: Rect2, radius: int) -> void:
	draw_style_box(UiTheme.flat_box(UiTheme.OUT_FACE, Color.TRANSPARENT, 0, radius), rect)
	var inset: Rect2 = rect.grow(-2.5)
	var r: float = minf(float(radius), inset.size.y / 2.0)
	var ink: Color = UiTheme.INK
	var left: float = inset.position.x + r
	var right: float = inset.end.x - r
	draw_dashed_line(
		Vector2(left, inset.position.y), Vector2(right, inset.position.y), ink, 5.0, 11.0
	)
	draw_dashed_line(Vector2(left, inset.end.y), Vector2(right, inset.end.y), ink, 5.0, 11.0)
	var mid: float = inset.get_center().y
	draw_arc(Vector2(left, mid), r, PI * 0.5, PI * 1.5, 10, ink, 5.0, true)
	draw_arc(Vector2(right, mid), r, -PI * 0.5, PI * 0.5, 10, ink, 5.0, true)
	var font: Font = _name.get_theme_font("font")
	var words: float = (
		font.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FONT_SMALL).x
	)
	var line_y: float = size.y / 2.0 + 1.0
	var x: float = _name.position.x
	draw_line(
		Vector2(x, line_y), Vector2(x + minf(words, _name.size.x), line_y), UiTheme.MUTE, 3.0, true
	)
