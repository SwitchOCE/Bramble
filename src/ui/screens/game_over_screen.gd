extends Control
## The end of a game: your placement, the final standings and your last board.
## Reads a SPEC 6.1 state whose phase is "game_over" (or one where you were eliminated).

signal menu_requested

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")

var _placement: Label
var _summary: Label
var _table: VBoxContainer
var _board: BoardView


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = UiTheme.BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 48)
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(columns)
	var left: VBoxContainer = VBoxContainer.new()
	left.add_theme_constant_override("separation", 16)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(left)
	left.add_child(UiTheme.label("Game over", UiTheme.FONT_TITLE, UiTheme.TEXT_DIM))
	_placement = UiTheme.label("", 120, UiTheme.HEADING)
	_placement.add_theme_color_override("font_outline_color", UiTheme.INK)
	_placement.add_theme_constant_override("outline_size", 12)
	left.add_child(_placement)
	_summary = UiTheme.label("", UiTheme.FONT_BODY)
	left.add_child(_summary)
	left.add_child(
		UiTheme.label("Your board in your last fight", UiTheme.FONT_BODY, UiTheme.TEXT_DIM)
	)
	_board = BoardView.new()
	_board.configure("final", 150.0, true, 16.0)
	left.add_child(_board)
	var menu: Button = UiTheme.button("Main menu", 300, UiTheme.FONT_TITLE - 4)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	left.add_child(menu)
	var right: VBoxContainer = VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.custom_minimum_size = Vector2(620, 0)
	columns.add_child(right)
	right.add_child(UiTheme.label("Final standings", UiTheme.FONT_TITLE - 4))
	_table = VBoxContainer.new()
	_table.add_theme_constant_override("separation", 8)
	right.add_child(_table)


func setup(port: GamePort) -> void:
	show_state(port.get_state(), port.get_last_combat())


## The board shown is the one the player brought to their last fight (its combat_start), because
## the core clears an eliminated player's board; with no fight on record, the state's board.
static func final_board(state: Dictionary, last_combat: Dictionary) -> Array:
	var events: Array = Data.a(last_combat, "events")
	if not events.is_empty():
		var start: Dictionary = Data.entry(events, 0)
		var ids: Array = Data.a(start, "player_ids")
		var side: int = ids.find(Data.i(state, "player_id", 0))
		var boards: Array = Data.a(start, "boards")
		if side >= 0 and side < boards.size():
			var board: Array = boards[side]
			return board
	return Data.a(state, "board")


func show_state(state: Dictionary, last_combat: Dictionary = {}) -> void:
	var placement: Variant = state.get("placement")
	_placement.text = (
		UiTheme.ordinal(Data.as_int(placement)) + " place" if placement != null else "-"
	)
	var last: Variant = state.get("last_combat")
	var summary: String = (
		"Round %d, tier %d." % [Data.i(state, "round", 0), Data.i(state, "tier", 1)]
	)
	if last is Dictionary:
		var fight: Dictionary = last
		summary += (
			" Last fight: %s, %d damage."
			% [_result_word(Data.i(fight, "winner", -1)), Data.i(fight, "damage", 0)]
		)
	_summary.text = summary
	_board.clear()
	var board: Array = final_board(state, last_combat)
	for slot: int in mini(board.size(), BoardView.SLOTS):
		var entry: Variant = board[slot]
		if entry is Dictionary:
			var card: CardView = CardView.new()
			var view: Dictionary = entry
			card.show_unit(view, CardView.Mode.FULL)
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_board.place_card(card, slot)
	_fill_table(Data.a(state, "standings"))


static func _result_word(winner: int) -> String:
	match winner:
		0:
			return "won"
		1:
			return "lost"
	return "tie"


## Sorted by placement; players still alive (the winner) come first by health.
func _fill_table(standings: Array) -> void:
	for child: Node in _table.get_children():
		_table.remove_child(child)
		child.queue_free()
	var rows: Array = standings.duplicate()
	rows.sort_custom(_before)
	for i: int in rows.size():
		var standing: Dictionary = rows[i]
		var placement: Variant = standing.get("placement")
		var place: int = Data.as_int(placement) if placement != null else i + 1
		var human: bool = Data.b(standing, "is_human", false)
		var panel: PanelContainer = PanelContainer.new()
		var fill: Color = UiTheme.PANEL_LIGHT if human else UiTheme.PANEL
		panel.add_theme_stylebox_override(
			"panel", UiTheme.flat_box(fill, UiTheme.GOLD if human else fill, 3, 8)
		)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		panel.add_child(row)
		var place_label: Label = UiTheme.label(
			UiTheme.ordinal(place), UiTheme.FONT_TITLE - 6, UiTheme.HEADING
		)
		place_label.custom_minimum_size = Vector2(90, 0)
		row.add_child(place_label)
		var name_label: Label = UiTheme.label(str(standing.get("name", "?")), UiTheme.FONT_BODY + 2)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(
			UiTheme.label(
				"Tier %d" % Data.i(standing, "tier", 1), UiTheme.FONT_BODY, UiTheme.TEXT_DIM
			)
		)
		var health: int = Data.i(standing, "health", 0)
		row.add_child(
			UiTheme.label(
				"%d health" % maxi(health, 0), UiTheme.FONT_BODY, UiTheme.HEALTH.lightened(0.3)
			)
		)
		_table.add_child(panel)


static func _before(a: Dictionary, b: Dictionary) -> bool:
	var pa: Variant = a.get("placement")
	var pb: Variant = b.get("placement")
	if pa == null and pb == null:
		return Data.i(a, "health", 0) > Data.i(b, "health", 0)
	if pa == null:
		return true
	if pb == null:
		return false
	return Data.as_int(pa) < Data.as_int(pb)
