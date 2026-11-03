extends PanelContainer
## The dev panel (PLAN item 7): the seed, add gold, spawn a unit to hand, set the tier, skip a
## turn. Each button calls the port's dev action and shows the reason string it returns.
## The recruit screen toggles it (Dev button, or the ` key).

signal changed
signal turn_skipped

const UiTheme := preload("res://src/ui/ui_theme.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const Data := preload("res://src/ui/view_data.gd")

const GOLD_STEP: int = 10

var port: GamePort

var _seed_label: Label
var _units: OptionButton
var _golden: CheckBox
var _tier: SpinBox
var _result: Label
var _ids: PackedStringArray = []


func _init() -> void:
	add_theme_stylebox_override(
		"panel", UiTheme.flat_box(Color("2b2433"), UiTheme.NIGHTSHADE, 3, 12)
	)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.add_child(UiTheme.label("Dev panel", UiTheme.FONT_BODY + 2, UiTheme.GOLD))
	_seed_label = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.TEXT_DIM)
	box.add_child(_seed_label)
	box.add_child(_action("Add %d gold" % GOLD_STEP, _on_add_gold))
	_units = OptionButton.new()
	_units.focus_mode = Control.FOCUS_NONE
	_units.add_theme_font_size_override("font_size", UiTheme.FONT_SMALL)
	_units.custom_minimum_size = Vector2(0, 56)
	box.add_child(_units)
	var spawn_row: HBoxContainer = HBoxContainer.new()
	_golden = CheckBox.new()
	_golden.text = "Golden"
	_golden.focus_mode = Control.FOCUS_NONE
	spawn_row.add_child(_golden)
	var spawn: Button = _action("Spawn to hand", _on_spawn)
	spawn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spawn_row.add_child(spawn)
	box.add_child(spawn_row)
	var tier_row: HBoxContainer = HBoxContainer.new()
	_tier = SpinBox.new()
	_tier.min_value = 1
	_tier.max_value = 6
	_tier.value = 1
	_tier.custom_minimum_size = Vector2(110, 56)
	tier_row.add_child(_tier)
	var set_tier: Button = _action("Set tier", _on_set_tier)
	set_tier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tier_row.add_child(set_tier)
	box.add_child(tier_row)
	box.add_child(_action("Skip turn (no fight)", _on_skip))
	_result = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.SELECT)
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result.custom_minimum_size = Vector2(0, 48)
	box.add_child(_result)


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


func _action(text: String, on_press: Callable) -> Button:
	var button: Button = UiTheme.button(text, 0, UiTheme.FONT_SMALL)
	button.custom_minimum_size = Vector2(0, 56)
	button.pressed.connect(on_press)
	return button


func show_result(action: String, reason: String) -> void:
	_result.text = "%s: %s" % [action, "done" if reason.is_empty() else reason]


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
