class_name GlassCounters
extends Node
## The player's counters (a tribe's count, a Compost number...) on the mock-up's two chips, in the
## left light above the hero's name. STAND-IN (polish.html .cnt): each counter or heap is a cream
## plate, its emblem (when it has one), its name and its number, the first lowest; the hover adds
## its reminder and, for a heap, what is in it. A number that changed since the last drawing pops.
##
## A part of its screen: it draws on the screen's Front layer and adds the plates to its targets.

## STAND-IN (polish.html .cnt): the plates' left edge, the first's top above the stage's bottom,
## the step up to the next, where a plate's pinned hover goes, and the pop when a number changes.
const PLATE_X: float = 40.0
const PLATE_UP: float = 244.0
const PLATE_STEP: float = 54.0
const PLATE_TIP_X: float = 220.0
const PLATE_TIP_DOWN: float = 40.0
const PLATE_POP: float = 1.25
const PLATE_POP_TIME: float = 0.35

var _screen: GlassScreen
## Each plate's number as last drawn, by id, so a change pops.
var _values: Dictionary = {}


func _init(screen: GlassScreen) -> void:
	_screen = screen


## Read chip clicks before recruit dragging or the controller's fight skip handler.
func _input(event: InputEvent) -> void:
	if not _screen.is_visible_in_tree() or _screen._compost != null or not _screen._hover_allowed():
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var at: Vector2 = _screen._stage.make_canvas_position_local(click.position)
	var hit: Dictionary = _screen._target_at(at, false)
	if hit.get("id", "") == "thorn_compost":
		get_viewport().set_input_as_handled()
		if not click.pressed:
			_screen._open_compost()


## Where counter plate i (of those shown) is drawn.
static func plate_xy(i: int, stage_height: float) -> Vector2:
	return Vector2(PLATE_X, stage_height - PLATE_UP - i * PLATE_STEP)


## Draws the plates for these counters ({id, value, entries?}); hidden ones are skipped.
func build(shown_counters: Array) -> void:
	var counters: Array = []
	for value: Variant in shown_counters:
		var counter_value: Dictionary = value if value is Dictionary else {}
		if not _screen.counter_entry(counter_value).is_empty():
			counters.append(counter_value)
	var before: Dictionary = _values
	_values = {}
	for i: int in counters.size():
		var counter: Dictionary = counters[i]
		var shown: Dictionary = _screen.counter_entry(counter)
		var value: String = GlassScreen.number_words(counter.get("value", ""))
		var plate: GlassBox = GlassParts.counter_plate(
			str(shown["name"]), value, _emblem(str(counter.get("id", "")))
		)
		plate.name = "Chip_%d" % i
		plate.position = plate_xy(i, _screen._stage.size.y)
		_screen._front.add_child(plate)
		_add_target(plate, _tip_card(counter, shown))
		var key: String = str(counter.get("id", ""))
		if key == "thorn_compost":
			_screen._targets.back()["id"] = key
			plate.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			plate.mouse_filter = Control.MOUSE_FILTER_PASS
			plate.mouse_entered.connect(func() -> void: plate.modulate = Color(1.16, 1.10, 1.02))
			plate.mouse_exited.connect(func() -> void: plate.modulate = Color.WHITE)
		_values[key] = value
		if before.has(key) and before[key] != value:
			_pop(plate)


## Takes the plates and their targets away (to draw them again, the rest left as it is).
func clear() -> void:
	for child: Node in _screen._front.get_children():
		if child.name.begins_with("Chip_"):
			_screen._front.remove_child(child)
			child.queue_free()
	for i: int in range(_screen._targets.size() - 1, -1, -1):
		if str(_screen._targets[i]["kind"]) == "counter":
			_screen._targets.remove_at(i)


## The emblem a counter's display entry names (`icon`), when the glass pieces have it
## (assets/glass/ui/tr-<icon>.png); "" for none.
func _emblem(id: String) -> String:
	var entry: Dictionary = CardTerms.table_entry(id, _screen._display_table())
	var icon: String = str(entry.get("icon", ""))
	if icon == "" or not ResourceLoader.exists("res://assets/glass/ui/tr-%s.png" % icon):
		return ""
	return icon


## A counter's hover: its name, "Counter" or "Heap · n units", its reminder, and a heap's
## entries, one line each, the same ones counted ("Bramble Runner ×2 · tier 1").
static func _tip_card(counter: Dictionary, shown: Dictionary) -> Dictionary:
	var tip_card: Dictionary = {
		"id": str(counter.get("id", "")),
		"name": shown["name"],
		"text": shown["reminder"],
		"kind_line": "Counter"
	}
	if not counter.has("entries"):
		return tip_card
	var entries: Array = counter["entries"]
	tip_card["kind_line"] = (
		"Heap · %d unit%s" % [entries.size(), "" if entries.size() == 1 else "s"]
	)
	var order: Array[String] = []
	var counts: Dictionary = {}
	for value: Variant in entries:
		var entry: Dictionary = value if value is Dictionary else {}
		var line: String = (
			"%s · tier %d"
			% [
				str(entry.get("name", entry.get("id", ""))),
				GlassPieces.as_int(entry.get("tier", 1))
			]
		)
		if not counts.has(line):
			order.append(line)
			counts[line] = 0
		counts[line] = GlassPieces.as_int(counts[line]) + 1
	var lines: PackedStringArray = PackedStringArray()
	for line: String in order:
		var n: int = GlassPieces.as_int(counts[line])
		var parts: PackedStringArray = line.split(" · ", true, 1)
		lines.append(line if n == 1 else "%s ×%d · %s" % [parts[0], n, parts[1]])
	tip_card["lines"] = lines
	return tip_card


func _pop(plate: Control) -> void:
	if not _screen.is_inside_tree():
		return
	plate.pivot_offset = plate.size / 2.0
	plate.scale = Vector2.ONE * PLATE_POP
	_screen.create_tween().tween_property(plate, "scale", Vector2.ONE, PLATE_POP_TIME).set_trans(
		Tween.TRANS_BACK
	)


## A plate as a pointer target, for its hover.
func _add_target(node: Control, tip_card: Dictionary) -> void:
	var box: Vector2 = (node as GlassBox).box_size
	(
		_screen
		. _targets
		. append(
			{
				"kind": "counter",
				"index": _screen._targets.size(),
				"node": node,
				"poly":
				PackedVector2Array([Vector2.ZERO, Vector2(box.x, 0), box, Vector2(0, box.y)]),
				"card": tip_card,
			}
		)
	)
