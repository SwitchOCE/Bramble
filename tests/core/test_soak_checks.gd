extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access", "unsafe_property_access")

const Bench := preload("res://tools/checks/bench_fights.gd")
const Checker := preload("res://tools/checks/soak.gd")
const FieldTestData := preload("res://tests/core/field_test_data.gd")
var _checker: SceneTree
var _library: UnitLibrary = TestLibraries.current()


func before_each() -> void:
	_checker = Checker.new()
	_checker._library = _library
	_checker._plain_library = _library
	_checker._full_library = _library
	_checker._preset = Pass3Rates.default_preset()


func after_each() -> void:
	_checker.free()


func test_directed_bog_check_respects_the_current_golden_king_cap() -> void:
	assert_eq(SoakBogCheck.problems(_library), PackedStringArray())


func test_real_field_lobby_does_not_reseat_display_rivals_or_audit_their_dummy_iids() -> void:
	_checker._field_library = FieldTestData.path()
	assert_gt(_checker._play(4, "field"), 0)
	var violations: Array[String] = _checker._violations
	assert_eq(violations, [], "a field lobby reaches its end through the ordinary soak checks")


func test_no_set_recruit_plant_puts_a_real_prototype_in_the_lobby() -> void:
	_checker._plant = "no_set"
	_checker._play(2, "preset")
	assert_true(
		_checker._violations.any(
			func(line: String) -> bool: return line.contains("holds fox_cub, which has no set")
		)
	)


func test_combat_only_summoned_and_killed_prototype_fails_the_lobby() -> void:
	_checker._plant = "no_set_combat"
	_checker._play(2, "preset")
	var violations: Array[String] = _checker._violations
	assert_true(
		violations.any(
			func(line: String) -> bool: return line.contains("fight ") and line.contains("fox_cub,")
		)
	)
	assert_false(violations.any(func(line: String) -> bool: return line.contains("holds fox_cub")))


func test_fetch_golden_copy_uses_explicit_stats_below_double_printed_base() -> void:
	var config := GameConfig.full_game()
	_checker._session = GameSession.create(147, _library, config)
	var ours: Array = [
		null,
		{"def_id": "cradle_fetch", "golden": true},
		null,
		null,
		{"def_id": "will_o_the_wisp"},
		null,
		null
	]
	var theirs: Array = [
		{"def_id": "will_o_the_wisp", "attack": 100, "health": 100},
		null,
		null,
		null,
		null,
		null,
		null
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 147
	var result: Dictionary = Combat.create(_library, config, rng).run(
		[ours, theirs], [6, 6], [0, 1], 0
	)
	_checker._check_fight(10, 0, 1, result)
	assert_eq(
		_checker._violations, [], "Fetch sets copied totals; the golden base layer is separate"
	)


func test_retired_prototypes_leave_a_nonempty_current_fight_benchmark_pool() -> void:
	assert_true(_library.pool_units().is_empty(), "the old default pool is retired")
	var config := GameConfig.full_game()
	var units: Array[Dictionary] = Bench._pool_units(_library, config)
	assert_eq(units.size(), _library.pool_units(config.card_set()).size())
	assert_gt(units.size(), 0, "the benchmark samples the full-game pool")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var board: Array = Bench._board(units, rng)
	var bodies: int = 0
	for body: Variant in board:
		if body != null:
			bodies += 1
			assert_true(_library.get_unit(body["def_id"]).has("set"))
	assert_gte(bodies, Bench.BOARD_MIN)
	assert_true(Bench._pool_units(UnitLibrary.new(), config).is_empty())


func test_soak_fails_loudly_before_starting_an_empty_pool_game() -> void:
	for kind: String in ["preset", "other", "synthetic"]:
		_checker._plain_library = UnitLibrary.new()
		_checker._full_library = UnitLibrary.new()
		assert_eq(_checker._play(3, kind), 0)
	assert_eq(_checker._empty_pools, 3)
	assert_eq(_checker._fights, 0)
	assert_eq(_checker._violations.size(), 2)
	assert_eq(_checker._synthetic_violations.size(), 1)
	for line: String in _checker._violations + _checker._synthetic_violations:
		assert_true(line.contains("empty recruit pool"), line)
