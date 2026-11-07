extends "res://src/ui/widgets/wood_panel.gd"
## The purple "this hit" panel (.wk-hit): who hits whom, then each step of the sum as numbered
## rosehips: 26 -> half for Nightshade -> 13 -> -1 -> 12, and what came back. Knows no rules: the
## screen feeds it what the events say.

const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")

const HEAD_H: float = 56.0
const NAMES_H: float = 66.0
const STEPS_TOP: float = 128.0
const STEPS_H: float = 168.0
const MAX_STEPS: int = 5
const BEAD: float = 78.0

## Step kinds as shown, for tests: "before", "half", "health", "hit", "after", "dies".
var steps: Array[Dictionary] = []

var _head: Label
var _count: Label
var _attacker: Label
var _target: Label
var _back: Label
var _step_nodes: Array[Control] = []


func _init() -> void:
	super(Kind.PURPLE)
	_head = UiTheme.burned("This hit", UiTheme.FONT_SMALL, UiTheme.CREAM)
	add_child(_head)
	_count = UiTheme.burned("", UiTheme.FONT_SMALL, UiTheme.CREAM)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_count)
	_attacker = _name_chip(UiTheme.ACORN, UiTheme.INK)
	_target = _name_chip(UiTheme.HEALTH, UiTheme.CREAM)
	_back = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.CREAM)
	_back.add_theme_font_override("font", UiTheme.bold_font())
	_back.clip_text = true
	_back.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_back.set_meta("ellipsis_ok", true)
	add_child(_back)
	resized.connect(_layout)
	ready.connect(_layout)
	clear()


## The two names share their row by length, so a long one beside a short one is read in full.
func _attacker_share() -> float:
	var ours: float = _chip_words(_attacker)
	var theirs: float = _chip_words(_target)
	return clampf(ours / maxf(ours + theirs, 1.0), 0.3, 0.7)


func _chip_words(chip: Label) -> float:
	var font: Font = chip.get_theme_font("font")
	var font_size: int = chip.get_theme_font_size("font_size")
	return font.get_string_size(chip.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 40.0


func _name_chip(fill: Color, ink: Color) -> Label:
	var chip: Label = UiTheme.head("", UiTheme.FONT_SMALL, ink)
	var face: StyleBoxFlat = UiTheme.slip_box(fill, 5, 10)
	chip.add_theme_stylebox_override("normal", face)
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.clip_text = true
	chip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	chip.set_meta("ellipsis_ok", true)
	add_child(chip)
	return chip


## Nothing has hit yet (Start of Combat, or between fights).
func clear() -> void:
	steps.clear()
	_attacker.text = ""
	_target.text = ""
	_attacker.visible = false
	_target.visible = false
	_count.text = ""
	_back.text = ""
	_rebuild()


func begin(attacker: String, target: String, target_health: int, attack_number: int) -> void:
	clear()
	_attacker.text = attacker
	_target.text = target
	_attacker.visible = true
	_target.visible = true
	_count.text = "ATTACK %d" % attack_number
	steps.append({"kind": "before", "value": target_health, "caption": "before"})
	_rebuild()
	queue_redraw()


## Nightshade: Health loss before the hit lands.
func add_half(after: int) -> void:
	steps.append({"kind": "half", "value": 0, "caption": ""})
	steps.append({"kind": "health", "value": after, "caption": "halved"})
	_rebuild()


## The hit lands on the target.
func add_hit(amount: int, after: int) -> void:
	steps.append({"kind": "hit", "value": amount, "caption": "hit"})
	steps.append({"kind": "after", "value": after, "caption": "after"})
	while steps.size() > MAX_STEPS:
		steps.pop_front()
	_rebuild()


func add_death() -> void:
	if not steps.is_empty():
		steps.pop_back()
	steps.append({"kind": "dies", "value": 0, "caption": "dies"})
	_rebuild()


## What came back at the attacker: "Takes 2 back: 3 left".
func set_back(words: String) -> void:
	_back.text = words


func _layout() -> void:
	var w: float = size.x
	_head.position = Vector2(32, 10)
	_head.size = Vector2(220, 44)
	_count.position = Vector2(w - 252.0, 10)
	_count.size = Vector2(220, 44)
	var arrow: float = 52.0
	var room: float = w - 60.0 - arrow
	var chip_w: float = room * _attacker_share()
	_attacker.position = Vector2(30, HEAD_H)
	_attacker.size = Vector2(chip_w, NAMES_H - 8.0)
	_target.position = Vector2(30 + chip_w + arrow, HEAD_H)
	_target.size = Vector2(room - chip_w, NAMES_H - 8.0)
	_back.position = Vector2(32, STEPS_TOP + STEPS_H + 2.0)
	_back.size = Vector2(w - 64.0, 44)
	_place_steps()
	queue_redraw()


func _rebuild() -> void:
	for node: Control in _step_nodes:
		remove_child(node)
		node.queue_free()
	_step_nodes.clear()
	var number: int = 0
	for step: Dictionary in steps:
		var step_kind: String = step["kind"]
		var numbered: bool = step_kind in ["before", "health", "after"]
		if numbered:
			number += 1
		_step_nodes.append(_make_step(step, number if numbered else 0))
	_place_steps()
	queue_redraw()


func _make_step(step: Dictionary, number: int) -> Control:
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = Vector2(BEAD, STEPS_H)
	add_child(holder)
	var step_kind: String = step["kind"]
	var value: int = step["value"]
	var at: Vector2 = Vector2(0, 32)
	match step_kind:
		"half":
			_add_icon(holder, "berry_big", at, BEAD)
			_add_number(holder, "½", at, UiTheme.CREAM, 36)
		"hit":
			_add_icon(holder, "burst", at - Vector2(10, 10), BEAD + 20.0)
			_add_number(holder, "−%d" % value, at, UiTheme.CREAM, 36)
		"dies":
			_add_icon(holder, "bones", at, BEAD)
		_:
			var badge: ShapeBadge = ShapeBadge.new(
				"rosehip" if step_kind == "after" else "rosehip_hurt"
			)
			badge.position = at
			badge.size = Vector2(BEAD, BEAD)
			holder.add_child(badge)
			_add_number(holder, str(maxi(value, 0)), at + Vector2(0, 4), UiTheme.CREAM, 36)
	if number > 0:
		var disc: Label = UiTheme.number(str(number), UiTheme.FONT_SMALL)
		var face: StyleBoxFlat = UiTheme.flat_box(UiTheme.BIRCH, UiTheme.INK, 3, 22)
		face.set_content_margin_all(0)
		disc.add_theme_stylebox_override("normal", face)
		disc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		disc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		disc.position = Vector2(-10, -8)
		disc.size = Vector2(42, 42)
		holder.add_child(disc)
	var caption: Label = UiTheme.label(str(step["caption"]), UiTheme.FONT_SMALL, UiTheme.CREAM)
	caption.add_theme_font_override("font", UiTheme.bold_font())
	if step_kind == "after":
		caption.add_theme_color_override("font_color", UiTheme.ACORN)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(-16, at.y + BEAD + 2.0)
	caption.size = Vector2(BEAD + 32.0, 42)
	holder.add_child(caption)
	return holder


func _add_icon(holder: Control, icon_name: String, at: Vector2, side: float) -> void:
	var icon: TextureRect = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = Icons.icon(icon_name, side)
	icon.position = at
	icon.size = Vector2(side, side)
	holder.add_child(icon)


func _add_number(
	holder: Control, words: String, at: Vector2, colour: Color, font_size: int
) -> void:
	var number: Label = UiTheme.number(words, font_size, colour)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.position = at
	number.size = Vector2(BEAD, BEAD)
	holder.add_child(number)


func _place_steps() -> void:
	var count: int = _step_nodes.size()
	if count == 0:
		return
	var inner: float = size.x - 64.0
	var cell: float = inner / maxf(count, MAX_STEPS)
	var start: float = 32.0 + (inner - cell * count) / 2.0
	for i: int in count:
		var x: float = start + cell * i + (cell - BEAD) / 2.0
		_step_nodes[i].position = Vector2(x, STEPS_TOP + 4.0)


func _draw() -> void:
	super()
	var tray: Rect2 = Rect2(24, STEPS_TOP - 6.0, size.x - 48.0, STEPS_H + 6.0)
	var box: StyleBoxFlat = UiTheme.flat_box(UiTheme.NIGHTSHADE_DARK, Color.TRANSPARENT, 0, 18)
	box.bg_color = Color(UiTheme.NIGHTSHADE_DARK, 0.75)
	draw_style_box(box, tray)
	if _step_nodes.size() > 1:
		var line_y: float = STEPS_TOP + 4.0 + 32.0 + BEAD / 2.0
		var first: float = _step_nodes[0].position.x + BEAD / 2.0
		var last: float = _step_nodes[-1].position.x + BEAD / 2.0
		draw_dashed_line(Vector2(first, line_y), Vector2(last, line_y), UiTheme.BIRCH, 6.0, 12.0)
	if not _attacker.visible:
		return
	var y: float = HEAD_H + (NAMES_H - 8.0) / 2.0
	var from_x: float = _attacker.position.x + _attacker.size.x
	var to_x: float = _target.position.x
	draw_line(Vector2(from_x, y), Vector2(to_x - 8.0, y), UiTheme.INK, 12.0)
	draw_dashed_line(Vector2(from_x, y), Vector2(to_x - 12.0, y), UiTheme.YARN, 6.0, 9.0)
	var tip: PackedVector2Array = [
		Vector2(to_x, y), Vector2(to_x - 16.0, y - 12.0), Vector2(to_x - 16.0, y + 12.0)
	]
	draw_colored_polygon(tip, UiTheme.YARN)
