extends "res://src/ui/widgets/interactive.gd"
## One unit card. Renders a recruit unit view (SPEC 6.2) or a combat unit view (6.3): name, tier,
## Attack, Health, type line, rules text, golden state, statuses, counters and shop cost.
## Laid out by hand at any size: every position and font scales with the card's width, so the same
## card works on the board, in the hand, in combat and as the large detail card.

## FULL shows rules text; COMPACT (hand, library) shows name, type line and stats only;
## DETAIL is the tall reading card (inspector) with room for the whole rules text.
enum Mode { FULL, COMPACT, DETAIL }

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

const BASE_WIDTH: float = 168.0
const FULL_RATIO: float = 232.0 / 168.0
const COMPACT_RATIO: float = 176.0 / 168.0
const DETAIL_RATIO: float = 262.0 / 168.0

## def_id -> true for units whose mechanics aren't built yet (GamePort.unbuilt_units); the app
## sets it once. Their cards carry a "Not built" badge: the rules text does nothing yet.
static var unbuilt: Dictionary = {}

var unit: Dictionary = {}
## The size this card is laid out for (set_card_width).
var card_size: Vector2 = Vector2(BASE_WIDTH, BASE_WIDTH * FULL_RATIO)
var mode: Mode = Mode.FULL
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
## A coloured outline drawn round the card (drop target, attacker); transparent for none.
var outline: Color = Color.TRANSPARENT:
	set(value):
		outline = value
		queue_redraw()

var _frame: Panel
var _portrait: TextureRect
var _portrait_fill: ColorRect
var _initials: Label
var _tier_badge: Panel
var _tier_label: Label
var _cost_badge: Panel
var _cost_label: Label
var _plate: Panel
var _name_label: Label
var _type_label: Label
var _text_label: Label
var _badges: HBoxContainer
var _attack_badge: Panel
var _attack_label: Label
var _health_badge: Panel
var _health_label: Label
var _scale: float = 1.0


static func size_for(width: float, card_mode: Mode = Mode.FULL) -> Vector2:
	var ratio: float = FULL_RATIO
	if card_mode == Mode.COMPACT:
		ratio = COMPACT_RATIO
	elif card_mode == Mode.DETAIL:
		ratio = DETAIL_RATIO
	return Vector2(width, roundf(width * ratio))


func _init() -> void:
	super()
	clip_contents = false
	_build()


## Sets the unit and redraws. Pass the view dictionary straight from the state or event log.
func show_unit(view: Dictionary, card_mode: Mode = mode) -> void:
	unit = view
	mode = card_mode
	_refresh()


func set_card_width(width: float) -> void:
	# size is clamped to the cached minimum size, which updates deferred: lay out from card_size,
	# not from size (see LEARNINGS, 4 Nov).
	card_size = size_for(width, mode)
	custom_minimum_size = card_size
	size = card_size
	_layout()


## Current Attack and Health shown on the card (combat playback updates these).
func set_stats(attack: int, health: int, max_health: int) -> void:
	unit["attack"] = attack
	unit["health"] = health
	unit["max_health"] = max_health
	_refresh_stats()


func set_statuses(statuses: Array) -> void:
	unit["statuses"] = statuses
	_refresh_badges()


func uid() -> int:
	return Data.i(unit, "uid", -1)


func _build() -> void:
	_frame = Panel.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_portrait_fill = ColorRect.new()
	_portrait_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait_fill)
	_initials = UiTheme.label("", 40, Color(1, 1, 1, 0.85))
	_initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_initials)
	_portrait = TextureRect.new()
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.clip_contents = true
	add_child(_portrait)
	_plate = Panel.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)
	_name_label = _ink_label(HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_name_label)
	_type_label = _ink_label(HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_type_label)
	_text_label = _ink_label(HORIZONTAL_ALIGNMENT_CENTER)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.clip_text = true
	_text_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_text_label)
	_badges = HBoxContainer.new()
	_badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badges.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_badges)
	_tier_badge = _round_badge(UiTheme.INK, UiTheme.GOLD)
	_tier_label = _badge_label(_tier_badge, UiTheme.GOLD)
	_cost_badge = _round_badge(UiTheme.GOLD, UiTheme.INK)
	_cost_label = _badge_label(_cost_badge, UiTheme.INK)
	_attack_badge = _round_badge(UiTheme.ATTACK, UiTheme.INK)
	_attack_label = _badge_label(_attack_badge, Color.WHITE)
	_health_badge = _round_badge(UiTheme.HEALTH, UiTheme.INK)
	_health_label = _badge_label(_health_badge, Color.WHITE)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	set_card_width(BASE_WIDTH)


func _ink_label(align: HorizontalAlignment) -> Label:
	var node: Label = UiTheme.label("", 16, UiTheme.INK)
	node.horizontal_alignment = align
	node.clip_text = true
	return node


func _round_badge(fill: Color, border: Color) -> Panel:
	var badge: Panel = Panel.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", UiTheme.flat_box(fill, border, 3, 999))
	add_child(badge)
	return badge


func _badge_label(badge: Panel, colour: Color) -> Label:
	var node: Label = UiTheme.label("", 24, colour)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.add_theme_color_override("font_outline_color", UiTheme.INK)
	badge.add_child(node)
	return node


func _r(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(x * _scale, y * _scale, w * _scale, h * _scale)


func _place(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size


func _fs(base: float) -> int:
	return maxi(10, roundi(base * _scale))


func _layout() -> void:
	_scale = card_size.x / BASE_WIDTH
	var full: bool = mode != Mode.COMPACT
	var height: float = card_size.y / _scale
	_place(_frame, _r(0, 0, BASE_WIDTH, height))
	var portrait_h: float = 88.0 if full else 80.0
	_place(_portrait_fill, _r(7, 7, 154, portrait_h))
	_place(_portrait, _r(7, 7, 154, portrait_h))
	_place(_initials, _r(7, 7, 154, portrait_h))
	_initials.add_theme_font_size_override("font_size", _fs(40))
	var plate_top: float = 7 + portrait_h
	_place(_plate, _r(7, plate_top, 154, height - plate_top - 7))
	_place(_name_label, _r(10, plate_top + 2, 148, 26))
	_place(_type_label, _r(10, plate_top + 27, 148, 18))
	_type_label.add_theme_font_size_override("font_size", _fs(13))
	_text_label.visible = full
	if full:
		_place(_text_label, _r(12, plate_top + 44, 144, height - plate_top - 44 - 34))
	_place(_badges, _r(4, plate_top - 26, 160, 24))
	_place(_tier_badge, _r(-8, -8, 40, 40))
	_tier_label.add_theme_font_size_override("font_size", _fs(22))
	_place(_cost_badge, _r(BASE_WIDTH - 34, -8, 42, 40))
	_cost_label.add_theme_font_size_override("font_size", _fs(20))
	var stat: float = 50.0
	_place(_attack_badge, _r(-10, height - stat + 8, stat, stat))
	_place(_health_badge, _r(BASE_WIDTH - stat + 10, height - stat + 8, stat, stat))
	for stat_label: Label in [_attack_label, _health_label]:
		stat_label.add_theme_font_size_override("font_size", _fs(28))
		stat_label.add_theme_constant_override("outline_size", maxi(3, roundi(5 * _scale)))
	_refresh()


func _refresh() -> void:
	if _frame == null:
		return
	var tribes: Array = Data.a(unit, "tribes")
	var colour: Color = UiTheme.tribe_colour(tribes)
	var golden: bool = Data.b(unit, "golden", false)
	var border: Color = UiTheme.GOLDEN_FRAME if golden else colour.darkened(0.45)
	var border_width: int = maxi(3, roundi((6.0 if golden else 3.0) * _scale))
	_frame.add_theme_stylebox_override(
		"panel", UiTheme.flat_box(colour, border, border_width, roundi(12 * _scale))
	)
	_plate.add_theme_stylebox_override(
		"panel", UiTheme.flat_box(UiTheme.PARCHMENT, Color.TRANSPARENT, 0, roundi(8 * _scale))
	)
	_portrait_fill.color = colour.darkened(0.25)
	var texture: Texture2D = UiTheme.portrait(tribes)
	_portrait.texture = texture
	_portrait.visible = texture != null
	var unit_name: String = str(unit.get("name", ""))
	_initials.text = _initials_of(unit_name)
	_initials.visible = texture == null
	_name_label.text = unit_name
	_fit_one_line(_name_label, unit_name, 148 * _scale, _fs(19))
	var type_text: String = UiTheme.type_line(tribes)
	if golden:
		type_text = "Golden · " + type_text
	_type_label.text = type_text
	_type_label.add_theme_color_override("font_color", colour.darkened(0.55))
	var rules: String = str(unit.get("text", ""))
	_text_label.text = rules
	if mode == Mode.FULL:
		_fit_lines(_text_label, rules, _fs(16), _fs(11))
	elif mode == Mode.DETAIL:
		_fit_lines(_text_label, rules, _fs(14), _fs(9))
	_tier_label.text = str(unit.get("tier", ""))
	_cost_badge.visible = unit.has("cost")
	_cost_label.text = "%dg" % Data.i(unit, "cost", 0)
	_refresh_stats()
	_refresh_badges()
	queue_redraw()


func _refresh_stats() -> void:
	var health: int = Data.i(unit, "health", 0)
	var max_health: int = unit.get("max_health", health)
	_attack_label.text = str(Data.i(unit, "attack", 0))
	_health_label.text = str(maxi(health, 0))
	var damaged: bool = health < max_health
	var fill: Color = UiTheme.HEALTH_DAMAGED if damaged else UiTheme.HEALTH
	_health_badge.add_theme_stylebox_override("panel", UiTheme.flat_box(fill, UiTheme.INK, 3, 999))


func _refresh_badges() -> void:
	for child: Node in _badges.get_children():
		_badges.remove_child(child)
		child.queue_free()
	var statuses: Array = Data.a(unit, "statuses")
	for entry: Variant in statuses:
		var status: Dictionary = entry
		var key: String = str(status.get("status", ""))
		_badges.add_child(_pill(UiTheme.status_label(key), UiTheme.status_colour(key)))
	if is_unbuilt(unit):
		_badges.add_child(_pill("Not built", Color("8a3b32")))
	var counters: Dictionary = Data.d(unit, "counters")
	for key: Variant in counters:
		_badges.add_child(_pill("%s %s" % [str(key).capitalize(), str(counters[key])], UiTheme.INK))


static func is_unbuilt(view: Dictionary) -> bool:
	return unbuilt.has(Data.s(view, "def_id"))


static func set_unbuilt(ids: PackedStringArray) -> void:
	unbuilt.clear()
	for id: String in ids:
		unbuilt[id] = true


func _pill(text: String, colour: Color) -> PanelContainer:
	var pill: PanelContainer = PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: StyleBoxFlat = UiTheme.flat_box(colour, Color.WHITE, maxi(1, roundi(2 * _scale)), 999)
	box.content_margin_left = 8 * _scale
	box.content_margin_right = 8 * _scale
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	pill.add_theme_stylebox_override("panel", box)
	var text_label: Label = UiTheme.label(text, _fs(14), Color.WHITE)
	pill.add_child(text_label)
	return pill


static func _initials_of(unit_name: String) -> String:
	var out: String = ""
	for word: String in unit_name.replace("-", " ").split(" ", false):
		out += word.left(1).to_upper()
	return out.left(2)


## Shrinks a one-line label's font until the text fits the width.
func _fit_one_line(node: Label, text: String, width: float, start: int) -> void:
	var font: Font = node.get_theme_font("font")
	var font_size: int = start
	while (
		font_size > 10
		and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width
	):
		font_size -= 1
	node.add_theme_font_size_override("font_size", font_size)


## Shrinks a wrapping label's font until the text fits its box, down to a floor (then ellipsis).
func _fit_lines(node: Label, text: String, start: int, floor_size: int) -> void:
	var font: Font = node.get_theme_font("font")
	var font_size: int = start
	var box: Vector2 = node.size
	if text.is_empty():
		return
	while font_size > floor_size:
		var needed: Vector2 = font.get_multiline_string_size(
			text, HORIZONTAL_ALIGNMENT_CENTER, box.x, font_size
		)
		# Label adds line spacing that the font measure leaves out; keep a margin.
		if needed.y * 1.2 <= box.y:
			break
		font_size -= 1
	node.add_theme_font_size_override("font_size", font_size)


func _draw() -> void:
	var grow: float = 5.0 * _scale
	var rect: Rect2 = Rect2(Vector2.ZERO, card_size).grow(grow)
	if outline.a > 0.0:
		draw_rect(rect, outline, false, 5.0 * _scale)
	if selected:
		draw_rect(rect.grow(grow * 0.6), UiTheme.SELECT, false, 6.0 * _scale)
