extends Control
## Build any two boards from the unit library and fight them (PLAN item 6). Tap a library unit,
## then tap a slot (or drag it there); tap a placed unit to remove it, or drag it to another slot.
## Fight hands both boards to the port (CombatSandbox.fight through the adapter).

signal fight_ready(result: Dictionary)
signal menu_requested

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")

const LIBRARY_CARD_WIDTH: float = 118.0
const BOARD_CARD_WIDTH: float = 138.0
## Side 0 is yours (bottom board), side 1 the enemy (top board).
const ZONES: PackedStringArray = ["own", "enemy"]

var port: GamePort
## [side 0, side 1], each 7 entries of null or {"def_id": String, "golden": bool}.
var boards: Array = [[], []]
var fight_seed: int = 1

var _units: Array[Dictionary] = []
var _by_id: Dictionary[String, Dictionary] = {}
var _tier_filter: int = 0
var _golden: CheckBox
var _grid: GridContainer
var _library_zone: Interactive
var _board_views: Array[BoardView] = []
var _detail: CardDetail
var _toast: Label
## {"zone", "index"} of the tapped library unit or placed unit; {} for none.
var _selected: Dictionary = {}


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: int in 2:
		var empty: Array = []
		empty.resize(BoardView.SLOTS)
		boards[side] = empty
	var background: ColorRect = ColorRect.new()
	background.color = UiTheme.BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side_name: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side_name, 14)
	add_child(margin)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	margin.add_child(columns)
	columns.add_child(_build_library())
	columns.add_child(_build_centre())
	var side_box: VBoxContainer = VBoxContainer.new()
	side_box.custom_minimum_size = Vector2(360, 0)
	_detail = CardDetail.new()
	_detail.set_card_width(280)
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_box.add_child(_detail)
	_toast = UiTheme.label("", UiTheme.FONT_BODY, UiTheme.SELECT)
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.custom_minimum_size = Vector2(0, 90)
	side_box.add_child(_toast)
	columns.add_child(side_box)


func setup(game_port: GamePort) -> void:
	port = game_port
	_units = port.library_units()
	_by_id.clear()
	for def: Dictionary in _units:
		_by_id[str(def.get("id", ""))] = def
	_render_library()
	render_boards()


func _build_library() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(430, 0)
	column.add_theme_constant_override("separation", 8)
	column.add_child(UiTheme.label("Unit library", UiTheme.FONT_BODY, UiTheme.TEXT_DIM))
	var filters: HBoxContainer = HBoxContainer.new()
	filters.add_theme_constant_override("separation", 4)
	for tier: int in 7:
		var button: Button = UiTheme.button(
			"All" if tier == 0 else str(tier), 52, UiTheme.FONT_SMALL
		)
		button.custom_minimum_size = Vector2(52, 52)
		button.pressed.connect(_set_filter.bind(tier))
		filters.add_child(button)
	column.add_child(filters)
	_golden = CheckBox.new()
	_golden.text = "Place as golden"
	_golden.focus_mode = Control.FOCUS_NONE
	column.add_child(_golden)
	_library_zone = Interactive.new()
	_library_zone.zone = "library"
	_library_zone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_wire(_library_zone)
	column.add_child(_library_zone)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_library_zone.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	var pad: MarginContainer = MarginContainer.new()
	for side_name: String in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_" + side_name, 10)
	pad.add_child(_grid)
	scroll.add_child(pad)
	return column


func _build_centre() -> VBoxContainer:
	var centre: VBoxContainer = VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_theme_constant_override("separation", 10)
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	var back: Button = UiTheme.button("Menu", 110)
	back.pressed.connect(func() -> void: menu_requested.emit())
	bar.add_child(back)
	var title: Label = UiTheme.label("Sandbox", UiTheme.FONT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title)
	var clear: Button = UiTheme.button("Clear boards", 200)
	clear.pressed.connect(clear_boards)
	bar.add_child(clear)
	var fight: Button = UiTheme.button("Fight!", 200, UiTheme.FONT_TITLE - 4)
	fight.add_theme_stylebox_override("normal", UiTheme.flat_box(UiTheme.GOLD, UiTheme.INK, 3))
	fight.pressed.connect(_on_fight)
	bar.add_child(fight)
	centre.add_child(bar)
	for side: int in [1, 0]:
		var label_text: String = "Enemy board" if side == 1 else "Your board"
		centre.add_child(UiTheme.label(label_text, UiTheme.FONT_BODY, UiTheme.TEXT_DIM))
		var holder: CenterContainer = CenterContainer.new()
		holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var board: BoardView = BoardView.new()
		board.configure(ZONES[side], BOARD_CARD_WIDTH, side == 0, 16.0)
		for slot: Interactive in board.slots:
			_wire(slot)
		holder.add_child(board)
		centre.add_child(holder)
		_board_views.append(board)
	_board_views.reverse()
	return centre


func _wire(node: Interactive) -> void:
	node.tapped.connect(_on_tapped)
	node.hovered.connect(_on_hovered)
	node.drag_data_fn = _drag_data
	node.can_drop_fn = _can_drop
	node.drop_fn = _drop
	node.preview_fn = _drag_preview


func _set_filter(tier: int) -> void:
	_tier_filter = tier
	_render_library()


func _render_library() -> void:
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for i: int in _units.size():
		var def: Dictionary = _units[i]
		if _tier_filter != 0 and Data.i(def, "tier", 0) != _tier_filter:
			continue
		var card: CardView = CardView.new()
		card.show_unit(UnitViews.from_def(def), CardView.Mode.COMPACT)
		card.set_card_width(LIBRARY_CARD_WIDTH)
		card.zone = "library"
		card.index = i
		card.selected = (
			_selected.get("zone", "") == "library" and Data.i(_selected, "index", -1) == i
		)
		_wire(card)
		_grid.add_child(card)


func render_boards() -> void:
	for side: int in 2:
		var view: BoardView = _board_views[side]
		view.clear()
		view.clear_highlights()
		var board: Array = boards[side]
		for slot: int in BoardView.SLOTS:
			var entry: Variant = board[slot]
			if entry is Dictionary:
				var card: CardView = CardView.new()
				card.show_unit(_placed_view(Data.entry(board, slot)), CardView.Mode.FULL)
				card.zone = ZONES[side]
				card.index = slot
				_wire(card)
				view.place_card(card, slot)
	var zone: String = str(_selected.get("zone", ""))
	var index: int = Data.i(_selected, "index", -1)
	var side_selected: int = ZONES.find(zone)
	if side_selected >= 0 and _board_views[side_selected].cards[index] != null:
		_board_views[side_selected].cards[index].selected = true
	if zone == "library" or side_selected >= 0:
		for side: int in 2:
			for slot: int in BoardView.SLOTS:
				if boards[side][slot] == null:
					_board_views[side].slots[slot].highlight = UiTheme.DROP_OK


func _placed_view(entry: Dictionary) -> Dictionary:
	var def: Dictionary = _by_id.get(str(entry.get("def_id", "")), {})
	return UnitViews.from_def(def, Data.b(entry, "golden", false))


func clear_boards() -> void:
	for side: int in 2:
		var board: Array = boards[side]
		board.fill(null)
	_selected = {}
	render_boards()
	_detail.show_empty("")


## Puts a library unit into a slot (replacing what's there).
func place(side: int, slot: int, def_id: String, golden: bool) -> void:
	boards[side][slot] = {"def_id": def_id, "golden": golden}
	render_boards()


func _view_at(zone: String, index: int) -> Dictionary:
	if zone == "library":
		return (
			UnitViews.from_def(_units[index], _golden.button_pressed)
			if index >= 0 and index < _units.size()
			else {}
		)
	var side: int = ZONES.find(zone)
	if side < 0 or index < 0 or index >= BoardView.SLOTS:
		return {}
	var board: Array = boards[side]
	var placed: Dictionary = Data.entry(board, index)
	return {} if placed.is_empty() else _placed_view(placed)


func _on_hovered(zone: String, index: int, inside: bool) -> void:
	if not inside or not _selected.is_empty():
		return
	var view: Dictionary = _view_at(zone, index)
	if not view.is_empty():
		_detail.show_unit(view)


func _on_tapped(zone: String, index: int) -> void:
	var from_zone: String = str(_selected.get("zone", ""))
	var from_index: int = Data.i(_selected, "index", -1)
	var side: int = ZONES.find(zone)
	if side >= 0 and from_zone == "library":
		place(side, index, str(_units[from_index].get("id", "")), _golden.button_pressed)
		return
	if side >= 0 and from_zone == zone and from_index != index:
		_move(side, from_index, index)
		return
	if from_zone == zone and from_index == index or _view_at(zone, index).is_empty():
		_selected = {}
	else:
		_selected = {"zone": zone, "index": index}
	_detail.clear_actions()
	var view: Dictionary = _view_at(zone, index)
	if not _selected.is_empty():
		var hint: String = (
			"Tap a slot on either board to place it"
			if zone == "library"
			else "Tap another slot to move it"
		)
		_detail.show_unit(view, hint)
		if side >= 0:
			_detail.add_action("Remove", _remove_selected)
	_render_library()
	render_boards()


func _move(side: int, from_slot: int, to_slot: int) -> void:
	var board: Array = boards[side]
	var moving: Variant = board[from_slot]
	board[from_slot] = board[to_slot]
	board[to_slot] = moving
	_selected = {}
	render_boards()


func _remove_selected() -> void:
	var side: int = ZONES.find(str(_selected.get("zone", "")))
	if side >= 0:
		boards[side][Data.i(_selected, "index", -1)] = null
	_selected = {}
	_detail.show_empty("")
	render_boards()


func _drag_data(zone: String, index: int) -> Variant:
	if _view_at(zone, index).is_empty():
		return null
	return {"zone": zone, "index": index}


func _drag_preview(zone: String, index: int) -> Control:
	var holder: Control = Control.new()
	var card: CardView = CardView.new()
	card.show_unit(_view_at(zone, index), CardView.Mode.COMPACT)
	card.set_card_width(LIBRARY_CARD_WIDTH)
	card.modulate = Color(1, 1, 1, 0.85)
	card.position = -card.card_size / 2.0
	holder.add_child(card)
	return holder


func _can_drop(data: Variant, zone: String, index: int) -> bool:
	if not data is Dictionary:
		return false
	var drag: Dictionary = data
	var from_zone: String = str(drag.get("zone", ""))
	if zone == "library":
		return from_zone in ZONES
	if ZONES.find(zone) < 0:
		return false
	return from_zone == "library" or from_zone == zone and Data.i(drag, "index", -1) != index


func _drop(data: Variant, zone: String, index: int) -> void:
	var drag: Dictionary = data
	var from_zone: String = str(drag.get("zone", ""))
	var from_index: int = Data.i(drag, "index", -1)
	_selected = {}
	if zone == "library":
		boards[ZONES.find(from_zone)][from_index] = null
		render_boards()
	elif from_zone == "library":
		place(
			ZONES.find(zone), index, str(_units[from_index].get("id", "")), _golden.button_pressed
		)
	else:
		_move(ZONES.find(zone), from_index, index)


func _on_fight() -> void:
	var result: Dictionary = port.sandbox_fight(boards, fight_seed)
	fight_seed += 1
	if result.has("error"):
		_toast.text = str(result["error"])
		return
	fight_ready.emit(result)
