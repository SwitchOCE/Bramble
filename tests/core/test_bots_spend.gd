extends GutTest
## Bots buy units before spells, so nobody fights round 1 with an empty board and gold spent.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")


func _first_rounds_boards(game_seed: int, bots: Array) -> Array:
	var config := GameConfig.full_game()
	config.set_value("bots", bots)
	config.set_value("human_bot", "balanced")
	var session := GameSession.create(game_seed, UnitLibrary.load_dir(), config)
	session.end_turn()
	session.end_turn()
	var rows: Array = session.get_game_log()["players"]
	return rows


## Greedy holds its gold on round 1, and so do the economy and climb openings.
## Every other bot fields one.
func test_every_bot_fields_a_unit_by_round_two() -> void:
	var lobbies: Array = [BotLobby.seats(BotLevel.HARD), BotLobby.seats(BotLevel.NORMAL)]
	for bots: Array in lobbies:
		for game_seed: int in [7, 8, 9, 10, 11]:
			for row: Dictionary in _first_rounds_boards(game_seed, bots):
				if row["personality"] == Bot.GREEDY:
					continue
				var board: Array = row["rounds"][1]["board"]
				var fielded: bool = board.any(func(unit: Variant) -> bool: return unit != null)
				assert_true(fielded, "seed %d %s" % [game_seed, row["name"]])


func test_a_spell_is_bought_only_with_gold_left_after_units() -> void:
	var kit := RecruitRules.create(
		UnitLibrary.load_dir(),
		_spell_config(),
		UnitPool.create(UnitLibrary.load_dir(), _spell_config())
	)
	var player := PlayerState.new()
	player.shop_rng.seed = 7
	player.bot_rng.seed = 7
	player.spell_rng.seed = 7
	kit.setup_player(player)
	kit.start_phase(player, 1)
	Bot.create(Bot.BALANCED).play_turn(player, kit, 1)
	assert_gt(player.board_count(), 0, "the 3 gold went on a unit")
	assert_eq(player.items.size(), 0, "not on a spell")


func _spell_config() -> GameConfig:
	var config := GameConfig.defaults()
	config.set_value("spells_in_shop", true)
	return config
