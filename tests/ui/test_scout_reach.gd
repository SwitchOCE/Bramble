extends GutTest
## The reader's transient scout reach follows native resolved loans, never a standing forecast.

const LaneProjection := preload("res://src/ui/lane_projection.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const ScoutPanel := preload("res://src/ui/widgets/scout_panel.gd")
const Settings := preload("res://src/ui/settings.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")


func after_each() -> void:
	Settings.reset()


func _unit(id: String, golden: bool = false) -> Dictionary:
	return UnitViews.from_def(UnitLibrary.load_dir().get_unit(id), golden)


func _targets(forecast: Dictionary, side: int) -> Dictionary:
	var targets: Dictionary = {}
	for entry: Dictionary in forecast["quarries"]:
		if entry["from_side"] == side:
			targets[entry["from_slot"]] = entry["slot"]
	return targets


func test_native_brock_loans_his_across_to_a_hunter_in_another_column() -> void:
	var own: Array = [null, null, _unit("field_vole"), null, null, _unit("mrs_sorrel"), null]
	var theirs: Array = [null, null, _unit("wick"), null, null, _unit("old_brock"), null]
	var projection: LaneProjection = LaneProjection.new()
	var targets: Dictionary = _targets(projection.forecast([own, theirs]), 1)
	assert_eq(
		CoreUtil.to_int(targets.get(2, -1)), 5, "Wick borrows Brock's across, not Wick's own column"
	)
	assert_false(targets.has(5), "the lender does not grant himself a hunt")


func test_native_own_quarry_beats_brock_loan_and_non_hunters_get_no_loan() -> void:
	var enemies: Array = [_unit("field_vole"), _unit("mrs_sorrel"), null, null, null, null, null]
	var friends: Array = [
		_unit("old_brock"), _unit("little_nip"), null, null, _unit("field_vole"), null, null
	]
	var projection: LaneProjection = LaneProjection.new()
	var targets: Dictionary = _targets(projection.forecast([friends, enemies]), 0)
	assert_eq(CoreUtil.to_int(targets.get(1, -1)), 1, "Nip keeps his printed own Quarry")
	assert_false(targets.has(4), "the Vole cannot borrow a Hunter hunt")


func test_isegrim_marks_biggest_then_lends_beside_or_next_to_when_golden() -> void:
	var biggest: Dictionary = _unit("field_vole")
	biggest["attack"] = 100
	var enemies: Array = [_unit("mrs_sorrel"), null, null, biggest, null, null, null]
	var projection: LaneProjection = LaneProjection.new()
	for golden: bool in [false, true]:
		var friends: Array = [
			_unit("old_isegrim", golden),
			_unit("wick"),
			null,
			null,
			_unit("young_brock"),
			null,
			null
		]
		var targets: Dictionary = _targets(projection.forecast([friends, enemies]), 0)
		assert_eq(CoreUtil.to_int(targets.get(0, -1)), 3, "Isegrim hunts the largest current body")
		assert_eq(CoreUtil.to_int(targets.get(1, -1)), 3, "the beside Hunter shares his hunt")
		assert_eq(
			CoreUtil.to_int(targets.get(4, -1)),
			3 if golden else -1,
			"golden widens the loan across rows"
		)


func test_reach_flashes_the_resolved_lent_pocket_then_returns_to_rest() -> void:
	var own: Array = [null, null, _unit("field_vole"), null, null, _unit("mrs_sorrel"), null]
	var theirs: Array = [null, null, _unit("wick"), null, null, _unit("old_brock"), null]
	var projection: LaneProjection = LaneProjection.new()
	var board: BoardView = BoardView.new()
	add_child_autofree(board)
	board.configure("board", 209, true)
	var scout: ScoutPanel = ScoutPanel.new()
	add_child_autofree(scout)
	scout.show_board("Enemy", theirs)
	Settings.reduce_motion = true
	scout.pulse_reach(board, projection.forecast([own, theirs]), 2)
	assert_eq(board.slots[5].reach_flash, 1.0, "the lent target flashes")
	assert_eq(board.slots[2].reach_flash, 0.0, "the tempting across slot stays unmarked")
	assert_eq(board.slots[5].highlight.a, 0.0, "reach never becomes a held legal-target tint")
	await wait_seconds(0.45)
	assert_eq(board.slots[5].reach_flash, 0.0, "no forecast remains after the demand-only cue")


func test_reach_flash_paints_above_an_occupied_card_and_leaves_no_mark() -> void:
	var board := BoardView.new()
	add_child_autofree(board)
	board.configure("board", 209, true)
	var card := CardView.new()
	card.show_unit(_unit("mr_crumb"), card.Mode.BOARD)
	board.place_card(card, 5)
	board.show_relations([5])
	var pulse: Tween = board.get("_reach_tween")
	pulse.pause()
	pulse.custom_step(0.1)
	var foreground: Control = board.slots[5].get("_reach_face")
	assert_true(foreground.visible, "the occupied target has an actual foreground cue")
	assert_gt(foreground.z_index, card.z_index, "the portrait cannot cover the reach pulse")
	assert_gt(foreground.modulate.a, 0.5)
	assert_eq(foreground.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	pulse.custom_step(0.4)
	assert_false(foreground.visible, "no permanent outline survives the reader beat")


func test_lent_quarry_stamps_only_the_resolved_target_and_keeps_a_distinct_aimer() -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		var own: Array = [null, null, _unit("field_vole"), null, null, _unit("mrs_sorrel"), null]
		var theirs: Array = [null, null, _unit("wick"), null, null, _unit("old_brock"), null]
		var board := BoardView.new()
		add_child_autofree(board)
		board.configure("board", 209, true)
		var resident := CardView.new()
		var resident_view: Dictionary = own[5]
		resident.show_unit(resident_view, CardView.Mode.BOARD)
		board.place_card(resident, 5)
		var scout := ScoutPanel.new()
		add_child_autofree(scout)
		scout.show_board("Enemy", theirs)
		scout.card_at(2).selected = true
		var projection := LaneProjection.new()
		scout.pulse_reach(board, projection.forecast([own, theirs]), 2)
		var pulse: Tween = board.get("_reach_tween")
		pulse.pause()
		pulse.custom_step(0.1)
		var stamp: Control = board.slots[5].get("_quarry_stamp")
		var across_stamp: Control = board.slots[2].get("_quarry_stamp")
		assert_true(stamp.visible, "the lent quarry is stamped in both motion modes")
		assert_gt(stamp.z_index, resident.z_index, "the target portrait cannot cover the glyph")
		assert_eq(stamp.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_false(across_stamp.visible, "no straight-across target is invented")
		assert_true(scout.card_at(2).selected, "the aimer stays selected during the target beat")
		assert_eq(scout.card_at(2).selection_color, UiTheme.RIME)
		assert_ne(scout.card_at(2).selection_color, UiTheme.SELECT)
		var source_board: BoardView = scout.get("_board")
		assert_eq(source_board.slots[2].reach_flash, 0.0, "selection is not a second gold pulse")
		pulse.custom_step(0.4)
		assert_false(stamp.visible, "the quarry glyph retires with the cue")
		assert_true(scout.card_at(2).selected, "the active selection remains available to inspect")


func test_non_quarry_relations_never_acquire_a_quarry_stamp_and_clearing_retires_it() -> void:
	Settings.reduce_motion = true
	var board := BoardView.new()
	add_child_autofree(board)
	board.configure("board", 209, true)
	board.show_relations([5], -1, [5])
	var stamp: Control = board.slots[5].get("_quarry_stamp")
	assert_true(stamp.visible)
	board.show_relations([5])
	assert_false(stamp.visible, "a later ordinary relation does not inherit the quarry glyph")
	board.show_relations([5], -1, [5])
	board.clear_highlights()
	assert_false(stamp.visible, "closing the reader retires the stamp immediately")
