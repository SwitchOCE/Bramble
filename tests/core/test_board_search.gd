extends GutTest
## BoardSearch and the bot's experiment placements. Normal games don't use any of this.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")

var _library: UnitLibrary = UnitLibrary.load_dir(UnitLibrary.DEFAULT_DIR, "position_test")


func _search(board: Array, opponents: Array, search_seed: int, budget: int = 200) -> Array[int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = search_seed
	return BoardSearch.best_layout(board, opponents, _library, GameConfig.defaults(), rng, budget)


func test_no_opponents_keeps_the_board() -> void:
	var board: Array = Kit.board({3: Kit.plain(1, 1)})
	assert_eq(_search(board, [], 1), BoardSearch.identity_layout(), "unchanged")


func test_every_layout_keeps_every_unit_once() -> void:
	var board: Array = Kit.board({0: Kit.plain(1, 1), 2: Kit.plain(2, 2), 6: Kit.plain(3, 3)})
	var layout: Array[int] = _search(board, [Kit.board({0: Kit.plain(1, 5)})], 3, 60)
	var used: Array[int] = []
	for source: int in layout:
		if source >= 0:
			used.append(source)
	used.sort()
	assert_eq(used, [0, 2, 6], "the same three units")


func test_same_seed_same_answer() -> void:
	var board: Array = Kit.board({0: Kit.plain(3, 5), 1: Kit.plain(1, 9), 4: Kit.plain(2, 2)})
	var theirs: Array = [Kit.board({0: Kit.plain(3, 6), 1: Kit.plain(2, 3)})]
	assert_eq(_search(board, theirs, 9), _search(board, theirs, 9), "reproducible")


func test_it_puts_the_lantern_behind_the_hitter() -> void:
	# The hitter needs the Lantern's +2 to win: 3 Attack takes three hits, 5 takes two.
	var board: Array = Kit.board({0: Kit.u("glow_worm_lantern"), 6: Kit.plain(3, 11)})
	var theirs: Array = [Kit.board({0: Kit.plain(5, 10)})]
	var layout: Array[int] = _search(board, theirs, 5, 300)
	var lantern: int = layout.find(0)
	var hitter: int = layout.find(6)
	assert_true(BoardGeometry.is_back(lantern), "the Lantern is in the back row")
	assert_true(BoardGeometry.in_front_of(lantern).has(hitter), "with the hitter in front of it")


func test_it_pairs_both_ends_units_on_the_ends() -> void:
	var board: Array = Kit.board(
		{1: Kit.u("hedgehog_twin"), 2: Kit.u("hedgehog_twin"), 4: Kit.plain(1, 1)}
	)
	var theirs: Array = [Kit.board({0: Kit.plain(4, 9), 1: Kit.plain(2, 4)})]
	var layout: Array[int] = _search(board, theirs, 11, 400)
	var ends: Array = [layout[0], layout[3]]
	ends.sort()
	var back_ends: Array = [layout[4], layout[6]]
	back_ends.sort()
	assert_true(ends == [1, 2] or back_ends == [1, 2], "the twins are a pair: %s" % str(layout))


func test_random_layout_spreads_over_all_slots() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var occupied: Array[int] = [0]
	var seen: Dictionary = {}
	for attempt: int in 200:
		seen[BoardSearch.random_layout(occupied, rng).find(0)] = true
	assert_eq(seen.size(), BoardGeometry.SLOTS, "every slot")


func _owned_by_round(placement: String, game_seed: int, rounds: int) -> Array:
	var config := GameConfig.defaults()
	config.set_value("human_bot", Bot.BALANCED)
	config.set_value("human_placement", placement)
	config.set_value("human_search_budget", 8)
	var session := GameSession.create(game_seed, _library, config)
	var out: Array = []
	for round_number: int in rounds:
		session.end_turn()
		var ids: Array = []
		for unit: RecruitUnit in session._players[GameSession.HUMAN_ID].owned_units():
			ids.append(unit.def_id())
		ids.sort()
		out.append(ids)
	return out


func test_placement_modes_buy_the_same_units() -> void:
	# Before anyone is eliminated the pool can't differ, so the units must match exactly.
	var heuristic: Array = _owned_by_round(Bot.PLACE_HEURISTIC, 7, 5)
	assert_eq(_owned_by_round(Bot.PLACE_SHUFFLED, 7, 5), heuristic, "shuffled buys the same")
	assert_eq(_owned_by_round(Bot.PLACE_SEARCH, 7, 5), heuristic, "search buys the same")
	assert_eq(_owned_by_round(Bot.PLACE_ORACLE, 7, 5), heuristic, "oracle buys the same")
	assert_eq(_owned_by_round(Bot.PLACE_SCOUT, 7, 5), heuristic, "scout buys the same")


func test_the_default_placement_is_untouched() -> void:
	var bot := Bot.create(Bot.BALANCED)
	assert_eq(bot.placement, "", "no mode")
	assert_eq(GameConfig.defaults().get_string("human_placement"), "", "off by default")


func test_pool_exclude_leaves_a_unit_out() -> void:
	var config := GameConfig.defaults()
	config.set_value("pool_exclude", ["field_vole"])
	var pool: UnitPool = UnitPool.create(_library, config)
	assert_false(pool.has_unit("field_vole"), "excluded")
	assert_true(pool.has_unit("pixie_scout"), "others stay")
	assert_true(pool.has_unit("lone_lynx"), "the experiment's units are in its library's pool")


func _rule_run(rule: String, mine: Array, theirs: Array, fight_seed: int = 1) -> Dictionary:
	var config := GameConfig.defaults()
	config.set_value("combat_rules", [rule])
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	return Combat.create(_library, config, rng).run([mine, theirs], tiers, ids, 0)


func test_column_rule_exposes_a_back_unit_with_nobody_in_front_of_it() -> void:
	var mine: Array = Kit.board({0: Kit.plain(1, 200), 1: Kit.plain(0, 9)})
	var theirs: Array = Kit.board({0: Kit.plain(0, 200), 6: Kit.plain(0, 200)})
	var hit_back: bool = false
	for fight_seed: int in 20:
		var result: Dictionary = _rule_run(Combat.RULE_COLUMN, mine, theirs, fight_seed)
		if Kit.of_type(result, "attack")[0]["defender"] == 4:
			hit_back = true
	assert_true(hit_back, "B3 has nobody in F3 or F4, so it can be attacked")


func test_across_rule_targets_the_slot_across() -> void:
	var mine: Array = Kit.board({2: Kit.plain(1, 200), 0: Kit.plain(0, 9)})
	var theirs: Array = Kit.board({0: Kit.plain(0, 200), 2: Kit.plain(0, 200)})
	for fight_seed: int in 10:
		var result: Dictionary = _rule_run(Combat.RULE_ACROSS, mine, theirs, fight_seed)
		assert_eq(Kit.of_type(result, "attack")[0]["defender"], 4, "F3 hits F3")


func test_back_half_rule_halves_back_row_damage_rounding_up() -> void:
	var mine: Array = Kit.board({4: Kit.plain(5, 200), 5: Kit.plain(0, 9)})
	var result: Dictionary = _rule_run(
		Combat.RULE_BACK_HALF, mine, Kit.board({0: Kit.plain(0, 200)})
	)
	assert_eq(Kit.of_type(result, "damage")[0]["amount"], 3, "5 -> 3")


func test_no_rule_flags_by_default() -> void:
	var rules: Array = GameConfig.defaults().get_value("combat_rules")
	assert_true(rules.is_empty(), "off")
