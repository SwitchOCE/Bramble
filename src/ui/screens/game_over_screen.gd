extends Control
## The end of a game: your placement carved big, your final board in its tray, how it went (each
## round, who knocked you out, your best win, your biggest unit), and the final standings. Reads a
## SPEC 6.1 state whose phase is "game_over" (or one where you were eliminated). The app passes the
## rounds it saw, and whether this beat your best.

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
const ROUND_TOKEN: float = 50.0
const TOKEN_GAP: float = 6.0
const LINE_GAP: float = 6.0
const BOX_PAD: float = 30.0

## Round tokens shown, for tests: each {round, result ("won", "lost", "tie"), damage, opponent,
## opponent_id}.
var round_log: Array = []
## The lines under the tokens, for tests.
var moments: PackedStringArray = []

var _plaque: WoodPanel
var _placement: Label
var _summary: Label
var _best: Label
var _board: BoardView
var _rounds_panel: WoodPanel
var _rounds_head: Label
var _rounds: Control
var _moments: Control
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
	_rounds_head = UiTheme.burned("How it went", UiTheme.FONT_SMALL, UiTheme.MUTE)
	_rounds_panel.add_child(_rounds_head)
	_rounds = Control.new()
	_rounds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rounds_panel.add_child(_rounds)
	_moments = Control.new()
	_moments.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rounds_panel.add_child(_moments)
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
	show_state(port.get_state(), port.get_last_combat(), port.get_game_log())


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


## The lines for the box: who ended it, the best win, the biggest unit. Only what really happened.
static func moment_lines(
	rounds: Array, placement: Variant, game_log: Dictionary
) -> PackedStringArray:
	var lines: PackedStringArray = []
	if placement != null and Data.as_int(placement) == 1:
		lines.append("Last one standing.")
	elif not rounds.is_empty():
		var last: Dictionary = rounds[-1]
		if Data.s(last, "result") == "lost":
			lines.append(
				(
					"Knocked out by %s on turn %d."
					% [Data.s(last, "opponent", "a rival"), Data.i(last, "round")]
				)
			)
	var best: Dictionary = {}
	for entry: Variant in rounds:
		var round_row: Dictionary = entry
		if Data.s(round_row, "result") != "won":
			continue
		if best.is_empty() or Data.i(round_row, "damage") > Data.i(best, "damage"):
			best = round_row
	if not best.is_empty():
		lines.append(
			(
				"Best win: %d damage to %s on turn %d."
				% [
					Data.i(best, "damage"),
					Data.s(best, "opponent", "a rival"),
					Data.i(best, "round")
				]
			)
		)
	var biggest: String = biggest_unit(game_log)
	if not biggest.is_empty():
		lines.append(biggest)
	return lines


## "Biggest unit: Golden Alderman Dozey, 76/106 on turn 10." "" if the log has no board for you.
static func biggest_unit(game_log: Dictionary) -> String:
	var line: String = ""
	var most: int = -1
	for row_value: Variant in Data.a(game_log, "players"):
		var row: Dictionary = row_value
		if Data.i(row, "player_id", -1) != 0:
			continue
		for round_value: Variant in Data.a(row, "rounds"):
			var round_row: Dictionary = round_value
			for unit_value: Variant in Data.a(round_row, "board"):
				if not unit_value is Dictionary:
					continue
				var unit: Dictionary = unit_value
				var size_now: int = Data.i(unit, "attack") + Data.i(unit, "health")
				if size_now <= most:
					continue
				most = size_now
				line = (
					"Biggest unit: %s%s, %d/%d on turn %d."
					% [
						"Golden " if Data.b(unit, "golden", false) else "",
						Data.s(unit, "name"),
						Data.i(unit, "attack"),
						Data.i(unit, "health"),
						Data.i(round_row, "round"),
					]
				)
	return line


func show_state(state: Dictionary, last_combat: Dictionary = {}, game_log: Dictionary = {}) -> void:
	var placement: Variant = state.get("placement")
	_placement.text = (
		UiTheme.ordinal(Data.as_int(placement)) + " place" if placement != null else "-"
	)
	# The core has moved on to the next round by now; the last fight is the turn it ended on.
	var last_turn: int = Data.i(state, "round", 0)
	if not round_log.is_empty():
		last_turn = Data.i(Data.d({"last": round_log[-1]}, "last"), "round", last_turn)
	_summary.text = "Turn %d, tier %d" % [last_turn, Data.i(state, "tier", 1)]
	var hero: String = Data.s(Data.d(state, "hero"), "name")
	if not hero.is_empty():
		_summary.text = "%s: %s" % [hero, _summary.text.to_lower()]
	_board.clear()
	var board: Array = final_board(state, last_combat)
	for slot: int in mini(board.size(), BoardView.SLOTS):
		var entry: Variant = board[slot]
		if entry is Dictionary:
			var card: CardView = CardView.new()
			var view: Dictionary = entry
			card.chip_hidden = true
			card.show_unit(view, CardView.Mode.BOARD)
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_board.place_card(card, slot)
	_fill_rounds()
	moments = moment_lines(round_log, placement, game_log)
	_fill_moments()
	_fill_table(Data.a(state, "standings"), _knocked_out_by(placement))
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
	_rounds_head.position = Vector2(BOX_PAD, 10)
	_rounds_head.size = Vector2(tray.x - BOX_PAD * 2.0, 42)
	_rounds.position = Vector2(BOX_PAD, 56)
	_rounds.size = Vector2(tray.x - BOX_PAD * 2.0, 0)
	_place_rounds()
	_layout_moments(tray.x)
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
	var columns: int = maxi(int((_rounds.size.x + TOKEN_GAP) / (ROUND_TOKEN + TOKEN_GAP)), 1)
	var i: int = 0
	for child: Node in _rounds.get_children():
		var token: Control = child as Control
		var row: int = floori(float(i) / columns)
		token.position = Vector2(
			(i % columns) * (ROUND_TOKEN + TOKEN_GAP), row * (ROUND_TOKEN + TOKEN_GAP)
		)
		i += 1
	var rows: int = ceili(float(i) / columns)
	_rounds.size.y = rows * (ROUND_TOKEN + TOKEN_GAP)


func _fill_moments() -> void:
	for child: Node in _moments.get_children():
		_moments.remove_child(child)
		child.queue_free()
	for line: String in moments:
		var words: Label = UiTheme.label(line, UiTheme.FONT_SMALL)
		words.add_theme_font_override("font", UiTheme.bold_font())
		words.add_theme_constant_override("line_spacing", -4)
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.clip_text = true
		_moments.add_child(words)


## The box is as tall as what it has to say, at most the room down to the screen's edge.
func _layout_moments(tray_w: float) -> void:
	var wide: float = tray_w - BOX_PAD * 2.0
	var font: Font = UiTheme.bold_font()
	var tall: float = 0.0
	for child: Node in _moments.get_children():
		var words: Label = child as Label
		var line: Vector2 = font.get_multiline_string_size(
			words.text, HORIZONTAL_ALIGNMENT_LEFT, wide, UiTheme.FONT_SMALL
		)
		words.position = Vector2(0, tall)
		words.size = Vector2(wide, line.y + 2.0)
		tall += line.y + LINE_GAP
	_moments.position = Vector2(BOX_PAD, _rounds.position.y + _rounds.size.y + 4.0)
	_moments.size = Vector2(wide, tall)
	var room: float = 1080.0 - 268.0 - _board.tray_size().y - 16.0 - 28.0
	var wanted: float = _moments.position.y + tall + 22.0
	_rounds_panel.size = Vector2(tray_w, minf(wanted, room))


## The player who ended your game, or -2 for nobody: a win, or a ghost.
func _knocked_out_by(placement: Variant) -> int:
	if placement == null or Data.as_int(placement) == 1 or round_log.is_empty():
		return -2
	var last: Dictionary = round_log[-1]
	return Data.i(last, "opponent_id", -2) if Data.s(last, "result") == "lost" else -2


## Sorted by placement; players still alive (the winner) come first by health.
func _fill_table(standings: Array, beaten_by: int) -> void:
	for child: Node in _table.get_children():
		_table.remove_child(child)
		child.queue_free()
	var rows: Array = standings.duplicate()
	rows.sort_custom(_before)
	for i: int in rows.size():
		var standing: Dictionary = rows[i]
		var placement: Variant = standing.get("placement")
		var place: int = Data.as_int(placement) if placement != null else i + 1
		var note: String = (
			"Knocked you out" if Data.i(standing, "player_id", -1) == beaten_by else ""
		)
		_table.add_child(_standing_row(standing, place, note))


func _standing_row(standing: Dictionary, place: int, note: String = "") -> Control:
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
	var name_text: String = UiTheme.player_name(standing)
	var name_label: Label = UiTheme.head(name_text, UiTheme.FONT_BODY + 2, ink)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.set_meta("ellipsis_ok", true)
	row.add_child(name_label)
	if not note.is_empty():
		var tag: Label = UiTheme.burned(note, UiTheme.FONT_SMALL, UiTheme.CREAM)
		var slip: StyleBoxFlat = UiTheme.slip_box(UiTheme.HEALTH, 3, 9)
		slip.content_margin_top = 0
		slip.content_margin_bottom = 0
		tag.add_theme_stylebox_override("normal", slip)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tag)
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
