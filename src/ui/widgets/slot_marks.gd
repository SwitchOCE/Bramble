extends Control
## What lies on the board's slots, over the tiles: a Ring of dots with its stats, a Rainbow band in
## the slot's own colour, an arrow on the unit a Pass will land on, and in a fight a Hex's slip.
## Empty slots show them too.

const UiTheme := preload("res://src/ui/ui_theme.gd")

const BAND_COLOURS: Array[Color] = [
	Color("c8372d"),
	Color("e2852b"),
	Color("e8c63a"),
	Color("4f9a3c"),
	Color("2f7fc1"),
	Color("47479c"),
	Color("8a4aa8"),
]
const RING_DOTS: int = 26
const RING: Color = Color("e9c75a")
const HEX: Color = Color("5b3a8a")

## One entry per slot: {"ring": "+1/+1" or "", "has_ring", "band"} (RecruitView.slot_marks).
var marks: Array = []
## The slot a Pass would land on, or -1.
var pass_slot: int = -1:
	set(value):
		pass_slot = value
		_place()

var board: Control

var _ring_labels: Array[Label] = []
var _pass_label: Label
var _hex_labels: Dictionary[int, Label] = {}


func _init(owner_board: Control) -> void:
	board = owner_board
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 3
	for i: int in 7:
		var label: Label = UiTheme.number("", UiTheme.FONT_SMALL, UiTheme.INK)
		label.add_theme_stylebox_override("normal", UiTheme.slip_box(RING, 3, 8))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.visible = false
		add_child(label)
		_ring_labels.append(label)
	_pass_label = UiTheme.head("Pass lands", UiTheme.FONT_SMALL, UiTheme.CREAM)
	_pass_label.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.MOSS, 3, 8))
	_pass_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pass_label.visible = false
	add_child(_pass_label)


func set_hex(slot: int, total: int) -> void:
	if not _hex_labels.has(slot):
		var made: Label = UiTheme.number("", UiTheme.FONT_SMALL, UiTheme.CREAM)
		made.add_theme_stylebox_override("normal", UiTheme.slip_box(HEX, 3, 8))
		made.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(made)
		_hex_labels[slot] = made
	var label: Label = _hex_labels[slot]
	label.text = "Hex %d" % -absi(total)
	label.size = label.get_minimum_size()
	var pocket: Vector2 = board.get("pocket")
	var at: Vector2 = board.call("slot_position", slot)
	label.position = at + Vector2((pocket.x - label.size.x) / 2.0, pocket.y * 0.42)


func clear_hexes() -> void:
	for label: Label in _hex_labels.values():
		remove_child(label)
		label.queue_free()
	_hex_labels.clear()


func set_marks(slot_marks: Array) -> void:
	marks = slot_marks
	_place()


func _place() -> void:
	var pocket: Vector2 = board.get("pocket")
	for i: int in _ring_labels.size():
		var label: Label = _ring_labels[i]
		var mark: Dictionary = marks[i] if i < marks.size() else {}
		var words: String = str(mark.get("ring", ""))
		label.visible = not words.is_empty()
		if label.visible:
			label.text = words
			label.size = label.get_minimum_size()
			var at: Vector2 = board.call("slot_position", i)
			var cards: Array = board.get("cards")
			var y: float = 34.0 if cards[i] != null else 6.0
			label.position = at + Vector2(pocket.x - label.size.x + 6.0, y)
	_pass_label.visible = pass_slot >= 0
	if _pass_label.visible:
		var at: Vector2 = board.call("slot_position", pass_slot)
		_pass_label.size = _pass_label.get_minimum_size()
		_pass_label.position = at + Vector2((pocket.x - _pass_label.size.x) / 2.0, 44.0)
	queue_redraw()


func _draw() -> void:
	var pocket: Vector2 = board.get("pocket")
	for i: int in mini(marks.size(), 7):
		var mark: Dictionary = marks[i]
		var at: Vector2 = board.call("slot_position", i)
		if mark.get("has_ring", false) == true:
			var cards: Array = board.get("cards")
			_draw_ring(Rect2(at, pocket).grow(-1.0), cards[i] != null)
		if mark.get("band", false) == true:
			var band: Rect2 = Rect2(
				at + Vector2(pocket.x * 0.27, pocket.y - 8.0), Vector2(pocket.x * 0.46, 16)
			)
			draw_rect(band.grow(3.0), UiTheme.INK)
			draw_rect(band, BAND_COLOURS[i])
	if pass_slot >= 0:
		var at: Vector2 = board.call("slot_position", pass_slot)
		var tip: Vector2 = at + Vector2(pocket.x / 2.0, 124.0)
		var points: PackedVector2Array = [tip, tip + Vector2(-28, -34), tip + Vector2(28, -34)]
		draw_colored_polygon(points, UiTheme.MOSS)
		points.append(tip)
		draw_polyline(points, UiTheme.INK, 4.0)


## Dots around the pocket's edge, like toadstools in a fairy ring.
## With a unit there the top run is left off: that edge is the unit's keyword chip.
func _draw_ring(rect: Rect2, skip_top: bool) -> void:
	var perimeter: float = (rect.size.x + rect.size.y) * 2.0
	for dot: int in RING_DOTS:
		var along: float = perimeter * dot / RING_DOTS
		var point: Vector2 = rect.position
		if along < rect.size.x:
			if skip_top:
				continue
			point += Vector2(along, 0)
		elif along < rect.size.x + rect.size.y:
			point += Vector2(rect.size.x, along - rect.size.x)
		elif along < rect.size.x * 2.0 + rect.size.y:
			point += Vector2(rect.size.x * 2.0 + rect.size.y - along, rect.size.y)
		else:
			point += Vector2(0, perimeter - along)
		draw_circle(point, 8.0, UiTheme.INK)
		draw_circle(point, 5.5, RING)
