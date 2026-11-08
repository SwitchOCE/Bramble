extends Control
## One player's plaque in the lobby strip: tier knot, name, rosehip health. Moss for you, walnut
## with a red rim and a NEXT tag for the next opponent, dashed and struck through once they're out.
## A ghost is the plaque of the player whose board it is: dashed like the out, rim and NEXT tag like
## the next opponent, and no health, because it has none.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Data := preload("res://src/ui/view_data.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")

## On the next opponent's plaque: opens the scouting panel. Taller than the plaque, to hit easily.
var tap: Interactive
var is_me: bool = false
var is_next: bool = false
var is_out: bool = false
var is_ghost: bool = false
var _prefix: String = ""
var _font_size: int = UiTheme.FONT_SMALL
var _words: PackedStringArray = []
var _name: Label
var _knot: Control
var _hip: Control
var _last_stand: Label
var _next_tag: Label


func _init(standing: Dictionary, next_up: bool, ghost: bool = false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_me = Data.b(standing, "is_human", false)
	is_next = next_up
	is_ghost = ghost
	is_out = not Data.b(standing, "alive", true)
	var ink: Color = UiTheme.INK
	if is_me or (is_next and not is_ghost):
		ink = UiTheme.CREAM
	elif is_out and not is_ghost:
		ink = UiTheme.MUTE
	_knot = ShapeBadge.new("knot_out" if is_out else "knot")
	add_child(_knot)
	var tier: Label = UiTheme.number(str(Data.i(standing, "tier", 1)), UiTheme.FONT_SMALL)
	tier.name = "TierKnot"
	tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier.set_anchors_preset(Control.PRESET_FULL_RECT)
	_knot.add_child(tier)
	_prefix = "Ghost of " if is_ghost else ""
	_words = UiTheme.player_name(standing).split(" ", false)
	_name = UiTheme.head(_prefix + " ".join(_words), UiTheme.FONT_SMALL, ink)
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
	_hip.visible = not is_ghost
	if Data.b(standing, "last_stand_enabled") and not is_out and not is_ghost:
		var status: String = "used" if Data.b(standing, "last_stand_used") else "locked"
		if status != "used" and Data.b(standing, "last_stand_active"):
			status = "ready"
		_last_stand = UiTheme.label("Last Stand: " + status, UiTheme.FONT_SMALL, ink)
		_last_stand.add_theme_font_override("font", UiTheme.body_font())
		_last_stand.name = "LastStand"
		_last_stand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_last_stand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_last_stand)
	if is_next:
		if _last_stand != null:
			_prefix = "Next: "
			_name.text = _prefix + " ".join(_words)
		_next_tag = UiTheme.burned("Next", UiTheme.FONT_SMALL, UiTheme.CREAM)
		var face: StyleBoxFlat = UiTheme.slip_box(UiTheme.HEALTH, 3, 9)
		face.content_margin_top = 0
		face.content_margin_bottom = 0
		_next_tag.add_theme_stylebox_override("normal", face)
		_next_tag.visible = _last_stand == null
		_next_tag.z_index = 2
		add_child(_next_tag)
		tap = Interactive.new()
		add_child(tap)
	resized.connect(_layout)
	ready.connect(_layout)


## A desktop's canvas is narrower than a phone's, and a smaller name still reads there.
func use_desktop_size(font_size: int) -> void:
	_font_size = font_size
	_name.add_theme_font_size_override("font_size", font_size)
	_name.set_meta("desktop_text", true)
	if _last_stand != null:
		_last_stand.add_theme_font_size_override("font_size", font_size)
		_last_stand.set_meta("desktop_text", true)


## Drops the name's first word, when the lobby can't fit them all: "Old Mother Mousewife" reads as
## "Mousewife", and that beats cutting it off. False when one word is left.
func shorten() -> bool:
	if _words.size() < 2:
		return false
	_words = _words.slice(1)
	_name.text = _prefix + " ".join(_words)
	return true


func wanted_width() -> float:
	var font: Font = _name.get_theme_font("font")
	var words: float = font.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
	var width: float = 5.0 + 46.0 + 8.0 + words + 8.0 + 46.0
	if _last_stand != null:
		width = maxf(width, _last_stand.get_minimum_size().x + 16.0)
	return width


func _layout() -> void:
	_knot.position = Vector2(5, (size.y - 46.0) / 2.0)
	_knot.size = Vector2(46, 46)
	_hip.size = Vector2(62, 62)
	_hip.position = Vector2(size.x - 62.0 + 15.0, (size.y - 62.0) / 2.0 - 3.0)
	_name.position = Vector2(59, 0)
	_name.size = Vector2(maxf(size.x - 59.0 - 46.0 - 8.0, 10.0), size.y)
	if _last_stand != null:
		_knot.position.y = -5.0
		_hip.position.y = -17.0
		_name.position.y = -5.0
		_name.size.y = 46.0
		_last_stand.position = Vector2(8, 38)
		_last_stand.size = Vector2(size.x - 16.0, 36)
	if tap != null:
		tap.position = Vector2(0, -17)
		tap.size = Vector2(size.x, size.y + 66.0)
	if _next_tag != null:
		_next_tag.size = _next_tag.get_minimum_size()
		_next_tag.position = Vector2((size.x - _next_tag.size.x) / 2.0, -17.0)
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var radius: int = 38
	if is_ghost:
		var ring: StyleBoxFlat = UiTheme.flat_box(UiTheme.HEALTH, UiTheme.INK, 0, 44)
		draw_style_box(ring, rect.grow(7))
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
	if is_ghost:
		return
	var font: Font = _name.get_theme_font("font")
	var words: float = font.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
	var line_y: float = size.y / 2.0 + 1.0
	var x: float = _name.position.x
	draw_line(
		Vector2(x, line_y), Vector2(x + minf(words, _name.size.x), line_y), UiTheme.MUTE, 3.0, true
	)
