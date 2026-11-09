extends GutTest
## The reader's transient scout reach follows native resolved loans, never a standing forecast.

const LaneProjection := preload("res://src/ui/lane_projection.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const ScoutPanel := preload("res://src/ui/widgets/scout_panel.gd")
const Settings := preload("res://src/ui/settings.gd")


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
