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
