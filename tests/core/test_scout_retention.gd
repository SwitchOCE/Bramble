extends GutTest
@warning_ignore_start("unsafe_call_argument")

const Retention := preload("res://tools/sim/scout_retention.gd")
var _library: UnitLibrary = UnitLibrary.load_dir()


func _board(entries: Dictionary) -> Array:
	var out: Array = []
	out.resize(7)
	for slot: int in entries:
		out[slot] = entries[slot]
	return out


func _unit(id: String, iid: int, attack: int) -> Dictionary:
	return {"def_id": id, "iid": iid, "attack": attack}


func test_moved_and_removed_instances_are_distinct_even_with_the_same_card_name() -> void:
	var one: Dictionary = _unit("bridge_toad", 10, 2)
	var two: Dictionary = _unit("bridge_toad", 11, 2)
	var carry: Dictionary = _unit("little_nip", 12, 20)
	var report: Dictionary = Retention.compare(
		_board({0: one, 1: two, 5: carry}), _board({1: one, 2: two}), _library
	)
	assert_eq(report["all"], {"units": 3, "same": 0, "moved": 2, "gone": 1})
	assert_eq(report["mirers"], {"units": 2, "same": 0, "moved": 2, "gone": 0})
	assert_eq(report["top_attack"], {"units": 1, "same": 0, "moved": 0, "gone": 1})
	assert_false(report["exact"])


func test_a_replacement_copy_is_not_the_scouted_identity() -> void:
	var report: Dictionary = Retention.compare(
		_board({0: _unit("sable", 1, 2)}), _board({0: _unit("sable", 2, 2)}), _library
	)
	assert_eq(report["all"]["gone"], 1)
	assert_eq(report["all"]["same"], 0)


func test_stats_can_change_without_losing_slot_identity_and_new_units_break_exact_layout() -> void:
	var old: Array = _board({0: _unit("little_nip", 1, 2)})
	var actual: Array = _board({0: _unit("little_nip", 1, 20)})
	var report: Dictionary = Retention.compare(old, actual, _library)
	assert_eq(report["all"]["same"], 1)
	assert_true(report["exact"], "this metric measures identity/slot, not fresh stats")
	actual[4] = _unit("wick", 2, 2)
	report = Retention.compare(old, actual, _library)
	assert_eq(report["all"]["same"], 1)
	assert_false(report["exact"], "a new unit changes the visible layout")


func test_all_tied_top_attack_units_are_in_the_carry_proxy() -> void:
	var old: Array = _board({0: _unit("sable", 1, 5), 1: _unit("little_nip", 2, 5)})
	var report: Dictionary = Retention.compare(old, old, _library)
	assert_eq(report["top_attack"]["units"], 2)
	assert_eq(report["top_attack"]["same"], 2)


func test_refreshing_fought_board_does_not_replace_the_scouts_old_snapshot() -> void:
	var player := PlayerState.new()
	player.board[0] = RecruitUnit.make(_library.get_unit("bridge_toad"), 41)
	player.remember_fought_board()
	var scout: Dictionary = {"views": player.fought_view}
	player.board[4] = player.board[0]
	player.board[0] = null
	player.remember_fought_board()
	var old: Array = scout["views"]
	var report: Dictionary = Retention.compare(old, player.fought_view, _library)
	assert_eq(report["all"]["moved"], 1)
	assert_eq(report["mirers"]["moved"], 1)
	assert_false(report["exact"])
