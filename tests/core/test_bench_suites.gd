extends GutTest
const STREAM := preload("res://tools/sim/hard_stream.gd")

## Active tools keep one player-facing bot strength and a tools-only Naive yardstick.


func test_a35_run1_seats_all_committed_lines_evenly_on_matched_seeds() -> void:
	assert_true(BenchSuites.is_known("a35_run1"))
	var counts: Dictionary = {}
	var profiles: Dictionary = LinePolicies.profiles()
	for game_seed: int in range(2911001, 2911033):
		var roster: PackedStringArray = BenchSuites.seats("a35_run1", game_seed)
		assert_eq(roster.size(), 8)
		assert_eq(roster, BenchSuites.seats("a35_run1", game_seed))
		var seen: Dictionary = {}
		for line: String in roster:
			assert_true(profiles.has(line), line)
			assert_false(seen.has(line), line)
			seen[line] = true
			counts[line] = CoreUtil.to_int(counts.get(line, 0)) + 1
	assert_eq(counts.size(), 12)
	for line: String in counts:
		assert_between(CoreUtil.to_int(counts[line]), 21, 22, line)


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


func test_head_to_head_swaps_shuffled_sides_and_deals_normal_builds() -> void:
	var partitions: Dictionary = {}
	for game_seed: int in [1, 2, 3, 61, 4001]:
		var first: Array[int] = BenchSuites.candidate_seats(game_seed, 0)
		var second: Array[int] = BenchSuites.candidate_seats(game_seed, 1)
		assert_eq(first.size(), 4)
		assert_eq(second.size(), 4)
		partitions[str(first)] = true
		for seat: int in first:
			assert_false(second.has(seat))
		var rng_a := RandomNumberGenerator.new()
		var rng_b := RandomNumberGenerator.new()
		rng_a.seed = game_seed
		rng_b.seed = game_seed
		var tribes: PackedStringArray = []
		var a: PackedStringArray = BotLobby.resolve(
			BenchSuites.seats("head_to_head", game_seed, "rule", "hard", 0), tribes, rng_a
		)
		var b: PackedStringArray = BotLobby.resolve(
			BenchSuites.seats("head_to_head", game_seed, "rule", "hard", 1), tribes, rng_b
		)
		var builds: Dictionary = {}
		for seat: int in 8:
			assert_eq(a[seat].get_slice(":", 1), b[seat].get_slice(":", 1))
			assert_eq(a[seat].begins_with("rule:"), first.has(seat))
			assert_eq(b[seat].begins_with("rule:"), second.has(seat))
			builds[a[seat].get_slice(":", 1)] = true
		assert_eq(builds.size(), 8)
	assert_gt(partitions.size(), 1)


func test_registry_selects_policy_and_preserves_dealt_build() -> void:
	var brain: BotBrain = BenchSuites.create_bot("rule:hedgerow_parish") as BotBrain
	assert_eq(brain.level.place, BotLevel.PLACE_RULE)
	assert_eq(brain.pinned_strategy, "hedgerow_parish")
	assert_eq(brain.level.name, BotLevel.HARD)


func test_null_arm_keeps_policy_and_changes_only_bot_stream_once() -> void:
	var stream: STREAM = BenchSuites.create_bot("hard_stream:hedgerow_parish") as STREAM
	var hard: BotBrain = BenchSuites.create_bot("hard:hedgerow_parish") as BotBrain
	assert_eq(stream.level.search_budget, hard.level.search_budget)
	assert_eq(stream.pinned_strategy, hard.pinned_strategy)
	var player := PlayerState.new()
	player.bot_rng.seed = 12345
	player.shop_rng.seed = 67890
	var shop_state: int = player.shop_rng.state
	stream._prepare_stream(player)
	assert_ne(player.bot_rng.seed, 12345)
	player.bot_rng.randi()
	var state: int = player.bot_rng.state
	stream._prepare_stream(player)
	assert_eq(player.bot_rng.state, state, "does not reset the stream each turn")
	assert_eq(player.shop_rng.state, shop_state)
	assert_eq(BenchSuites.comparison_kind("hard", "hard"), "bookkeeping")
	assert_eq(BenchSuites.comparison_kind("hard_stream", "hard"), "rng_aa")
	assert_eq(BenchSuites.comparison_kind("rule", "hard"), "promotion")


func test_plain_registry_alias_does_not_invent_a_strategy() -> void:
	var brain: BotBrain = BenchSuites.create_bot("hard") as BotBrain
	assert_eq(brain.pinned_strategy, "")
	assert_true(brain.value.strategy.is_empty())
