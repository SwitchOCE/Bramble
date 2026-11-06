extends Control
## The end of a game: your placement carved big, your final board in its tray, how each round went,
## and the final standings. Reads a SPEC 6.1 state whose phase is "game_over" (or one where you were
## eliminated). The app passes the rounds it saw, and whether this beat your best.

signal menu_requested

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")

const POCKET: float = 150.0
const ROW_H: float = 92.0
const ROUND_TOKEN: float = 58.0

## Round tokens shown, for tests: each {round, result ("won", "lost", "tie"), damage}.
var round_log: Array = []

var _plaque: WoodPanel
var _placement: Label
var _summary: Label
var _best: Label
var _board: BoardView
var _rounds_panel: WoodPanel
var _rounds_head: Label
var _rounds: Control
var _table_panel: WoodPanel
var _table_head: Label
var _table: VBoxContainer
var _menu: LeafButton


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiTheme.add_table(self)
	_plaque = WoodPanel.new(WoodPanel.Kind.OAK)
	add_child(_plaque)
	_placement = UiTheme.label("", UiTheme.FONT_HUGE + 34)
	_placement.add_theme_font_override("font", UiTheme.title_font())
	_placement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plaque.add_child(_placement)
	_summary = UiTheme.head("", UiTheme.FONT_SMALL + 3)
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plaque.add_child(_summary)
	_best = UiTheme.burned("New best!", UiTheme.FONT_SMALL, UiTheme.INK)
	_best.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.GILT, 5, 10))
	_best.visible = false
	_plaque.add_child(_best)
	_board = BoardView.new()
	_board.configure("final", POCKET, true)
	add_child(_board)
	_rounds_panel = WoodPanel.new(WoodPanel.Kind.PAPER)
	add_child(_rounds_panel)
	_rounds_head = UiTheme.burned("Round by round", UiTheme.FONT_SMALL, UiTheme.MUTE)
	_rounds_panel.add_child(_rounds_head)
	_rounds = Control.new()
	_rounds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rounds_panel.add_child(_rounds)
	_table_panel = WoodPanel.new(WoodPanel.Kind.OAK)
	add_child(_table_panel)
	_table_head = UiTheme.burned("Final standings", UiTheme.FONT_SMALL)
	_table_panel.add_child(_table_head)
	_table = VBoxContainer.new()
	_table.add_theme_constant_override("separation", 0)
	_table_panel.add_child(_table)
	_menu = LeafButton.new()
	_menu.colour = LeafButton.Colour.MOSS
	_menu.set_face("Main menu")
	_menu.pressed.connect(func() -> void: menu_requested.emit())
	add_child(_menu)
	resized.connect(_layout)
	ready.connect(_layout)


func setup(port: GamePort, rounds: Array = [], new_best: bool = false) -> void:
	round_log = rounds
	_best.visible = new_best
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
	_summary.text = "Turn %d, tier %d" % [Data.i(state, "round", 0), Data.i(state, "tier", 1)]
	_board.clear()
	var board: Array = final_board(state, last_combat)
	for slot: int in mini(board.size(), BoardView.SLOTS):
		var entry: Variant = board[slot]
		if entry is Dictionary:
			var card: CardView = CardView.new()
			var view: Dictionary = entry
			card.show_unit(view, CardView.Mode.BOARD)
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_board.place_card(card, slot)
	_fill_rounds()
	_fill_table(Data.a(state, "standings"))
	_layout()


func _layout() -> void:
	var w: float = size.x
	if w < 10.0:
		return
	var top: float = maxf(0.0, (size.y - 1080.0) / 2.0)
	var tray: Vector2 = _board.tray_size()
	var left_x: float = 40.0
	_plaque.position = Vector2(left_x, top + 24.0)
	_plaque.size = Vector2(tray.x, 226)
	_placement.position = Vector2(0, 2)
	_placement.size = Vector2(tray.x, 150)
	_summary.position = Vector2(0, 152)
	_summary.size = Vector2(tray.x, 48)
	_best.size = _best.get_minimum_size()
	_best.position = Vector2(tray.x - _best.size.x - 22.0, 150)
	_board.position = Vector2(left_x, top + 268.0)
	_board.size = tray
	_rounds_panel.position = Vector2(left_x, top + 268.0 + tray.y + 16.0)
	_rounds_panel.size = Vector2(tray.x, 1080.0 - 268.0 - tray.y - 16.0 - 28.0)
	_rounds_head.position = Vector2(30, 14)
	_rounds_head.size = Vector2(tray.x - 60.0, 42)
	_rounds.position = Vector2(30, 60)
	_rounds.size = Vector2(tray.x - 60.0, _rounds_panel.size.y - 72.0)
	_place_rounds()
	var right_x: float = left_x + tray.x + 40.0
	var right_w: float = w - right_x - 40.0
	var leaf_h: float = 136.0
	_table_panel.position = Vector2(right_x, top + 24.0)
	_table_panel.size = Vector2(right_w, 1080.0 - 24.0 - leaf_h - 46.0)
	_table_head.position = Vector2(30, 14)
	_table_head.size = Vector2(right_w - 60.0, 42)
	_table.position = Vector2(20, 58)
	_table.size = Vector2(right_w - 40.0, _table_panel.size.y - 70.0)
	_menu.position = Vector2(right_x + (right_w - 520.0) / 2.0, top + 1080.0 - leaf_h - 24.0)
	_menu.size = Vector2(520, leaf_h)


## One token per round: moss for a win, red for a loss, pale for a tie, the round's number on it.
func _fill_rounds() -> void:
	for child: Node in _rounds.get_children():
		_rounds.remove_child(child)
		child.queue_free()
	for entry: Variant in round_log:
		var item: Dictionary = entry
		var result: String = Data.s(item, "result")
		var fill: Color = UiTheme.BIRCH
		var ink: Color = UiTheme.INK
		if result == "won":
			fill = UiTheme.MOSS
			ink = UiTheme.CREAM
		elif result == "lost":
			fill = UiTheme.HEALTH
			ink = UiTheme.CREAM
		var token: Label = UiTheme.number(str(Data.i(item, "round")), UiTheme.FONT_SMALL, ink)
		var face: StyleBoxFlat = UiTheme.flat_box(fill, UiTheme.INK, 4, 30)
		face.set_content_margin_all(0)
		token.add_theme_stylebox_override("normal", face)
		token.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		token.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		token.size = Vector2(ROUND_TOKEN, ROUND_TOKEN)
		_rounds.add_child(token)
	_place_rounds()


func _place_rounds() -> void:
	var columns: int = maxi(int((_rounds.size.x + 8.0) / (ROUND_TOKEN + 8.0)), 1)
	var i: int = 0
	for child: Node in _rounds.get_children():
		var token: Control = child as Control
		var row: int = floori(float(i) / columns)
		token.position = Vector2((i % columns) * (ROUND_TOKEN + 8.0), row * (ROUND_TOKEN + 6.0))
		i += 1


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
		_table.add_child(_standing_row(standing, place))


func _standing_row(standing: Dictionary, place: int) -> Control:
	var human: bool = Data.b(standing, "is_human", false)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, ROW_H)
	var face: StyleBoxFlat = UiTheme.flat_box(UiTheme.MOSS, UiTheme.INK, 4, 30)
	if not human:
		face = StyleBoxFlat.new()
		face.bg_color = Color.TRANSPARENT
		face.content_margin_left = 14
		face.content_margin_right = 14
	face.content_margin_top = 0
	face.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", face)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)
	var ink: Color = UiTheme.CREAM if human else UiTheme.INK
	var place_label: Label = UiTheme.number(UiTheme.ordinal(place), UiTheme.FONT_BODY, ink)
	place_label.custom_minimum_size = Vector2(80, 0)
	place_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(place_label)
	var name_text: String = UiTheme.short_name(Data.s(standing, "name", "?"))
	var name_label: Label = UiTheme.head(name_text, UiTheme.FONT_BODY + 2, ink)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.set_meta("ellipsis_ok", true)
	row.add_child(name_label)
	row.add_child(_bead("knot", str(Data.i(standing, "tier", 1)), UiTheme.INK, 62.0))
	var health: int = maxi(Data.i(standing, "health", 0), 0)
	var shape: String = "rosehip" if health > 0 else "rosehip_out"
	row.add_child(_bead(shape, str(health), UiTheme.CREAM, 70.0))
	return panel


func _bead(shape: String, words: String, ink: Color, side: float) -> ShapeBadge:
	var badge: ShapeBadge = ShapeBadge.new(shape)
	badge.custom_minimum_size = Vector2(side, side)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var number: Label = UiTheme.number(words, UiTheme.FONT_SMALL, ink)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(number)
	return badge


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
