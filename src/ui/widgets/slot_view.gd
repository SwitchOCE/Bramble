extends "res://src/ui/widgets/interactive.gd"
## One fixed board slot (F1-F4, B1-B3), a carved pocket in the tray (.wc-pocket). Always shown, so
## the 4-3 brick and its gaps read at a glance. Empty, it says its name and where it sits ("behind
## F3 & F4"), and it lights up as a drop or tap target.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const SLOT_NAMES: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]

## Highlight colour (valid target); transparent for none.
var highlight: Color = Color.TRANSPARENT:
	set(value):
		highlight = value
		_refresh_labels()
		queue_redraw()
## Show the "behind F3 & F4" note when empty.
var with_note: bool = false:
	set(value):
		with_note = value
		_refresh_labels()
## A unit stands in this pocket: draw a solid line and no words.
var filled: bool = false:
	set(value):
		filled = value
		_refresh_labels()
		queue_redraw()

var _name_label: Label
var _empty_label: Label
var _note: Label
var _note_box: Panel


func _init() -> void:
	super()
	_name_label = UiTheme.number("", 47, Color(UiTheme.CREAM, 0.92))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name_label)
	_empty_label = UiTheme.burned("Empty", UiTheme.FONT_SMALL, Color(UiTheme.CREAM, 0.92))
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_empty_label)
	_note_box = Panel.new()
	_note_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note_box.add_theme_stylebox_override("panel", UiTheme.thin_box(UiTheme.BIRCH, 8))
	add_child(_note_box)
	_note = UiTheme.head("", UiTheme.FONT_SMALL)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note_box.add_child(_note)
	resized.connect(_refresh_labels)
	ready.connect(_refresh_labels)


func set_slot(slot_zone: String, slot: int) -> void:
	zone = slot_zone
	index = slot
	_name_label.text = SLOT_NAMES[slot] if slot >= 0 and slot < SLOT_NAMES.size() else ""
	_refresh_labels()


## Where an empty slot sits (8.2.1): "in front of B1 & B2", "behind F3 & F4".
static func note(slot: int) -> String:
	if slot >= 4:
		return "behind F%d & F%d" % [slot - 3, slot - 2]
	var behind: PackedStringArray = []
	for back: int in [slot - 1, slot]:
		if back >= 0 and back < 3:
			behind.append("B%d" % (back + 1))
	return ("ahead of " if behind.size() > 1 else "in front of ") + " & ".join(behind)


func _refresh_labels() -> void:
	if _name_label == null:
		return
	var empty: bool = not filled
	_name_label.visible = empty
	_empty_label.visible = empty and not with_note
	_note_box.visible = empty and with_note
	var name_h: float = 56.0
	var note_h: float = 44.0
	if with_note and empty:
		_note.text = note(index)
		var note_w: float = size.x - 12.0
		_note_box.size = Vector2(note_w, note_h)
		_note_box.position = Vector2(6, size.y - note_h - 14.0)
		_note.position = Vector2.ZERO
		_note.size = _note_box.size
		_name_label.position = Vector2(0, (_note_box.position.y - name_h) / 2.0)
	else:
		_name_label.position = Vector2(0, size.y / 2.0 - name_h + 6.0)
		_empty_label.position = Vector2(0, size.y / 2.0 + 4.0)
		_empty_label.size = Vector2(size.x, 40)
	_name_label.size = Vector2(size.x, name_h)


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var fill: Color = UiTheme.CARVE
	if highlight.a > 0.0:
		fill = highlight
	draw_style_box(UiTheme.flat_box(fill, Color.TRANSPARENT, 0, 24), rect)
	# The pocket's shadowed top edge.
	var shade: StyleBoxFlat = UiTheme.flat_box(Color(UiTheme.INK, 0.45), Color.TRANSPARENT, 0, 24)
	shade.corner_radius_bottom_left = 0
	shade.corner_radius_bottom_right = 0
	draw_style_box(shade, Rect2(0, 0, size.x, 14))
	if filled:
		draw_style_box(UiTheme.flat_box(Color.TRANSPARENT, UiTheme.INK, 5, 24), rect)
		return
	var line: Color = UiTheme.ACORN if highlight.a > 0.0 else UiTheme.INK
	_dashed_round_rect(rect.grow(-2.5), 24.0, line)


func _dashed_round_rect(rect: Rect2, corner: float, colour: Color) -> void:
	var left: float = rect.position.x
	var top: float = rect.position.y
	var right: float = rect.end.x
	var bottom: float = rect.end.y
	var dash: float = 10.0
	draw_dashed_line(Vector2(left + corner, top), Vector2(right - corner, top), colour, 5.0, dash)
	draw_dashed_line(
		Vector2(left + corner, bottom), Vector2(right - corner, bottom), colour, 5.0, dash
	)
	draw_dashed_line(Vector2(left, top + corner), Vector2(left, bottom - corner), colour, 5.0, dash)
	draw_dashed_line(
		Vector2(right, top + corner), Vector2(right, bottom - corner), colour, 5.0, dash
	)
	draw_arc(Vector2(left + corner, top + corner), corner, PI, PI * 1.5, 8, colour, 5.0, true)
	draw_arc(Vector2(right - corner, top + corner), corner, PI * 1.5, TAU, 8, colour, 5.0, true)
	draw_arc(Vector2(right - corner, bottom - corner), corner, 0.0, PI * 0.5, 8, colour, 5.0, true)
	draw_arc(Vector2(left + corner, bottom - corner), corner, PI * 0.5, PI, 8, colour, 5.0, true)
