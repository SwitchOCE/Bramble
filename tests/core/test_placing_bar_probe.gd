extends GutTest

const Probe := preload("res://tools/sim/placing_bar_probe.gd")
@warning_ignore_start("unsafe_call_argument")


func test_probe_runs_two_real_paired_boards_with_held_out_fights() -> void:
	var probe := Probe.new()
	var report: Dictionary = probe.run_probe(2, 1, 2, 12, 19982001, 19982002)
	assert_true(report["complete"])
	assert_eq(report["boards"], 2)
	var rows: Array = report["rows"]
	var mid: int = 0
	for row: Dictionary in rows:
		assert_gte(row["units"], 5)
		assert_between(row["screen"], 0.2, 0.8)
		assert_ne(row["seat"], row["opponent"])
		assert_between(row["best"], 0.0, 1.0)
		assert_between(row["rule"], 0.0, 1.0)
		mid += 1 if CoreUtil.to_int(row["round"]) < 10 else 0
	assert_eq(mid, 1, "one mid-game and one late-game board")
