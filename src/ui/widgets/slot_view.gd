extends "res://src/ui/widgets/interactive.gd"
## One fixed board slot (F1-F4, B1-B3). Always visible, even when empty, so the 4-3 brick and its
## gaps read at a glance. Shows its label and lights up as a drop or tap target. In Folk Print an
## empty slot is dashed ink on paper and says where it is ("B1 · behind F1 · F2").

const UiTheme := preload("res://src/ui/ui_theme.gd")
const SLOT_NAMES: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]

## Highlight colour (valid target, selected source); transparent for none.
var highlight: Color = Color.TRANSPARENT:
	set(value):
		highlight = value
		_restyle()

var _label: Label


func _init() -> void:
	super()
	_label = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.TEXT_DIM)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_label)
	_restyle()


func set_slot(slot_zone: String, slot: int) -> void:
	zone = slot_zone
	index = slot
	_label.text = SLOT_NAMES[slot] if slot >= 0 and slot < SLOT_NAMES.size() else ""
	if UiTheme.has_shape("slot_notes") and not _label.text.is_empty():
		_label.text += "\n" + note(slot)
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## Where an empty slot sits: "front row", or the two front slots a back slot is behind (8.2.1).
static func note(slot: int) -> String:
	if slot < 4:
		return "front row"
	return "behind F%d · F%d" % [slot - 3, slot - 2]


func _restyle() -> void:
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var fill: Color = UiTheme.SLOT_FILL
	var border: Color = UiTheme.SLOT_BORDER
	var width: float = 3.0
	if highlight.a > 0.0:
		fill = Color(highlight, 0.18)
		border = highlight
		width = 5.0
	elif UiTheme.has_shape("slot_notes"):
		# Dashed ink on paper, like a cut line.
		draw_style_box(UiTheme.flat_box(fill, Color.TRANSPARENT, 0, 14), rect)
		var corners: PackedVector2Array = [
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		]
		for i: int in 4:
			draw_dashed_line(corners[i], corners[(i + 1) % 4], border, width, 10.0)
		return
	var box: StyleBoxFlat = UiTheme.flat_box(fill, border, int(width), 14)
	draw_style_box(box, rect)
