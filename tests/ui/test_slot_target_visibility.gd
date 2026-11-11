extends GutTest
## Tap and drag action targets have actual foreground paint, even without a viewport drag.

const Fixture := preload("res://tests/ui/shots/declutter_cold_fixture.gd")
const Screen := preload("res://src/ui/screens/recruit_screen.gd")
const Card := preload("res://src/ui/widgets/card_view.gd")
const Slot := preload("res://src/ui/widgets/slot_view.gd")
const Board := preload("res://src/ui/widgets/board_view.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const Settings := preload("res://src/ui/settings.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Data := preload("res://src/ui/view_data.gd")
const WINDOWS: Array[Vector2i] = [Vector2i(1688, 780), Vector2i(1920, 1080)]


func after_each() -> void:
	Card.window_override = Vector2.ZERO
	Settings.reset()


func _screen(pixels: Vector2i, port: CorePort) -> Screen:
	Settings.reduce_motion = true
	Card.window_override = Vector2(pixels)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(roundi(1080.0 * pixels.x / pixels.y), 1080)
	add_child_autofree(viewport)
	var screen := Screen.new()
	viewport.add_child(screen)
	screen.setup(port)
	return screen


func _slot_paints(slot: Slot, expected: bool) -> void:
	var paint: Control = slot.get("_target_face")
	assert_not_null(paint, "legal targets own an inspectable paint node")
	if paint == null:
		return
	assert_true(paint.draw.is_connected(Callable(slot, "_draw_target")))
	assert_eq(paint.is_visible_in_tree(), expected, "target paint follows the action state")
	assert_eq(paint.mouse_filter, Control.MOUSE_FILTER_IGNORE, "paint never intercepts a tap")
	assert_eq(paint.size, slot.size, "target paint uses the complete slot coordinate space")
	if expected:
		assert_eq(
			paint.modulate, slot.highlight.lightened(0.45), "paint carries a legible target colour"
		)
		assert_gt(paint.modulate.a, 0.0)
		assert_gt(paint.z_index, 0, "paint clears later board card siblings")


func _occupied_paints(card: Card) -> void:
	var paint: Control = card.get("_focus_rim")
	assert_true(paint.is_visible_in_tree(), "occupied destinations paint their focus rim")
	assert_true(paint.draw.is_connected(Callable(card, "_draw_focus")))
	assert_gt(card.outline.a, 0.0, "an unselected destination has a legal-target colour")
	assert_gt(paint.z_index, 0, "destination rim paints over the occupied card face")


func _rest(board: Board) -> void:
	for slot: Slot in board.slots:
		_slot_paints(slot, false)
	for card: Card in board.cards:
		if card != null:
			assert_eq(card.outline.a, 0.0, "rest leaves no occupied target outline")


func test_tapped_hand_shows_empty_targets_then_clears_on_cancel_and_successful_play() -> void:
	for pixels: Vector2i in WINDOWS:
		var port: CorePort = Fixture.make("play")
		var screen: Screen = _screen(pixels, port)
		await wait_process_frames(2)
		_rest(screen._board)
		assert_false(screen.get_viewport().gui_is_dragging())
		screen._card_at("hand", 0).tapped.emit("hand", 0)
		for index: int in Board.SLOTS:
			_slot_paints(screen._board.slots[index], screen._board.cards[index] == null)
		screen._on_tapped("table", -1)
		_rest(screen._board)
		screen._card_at("hand", 0).tapped.emit("hand", 0)
		screen._board.slots[1].tapped.emit("board", 1)
		assert_not_null(screen._board.cards[1], "the real core commits the tapped placement")
		assert_true(Data.a(port.get_state(), "hand").is_empty())
		_rest(screen._board)


func test_tapped_board_and_drag_targets_show_empty_and_occupied_destinations() -> void:
	for pixels: Vector2i in WINDOWS:
		var screen: Screen = _screen(pixels, Fixture.make("play"))
		await wait_process_frames(2)
		screen._card_at("board", 0).tapped.emit("board", 0)
		_slot_paints(screen._board.slots[0], false)
		_slot_paints(screen._board.slots[1], true)
		_occupied_paints(screen._board.cards[5])
		var first_iid: int = screen._board.cards[0].unit["iid"]
		var second_iid: int = screen._board.cards[5].unit["iid"]
		screen._card_at("board", 5).tapped.emit("board", 5)
		assert_eq(Data.i(screen._board.cards[5].unit, "iid"), first_iid, "tapped swap commits")
		assert_eq(Data.i(screen._board.cards[0].unit, "iid"), second_iid)
		_rest(screen._board)
		screen._on_drag_started("board", 0)
		_slot_paints(screen._board.slots[1], true)
		_occupied_paints(screen._board.cards[5])
		screen.notification(Control.NOTIFICATION_DRAG_END)
		_rest(screen._board)
		screen._on_drag_started("hand", 0)
		_slot_paints(screen._board.slots[1], true)
		screen.notification(Control.NOTIFICATION_DRAG_END)
		_rest(screen._board)


func test_hero_aim_paints_empty_and_occupied_targets_and_clears_after_use() -> void:
	for pixels: Vector2i in WINDOWS:
		var port: CorePort = Fixture.make("play")
		var players: Array[PlayerState] = port.session.get("_players")
		players[0].hero = port.library.get_hero("sample_painter").duplicate(true)
		players[0].power_uses_left = 1
		var screen: Screen = _screen(pixels, port)
		await wait_process_frames(2)
		screen._on_hero_power()
		_slot_paints(screen._board.slots[1], true)
		_occupied_paints(screen._board.cards[0])
		screen._on_tapped("table", -1)
		_rest(screen._board)
		screen._on_hero_power()
		screen._board.slots[1].tapped.emit("board", 1)
		assert_eq(
			Data.i(port.get_state(), "gold"), 8, "the real aimed power commits and pays its cost"
		)
		var slot_effects: Array = Data.a(port.get_state(), "slot_effects")
		var painted_slot: Array = slot_effects[1]
		assert_false(painted_slot.is_empty())
		_rest(screen._board)


func test_target_colour_changes_and_reach_flash_have_independent_visible_paint() -> void:
	var slot := Slot.new()
	add_child_autofree(slot)
	slot.size = Vector2(209, 280)
	_slot_paints(slot, false)
	slot.highlight = UiTheme.DROP_OK
	_slot_paints(slot, true)
	slot.highlight = UiTheme.OUT_FACE
	_slot_paints(slot, true)
	slot.reach_flash = 1.0
	slot.highlight = Color.TRANSPARENT
	_slot_paints(slot, false)
	var reach: Control = slot.get("_reach_face")
	assert_true(reach.is_visible_in_tree(), "clearing targets preserves the independent reach cue")
	slot.reach_flash = 0.0
	assert_false(reach.is_visible_in_tree())
