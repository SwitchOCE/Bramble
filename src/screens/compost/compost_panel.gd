class_name CompostPanel
extends GlassScreen
## A detached, read-only spread. It stays above screen redraws while a fight keeps playing.

signal close_requested

const PANE: Rect2 = Rect2(490, 72, 940, 936)
const AREA: Rect2 = Rect2(530, 206, 860, 758)
const CARD_HEIGHT: float = 244.0
const STEP: float = 164.0

var scroll: ScrollContainer
var entries: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_fit)
	super()


func _build() -> void:
	scroll = null
	var dim := ColorRect.new()
	dim.color = BrowserLook.DIM
	dim.size = _stage.size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.add_child(dim)
	var pane: GlassBox = GlassUi.pane(_back, PANE)
	pane.radii = Vector4.ONE * BrowserLook.PANE_RADIUS
	pane.refresh()
	BrowserLook.label(_front, "Compost", Vector2(534, 100), 44, true, BrowserLook.HEADING_COLOUR)
	var count_label: GlassText = BrowserLook.label(
		_front,
		"%d card%s" % [entries.size(), "" if entries.size() == 1 else "s"],
		Vector2(754, 120),
		24
	)
	count_label.name = "Count"
	BrowserLook.filter_button(
		_front, "Close", Vector2(1230, 108), 150, close_requested.emit, false, true
	)
	if entries.is_empty():
		BrowserLook.label(_front, "Your Compost is empty.", Vector2(570, 360), 32)
		BrowserLook.label(_front, "Bury a shop unit to add it here.", Vector2(570, 412), 24)
		return
	BrowserLook.label(_front, "Newest first", Vector2(534, 166), 22)
	_build_spread()


func _build_spread() -> void:
	scroll = ScrollContainer.new()
	scroll.name = "CompostScroll"
	scroll.position = AREA.position
	scroll.size = AREA.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_back.add_child(scroll)
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	var track := StyleBoxEmpty.new()
	track.content_margin_left = 12
	bar.add_theme_stylebox_override("scroll", track)
	for key: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = BrowserLook.SCROLL_COLOUR
		style.set_corner_radius_all(6)
		bar.add_theme_stylebox_override(key, style)
	var spread := Control.new()
	spread.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spread.custom_minimum_size = Vector2(820, (entries.size() - 1) * STEP + CARD_HEIGHT + 16)
	scroll.add_child(spread)
	for i: int in entries.size():
		var card: Dictionary = entries[entries.size() - 1 - i]
		var at := Vector2(16 + (i % 2) * 16, 8 + i * STEP)
		# The shared tooltip resets the card's z after hover; keep the spread order on its parent.
		var leaf := Control.new()
		leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		leaf.position = at
		leaf.z_index = entries.size() - i
		spread.add_child(leaf)
		var node: Control = _make_card("compost", card, {})
		leaf.add_child(node)
		BrowserLook.label(
			spread,
			str(card.get("name", "")),
			Vector2(224, at.y + 28),
			30,
			true,
			BrowserLook.HEADING_COLOUR
		)
		BrowserLook.label(
			spread,
			"%d Attack · %d Health" % [_i(card.get("attack", 0)), _i(card.get("health", 0))],
			Vector2(224, at.y + 76),
			26
		)
		BrowserLook.label(spread, "Tier %d" % _i(card.get("tier", 1)), Vector2(224, at.y + 114), 22)
		var width: float = 790 - at.x
		var w: float = node.size.x
		_targets.append(
			{
				"kind": "compost",
				"index": i,
				"node": node,
				"card": card,
				"poly":
				PackedVector2Array(
					[
						Vector2.ZERO,
						Vector2(width, 0),
						Vector2(width, STEP),
						Vector2(w, STEP),
						Vector2(w, CARD_HEIGHT),
						Vector2(0, CARD_HEIGHT)
					]
				)
			}
		)


func _make_card(kind: String, data: Dictionary, extra: Dictionary) -> Control:
	if kind == "compost":
		return _unit_card(data, CARD_HEIGHT)
	return super(kind, data, extra)


## The spread's newest card is painted on top; clipped cards cannot receive a hover.
func _target_at(at: Vector2, _cards_only: bool) -> Dictionary:
	if not AREA.has_point(at):
		return {}
	for target: Dictionary in _targets:
		var node: Control = target["node"]
		var poly: PackedVector2Array = target["poly"]
		if Geometry2D.is_point_in_polygon(_to_local_of(node, at), poly):
			return target
	return {}


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var key: InputEventKey = event as InputEventKey
	if key != null:
		if key.keycode == KEY_ESCAPE and key.pressed and not key.echo:
			get_viewport().set_input_as_handled()
			close_requested.emit()
			return
		# Keep fight skip/leaderboard keys out of the screen beneath this panel.
		if key.keycode != KEY_F11:
			get_viewport().set_input_as_handled()
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_pointer = _stage.make_canvas_position_local(motion.position)
		_tips.hover(_pointer)
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and not PANE.has_point(_stage.make_canvas_position_local(click.position)):
		get_viewport().set_input_as_handled()
		if click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
			close_requested.emit()


## Escape lives in _input, before focused controls and the game's pause shortcut.
func _unhandled_key_input(_event: InputEvent) -> void:
	pass


## Pointer tracking uses _input even over the scroll's children. Entering one is not leaving
## this viewer; actual window/focus exits still clear the shared tooltip through the base.
func _notification(what: int) -> void:
	if what != NOTIFICATION_MOUSE_EXIT:
		super(what)


func _gui_input(_event: InputEvent) -> void:
	pass


func _draw() -> void:
	pass
