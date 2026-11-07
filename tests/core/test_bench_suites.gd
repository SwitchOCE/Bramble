extends GutTest
## Active tools keep one player-facing bot strength and a tools-only Naive yardstick.


func test_retired_difficulty_suites_are_rejected() -> void:
	for suite: String in [
		"hard_easy",
		"hard_normal",
		"normal_easy",
		"easy_naive",
		"plain_easy",
		"hard_lobby_normal",
		"hard_lobby_normal4"
	]:
		assert_false(BenchSuites.is_known(suite), suite)


func test_naive_yardstick_is_one_best_bot_among_seven_naive() -> void:
	assert_true(BenchSuites.is_known("hard_naive"))
	for game_seed: int in [1, 3, 61, 4001]:
		var seats: PackedStringArray = BenchSuites.seats("hard_naive", game_seed)
		var focus: int = BenchSuites.focus_seat("hard_naive", game_seed)
		assert_eq(seats.size(), 8)
		for seat: int in seats.size():
			assert_eq(seats[seat], "hard" if seat == focus else "naive")


func test_player_lobby_bench_uses_only_current_best_bots() -> void:
	assert_true(BenchSuites.is_known("hard_lobby_hard"))
	var seats: PackedStringArray = BenchSuites.seats("hard_lobby_hard", 3)
	var focus: int = BenchSuites.focus_seat("hard_lobby_hard", 3)
	assert_eq(seats.size(), 8)
	assert_eq(seats[focus], "hard")
	for seat: int in seats.size():
		if seat != focus:
			assert_eq(seats[seat], "hard:varied")
