extends GutTest
## The lobby: pairing (2.3), the ghost (2.1.2), damage (10.1), elimination and game end (10.2,
## 2.1.3), pool returns on elimination (5.3.8), determinism.

@warning_ignore_start("unsafe_call_argument")

const CoreKit := preload("res://tests/core/core_kit.gd")


func _empty_round(game: GameSession) -> void:
	game.start_round()
	game.finish_round()


func test_2_3_1_everyone_meets_everyone_once_in_7_rounds() -> void:
	var game: GameSession = CoreKit.session(6)
	for _i: int in 7:
		_empty_round(game)
	for p: PlayerState in game.players:
		var met: Dictionary = {}
		for other: int in p.opponents:
			met[other] = true
		assert_eq(met.size(), 7, "player %d met %s" % [p.id, p.opponents])
		assert_false(met.has(p.id))


func test_2_3_2_no_rematch_within_3_rounds_after_an_elimination() -> void:
	var game: GameSession = CoreKit.session(7)
	game.start_round()
	game.player(3).health = 0
	game.finish_round()
	assert_false(game.player(3).alive)
	for _i: int in 6:
		_empty_round(game)
		for p: PlayerState in game.alive_players():
			var recent: Array[int] = p.opponents.slice(p.opponents.size() - 4)
			var last: int = recent.pop_back()
			if last != Matchmaking.GHOST:
				assert_false(recent.has(last), "p%d met %d again: %s" % [p.id, last, p.opponents])


func test_2_1_2_odd_player_out_fights_the_ghost() -> void:
	var game: GameSession = CoreKit.session(8)
	game.start_round()
	CoreKit.put(game, game.player(5), "t6_titan", 0)
	game.player(5).health = 0
	game.finish_round()
	assert_eq(game.ghost_of, 5)
	game.start_round()
	var ghost_pairs: Array = game.pairings.filter(
		func(pair: Array) -> bool: return pair[1] == Matchmaking.GHOST
	)
	assert_eq(ghost_pairs.size(), 1)
	var fighter: int = ghost_pairs[0][0]
	var health: int = game.player(fighter).health
	game.finish_round()
	assert_lt(game.player(fighter).health, health, "10.1.7 the ghost's titan deals damage")


func test_10_1_1_small_and_big_losses() -> void:
	var game: GameSession = CoreKit.session(9)
	game.start_round()
	var a: PlayerState = game.player(0)
	var b: PlayerState = game.player(game.opponent_of(0))
	CoreKit.put(game, a, "t6_titan", 0)
	game.finish_round()
	assert_eq(b.health, 40 - 5, "round 1 big loss: no kills against 1 starting unit")
	assert_eq(a.health, 40)


func test_10_1_1_killing_half_their_board_is_a_small_loss() -> void:
	var game: GameSession = CoreKit.session(9)
	game.start_round()
	var a: PlayerState = game.player(0)
	var b: PlayerState = game.player(game.opponent_of(0))
	CoreKit.put(game, a, "t6_titan", 0)
	var weak: Unit = CoreKit.put(game, a, "t1_plain", 4)
	weak.stats.set_attack = 0
	CoreKit.put(game, b, "t5_bomber", 4)
	game.player(b.id).board[4].stats.set_health = 1
	game.finish_round()
	var mine: Callable = func(f: Dictionary) -> bool: return CoreUtil.to_array(f["players"]).has(0)
	var fight: Dictionary = game.fights.filter(mine)[0]
	var result: Dictionary = fight["result"]
	var killed: Array = result["killed"]
	var expected: int = 2 if CoreUtil.to_int(killed[0]) >= 1 else 5
	assert_eq(b.health, 40 - expected, "small loss when the bomber's 8 killed the plain")


func test_10_1_6_a_tie_deals_no_damage() -> void:
	var game: GameSession = CoreKit.session(10)
	_empty_round(game)
	for p: PlayerState in game.players:
		assert_eq(p.health, 40)


func test_10_1_5_armor_absorbs_first() -> void:
	var game: GameSession = CoreKit.session(9)
	game.start_round()
	var a: PlayerState = game.player(0)
	var b: PlayerState = game.player(game.opponent_of(0))
	b.armor = 3
	CoreKit.put(game, a, "t6_titan", 0)
	game.finish_round()
	assert_eq([b.armor, b.health], [0, 38])


func test_10_2_2_same_round_eliminations_place_by_health() -> void:
	var game: GameSession = CoreKit.session(11)
	game.start_round()
	game.player(1).health = -3
	game.player(2).health = 0
	game.finish_round()
	assert_eq(game.player(1).placement, 8)
	assert_eq(game.player(2).placement, 7)
	assert_eq(game.ghost_of, 2, "the better placed becomes the ghost")


func test_5_3_8_eliminated_players_cards_go_back() -> void:
	var game: GameSession = CoreKit.session(12)
	game.start_round()
	var p: PlayerState = game.player(4)
	p.gold = 50
	game.act(4, {"type": "buy", "spell": false, "index": 0})
	game.act(4, {"type": "buy", "spell": false, "index": 1})
	game.act(4, {"type": "play", "hand": 0, "slot": 0, "target": -1})
	game.act(4, {"type": "freeze"})
	p.health = 0
	game.finish_round()
	var held: int = 0
	for other: PlayerState in game.alive_players():
		for card_id: StringName in other.shop_units:
			held += 1 if card_id != PlayerState.NO_CARD else 0
		for unit: Unit in other.all_cards():
			held += unit.pool_copies if not unit.is_spell() else 0
	var total: int = 0
	for card_id: StringName in game.units.ids():
		total += game.units.starting_copies(card_id)
	assert_eq(game.units.total_left() + held, total)


func test_10_2_3_last_player_left_wins() -> void:
	var game: GameSession = CoreKit.session(13)
	game.start_round()
	for id: int in range(1, 8):
		game.player(id).health = -id
	game.finish_round()
	assert_true(game.over)
	assert_eq(game.player(0).placement, 1)
	assert_eq(game.player(7).placement, 8)
	assert_eq(game.player(1).placement, 2)


func test_2_1_3_round_limit_places_by_health() -> void:
	var config := GameConfig.new()
	config.round_limit = 3
	var game: GameSession = CoreKit.session(14, config)
	for id: int in 8:
		game.player(id).health = 10 + id
	for _i: int in 3:
		_empty_round(game)
	assert_true(game.over)
	assert_eq(game.player(7).placement, 1)
	assert_eq(game.player(0).placement, 8)


func test_bots_play_whole_games_without_refusals() -> void:
	for game_seed: int in [21, 22]:
		var game: GameSession = CoreKit.session(game_seed)
		game.keep_fight_events = false
		var bots: Array[Bot] = []
		for id: int in 8:
			var stream: Rng = Rng.derive(game_seed, "bot:%d" % id)
			if id < 4:
				bots.append(SimpleBot.new(stream))
			else:
				bots.append(RandomBot.new(stream))
		while not game.over:
			game.start_round()
			for p: PlayerState in game.alive_players():
				bots[p.id].take_turn(game, p.id)
			game.finish_round()
		var places: Array = game.placements().values()
		places.sort()
		assert_eq(places, [1, 2, 3, 4, 5, 6, 7, 8])
		for bot: Bot in bots:
			assert_eq(bot.refused, 0, bot.last_refusal)
		assert_lt(game.round_number, 50, "the game ended by eliminations")


func test_same_seed_same_game() -> void:
	var logs: Array[String] = []
	for _run: int in 2:
		var game: GameSession = CoreKit.session(31)
		var bots: Array[Bot] = []
		for id: int in 8:
			bots.append(SimpleBot.new(Rng.derive(31, "bot:%d" % id)))
		for _round: int in 6:
			game.start_round()
			for p: PlayerState in game.alive_players():
				bots[p.id].take_turn(game, p.id)
			game.finish_round()
		logs.append(JSON.stringify(game.events))
	assert_eq(logs[0].length(), logs[1].length())
	assert_true(logs[0] == logs[1], "the whole game log repeats")
