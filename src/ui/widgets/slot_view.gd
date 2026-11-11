extends "res://src/ui/widgets/interactive.gd"
## One fixed board pocket in the 4-3 brick. It remains carved and wordless when empty, and
## breathes as an action target or flashes once when the reader reveals a spatial reach.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const QuarryPreview := preload("res://src/ui/widgets/quarry_preview.gd")
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
## A combat pocket is a carved shape, including when empty or marked.
var wordless: bool = true:
	set(value):
		wordless = value
		_refresh_labels()
## A unit stands in this pocket: draw a solid line and no words.
var filled: bool = false:
	set(value):
		filled = value
		_refresh_labels()
		queue_redraw()

## Independent of legal targets, a demand-only reach flash fades completely.
var reach_flash: float = 0.0:
	set(value):
		reach_flash = value
		if _reach_face != null:
			_reach_face.visible = value > 0.001
			_reach_face.modulate.a = value
		if _quarry_stamp != null:
			_quarry_stamp.visible = quarry_preview and value > 0.001
			_quarry_stamp.modulate.a = value
		if _reach_face != null:
			_reach_face.queue_redraw()
		queue_redraw()

var quiet: bool = false:
	set(value):
		quiet = value
		queue_redraw()

var quarry_preview: bool = false
var _target_age: float = 0.0

var _name_label: Label
var _empty_label: Label
var _note: Label
var _note_box: Panel
var _reach_face: Control
var _quarry_stamp: Control


func _init() -> void:
	super()
	hex_hit_test = true
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
	# Occupied cards are later board siblings; the demand-only cue must paint above them.
	_reach_face = Control.new()
	_reach_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reach_face.z_index = 20
	_reach_face.draw.connect(_draw_reach)
	add_child(_reach_face)
	_reach_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reach_face.hide()
	_quarry_stamp = QuarryPreview.new()
	_quarry_stamp.z_index = 21
	add_child(_quarry_stamp)
	_quarry_stamp.hide()


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
	return ("before " if behind.size() > 1 else "in front of ") + " & ".join(behind)


func _refresh_labels() -> void:
	if _name_label == null:
		return
	if _quarry_stamp != null:
		_quarry_stamp.position = (size - _quarry_stamp.size) / 2.0
	var empty: bool = not filled and not wordless
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


func _process(delta: float) -> void:
	if highlight.a <= 0.0:
		_target_age = 0.0
		return
	_target_age += delta
	queue_redraw()


func _draw() -> void:
	_draw_target()


func _draw_reach() -> void:
	var rect: Rect2 = face_rect()
	_reach_face.draw_colored_polygon(HexShape.polygon(rect), Color(UiTheme.GILT, 0.15))
	_reach_face.draw_polyline(HexShape.closed(rect), UiTheme.GILT, 3.0, true)


func _draw_target() -> void:
	if highlight.a <= 0.0 or not get_viewport().gui_is_dragging():
		return
	var pulse: float = 0.8 + 0.2 * sin(TAU * _target_age / 0.8)
	var rect: Rect2 = face_rect()
	draw_colored_polygon(HexShape.polygon(rect), Color(highlight, highlight.a * pulse * 0.22))
	draw_polyline(HexShape.closed(rect), Color(UiTheme.ACORN, pulse), 3.0, true)
