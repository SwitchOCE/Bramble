class_name RecruitAuraPanel
extends Control
## The buy screen's shared pane for player-owned effects and heap contents.

signal close_requested

const OVERFLOW: String = "+more"
const CREAM: Color = Color("f2e9d4")
const DIM: Color = Color("a9b2ad")
const CLOSE: String = '<path d="M7 7l10 10M17 7L7 17"/>'
const BACK: String = '<path d="M15 5l-7 7 7 7"/>'
const CHEVRON: String = '<path d="M9 5l7 7-7 7"/>'
const LEAD: String = "15191a"
const SLATE_MID: String = "1b262b"
const SLATE_DARK: String = "121a1e"

var rows: Array[Dictionary] = []
var groups: Array[Dictionary] = []
var scroll: ScrollContainer
var heap_id: String = ""

var _contents: Control
var _surface: Control
var _screen: RecruitScreen
var _counters: RecruitCounters
var _heap_targets: Array[Dictionary] = []
var _mouse: Vector2 = Vector2(-1, -1)
var _opener: String
var _anchor_y: float
var _from_list: bool = false
var _outside_button: MouseButton = MOUSE_BUTTON_NONE
var _list_offset: int = 0


func _init(screen: RecruitScreen, opener: String, anchor_y: float) -> void:
	_screen = screen
	_counters = screen._counters as RecruitCounters
	_opener = opener
	_anchor_y = anchor_y
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	refresh(_counters.rows)
	if _surface != null:
		var rest: float = _surface.position.x
		_surface.position.x += L1Layout.number("panel.slide.px")
		(
			create_tween()
			. tween_property(_surface, "position:x", rest, L1Layout.number("panel.slide.seconds"))
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
		)


func refresh(next_rows: Array[Dictionary]) -> void:
	if next_rows == rows and _surface != null:
		return
	var offset: int = scroll.scroll_vertical if scroll != null else 0
	var opening: bool = _surface == null
	rows = next_rows.duplicate(true)
	if opening and _row(_opener).has("entries"):
		heap_id = _opener
	if heap_id != "" and not _row(heap_id).has("entries"):
		if not _from_list:
			close_requested.emit()
			return
		heap_id = ""
		_from_list = false
		offset = _list_offset
	if rows.is_empty():
		close_requested.emit()
		return
	if opening and heap_id == "":
		var row_step: float = L1Layout.number("panel.auras.step")
		var limit: int = int(L1Layout.number("panel.auras.max_rows"))
		for i: int in range(limit, rows.size()):
			if rows[i]["id"] == _opener:
				offset = roundi((i - limit + 1) * row_step)
				break
	_render(offset)


func _row(id: String) -> Dictionary:
	for row: Dictionary in rows:
		if row["id"] == id:
			return row
	return {}


func _open_heap(id: String) -> void:
	_list_offset = scroll.scroll_vertical
	heap_id = id
	_from_list = true
	_render()


func _back_to_list() -> void:
	heap_id = ""
	_from_list = false
	_render(_list_offset)


func _render(offset: int = 0) -> void:
	if not _heap_targets.is_empty():
		_screen._tips.hide()
		_heap_targets.clear()
	if _surface != null:
		remove_child(_surface)
		_surface.queue_free()
	scroll = null
	var heap: Dictionary = _row(heap_id)
	var entries: Array = heap.get("entries", [])
	groups = RecruitHeapCards.groups(entries)
	var top: float = L1Layout.number("panel.top")
	var content_y: float = L1Layout.number("panel.content.y")
	var row_step: float = L1Layout.number("panel.auras.step")
	var shown: int = mini(rows.size(), int(L1Layout.number("panel.auras.max_rows")))
	var height: float = content_y + shown * row_step + L1Layout.number("panel.auras.bottom")
	var y: float = clampf(
		L1Layout.number("panel.bottom") - height, top, L1Layout.number("panel.few_y")
	)
	if not heap.is_empty():
		y = top
		height = L1Layout.number("panel.heap.empty_h" if entries.is_empty() else "panel.heap.h")
	var rect: Rect2 = Rect2(L1Layout.number("panel.x"), y, L1Layout.number("panel.w"), height)
	_surface = L1ColumnArt.area(rect)
	_surface.name = "Surface"
	_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	_surface.mouse_force_pass_scroll_events = false
	add_child(_surface)
	_build_pane(rect.size)
	_header(heap, entries.size())
	if heap.is_empty():
		var view: Rect2 = Rect2(0, content_y, rect.size.x, height - content_y)
		view.size.y -= L1Layout.number("panel.auras.clip_bottom")
		view.size.x -= L1Layout.number("panel.auras.rail_inset")
		_open_scroll(view)
		_contents.custom_minimum_size.y = rows.size() * row_step
		for i: int in rows.size():
			_aura_row(rows[i], i * row_step)
	elif groups.is_empty():
		var empty: GlassText = L1ColumnArt.text(
			"Empty", L1Layout.number("panel.heap.empty_font"), DIM
		)
		empty.name = "Empty"
		empty.position = L1Layout.centre("panel.heap.empty", empty.size)
		empty.position.y = L1Layout.number("panel.heap.empty.y")
		_surface.add_child(empty)
	else:
		var view: Rect2 = L1Layout.rect("panel.heap.view")
		view.size.x += L1Layout.number("panel.heap.rail_overhang")
		_open_scroll(view)
		_heap_targets = RecruitHeapCards.fill(_contents, groups)
	if scroll != null and offset > 0:
		scroll.set_deferred("scroll_vertical", offset)


## STAND-IN: the slate glass and lead are drawn in code pending a painted pane.
func _build_pane(box: Vector2) -> void:
	var radius: float = L1Layout.number("panel.radius")
	var lead: float = L1Layout.number("panel.outer_lead")
	var line: float = L1Layout.number("panel.outer_line")
	var rim: GlassBox = _box(Rect2(Vector2.ZERO, box).grow(lead + line), radius + lead + line, LEAD)
	rim.border_width = line
	rim.border_colour = Color("3c4244")
	rim.shadows = [
		_shadow("panel.shadow_near", "00000099"), _shadow("panel.shadow_far", "000000a6")
	]
	rim.refresh()
	_surface.add_child(rim)
	var face: GlassBox = _box(Rect2(Vector2.ZERO, box), radius, "26343a")
	face.image_texture = L1ColumnArt.gradient(
		[Color("26343a"), Color(SLATE_MID), Color(SLATE_DARK)],
		[0.0, 0.55, 1.0],
		Vector2.ZERO,
		Vector2.DOWN
	)
	var glass: GradientTexture2D = face.image_texture as GradientTexture2D
	glass.width = roundi(box.x)
	glass.height = roundi(box.y)
	face.layers = [
		{
			"kind": "radial",
			"shape": "ellipse",
			"at": [30, 0],
			"size": [90, 60],
			"stops": [["2f4148", 0], ["2f414800", 70]]
		},
		{"kind": "image", "size": [100.0, "auto"]}
	]
	face.refresh()
	_surface.add_child(face)
	var inner: Rect2 = Rect2(Vector2.ZERO, box).grow(-L1Layout.number("panel.inner_inset"))
	var inner_radius: float = L1Layout.number("panel.inner_radius")
	var inner_line: float = L1Layout.number("panel.inner_line")
	_outline(inner, inner_radius, inner_line, Color("7887872e"))
	_outline(
		inner.grow(-inner_line),
		inner_radius - inner_line,
		L1Layout.number("panel.inner_lead"),
		Color("0a0e0fd9")
	)
	_tab(box)


func _tab(box: Vector2) -> void:
	var w: float = L1Layout.number("panel.tab.w")
	var h: float = L1Layout.number("panel.tab.h")
	var inset: float = L1Layout.number("panel.tab.offset")
	var center: float = clampf(_anchor_y - _surface.position.y, h / 2.0, box.y - h / 2.0)
	for overlap: float in [L1Layout.number("panel.tab.lead"), 0.0]:
		var tab: Polygon2D = Polygon2D.new()
		tab.position = Vector2(box.x + inset, center)
		tab.polygon = PackedVector2Array(
			[
				Vector2(-overlap, -h / 2.0 - overlap),
				Vector2(w + overlap, 0.0),
				Vector2(-overlap, h / 2.0 + overlap)
			]
		)
		tab.color = Color(LEAD if overlap > 0.0 else SLATE_MID)
		_surface.add_child(tab)


func _header(heap: Dictionary, count: int) -> void:
	var rect: Rect2 = L1Layout.rect("panel.head")
	var x: float = L1Layout.number("panel.head.back_x") if _from_list else rect.position.x
	var center_y: float = rect.get_center().y
	var gap: float = L1Layout.number("panel.head.gap")
	if not heap.is_empty():
		var side: float = L1Layout.number("panel.head.medal")
		var med: GlassBox = _counters.medallion(
			heap, Rect2(Vector2(x, center_y - side / 2.0), Vector2.ONE * side), true
		)
		_surface.add_child(med)
		x += side + gap
	var title: GlassText = L1ColumnArt.text(
		str(heap.get("name", "Auras")), L1Layout.number("panel.head.title_font"), CREAM
	)
	title.name = "Title"
	title.position = Vector2(x, center_y - title.size.y / 2.0)
	_surface.add_child(title)
	var number: GlassText = L1ColumnArt.text(
		str(rows.size() if heap.is_empty() else count),
		L1Layout.number("panel.head.count_font"),
		DIM
	)
	number.name = "Count"
	number.position = Vector2(x + title.size.x + gap, center_y - number.size.y / 2.0)
	_surface.add_child(number)

	var close: TextureRect = L1ColumnArt.entry("panel.close", CLOSE, close_requested.emit)
	close.name = "Close"
	_surface.add_child(close)
	if _from_list:
		var back: TextureRect = L1ColumnArt.entry("panel.back", BACK, _back_to_list)
		back.name = "Back"
		_surface.add_child(back)
	var rule: Rect2 = L1Layout.rect("panel.rule")
	_surface.add_child(_box(rule, 0.0, LEAD))


func _aura_row(data: Dictionary, y: float) -> void:
	var rect: Rect2 = L1Layout.rect("panel.row")
	rect.position.y = y
	var heap: bool = data.has("entries")
	var radius: float = L1Layout.number("panel.row.radius")
	var row: GlassBox = _box(rect, radius, "ffffff09" if heap else "00000000")
	row.name = "Row_" + str(data["id"]).validate_node_name()
	_contents.add_child(row)
	if data["id"] == _opener:
		row.border_width = L1Layout.number("panel.row.selection")
		row.border_colour = Color("e8d49a8c")
		row.refresh()
	var med: Vector2 = Vector2.ONE * L1Layout.number("panel.row.medal.d")
	row.add_child(_counters.medallion(data, Rect2(L1Layout.point("panel.row.medal"), med), true))
	var title: GlassText = L1ColumnArt.text(
		str(data["name"]), L1Layout.number("panel.row.name_font"), CREAM
	)
	title.position = L1Layout.point("panel.row.name")
	row.add_child(title)
	var effect: String = str(data["effect"])
	if not effect.is_empty():
		_add_effect(row, effect)
	else:
		title.position.y = (row.size.y - title.size.y) / 2.0
	if data.has("slot"):
		_slot_map(row, GlassPieces.as_int(data["slot"]))
	else:
		_value(row, str(data["value"]), heap)
	if heap:
		var icon_rect: Rect2 = L1Layout.rect("panel.row.chevron")
		var chevron: TextureRect = L1ColumnArt.icon(
			CHEVRON,
			Color("c9c2ae"),
			int(icon_rect.size.x),
			L1Layout.number("panel.row.chevron.stroke")
		)
		chevron.position = icon_rect.position
		row.add_child(chevron)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.gui_input.connect(_heap_click.bind(str(data["id"])))


func _add_effect(row: Control, words: String) -> void:
	var effect: Label = Label.new()
	effect.text = words
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	effect.add_theme_font_override("font", GlassPieces.body_font(400))
	effect.add_theme_font_size_override("font_size", int(L1Layout.number("panel.row.effect_font")))
	effect.add_theme_color_override("font_color", DIM)
	effect.position = L1Layout.point("panel.row.effect")
	effect.size.x = row.size.x - effect.position.x - L1Layout.number("panel.row.effect_right")
	row.add_child(effect)


func _heap_click(event: InputEvent, id: String) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
		get_viewport().set_input_as_handled()
		_open_heap(id)


func _value(row: Control, words: String, heap: bool) -> void:
	var key: String = "panel.row."
	var right: float = L1Layout.number(key + ("heap_value_right" if heap else "value_right"))
	var room: float = L1Layout.number(key + "value_w")
	var y: float = L1Layout.number(key + "value_y") + L1Layout.number(key + "value_h") / 2.0
	var font: float = L1Layout.number(key + "value_font")
	var label: GlassText = L1ColumnArt.text(words, font, CREAM)
	L1ColumnArt.fit_number(label, words, font, Vector2.ZERO, room)
	label.position = Vector2(row.size.x - right - label.size.x, y - label.size.y / 2.0)
	row.add_child(label)


func _slot_map(row: Control, lit: int) -> void:
	var key: String = "panel.slot_map."
	var w: float = L1Layout.number(key + "w")
	var h: float = L1Layout.number(key + "h")
	var gap: float = L1Layout.number(key + "gap")
	var step: float = w + gap
	var cols: int = GlassScreen.FRONT_SLOTS
	var left: float = row.size.x - L1Layout.number(key + "right") - (cols * step - gap)
	var top: float = L1Layout.number(key + "y")
	for i: int in GlassScreen.BOARD_SLOTS:
		var p: Vector2 = Vector2(left + i * step, top)
		if i >= cols:
			p.x = left + (i - cols + 0.5) * step
			p.y += h + gap - L1Layout.number(key + "overlap")
		var mark: Polygon2D = Polygon2D.new()
		mark.name = "Slot_%d" % i
		mark.position = p
		mark.polygon = GlassBox.hexagon(Rect2(0, 0, w, h), L1Layout.number(key + "point"))
		mark.color = Color("f0d68a") if i == lit else Color("c8d2cd38")
		row.add_child(mark)


func _open_scroll(rect: Rect2) -> void:
	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.position = rect.position
	scroll.size = rect.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_surface.add_child(scroll)
	_contents = L1ColumnArt.area(Rect2())
	_contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_contents)
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	var width: float = L1Layout.number("panel.scroll.w")
	var radius: int = int(L1Layout.number("panel.scroll.radius"))
	bar.add_theme_stylebox_override("scroll", _scroll_style(Color("00000073"), width, radius))
	for style: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(style, _scroll_style(Color("7d8a86"), width, radius))
	var fade: TextureRect = _scroll_fade(rect)
	bar.changed.connect(_update_fade.bind(bar, fade))
	bar.value_changed.connect(func(_value_now: float) -> void: _update_fade(bar, fade))


func _scroll_fade(rect: Rect2) -> TextureRect:
	var h: float = L1Layout.number("panel.fade.h")
	var left: float = maxf(rect.position.x, L1Layout.number("panel.fade.x"))
	var right: float = minf(rect.end.x, _surface.size.x - L1Layout.number("panel.fade.right"))
	var ramp: GradientTexture2D = L1ColumnArt.gradient(
		[Color(SLATE_DARK + "00"), Color(SLATE_DARK)], [0.0, 1.0], Vector2.ZERO, Vector2.DOWN
	)
	var fade: TextureRect = L1ColumnArt.picture(ramp, Rect2(left, rect.end.y - h, right - left, h))
	fade.hide()
	_surface.add_child(fade)
	return fade


static func _update_fade(bar: VScrollBar, fade: Control) -> void:
	fade.visible = bar.value + bar.page < bar.max_value


static func _scroll_style(tint: Color, width: float, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = tint
	style.content_margin_left = width
	style.set_corner_radius_all(radius)
	return style


func _outline(rect: Rect2, radius: float, width: float, tint: Color) -> void:
	var ring: GlassBox = _box(rect, radius, "00000000")
	ring.border_width = width
	ring.border_colour = tint
	ring.refresh()
	_surface.add_child(ring)


static func _shadow(key: String, colour: String) -> Dictionary:
	return L1ColumnArt.shadow(L1Layout.number(key + ".y"), L1Layout.number(key + ".blur"), colour)


static func _box(rect: Rect2, radius: float, fill: String) -> GlassBox:
	var box: GlassBox = GlassBox.new()
	box.position = rect.position
	box.box_size = rect.size
	box.radii = Vector4.ONE * radius
	box.layers = [{"kind": "colour", "colour": fill}]
	box.refresh()
	return box


## Only the portion of a miniature inside the scroll window can open its detail.
func heap_target_at(at: Vector2) -> Dictionary:
	if _heap_targets.is_empty():
		return {}
	var canvas: Vector2 = _screen._stage.get_global_transform_with_canvas() * at
	if not Rect2(Vector2.ZERO, scroll.size).has_point(scroll.make_canvas_position_local(canvas)):
		return {}
	for target: Dictionary in _heap_targets:
		var node: Control = target["node"]
		var poly: PackedVector2Array = target["poly"]
		if Geometry2D.is_point_in_polygon(node.make_canvas_position_local(canvas), poly):
			return target
	return {}


func _process(_delta: float) -> void:
	# Scrolling can change the card under a stationary pointer.
	if not _heap_targets.is_empty() and _mouse.x >= 0.0:
		_screen._tips.hover(_screen._stage.make_canvas_position_local(_mouse))


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_MOUSE_EXIT, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		_mouse = Vector2(-1, -1)


func _input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_mouse = motion.position
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.keycode == KEY_ESCAPE and key.pressed and not key.echo:
		get_viewport().set_input_as_handled()
		close_requested.emit()
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or _surface == null:
		return
	var where: Vector2 = _surface.make_canvas_position_local(click.position)
	var outside: bool = not Rect2(Vector2.ZERO, _surface.size).has_point(where)
	if click.pressed and outside:
		get_viewport().set_input_as_handled()
		if click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_outside_button = click.button_index
	elif not click.pressed and _outside_button == click.button_index:
		get_viewport().set_input_as_handled()
		close_requested.emit()
