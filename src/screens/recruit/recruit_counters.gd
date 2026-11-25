class_name RecruitCounters
extends GlassCounters
## L1 medallions, overflow plate, and the player-owned entries shown in Auras.

const LEAF: String = '<path d="M5 19c0-8 5-13 14-14-1 9-6 14-14 14zM5 19l8-8"/>'
const WAVES: String = (
	'<path d="M3 9c2.5-2.5 4.5-2.5 6 0s3.5 2.5 6 0 4.5-2.5 6 0'
	+ 'M3 15c2.5-2.5 4.5-2.5 6 0s3.5 2.5 6 0 4.5-2.5 6 0"/>'
)
const HOPPER: String = '<path d="M6 16l5-8 3 5 4-2M11 8l-1-4M14 13l2 6M6 16l-2 3"/>'
const GUARD: String = '<path d="M12 3l7 3v5c0 5-3 8-7 10-4-2-7-5-7-10V6z"/>'
const SLOT: String = '<path d="M12 3l7 4v10l-7 4-7-4V7zM12 9v6M9 12h6"/>'

const AURA_LINES: String = "res://assets/glass/l1/aura_lines.json"

static var _lead: GradientTexture2D
static var _aura_lines: Dictionary

var rows: Array[Dictionary] = []

var _recruit: RecruitScreen
var _pressed_id: String = ""
var _order: Array[String] = []
var _recent: Dictionary = {}
var _revision: int = 0


func _init(screen: RecruitScreen) -> void:
	super(screen)
	_recruit = screen


func _input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _screen.is_visible_in_tree() or not _screen._hover_allowed():
		_pressed_id = ""
		return
	var at: Vector2 = _screen._stage.make_canvas_position_local(click.position)
	var plate: Control = _screen._front.get_node_or_null("AurasPlate")
	var chip: Dictionary = _screen._target_at(at, false)
	var id: String = str(chip.get("id", "")) if chip.get("kind") == "counter" else ""
	var anchor: Rect2 = Rect2()
	if plate != null and Rect2(plate.position, plate.size).has_point(at):
		id = RecruitAuraPanel.OVERFLOW
		anchor = Rect2(plate.position, plate.size)
	elif id != "":
		var node: Control = chip["node"]
		anchor = Rect2(node.position, node.size)
	if click.pressed:
		_pressed_id = id
		if id != "":
			get_viewport().set_input_as_handled()
	elif _pressed_id != "":
		get_viewport().set_input_as_handled()
		var pressed: String = _pressed_id
		_pressed_id = ""
		if pressed == id:
			_recruit._open_auras(id, anchor.get_center().y)


static func counter_area(i: int) -> Rect2:
	var area: Rect2 = L1Layout.rect("right.counter")
	var columns: int = int(L1Layout.number("right.counter.columns"))
	var step: float = L1Layout.number("right.counter.step")
	area.position += Vector2(i % columns, floorf(float(i) / columns)) * step
	return area


## The medallions and card flights use the same selection and places.
func visible_counters(raw: Array) -> Array[Dictionary]:
	return _select_visible(_fixed_order(raw))


## Keep the order in which counters first appeared, regardless of the incoming order or values.
func _fixed_order(raw: Array) -> Array[Dictionary]:
	var by_id: Dictionary[String, Dictionary] = {}
	for value: Variant in raw:
		var counter: Dictionary = value if value is Dictionary else {}
		if not _screen.counter_entry(counter).is_empty():
			by_id[str(counter.get("id", ""))] = counter
	var counters: Array[Dictionary] = []
	for id: String in _order:
		if by_id.has(id):
			counters.append(by_id[id])
			by_id.erase(id)
	counters.append_array(by_id.values())
	return counters


func _select_visible(counters: Array[Dictionary]) -> Array[Dictionary]:
	var limit: int = int(L1Layout.number("right.counter.limit"))
	if counters.size() <= limit:
		return counters
	var ranked: Array[Dictionary] = counters.duplicate()
	ranked.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var newer_a: int = _recency(a)
			var newer_b: int = _recency(b)
			if newer_a != newer_b:
				return newer_a > newer_b
			var amount_a: float = str(a.get("value", 0)).to_float()
			var amount_b: float = str(b.get("value", 0)).to_float()
			if amount_a != amount_b:
				return amount_a > amount_b
			return str(a.get("id", "")) < str(b.get("id", ""))
	)
	ranked.resize(limit)
	var shown: Array[Dictionary] = []
	for counter: Dictionary in counters:
		if ranked.has(counter):
			shown.append(counter)
	return shown


func _recency(counter: Dictionary) -> int:
	var id: String = str(counter.get("id", ""))
	var value: String = GlassScreen.number_words(counter.get("value", ""))
	if _revision > 0 and _values.get(id, null) != value:
		return _revision + 1
	return _recent.get(id, 0)


func build(shown_counters: Array) -> void:
	var counters: Array[Dictionary] = _fixed_order(shown_counters)
	var shown: Array[Dictionary] = _select_visible(counters)
	rows.assign(counters.map(_counter_row))
	rows.append_array(_slot_rows())
	var before: Dictionary = _values
	var recent: Dictionary = {}
	_values = {}
	for counter: Dictionary in counters:
		var id: String = str(counter.get("id", ""))
		var value: String = GlassScreen.number_words(counter.get("value", ""))
		var changed: bool = before.get(id, null) != value
		if not _order.has(id):
			_order.append(id)
		recent[id] = _revision + 1 if _revision > 0 and changed else _recent.get(id, 0)
		_values[id] = value
	for i: int in shown.size():
		var row: Dictionary = _counter_row(shown[i])
		var id: String = row["id"]
		var value: String = _values[id]
		_build_medallion(row, i, str(before.get(id, value)) != value)
	_recent = recent
	_revision += 1
	if counters.size() > shown.size():
		_build_auras_plate(rows.size() - shown.size())
	if _recruit._auras != null:
		_recruit._auras.refresh(rows)


func _counter_row(counter: Dictionary) -> Dictionary:
	var row: Dictionary = counter.duplicate()
	var shown: Dictionary = _screen.counter_entry(counter)
	row["name"] = shown["name"]
	row["reminder"] = shown["reminder"]
	var value: String = GlassScreen.number_words(counter.get("value", ""))
	row["value"] = value
	row["effect"] = _aura_line(str(row["id"]), value)
	return row


static func _aura_line(id: String, value: String = "") -> String:
	if _aura_lines.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(AURA_LINES))
		assert(parsed is Dictionary, "%s is not a JSON object" % AURA_LINES)
		_aura_lines = parsed
	var line: String = str(_aura_lines.get(id, ""))
	if value.begins_with("-"):
		line = line.replace("+N", "N")
	return CardTerms.fill(line, value)


func _slot_rows() -> Array[Dictionary]:
	var rows_on_board: Array[Dictionary] = []
	var slots: Array = _screen.state.get("slots", [])
	var display: Dictionary = _screen._display_table()
	for i: int in mini(slots.size(), GlassScreen.BOARD_SLOTS):
		var slot: Dictionary = slots[i] if slots[i] is Dictionary else {}
		for keyword: Dictionary in slot.get("keywords", []):
			var id: String = str(keyword.get("id", ""))
			var shown: Dictionary = _screen.display_entry(id)
			if not shown.is_empty():
				rows_on_board.append(_slot_row(i, id, shown, _aura_line(id)))
		var renown: int = GlassPieces.as_int(slot.get("renown", 0))
		if renown != 0:
			var entry: Dictionary = display.get("renown", ContentSet.CORE_DISPLAY["renown"])
			rows_on_board.append(_slot_row(i, "renown", entry, _aura_line("renown", str(renown))))
	return rows_on_board


static func _slot_row(index: int, id: String, entry: Dictionary, effect: String) -> Dictionary:
	return {
		"id": "%s:%d" % [id, index],
		"icon_id": id,
		"slot": index,
		"name": entry["name"],
		"effect": effect,
	}


func clear() -> void:
	var plate: Node = _screen._front.get_node_or_null("AurasPlate")
	if plate != null:
		_screen._front.remove_child(plate)
		plate.queue_free()
	super()


func _build_medallion(row: Dictionary, i: int, pop: bool) -> void:
	var plate: GlassBox = medallion(row, counter_area(i))
	plate.name = "Chip_%d" % i
	if row.has("value"):
		var badge: GlassBox = _number_badge(str(row["value"]), plate.size)
		plate.add_child(badge)
		if pop:
			_pop(badge)
	_screen._front.add_child(plate)
	_add_target(plate, _tip_card(row, row))
	_screen._targets.back()["id"] = row["id"]
	_screen._targets.back()["poly"] = (
		plate.polygon_outer if row.has("entries") else GlassParts.round_poly(plate.size)
	)
	_clickable(plate)


func medallion(row: Dictionary, rect: Rect2, compact: bool = false) -> GlassBox:
	var id: String = str(row.get("icon_id", row["id"]))
	var heap: bool = row.has("entries")
	var inset: float = L1Layout.number("panel.medal.inset" if compact else "right.counter.inset")
	if compact:
		rect = rect.grow(inset)
	var plate: GlassBox = _shape(rect, heap)
	plate.image_texture = _lead_texture()
	plate.layers = [{"kind": "image", "size": [100.0, "auto"]}]
	if not compact:
		plate.shadows = [
			L1ColumnArt.shadow(
				L1Layout.number("right.counter.shadow_y"),
				L1Layout.number("right.counter.shadow_blur"),
				"000000a6"
			)
		]
	plate.refresh()

	var glass: GlassBox = _shape(Rect2(Vector2.ZERO, rect.size), heap, inset)
	var middle: float = L1Layout.number("right.counter.glass_stop")
	# STAND-IN: slate and the current emblem for counters without an L1 design.
	var stops: Array = [["6f8597", 0], ["3a4f5e", middle], ["1a2731", 100]]
	var icon_path: String = ""
	match id:
		"thorn_compost", "compost":
			stops = (
				[["7fb05a", 0], ["4c7e33", middle], ["2f5520", 100]]
				if compact
				else [["7da35c", 0], ["3f6a2c", middle], ["1f3a16", 100]]
			)
			icon_path = LEAF
		"locust_tide", "tide":
			stops = (
				[["6aa3d6", 0], ["3a6fa4", middle], ["21466e", 100]]
				if compact
				else [["6fa3c8", 0], ["2f6490", middle], ["143454", 100]]
			)
			icon_path = WAVES
		"locust_hopper_bonus":
			stops = [["73c3b4", 0], ["3a8679", middle], ["22564e", 100]]
			icon_path = HOPPER
		"pigeon_guard_post":
			icon_path = GUARD
		"renown":
			stops = [["e2a05a", 0], ["b5692c", middle], ["7a3e17", 100]]
			icon_path = SLOT
	var focus: Vector2 = L1Layout.point("right.counter.glass_focus")
	glass.layers = [{"kind": "radial", "shape": "circle", "at": [focus.x, focus.y], "stops": stops}]
	if not heap:
		glass.padding_override = Rect2(-Vector2.ONE * inset, rect.size)
	glass.refresh()
	plate.add_child(glass)
	var px: int = roundi(
		(
			(rect.size.y - 2.0 * inset) * L1Layout.number("panel.medal.icon_share")
			if compact
			else L1Layout.number("right.counter.icon")
		)
	)
	var mark: TextureRect = _mark(id, icon_path, px)
	if mark != null:
		mark.position = (plate.size - mark.size) / 2.0
		plate.add_child(mark)
	return plate


static func _clickable(plate: Control) -> void:
	plate.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	plate.mouse_filter = Control.MOUSE_FILTER_PASS
	plate.mouse_entered.connect(func() -> void: plate.modulate = Color("fff4df"))
	plate.mouse_exited.connect(func() -> void: plate.modulate = Color.WHITE)


static func _shape(rect: Rect2, hex: bool, inset: float = 0.0) -> GlassBox:
	var box: GlassBox = GlassBox.new()
	if hex:
		var half: Vector2 = rect.size / 2.0
		var slope: float = cos(PI / 6.0)
		var hex_rect: Rect2 = Rect2(
			Vector2(half.x * (1.0 - slope) + inset * slope, inset),
			Vector2((rect.size.x - 2.0 * inset) * slope, rect.size.y - 2.0 * inset)
		)
		box.polygon_outer = GlassBox.hexagon(hex_rect, 0.25)
	else:
		rect = rect.grow(-inset)
	box.position = rect.position
	box.box_size = rect.size
	box.radii = Vector4.ONE * rect.size.y / 2.0
	return box


static func _lead_texture() -> GradientTexture2D:
	if _lead == null:
		var angle: float = deg_to_rad(L1Layout.number("right.counter.lead_angle") - 90.0)
		var axis: Vector2 = Vector2.from_angle(angle)
		var span: Vector2 = axis * (absf(axis.x) + absf(axis.y)) / 2.0
		_lead = L1ColumnArt.gradient(
			[Color("4d5356"), Color("15191a"), Color("0b0d0c")],
			[0.0, L1Layout.number("right.counter.lead_stop") / 100.0, 1.0],
			Vector2(0.5, 0.5) - span,
			Vector2(0.5, 0.5) + span
		)
	return _lead


func _mark(id: String, icon_path: String, px: int) -> TextureRect:
	if not icon_path.is_empty():
		return L1ColumnArt.icon(
			icon_path, L1ColumnArt.CREAM, px, L1Layout.number("right.counter.icon_stroke")
		)
	var emblem: String = _emblem(id)
	if emblem.is_empty():
		return null
	var tex: Texture2D = GlassPieces.texture("ui/tr-%s.png" % emblem)
	var mark: TextureRect = L1ColumnArt.picture(tex, Rect2(Vector2.ZERO, Vector2.ONE * px))
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return mark


static func _number_badge(value: String, plate_size: Vector2) -> GlassBox:
	var key: String = "right.counter.badge."
	var diameter: float = L1Layout.number(key + "d")
	# STAND-IN: numbers longer than three digits use the wide badge with fitted type.
	var wide: bool = value.length() >= 3
	var width: float = L1Layout.number(key + "wide") if wide else diameter
	var outer: float = L1Layout.number(key + "outer_ring")
	var inner: float = L1Layout.number(key + "inner_ring")
	var center: Vector2 = plate_size / 2.0 * (1.0 + L1Layout.number(key + "rim_share"))
	if wide:
		center.x -= L1Layout.number(key + "wide_nudge")
	var size: Vector2 = Vector2(width, diameter) + Vector2.ONE * 2.0 * (outer + inner)
	var badge: GlassBox = _shape(Rect2(center - size / 2.0, size), false)
	badge.name = "Badge"
	badge.layers = [{"kind": "colour", "colour": "15191a"}]
	badge.border_width = outer
	badge.border_colour = Color("6a6f70")
	badge.refresh()
	var face: GlassBox = _shape(Rect2(Vector2.ZERO, size).grow(-outer - inner), false)
	var stop: float = L1Layout.number(key + "glass_stop")
	var focus: Vector2 = L1Layout.point("right.counter.glass_focus")
	face.layers = [
		{
			"kind": "radial",
			"shape": "circle",
			"at": [focus.x, focus.y],
			"stops": [["fffaf0", 0], ["e9dcbb", stop]]
		}
	]
	face.refresh()
	badge.add_child(face)
	var font: float = L1Layout.number(key + "font")
	var label: GlassText = L1ColumnArt.text("", font, Color("2a2016"))
	label.name = "Value"
	var text_center: Vector2 = (
		size / 2.0 + Vector2.DOWN * font * L1Layout.number(key + "text_lower_em")
	)
	L1ColumnArt.fit_number(label, value, font, text_center, width - 2.0 * inner)
	badge.add_child(label)
	return badge


func _build_auras_plate(hidden: int) -> void:
	var plate: TextureRect = L1ColumnArt.piece("l1p-plate", L1Layout.rect("right.auras"))
	plate.name = "AurasPlate"
	var label: GlassText = L1ColumnArt.text(
		"+%d" % hidden, L1Layout.number("right.auras.font"), L1ColumnArt.CREAM
	)
	label.position = (plate.size - label.size) / 2.0
	plate.add_child(label)
	_clickable(plate)
	_screen._front.add_child(plate)
