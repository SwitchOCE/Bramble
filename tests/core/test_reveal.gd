extends GutTest
## The reveal, a test rule that is off by default (evidence/reveal.md).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = UnitLibrary.load_dir()


func _board(ids: Array) -> Array:
	var out: Array = []
	for value: Variant in ids:
		if value == null:
			out.append(null)
		else:
			out.append({"def_id": str(value), "golden": false})
	return out


func test_off_by_default() -> void:
	assert_false(Reveal.applies(GameConfig.defaults(), 5))
	assert_false(Reveal.applies(GameConfig.full_game(), 5))


func test_from_round() -> void:
	var config: GameConfig = GameConfig.defaults()
	config.set_value("reveal_swaps", 1)
	config.set_value("reveal_from_round", 3)
	assert_false(Reveal.applies(config, 2))
	assert_true(Reveal.applies(config, 3))


func test_swaps_need_a_unit() -> void:
	var board: Array = _board(["field_vole", null, null, null, null, null, null])
	assert_eq(Reveal.swap_pairs(board).size(), 6, "the vole with each other slot")
	# Two units: 6 + 6 pairs, less the one they share.
	board[4] = {"def_id": "marsh_frog", "golden": false}
	assert_eq(Reveal.swap_pairs(board).size(), 11)


func test_reachable_boards_are_distinct() -> void:
	var board: Array = _board(["field_vole", "marsh_frog", null, null, null, null, null])
	var one: Array = Reveal.reachable(board, 1)
	assert_eq(one.size(), 1 + 11, "standing still and every swap")
	var seen: Dictionary = {}
	for value: Variant in Reveal.reachable(board, 2):
		var layout: Array[int] = []
		var entries: Array = value
		layout.assign(entries)
		seen[str(BoardSearch.arranged_specs(board, layout))] = true
	assert_eq(seen.size(), Reveal.reachable(board, 2).size(), "no board twice")
	# Two units over 7 slots: 7 * 6 = 42 boards, all within two swaps.
	assert_eq(seen.size(), 42)


func test_random_swaps_stay_within_the_limit() -> void:
	var board: Array = _board(["field_vole", "marsh_frog", "field_vole", null, null, null, null])
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for attempt: int in 20:
		var layout: Array[int] = Reveal.random_swaps(board, 1, rng)
		var moved: int = 0
		for slot: int in BoardGeometry.SLOTS:
			moved += 1 if layout[slot] != slot else 0
		assert_eq(moved, 2, "one swap moves two slots")


func test_compose_applies_inner_first() -> void:
	var a: Array[int] = Reveal.swapped(BoardSearch.identity_layout(), Vector2i(0, 1))
	var b: Array[int] = Reveal.swapped(BoardSearch.identity_layout(), Vector2i(1, 2))
	var board: Array = _board(["field_vole", "marsh_frog", null, null, null, null, null])
	var both: Array = BoardSearch.arranged_specs(board, Reveal.compose(a, b))
	var step: Array = BoardSearch.arranged_specs(BoardSearch.arranged_specs(board, a), b)
	assert_eq(both, step)


func test_a_game_with_the_reveal_runs_and_reports_swaps() -> void:
	var config: GameConfig = GameConfig.full_game()
	config.set_value("human_bot", "hard")
	config.set_value("bots", ["hard", "hard", "normal", "normal", "easy", "easy", "naive"])
	config.set_value("reveal_swaps", 1)
	var session: GameSession = GameSession.create(3, _library, config)
	var reveals: Array = []
	session.fight_observer = func(_r: int, _a: int, _b: int, result: Dictionary) -> void:
		if result.has("reveal"):
			reveals.append(result["reveal"])
	for turn: int in 4:
		session.end_turn()
	assert_gt(reveals.size(), 0, "fights had a reveal")
	var swapped: int = 0
	for value: Variant in reveals:
		var reveal: Dictionary = value
		var layouts: Array = reveal["layouts"]
		for layout: Variant in layouts:
			swapped += 1 if layout != BoardSearch.identity_layout() else 0
	assert_gt(swapped, 0, "some side swapped")
