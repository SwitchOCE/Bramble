extends GutTest
## Review Ask 1: recruit placement exposes the current Bitter sum and persistent kiss counter.

const Data := preload("res://src/ui/view_data.gd")
const LaneProjection := preload("res://src/ui/lane_projection.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const States := preload("res://tests/ui/review_bog_states.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_bitter_counts_native_and_both_adjacent_golden_auras_without_mutation() -> void:
	var board: Array = States.board()
	var before: Array = board.duplicate(true)
	var projected: Dictionary = LaneProjection.new().recruit_unit(board, 1)
	assert_eq(Data.i(projected, "recruit_bitter"), 6, "Bufo 2 + golden Nan 2 + golden Chorus 2")
	assert_eq(Data.i(projected, "recruit_bitter_printed"), 2)
	assert_eq(Data.i(projected, "recruit_bitter_borrowed"), 4)
	assert_eq(CardView.chip_text(projected), "Mire\nBitter 6")
	assert_string_contains(CardDetail.full_text_bbcode(projected), "2 base + 4 from beside")
	assert_eq(board, before, "a forecast never changes recruit units or their counters")


func test_golden_card_bitter_and_non_bog_borrowers_use_the_actual_live_row() -> void:
	var board: Array = [
		States.unit("madame_bufo", 1, true),
		States.unit("warty_nan", 2),
		null,
		null,
		States.unit("field_vole", 3),
		States.unit("natterjack_chorus", 4, true),
		null
	]
	var projection: LaneProjection = LaneProjection.new()
	assert_eq(
		Data.i(projection.recruit_unit(board, 0), "recruit_bitter"), 5, "golden Bufo 4 + Nan 1"
	)
	assert_eq(
		Data.i(projection.recruit_unit(board, 4), "recruit_bitter"), 2, "Chorus lends to any tribe"
	)
	assert_string_contains(
		CardDetail.notes_bbcode(projection.recruit_unit(board, 4)),
		"Bitter",
		"a borrower gets the keyword reminder too"
	)
	board[5] = null
	assert_false(
		projection.recruit_unit(board, 4).has("recruit_bitter"), "a removed aura stops lending"
	)
	board[1]["alive"] = false
	assert_eq(
		Data.i(projection.recruit_unit(board, 0), "recruit_bitter"),
		4,
		"a non-live source lends nothing"
	)


func test_kisses_read_persistent_counters_and_bitter_does_not_hide_them() -> void:
	var board: Array = States.board()
	var projection: LaneProjection = LaneProjection.new()
	var frog: Dictionary = projection.recruit_unit(board, 4)
	assert_eq(CardView.chip_text(frog), "Bitter 1\nKiss 2/3")
	assert_string_contains(CardDetail.full_text_bbcode(frog), "Kisses: 2/3")
	board[5] = null
	assert_eq(CardView.chip_text(projection.recruit_unit(board, 4)), "Snap\nKiss 2/3")
	board[4] = States.unit("his_highness", 6, true)
	assert_eq(
		Data.i(projection.recruit_unit(board, 4), "recruit_kisses"),
		0,
		"a fresh golden starts at 0/3"
	)
	board[4] = States.unit("prince_restored", 7)
	assert_false(
		projection.recruit_unit(board, 4).has("recruit_kisses"),
		"the restored Prince is done counting"
	)


func test_moving_a_unit_recomputes_its_bitter_and_keeps_its_kisses() -> void:
	var board: Array = States.board()
	var frog: Dictionary = board[4]
	board[4] = board[1]
	board[1] = frog
	var projection: LaneProjection = LaneProjection.new()
	assert_eq(Data.i(projection.recruit_unit(board, 1), "recruit_bitter"), 4)
	assert_eq(Data.i(projection.recruit_unit(board, 1), "recruit_kisses"), 2)
	assert_eq(Data.i(projection.recruit_unit(board, 4), "recruit_bitter"), 3)


func test_phone_tray_chip_and_selected_detail_fit_and_refresh_after_a_move() -> void:
	CardView.window_override = Vector2(1688, 780)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(2337, 1080)
	add_child_autofree(viewport)
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	States.recruit(port.get_state())
	var screen: RecruitScreen = RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	screen.call("_on_tapped", "board", 4)
	await wait_process_frames(2)
	assert_eq(screen._board.cards[1].chip_shown, "Mire\nBitter 6")
	assert_eq(screen._board.cards[4].chip_shown, "Bitter 1\nKiss 2/3")
	var detail: CardDetail = screen.get("_detail")
	assert_string_contains(CardDetail.full_text_bbcode(detail.shown), "Kisses: 2/3")
	assert_eq(LayoutCheck.problems(screen, "Bog recruit preview"), PackedStringArray())
	var board: Array = port.get_state()["board"]
	board[5] = null
	screen.render()
	await wait_process_frames(2)
	assert_eq(
		screen._board.cards[4].chip_shown, "Snap\nKiss 2/3", "the old aura total does not linger"
	)
	screen.free()
