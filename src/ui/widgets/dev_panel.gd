extends PanelContainer
## The dev panel (PLAN item 7): the seed, add gold, spawn a unit to hand, set the tier, skip a
## turn. Each button calls the port's dev action and shows the reason string it returns.
## Only shown when "Show dev panel" is on in Settings; then the Dev token (or the ` key) toggles it.

signal changed
## The owner typed a seed and asked to replay: the app starts a new game from it.
signal replay_requested(game_seed: int)
signal turn_skipped

const UiTheme := preload("res://src/ui/ui_theme.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const Data := preload("res://src/ui/view_data.gd")

const GOLD_STEP: int = 10
const ROW_H: float = 122.0

var port: GamePort

var _seed_label: Label
var _seed_input: LineEdit
var _units: OptionButton
var _golden: CheckBox
var _tier: SpinBox
var _result: Label
var _ids: PackedStringArray = []


func _init() -> void:
	add_theme_stylebox_override("panel", UiTheme.flat_box(UiTheme.BIRCH, UiTheme.NIGHTSHADE, 5, 18))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var head: HBoxContainer = HBoxContainer.new()
	head.add_theme_constant_override("separation", 24)
	head.add_child(UiTheme.head("Dev panel", UiTheme.FONT_BODY + 2))
	_seed_label = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.TEXT_DIM)
	head.add_child(_seed_label)
	box.add_child(head)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	var seed_row: HBoxContainer = _row()
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = "seed"
	_seed_input.custom_minimum_size = Vector2(170, ROW_H)
	_seed_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_seed_input.text_submitted.connect(func(_text: String) -> void: _on_replay())
	seed_row.add_child(_seed_input)
	seed_row.add_child(_action("New game", _on_replay, true))
	grid.add_child(seed_row)
	grid.add_child(_action("Add %d gold" % GOLD_STEP, _on_add_gold))
	_units = OptionButton.new()
	_units.focus_mode = Control.FOCUS_NONE
	_units.custom_minimum_size = Vector2(460, ROW_H)
	_units.clip_text = true
	grid.add_child(_units)
	var spawn_row: HBoxContainer = _row()
	_golden = CheckBox.new()
	_golden.text = "Golden"
	_golden.focus_mode = Control.FOCUS_NONE
	_golden.custom_minimum_size = Vector2(0, ROW_H)
	spawn_row.add_child(_golden)
	spawn_row.add_child(_action("Spawn", _on_spawn, true))
	grid.add_child(spawn_row)
	var tier_row: HBoxContainer = _row()
	_tier = SpinBox.new()
	_tier.min_value = 1
	_tier.max_value = 6
	_tier.value = 1
	_tier.custom_minimum_size = Vector2(170, ROW_H)
	_tier.get_line_edit().add_theme_font_size_override("font_size", UiTheme.FONT_SMALL)
	tier_row.add_child(_tier)
	tier_row.add_child(_action("Set tier", _on_set_tier, true))
	grid.add_child(tier_row)
	grid.add_child(_action("Skip turn (no fight)", _on_skip))
	_result = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.MUTE)
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result.custom_minimum_size = Vector2(0, 44)
	box.add_child(_result)


func _row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	return row


func setup(game_port: GamePort) -> void:
	port = game_port
	_units.clear()
	_ids.clear()
	for unit: Dictionary in port.library_units():
		_ids.append(Data.s(unit, "id"))
		_units.add_item("T%d  %s" % [Data.i(unit, "tier", 1), Data.s(unit, "name")])
	refresh()


func refresh() -> void:
	var game_seed: int = port.get_seed() if port != null else -1
	_seed_label.text = "Seed: %s" % (str(game_seed) if game_seed >= 0 else "none")
	if port != null:
		_tier.value = Data.i(port.get_state(), "tier", 1)


func _action(text: String, on_press: Callable, fill: bool = false) -> Button:
	var button: Button = UiTheme.button(text, 0, UiTheme.FONT_SMALL)
	button.custom_minimum_size = Vector2(0, ROW_H)
	if fill:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(on_press)
	return button


func show_result(action: String, reason: String) -> void:
	_result.text = "%s: %s" % [action, "done" if reason.is_empty() else reason]


## Starts a new game from the typed seed (a whole number, 0 or more).
func _on_replay() -> void:
	var text: String = _seed_input.text.strip_edges()
	if not text.is_valid_int() or text.to_int() < 0:
		show_result("New game", "type a whole number")
		return
	replay_requested.emit(text.to_int())


func _on_add_gold() -> void:
	show_result("Add gold", port.dev_add_gold(GOLD_STEP))
	changed.emit()


func _on_spawn() -> void:
	var index: int = _units.selected
	if index < 0 or index >= _ids.size():
		show_result("Spawn", "pick a unit first")
		return
	show_result("Spawn", port.dev_spawn_to_hand(_ids[index], _golden.button_pressed))
	changed.emit()


func _on_set_tier() -> void:
	show_result("Set tier", port.dev_set_tier(int(_tier.value)))
	changed.emit()


func _on_skip() -> void:
	var reason: String = port.dev_skip_turn()
	show_result("Skip turn", reason)
	if reason.is_empty():
		turn_skipped.emit()
	else:
		changed.emit()
