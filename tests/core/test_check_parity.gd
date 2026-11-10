extends GutTest
## Counts the real shop pool, with synthetic cases for the parity gate's policies.
@warning_ignore_start("unsafe_call_argument")

const Parity = preload("res://tools/checks/check_parity.gd")


func test_counts_only_full_game_pool_with_actual_library_filter() -> void:
	var library: UnitLibrary = TestLibraries.current()
	var template: Dictionary = library.get_unit("worker_bee").duplicate(true)
	var synthetic := UnitLibrary.new()
	for spec: Array in [
		["slice_unit", "slice", true, 1],
		["token", "slice", false, 2],
		["old_library", "", true, 3],
		["other_set", "future", true, 4],
	]:
		var unit: Dictionary = template.duplicate(true)
		unit["id"] = spec[0]
		unit["set"] = spec[1]
		unit["pool"] = spec[2]
		unit["tier"] = spec[3]
		unit["tribes"] = ["Birds"]
		assert_eq(synthetic.register_unit(unit), "")
	var pool: Array[Dictionary] = synthetic.pool_units(GameConfig.full_game().card_set())
	assert_eq(pool.size(), 1, "only the slice's shop card survives")
	assert_eq(Parity.count_pool(pool)["Birds"], [1, 0, 0, 0, 0, 0])


func test_counts_dual_tribes_and_neutrals_separately() -> void:
	var units: Array[Dictionary] = [
		{"tier": 2, "tribes": ["Birds", "Fairies"]},
		{"tier": 6, "tribes": []},
		{"tier": 1, "tribes": ["Hive"]},
	]
	var counts: Dictionary = Parity.count_pool(units)
	assert_eq(counts["Birds"], [0, 1, 0, 0, 0, 0])
	assert_eq(counts["Fairies"], [0, 1, 0, 0, 0, 0])
	assert_eq(counts["Neutrals"], [0, 0, 0, 0, 0, 1])
	assert_eq(counts["Hive"], [1, 0, 0, 0, 0, 0], "unexpected tribes remain visible")
	assert_eq(counts["Hunters"], [0, 0, 0, 0, 0, 0], "missing tribes cannot disappear")


func test_strict_checks_spread_even_when_total_is_sixteen_and_exempts_neutrals() -> void:
	var counts: Dictionary = Parity.count_pool([])
	for tribe: String in Parity.TRIBES:
		counts[tribe] = [3, 3, 3, 3, 2, 2]
	counts["Neutrals"] = [20, 0, 0, 0, 0, 0]
	assert_eq(Parity.exit_status(counts, "1"), 0, "balanced pool passes strict")
	counts["Birds"] = [4, 4, 2, 3, 1, 2]
	assert_eq(Parity.mismatches(counts), PackedStringArray(["Birds"]))
	assert_eq(Parity.exit_status(counts, ""), 0, "measurement mode warns")
	assert_eq(Parity.exit_status(counts, "0"), 0, "strict must be explicitly enabled")
	assert_eq(Parity.exit_status(counts, "1"), 1, "same total, wrong spread fails strict")


func test_absent_and_unexpected_tribes_fail_strict() -> void:
	var counts: Dictionary = Parity.count_pool([])
	assert_true(Parity.mismatches(counts).has("Birds"), "empty tribe still checked")
	for tribe: String in Parity.TRIBES:
		counts[tribe] = Parity.TARGET.duplicate()
	counts["Hive"] = [1, 0, 0, 0, 0, 0]
	assert_eq(Parity.mismatches(counts), PackedStringArray(["Hive"]))
	assert_eq(Parity.exit_status(counts, "1"), 1)
