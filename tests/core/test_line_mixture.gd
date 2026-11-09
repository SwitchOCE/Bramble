extends GutTest
@warning_ignore_start("unsafe_call_argument")


func test_strength_comparison_excludes_hard_anchors_from_the_candidate() -> void:
	var seen: PackedStringArray = []
	for leg: int in 2:
		var seats: PackedStringArray = BenchSuites.seats(
			"head_to_head", 71, BenchSuites.TRIBAL_MIXTURE, "hard_field", leg
		)
		for seat: int in 8:
			if BenchSuites.candidate_seats(71, leg).has(seat):
				seen.append(seats[seat].get_slice(":", 0))
			else:
				assert_eq(seats[seat], "hard_field:varied")
	assert_eq(seen.count("line_tempo"), 4)
	assert_eq(seen.count("line_engine"), 3)
	assert_eq(seen.count("line_fast"), 1)
	assert_false(seen.has("hard_field"))


func test_mixture_covers_the_exact_line_lobby_across_swapped_legs() -> void:
	for game_seed: int in [1, 2, 17, 193]:
		var lobby: PackedStringArray = BenchSuites.seats("lines", game_seed)
		var seen: PackedStringArray = []
		for leg: int in 2:
			var seats: PackedStringArray = BenchSuites.seats(
				"head_to_head", game_seed, BenchSuites.LINE_MIXTURE, "hard", leg
			)
			var candidates: Array[int] = BenchSuites.candidate_seats(game_seed, leg)
			for seat: int in 8:
				if candidates.has(seat):
					assert_eq(seats[seat].get_slice(":", 0), lobby[seat].get_slice(":", 0))
					seen.append(seats[seat].get_slice(":", 0))
				else:
					assert_eq(seats[seat], "hard:varied")
		assert_eq(seen.count("hard_field"), 2)
		assert_eq(seen.count("line_tempo"), 2)
		assert_eq(seen.count("line_engine"), 3)
		assert_eq(seen.count("line_fast"), 1)


func test_mixture_preserves_the_available_tribe_deal_at_every_seat() -> void:
	var tribes: PackedStringArray = ["Birds", "Fairies", "Hunters", "Bog folk", "Oozes"]
	for leg: int in 2:
		var mixed_rng := RandomNumberGenerator.new()
		var hard_rng := RandomNumberGenerator.new()
		mixed_rng.seed = 83
		hard_rng.seed = 83
		var mixed: PackedStringArray = BotLobby.resolve(
			BenchSuites.seats("head_to_head", 19, BenchSuites.LINE_MIXTURE, "hard", leg),
			tribes,
			mixed_rng
		)
		var hard: PackedStringArray = BotLobby.resolve(
			BenchSuites.seats("head_to_head", 19, "hard", "hard", leg), tribes, hard_rng
		)
		for seat: int in 8:
			assert_eq(mixed[seat].get_slice(":", 1), hard[seat].get_slice(":", 1))
			var brain: Bot = BenchSuites.create_bot(mixed[seat])
			assert_not_null(brain)


func test_mixture_is_only_accepted_as_a_head_to_head_composition() -> void:
	assert_true(BenchSuites.is_candidate(BenchSuites.LINE_MIXTURE, "head_to_head"))
	assert_true(BenchSuites.is_candidate(BenchSuites.TRIBAL_MIXTURE, "head_to_head"))
	assert_false(BenchSuites.is_candidate(BenchSuites.LINE_MIXTURE, "line_tune"))
	assert_eq(BenchSuites.comparison_kind(BenchSuites.TRIBAL_MIXTURE, "hard_field"), "promotion")
	assert_eq(BenchSuites.comparison_kind("hard_field", BenchSuites.TRIBAL_MIXTURE), "promotion")
	assert_eq(
		BenchSuites.comparison_kind(BenchSuites.TRIBAL_MIXTURE, BenchSuites.TRIBAL_MIXTURE),
		"bookkeeping"
	)
	assert_eq(BenchSuites.comparison_kind(BenchSuites.LINE_MIXTURE, "hard"), "promotion")
	assert_eq(
		BenchSuites.comparison_kind(BenchSuites.LINE_MIXTURE, BenchSuites.LINE_MIXTURE),
		"bookkeeping"
	)
