extends Control
## Build any two boards from the unit library and fight them (PLAN item 6). Tap a library unit,
## then tap a slot (or drag it there); tap a placed unit to remove it, or drag it to another slot.
## Fight hands both boards to the port (CombatSandbox.fight through the adapter). The Scenarios
## tab lists the mechanics library's scenes: one tap loads both boards (CombatSandbox
## .load_scenario), shows the title and what to watch, and Fight plays it at its seed.

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

const LIBRARY_CARD_WIDTH: float = 124.0
const POCKET: float = 165.0
const TAP: float = 122.0
## Side 0 is yours (bottom board), side 1 the enemy (top board).
const ZONES: PackedStringArray = ["own", "enemy"]

var port: GamePort
## [side 0, side 1], each 7 entries of null or {"def_id": String, "golden": bool}.
var boards: Array = [[], []]
var fight_seed: int = 1
## The loaded scenario's title ("" when the boards weren't loaded from one), for the fight title.
var scenario_title: String = ""

var _units: Array[Dictionary] = []
var _by_id: Dictionary[String, Dictionary] = {}
var _tier_filter: int = 0
var _tiers: Array = [1, 1]
var _scenario_id: String = ""
var _scenario_watch: String = ""
## The loaded scenario was changed by hand since it was loaded.
var _edited: bool = false
var _units_box: VBoxContainer
var _scenarios_box: ScrollContainer
var _scenario_list: VBoxContainer
var _tab_buttons: Array[Button] = []
var _banner: Label
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
	UiTheme.add_table(self)
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
	side_box.custom_minimum_size = Vector2(474, 0)
	_detail = CardDetail.new()
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_box.add_child(_detail)
	_toast = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.INK)
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
	_render_scenarios()
	render_boards()


func _build_library() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(468, 0)
	column.add_theme_constant_override("separation", 8)
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	for tab: String in ["Units", "Scenarios"]:
		var button: Button = UiTheme.button(tab, 0, UiTheme.FONT_SMALL)
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, TAP)
		button.pressed.connect(show_tab.bind(tab))
		tabs.add_child(button)
		_tab_buttons.append(button)
	column.add_child(tabs)
	_scenarios_box = ScrollContainer.new()
	_scenarios_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scenarios_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scenario_list = VBoxContainer.new()
	_scenario_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scenario_list.add_theme_constant_override("separation", 10)
	_scenarios_box.add_child(_scenario_list)
	column.add_child(_scenarios_box)
	_units_box = VBoxContainer.new()
	_units_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_units_box.add_theme_constant_override("separation", 8)
	column.add_child(_units_box)
	var filters: HBoxContainer = HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	var filter: OptionButton = OptionButton.new()
	filter.focus_mode = Control.FOCUS_NONE
	filter.custom_minimum_size = Vector2(0, TAP)
	filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for tier: int in 7:
		filter.add_item("All tiers" if tier == 0 else "Tier %d" % tier)
	filter.item_selected.connect(_set_filter)
	filters.add_child(filter)
	_golden = CheckBox.new()
	_golden.text = "Golden"
	_golden.focus_mode = Control.FOCUS_NONE
	_golden.custom_minimum_size = Vector2(0, TAP)
	filters.add_child(_golden)
	_units_box.add_child(filters)
	_library_zone = Interactive.new()
	_library_zone.zone = "library"
	_library_zone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_wire(_library_zone)
	_units_box.add_child(_library_zone)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_library_zone.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 26)
	_grid.add_theme_constant_override("v_separation", 26)
	var pad: MarginContainer = MarginContainer.new()
	for side_name: String in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_" + side_name, 10)
	pad.add_child(_grid)
	scroll.add_child(pad)
	show_tab("Units")
	return column


## "Units" (the library grid) or "Scenarios" (the scene list).
func show_tab(tab: String) -> void:
	_units_box.visible = tab == "Units"
	_scenarios_box.visible = tab == "Scenarios"
	for button: Button in _tab_buttons:
		button.set_pressed_no_signal(button.text == tab)


func _render_scenarios() -> void:
	for child: Node in _scenario_list.get_children():
		_scenario_list.remove_child(child)
		child.queue_free()
	var list: Array[Dictionary] = port.scenarios()
	if list.is_empty():
		_scenario_list.add_child(
			_wrapped(
				"No scenarios found in content/scenarios.", UiTheme.FONT_SMALL, UiTheme.TEXT_DIM
			)
		)
	for scenario: Dictionary in list:
		_scenario_list.add_child(_scenario_entry(scenario))


func _scenario_entry(scenario: Dictionary) -> PanelContainer:
	var id: String = Data.s(scenario, "id")
	var panel: PanelContainer = PanelContainer.new()
	var box_style: StyleBoxFlat = UiTheme.flat_box(
		UiTheme.BIRCH, UiTheme.ACORN if id == _scenario_id else UiTheme.INK, 4, 12
	)
	box_style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", box_style)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	column.add_child(_wrapped(Data.s(scenario, "title"), UiTheme.FONT_BODY, UiTheme.TEXT))
	var names: PackedStringArray = []
	for unit_id: Variant in Data.a(scenario, "units"):
		var def: Dictionary = _by_id.get(str(unit_id), {})
		names.append(Data.s(def, "name", str(unit_id)))
	column.add_child(
		_wrapped(
			"Library entry %d · %s" % [Data.i(scenario, "entry"), ", ".join(names)],
			UiTheme.FONT_SMALL,
			UiTheme.HEADING
		)
	)
	column.add_child(
		_wrapped("Watch: " + Data.s(scenario, "watch"), UiTheme.FONT_SMALL, UiTheme.TEXT)
	)
	var note: String = Data.s(scenario, "note")
	if not note.is_empty():
		column.add_child(_wrapped(note, UiTheme.FONT_SMALL, UiTheme.TEXT_DIM))
	var load_button: Button = UiTheme.button("Load both boards", 0, UiTheme.FONT_SMALL)
	load_button.name = "Load_" + id
	load_button.pressed.connect(load_scenario.bind(id))
	column.add_child(load_button)
	return panel


static func _wrapped(text: String, font_size: int, colour: Color) -> Label:
	var label: Label = UiTheme.label(text, font_size, colour)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(380, 0)
	return label


## Loads a scenario's two boards (and tiers and seed) from the port; Fight then plays it.
func load_scenario(id: String) -> void:
	var result: Dictionary = port.load_scenario(id)
	if result.has("error"):
		_toast.text = Data.s(result, "error")
		return
	var loaded: Array = Data.a(result, "boards")
	for side: int in 2:
		var board: Array = loaded[side] if side < loaded.size() else []
		var full: Array = board.duplicate(true)
		full.resize(BoardView.SLOTS)
		boards[side] = full
	fight_seed = Data.i(result, "seed", 1)
	_edited = false
	var tiers: Array = Data.a(result, "tiers")
	_tiers = tiers if tiers.size() == 2 else [1, 1]
	_scenario_id = id
	for scenario: Dictionary in port.scenarios():
		if Data.s(scenario, "id") == id:
			scenario_title = Data.s(scenario, "title")
			_scenario_watch = Data.s(scenario, "watch")
	_selected = {}
	_toast.text = ""
	_detail.show_empty()
	_show_banner(false)
	_render_scenarios()
	render_boards()


func _show_banner(edited: bool) -> void:
	_banner.visible = not _scenario_id.is_empty()
	_banner.text = (
		"%s%s. Watch: %s" % [scenario_title, " (edited)" if edited else "", _scenario_watch]
	)


## A loaded scenario's boards were changed by hand: say so, and fight at the next seeds.
func _mark_edited() -> void:
	if not _scenario_id.is_empty():
		_edited = true
		_show_banner(true)


func _build_centre() -> VBoxContainer:
	var centre: VBoxContainer = VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_theme_constant_override("separation", 10)
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	var back: Button = UiTheme.button("Menu", 140)
	back.pressed.connect(func() -> void: menu_requested.emit())
	bar.add_child(back)
	var title: Label = UiTheme.head("Sandbox", UiTheme.FONT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title)
	var clear: Button = UiTheme.button("Clear boards", 200)
	clear.pressed.connect(clear_boards)
	bar.add_child(clear)
	var fight: Button = UiTheme.button("Fight!", 200, UiTheme.FONT_BODY + 6)
	UiTheme.make_primary(fight)
	fight.pressed.connect(_on_fight)
	bar.add_child(fight)
	centre.add_child(bar)
	_banner = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.INK)
	_banner.clip_text = true
	_banner.custom_minimum_size = Vector2(0, 80)
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.visible = false
	centre.add_child(_banner)
	for side: int in [1, 0]:
		var holder: CenterContainer = CenterContainer.new()
		holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var board: BoardView = BoardView.new()
		board.configure(ZONES[side], POCKET, side == 0)
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
		card.show_unit(UnitViews.from_def(def), CardView.Mode.MINI)
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
				card.show_unit(_placed_view(Data.entry(board, slot)), CardView.Mode.BOARD)
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
	var view: Dictionary = UnitViews.from_def(def, Data.b(entry, "golden", false))
	for key: String in ["attack", "health"]:
		if entry.has(key):
			view[key] = Data.i(entry, key, 0)
	if entry.has("display_name"):
		view["name"] = Data.s(entry, "display_name")
	return view


func clear_boards() -> void:
	for side: int in 2:
		var board: Array = boards[side]
		board.fill(null)
	_selected = {}
	_tiers = [1, 1]
	_scenario_id = ""
	_edited = false
	scenario_title = ""
	_show_banner(false)
	_render_scenarios()
	render_boards()
	_detail.show_empty()


## Overrides a placed unit's Attack and Health for this fight (SPEC 7 set_board), e.g. a 40/70
## unit to try Nightshade against a tall board. The numbers replace the golden-doubled stats.
func set_stats(side: int, slot: int, attack: int, health: int) -> void:
	_mark_edited()
	var board: Array = boards[side]
	var entry: Dictionary = Data.entry(board, slot)
	if entry.is_empty():
		return
	entry["attack"] = maxi(attack, 0)
	entry["health"] = maxi(health, 1)
	board[slot] = entry
	render_boards()
	_detail.show_unit(_placed_view(entry), "Tap another slot to move it")


func reset_stats(side: int, slot: int) -> void:
	_mark_edited()
	var board: Array = boards[side]
	var entry: Dictionary = Data.entry(board, slot)
	if entry.is_empty():
		return
	entry.erase("attack")
	entry.erase("health")
	render_boards()
	_detail.show_unit(_placed_view(entry), "Tap another slot to move it")


## Attack and Health boxes plus Set / Reset, under the selected board unit.
func _add_stat_editor(side: int, slot: int) -> void:
	var view: Dictionary = _view_at(ZONES[side], slot)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var boxes: Array[SpinBox] = []
	for key: String in ["attack", "health"]:
		row.add_child(UiTheme.label(key.capitalize(), UiTheme.FONT_SMALL, UiTheme.TEXT_DIM))
		var box: SpinBox = SpinBox.new()
		box.name = key.capitalize() + "Box"
		box.min_value = 0 if key == "attack" else 1
		box.max_value = 999
		box.value = Data.i(view, key, 1)
		box.custom_minimum_size = Vector2(100, TAP)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(box)
		boxes.append(box)
	_detail.actions.add_child(row)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	var apply: Button = UiTheme.button("Set stats", 0, UiTheme.FONT_SMALL)
	apply.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply.pressed.connect(
		func() -> void: set_stats(side, slot, int(boxes[0].value), int(boxes[1].value))
	)
	buttons.add_child(apply)
	var reset: Button = UiTheme.button("Reset", 0, UiTheme.FONT_SMALL)
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(func() -> void: reset_stats(side, slot))
	buttons.add_child(reset)
	_detail.actions.add_child(buttons)


## Puts a library unit into a slot (replacing what's there).
func place(side: int, slot: int, def_id: String, golden: bool) -> void:
	_mark_edited()
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
			_add_stat_editor(side, index)
			_detail.add_action("Remove", _remove_selected)
	_render_library()
	render_boards()


func _move(side: int, from_slot: int, to_slot: int) -> void:
	_mark_edited()
	var board: Array = boards[side]
	var moving: Variant = board[from_slot]
	board[from_slot] = board[to_slot]
	board[to_slot] = moving
	_selected = {}
	render_boards()


func _remove_selected() -> void:
	_mark_edited()
	var side: int = ZONES.find(str(_selected.get("zone", "")))
	if side >= 0:
		boards[side][Data.i(_selected, "index", -1)] = null
	_selected = {}
	_detail.show_empty()
	render_boards()


func _drag_data(zone: String, index: int) -> Variant:
	if _view_at(zone, index).is_empty():
		return null
	return {"zone": zone, "index": index}


func _drag_preview(zone: String, index: int) -> Control:
	var holder: Control = Control.new()
	var card: CardView = CardView.new()
	card.show_unit(_view_at(zone, index), CardView.Mode.MINI)
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
		_mark_edited()
		render_boards()
	elif from_zone == "library":
		place(
			ZONES.find(zone), index, str(_units[from_index].get("id", "")), _golden.button_pressed
		)
	else:
		_move(ZONES.find(zone), from_index, index)


func _on_fight() -> void:
	var result: Dictionary = port.sandbox_fight(boards, fight_seed, _tiers)
	# An unedited scenario replays at its own seed, so its watch line stays true.
	if _scenario_id.is_empty() or _edited:
		fight_seed += 1
	if result.has("error"):
		_toast.text = str(result["error"])
		return
	fight_ready.emit(result)
