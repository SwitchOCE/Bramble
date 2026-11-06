extends GutTest
## The levelled bots, the scouting rule and the placer.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

var _library: UnitLibrary = UnitLibrary.load_dir()


func _full_game(seats: Array, game_seed: int) -> GameSession:
	var config: GameConfig = GameConfig.full_game()
	config.set_value("human_bot", str(seats[0]))
	config.set_value("bots", seats.slice(1))
	return GameSession.create(game_seed, _library, config)


func _play_out(session: GameSession) -> void:
	var turns: int = 0
	while not session.is_over() and turns < 60:
		assert_eq(session.end_turn(), "", "turn %d" % turns)
		turns += 1
	assert_true(session.is_over(), "the game finishes")


func _rules() -> RecruitRules:
	var config: GameConfig = GameConfig.defaults()
	return RecruitRules.create(_library, config, UnitPool.create(_library, config))


func _placed(rules: RecruitRules, player: PlayerState, ids: Array) -> void:
	for slot: int in ids.size():
		if ids[slot] != null:
			player.board[slot] = RecruitUnit.make(
				_library.get_unit(str(ids[slot])), rules.new_iid()
			)


func test_scouting_is_empty_in_round_1() -> void:
	var session: GameSession = _full_game(["hard", "hard"], 1)
	var state: Dictionary = session.get_state()
	assert_eq(state["next_opponent_last_board"], [], "nothing to see before a fight")


func test_scouting_shows_the_opponents_board_as_it_fought() -> void:
	var config: GameConfig = GameConfig.defaults()
	config.set_value("human_bot", "balanced")
	var session: GameSession = GameSession.create(4, _library, config)
	session.end_turn()
	var state: Dictionary = session.get_state()
	var seen: Array = state["next_opponent_last_board"]
	assert_eq(seen.size(), BoardGeometry.SLOTS, "one entry per slot")
	var opponent: int = state["next_opponent_id"]
	var rows: Array = session.get_game_log()["players"]
	var fought: Array = rows[opponent]["rounds"][0]["board"]
	for slot: int in BoardGeometry.SLOTS:
		if fought[slot] == null:
			assert_null(seen[slot], "slot %d stays empty" % slot)
		else:
			assert_eq(seen[slot]["def_id"], fought[slot]["def_id"], "slot %d" % slot)
			assert_true(seen[slot].has("stat_layers"), "the same dict as a board unit")


func test_scouting_does_not_show_this_rounds_changes() -> void:
	var session: GameSession = _full_game(["hard", "hard"], 2)
	session.end_turn()
	var before: String = JSON.stringify(session.get_state()["next_opponent_last_board"])
	session.refresh()
	assert_eq(JSON.stringify(session.get_state()["next_opponent_last_board"]), before, "fixed")


func test_every_level_plays_a_full_game() -> void:
	for level: String in BotLevel.ALL:
		var seats: Array = [level, level, level, level, level, level, level, level]
		var session: GameSession = _full_game(seats, 11)
		_play_out(session)
		assert_eq(session.get_game_log()["players"].size(), 8, level)


func test_a_seed_replays_exactly() -> void:
	var seats: Array = ["hard", "normal", "easy", "naive", "hard", "normal", "easy", "naive"]
	var one: GameSession = _full_game(seats, 21)
	_play_out(one)
	var two: GameSession = _full_game(seats, 21)
	_play_out(two)
	assert_eq(JSON.stringify(one.get_game_log()), JSON.stringify(two.get_game_log()), "same game")


func test_names_build_the_right_bot() -> void:
	var pinned: BotBrain = BotBrain.from_name("hard:hedgerow_parish@shuffled")
	assert_eq(pinned.level.name, BotLevel.HARD, "level")
	assert_eq(pinned.pinned_strategy, "hedgerow_parish", "strategy")
	assert_eq(pinned.level.place, BotLevel.PLACE_SHUFFLED, "placing")
	assert_null(BotBrain.from_name("balanced"), "an old personality isn't a brain")
	assert_false(Bot.create("balanced") is BotBrain, "and stays the old bot")


func test_quiet_fight_has_the_same_result() -> void:
	var board: Array = [{"def_id": "field_vole"}, null, null, null, null, null, null]
	var other: Array = [{"def_id": "marsh_frog"}, null, null, null, null, null, null]
	var results: Array = []
	for quiet: bool in [false, true]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 9
		var combat: Combat = Combat.create(_library, GameConfig.defaults(), rng)
		combat.log_events = not quiet
		var ids: Array[int] = [0, 1]
		var tiers: Array[int] = [1, 1]
		var result: Dictionary = combat.run([board, other], tiers, ids, 0)
		results.append([result["winner"], result["damage"]])
		assert_eq(result["events"].is_empty(), quiet, "events only when logging")
	assert_eq(results[0], results[1], "same fight")


func test_search_leaves_pinned_slots_alone() -> void:
	var rules: RecruitRules = _rules()
	var player := PlayerState.new()
	player.bot_rng.seed = 5
	_placed(rules, player, ["field_vole", "marsh_frog", null, null, "pixie_scout"])
	var problem := BoardSearch.Problem.new()
	problem.board = player.combat_board()
	problem.slots = player.combat_slots()
	problem.enemy = player.combat_board()
	problem.enemy_slots = player.combat_slots()
	problem.pinned = [0]
	problem.library = rules.library
	problem.config = rules.config
	var layout: Array[int] = BoardSearch.best_layout(problem, player.bot_rng, 40)
	assert_eq(layout[0], 0, "the pinned unit stays")


func test_search_with_nothing_scouted_keeps_the_board() -> void:
	var rules: RecruitRules = _rules()
	var player := PlayerState.new()
	player.bot_rng.seed = 6
	_placed(rules, player, ["field_vole", "marsh_frog", null, null, "pixie_scout"])
	var problem := BoardSearch.Problem.new()
	problem.board = player.combat_board()
	problem.library = rules.library
	problem.config = rules.config
	var same: Array[int] = BoardSearch.best_layout(problem, player.bot_rng, 40)
	assert_eq(same, BoardSearch.identity_layout(), "no enemy board, no change")


func test_moves_go_through_the_rules() -> void:
	var rules: RecruitRules = _rules()
	var player := PlayerState.new()
	_placed(rules, player, ["field_vole", "marsh_frog"])
	var layout: Array[int] = [1, 0, -1, -1, -1, -1, -1]
	var first: RecruitUnit = player.board[0]
	BotPlacer.apply_layout(player, rules, layout)
	assert_eq(player.board[1], first, "swapped")
	var moves: int = 0
	for entry: Dictionary in player.recruit_log:
		moves += 1 if str(entry["type"]) == "move" else 0
	assert_eq(moves, 1, "logged as one move")


func test_naive_buys_what_it_can_afford() -> void:
	var rules: RecruitRules = _rules()
	var player := PlayerState.new()
	player.bot_rng.seed = 3
	player.shop_rng.seed = 3
	rules.setup_player(player)
	rules.start_phase(player, 1)
	Bot.create("naive").play_turn(player, rules, 1)
	assert_eq(player.board_count(), 1, "3 gold, one unit, played")


func test_the_strategy_data_is_valid() -> void:
	var known: BotKnowledge = BotKnowledge.shared()
	assert_gt(known.strategies.size(), 0, "strategies load")
	for strategy_id: Variant in known.strategies:
		var entry: Dictionary = known.strategies[strategy_id]
		assert_eq(str(entry["id"]), str(strategy_id), "id")
		assert_true(entry.has("name") and entry.has("shape"), str(strategy_id))


# --- The slice's cards ---------------------------------------------------------------------------


func _slice_rules() -> RecruitRules:
	var config: GameConfig = GameConfig.full_game()
	var rules := RecruitRules.create(_library, config, UnitPool.create(_library, config))
	return rules


func _slice_player(rules: RecruitRules) -> PlayerState:
	var player := PlayerState.new()
	player.bot_rng.seed = 8
	player.shop_rng.seed = 8
	player.spell_rng.seed = 8
	rules.setup_player(player)
	return player


func _brain(bot_name: String, player: PlayerState, rules: RecruitRules) -> BotBrain:
	var brain: BotBrain = BotBrain.from_name(bot_name)
	brain._player = player
	brain._rules = rules
	return brain


func _item(rules: RecruitRules, card: String) -> HandItem:
	return HandItem.make(_library.get_card(card), rules.new_iid())


func test_every_id_in_the_bot_data_exists() -> void:
	var known: BotKnowledge = BotKnowledge.shared()
	for card: Variant in known.cards:
		var is_card: bool = not _library.get_unit(str(card)).is_empty()
		is_card = is_card or not _library.get_card(str(card)).is_empty()
		assert_true(is_card, "cards.json: %s" % card)
	for hero: Variant in known.heroes:
		assert_false(_library.get_hero(str(hero)).is_empty(), "heroes: %s" % hero)
	for strategy_id: Variant in known.strategies:
		var entry: Dictionary = known.strategies[strategy_id]
		var units: Dictionary = entry.get("units", {})
		for unit: Variant in units:
			assert_false(_library.get_unit(str(unit)).is_empty(), "%s: %s" % [strategy_id, unit])
		var spells: Dictionary = entry.get("spells", {})
		for spell: Variant in spells:
			assert_false(_library.get_card(str(spell)).is_empty(), "%s: %s" % [strategy_id, spell])


func test_a_unit_counting_turns_is_pinned_but_not_before_it_starts() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["sleeping_partner"])
	assert_eq(BotPlacer.pinned_slots(player), [] as Array[int], "not counting yet")
	player.board[0].turns_in_slot = 1
	assert_eq(BotPlacer.pinned_slots(player), [0] as Array[int], "counting")
	player.board[0].turns_in_slot = 3
	assert_eq(BotPlacer.pinned_slots(player), [] as Array[int], "done, free to move")


func test_a_band_pins_its_unit() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["pill_bug"])
	player.bands[0] = player.board[0].iid
	assert_eq(BotPlacer.pinned_slots(player), [0] as Array[int], "moving it would fade the band")


func test_acorns_are_cashed_only_when_gold_is_needed() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	player.items.append(_item(rules, "acorn"))
	player.items.append(_item(rules, "acorn"))
	var brain: BotBrain = _brain("normal", player, rules)
	player.gold = 3
	assert_true(brain._pay(3, 5.0), "has the gold")
	assert_eq(player.items.size(), 2, "keeps both Acorns")
	player.gold = 2
	assert_true(brain._pay(3, 5.0), "cashes to reach it")
	assert_eq([player.gold, player.items.size()], [3, 1], "one Acorn, no more")


func test_easy_cashes_acorns_at_once() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	rules.start_phase(player, 1)
	player.items.append(_item(rules, "acorn"))
	Bot.create("easy").play_turn(player, rules, 1)
	assert_eq(player.larder(), 0, "a person's first game spends what it has")


func test_a_treasurer_makes_holding_worth_something() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["honorary_treasurer"])
	player.items.append(_item(rules, "acorn"))
	var brain: BotBrain = _brain("normal", player, rules)
	player.gold = 2
	assert_false(brain._pay(3, 0.5), "not for a small gain")
	assert_true(brain._pay(3, 50.0), "yes for a big one")


func test_stats_are_never_aimed_at_a_shy_unit() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["hob_in_the_hearth", "pill_bug"])
	var brain: BotBrain = _brain("normal", player, rules)
	var aim: int = brain._aim_for(HandItem.AIM_UNIT, _library.get_card("pinch_of_dust"))
	assert_eq(aim, 1, "the Pill Bug, though the Hob is worth more")


func test_a_shy_unit_stays_out_from_behind_a_feeder() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["old_moth_annis", "pill_bug", "pill_bug", null, "hob_in_the_hearth"])
	var value := BotEval.make(BotLevel.of(BotLevel.NORMAL), BotKnowledge.shared())
	var layout: Array[int] = BotPlacer.rule_layout(player, value, [])
	var hob_at: int = layout.find(4)
	var moth_at: int = layout.find(0)
	assert_false(BoardGeometry.in_front_of(hob_at).has(moth_at), "the Moth doesn't feed the Hob")


func test_hard_puts_its_carry_where_a_pass_lands() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["mr_crumb", "pill_bug", "alderman_dozey"])
	player.pending_passes.append({"iid": player.board[0].iid, "slot": 0, "attack": 1, "health": 1})
	var value := BotEval.make(BotLevel.of(BotLevel.HARD), BotKnowledge.shared())
	var layout: Array[int] = BotPlacer.rule_layout(player, value, [])
	var landings: Array[int] = BotPlacer._pass_landings(player, layout)
	assert_eq(player.board[layout[landings[0]]].def_id(), "alderman_dozey", "the carry gets it")


func test_a_pinned_bot_plays_its_strategy() -> void:
	var seats: Array = []
	for strategy_id: String in ["fairies_hag", "hedgerow_parish"]:
		for _copy: int in 4:
			seats.append("hard:%s" % strategy_id)
	var session: GameSession = _full_game(seats, 31)
	_play_out(session)
	var bought: Dictionary = session.get_game_log()["players"][0]["bought_by_tribe"]
	assert_gt(CoreUtil.to_int(bought.get("Fairies", 0)), 0, "seat 0 buys Fairies")
