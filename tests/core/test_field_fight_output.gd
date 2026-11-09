extends GutTest
@warning_ignore_start("unsafe_call_argument")

const FieldDriver = preload("res://tools/sim/field_fights.gd")


func test_aggregate_and_per_seed_preserve_their_distinct_legacy_seed_families() -> void:
	for rep: int in [0, 1, 63, 4095]:
		var aggregate: int = ("field|12|left|right|%d" % rep).hash()
		var paired: int = "designed|12|left|right".hash() * 4096 + rep
		assert_eq(FieldDriver.seed_for("12", "left", "right", rep), aggregate)
		assert_eq(FieldDriver.seed_for("12", "left", "right", rep, true), paired)
		assert_ne(aggregate, paired)


func test_aggregate_row_keeps_counts_and_omits_seed_only_fields() -> void:
	var wins: Array[int] = [3, 4]
	assert_eq(
		FieldDriver.result_row(12, "left", "right", wins, 1, 8),
		{"round": 12, "a": "left", "b": "right", "wins_a": 3, "wins_b": 4, "draws": 1, "trials": 8}
	)


func test_per_seed_row_keeps_paired_counts_and_lossless_seed_string() -> void:
	var wins: Array[int] = [1, 0]
	var row: Dictionary = FieldDriver.result_row(
		12, "left", "right", wins, 1, 2, 63, 9007199254740993
	)
	assert_eq(row["replicate"], 63)
	assert_eq(row["seed"], "9007199254740993")
	assert_eq(row["wins_a"], 1)
	assert_eq(row["wins_b"], 0)
	assert_eq(row["draws"], 1)
	assert_eq(row["trials"], 2)
	assert_eq(CoreUtil.to_int(row["wins_a"]) + CoreUtil.to_int(row["wins_b"]) + 1, 2)
