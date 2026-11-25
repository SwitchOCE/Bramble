class_name RecruitCounters
extends GlassCounters
## L1 medallions with the shared counter hover, Compost click, and change animation.

const LEAF: String = '<path d="M5 19c0-8 5-13 14-14-1 9-6 14-14 14zM5 19l8-8"/>'
const WAVES: String = (
	'<path d="M3 9c2.5-2.5 4.5-2.5 6 0s3.5 2.5 6 0 4.5-2.5 6 0'
	+ 'M3 15c2.5-2.5 4.5-2.5 6 0s3.5 2.5 6 0 4.5-2.5 6 0"/>'
)
const STAR: String = (
	'<path d="M12 2.5l2.3 6.2 6.2 2.3-6.2 2.3L12 19.5l-2.3-6.2-6.2-2.3'
	+ ' 6.2-2.3z" fill="#f0d68a" stroke="#4a3608" stroke-width="1.2"/>'
)
const TRIANGLE: String = '<path d="M6 4l12 8-12 8z" fill="#cfc6b0" stroke="none"/>'

static var _lead: GradientTexture2D

var _order: Array[String] = []
var _recent: Dictionary = {}
var _revision: int = 0


func _init(screen: GlassScreen) -> void:
	super(screen)


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
		var counter: Dictionary = shown[i]
		var id: String = str(counter.get("id", ""))
		var value: String = _values[id]
		_build_medallion(counter, id, value, i, str(before.get(id, value)) != value)
	_recent = recent
	_revision += 1
	if counters.size() > shown.size():
		_build_auras_plate(counters.size())


func clear() -> void:
	var plate: Node = _screen._front.get_node_or_null("AurasPlate")
	if plate != null:
		_screen._front.remove_child(plate)
		plate.queue_free()
	super()


func _build_medallion(counter: Dictionary, id: String, value: String, i: int, pop: bool) -> void:
	var rect: Rect2 = counter_area(i)
	var heap: bool = counter.has("entries")
	var plate: GlassBox = _shape(rect, heap)
	plate.name = "Chip_%d" % i
	plate.image_texture = _lead_texture()
	plate.layers = [{"kind": "image", "size": [100.0, "auto"]}]
	plate.shadows = [
		L1ColumnArt.shadow(
			L1Layout.number("right.counter.shadow_y"),
			L1Layout.number("right.counter.shadow_blur"),
			"000000a6"
		)
	]
	plate.refresh()

	var inset: float = L1Layout.number("right.counter.inset")
	var glass: GlassBox = _shape(Rect2(Vector2.ZERO, rect.size), heap, inset)
	# STAND-IN: slate and the current emblem for counters without an L1 design.
	var middle: float = L1Layout.number("right.counter.glass_stop")
	var stops: Array = [["6f8597", 0], ["3a4f5e", middle], ["1a2731", 100]]
	var icon_path: String = ""
	match id:
		"thorn_compost", "compost":
			stops = [["7da35c", 0], ["3f6a2c", middle], ["1f3a16", 100]]
			icon_path = LEAF
		"locust_tide", "tide":
			stops = [["6fa3c8", 0], ["2f6490", middle], ["143454", 100]]
			icon_path = WAVES
	var focus: Vector2 = L1Layout.point("right.counter.glass_focus")
	glass.layers = [{"kind": "radial", "shape": "circle", "at": [focus.x, focus.y], "stops": stops}]
	if not heap:
		# The gradient fills the medallion before it is clipped to the inner circle.
		glass.padding_override = Rect2(-Vector2.ONE * inset, rect.size)
	glass.refresh()
	plate.add_child(glass)
	var mark: TextureRect = _mark(id, icon_path)
	if mark != null:
		mark.position = (plate.size - mark.size) / 2.0
		plate.add_child(mark)
	var badge: GlassBox = _number_badge(value, rect.size)
	plate.add_child(badge)
	_screen._front.add_child(plate)
	_add_target(plate, _tip_card(counter, _screen.counter_entry(counter)))
	_screen._targets.back()["poly"] = (
		plate.polygon_outer if heap else GlassParts.round_poly(plate.size)
	)
	if id == "thorn_compost":
		_screen._targets.back()["id"] = id
		plate.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		plate.mouse_filter = Control.MOUSE_FILTER_PASS
		# STAND-IN: a warm, static hover tint on the clickable heap.
		plate.mouse_entered.connect(func() -> void: plate.modulate = Color("fff4df"))
		plate.mouse_exited.connect(func() -> void: plate.modulate = Color.WHITE)
	if pop:
		_pop(badge)


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


func _mark(id: String, icon_path: String) -> TextureRect:
	var px: int = int(L1Layout.number("right.counter.icon"))
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


func _build_auras_plate(total: int) -> void:
	var plate: TextureRect = L1ColumnArt.piece("l1p-plate", L1Layout.rect("right.auras"))
	plate.name = "AurasPlate"
	var star_px: int = int(L1Layout.number("right.auras.star"))
	var triangle_px: int = int(L1Layout.number("right.auras.triangle"))
	var star: TextureRect = L1ColumnArt.icon(STAR, L1ColumnArt.CREAM, star_px, 0.0)
	var triangle: TextureRect = L1ColumnArt.icon(TRIANGLE, L1ColumnArt.CREAM, triangle_px, 0.0)
	var label: GlassText = L1ColumnArt.text(
		str(total), L1Layout.number("right.auras.font"), L1ColumnArt.PLATE_INK
	)
	var gap: float = L1Layout.number("right.auras.gap")
	var x: float = (plate.size.x - star.size.x - label.size.x - triangle.size.x - 2.0 * gap) / 2.0
	for part: Control in [star, label, triangle]:
		part.position = Vector2(x, (plate.size.y - part.size.y) / 2.0)
		plate.add_child(part)
		x += part.size.x + gap
	# STAND-IN: the overflow panel is awaiting its design.
	_screen._front.add_child(plate)
