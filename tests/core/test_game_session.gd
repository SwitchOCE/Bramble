extends GutTest
## GameSession: the state format of SPEC section 6 against the fixtures, the human's actions,
## end of turn, matchmaking (2.1.2, 2.3), hero damage and elimination (chapter 10).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const ROUND1: String = "res://docs/prototype/fixtures/recruit_round1.json"
const ROUND7: String = "res://docs/prototype/fixtures/recruit_round7.json"

var _library: UnitLibrary = UnitLibrary.load_dir()


func _fixture(path: String) -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data


func _keys(entry: Dictionary) -> Array:
	var keys: Array = entry.keys()
	keys.sort()
	return keys


func test_state_keys_match_fixture_6_1() -> void:
	var state: Dictionary = GameSession.create(1, _library).get_state()
	assert_eq(_keys(state), _keys(_fixture(ROUND1)), "same keys as recruit_round1.json")


func test_unit_view_keys_match_fixture_6_2() -> void:
	var fixture: Dictionary = _fixture(ROUND7)
	var fixture_shop: Array = fixture["shop"]
	var expected: Array = _keys(fixture_shop[0])
	expected.append("keyword_text")
	expected.sort()
	var state: Dictionary = GameSession.create(1, _library).get_state()
	var shop: Array = state["shop"]
	assert_eq(_keys(shop[0]), expected, "shop view: 6.2 plus cost and keyword_text")
	var standings: Array = state["standings"]
	var fixture_standings: Array = fixture["standings"]
	assert_eq(_keys(standings[0]), _keys(fixture_standings[0]), "6.4 standing")


func test_round_one_state_3_2_1() -> void:
	var state: Dictionary = GameSession.create(1, _library).get_state()
	assert_eq(state["round"], 1, "round 1")
	assert_eq(state["phase"], "recruit", "recruit")
	assert_eq(state["gold"], 3, "income 3")
	assert_eq(state["tier"], 1, "tier 1")
	assert_eq(state["tier_up_cost"], 5, "upgrade 5")
	assert_eq(state["health"], 30, "30 health (2.2.5)")
	var shop: Array = state["shop"]
	assert_eq(shop.size(), 3, "3 shop units")
	assert_eq(state["last_combat"], null, "no fight yet")
	assert_eq(state["placement"], null, "alive")
	var standings: Array = state["standings"]
	assert_eq(standings.size(), 8, "8 players (2.1.1)")
	var bot_3: Dictionary = standings[3]
	assert_eq(bot_3["name"], "Bot 3 (wide)", "bot names")
	var opponent: int = state["next_opponent_id"]
	assert_true(opponent >= 1 and opponent <= 7, "an opponent is known (2.3.3)")


func test_human_actions() -> void:
	var session: GameSession = GameSession.create(5, _library)
	assert_eq(session.buy(0), "", "buy")
	assert_eq(session.buy(0), "Not enough gold", "3 gold buys one")
	assert_eq(session.play(0, 6), "", "play to B3")
	assert_eq(session.move(6, 1), "", "move to F2")
	var board: Array = session.get_state()["board"]
	assert_null(board[6], "B3 empty")
	assert_not_null(board[1], "F2 holds it")
	assert_eq(session.sell(1), "", "sell")
	assert_eq(session.get_state()["gold"], 1, "sold for 1")
	assert_eq(session.toggle_freeze(), "", "freeze")
	assert_eq(session.get_state()["frozen"], true, "frozen")
	assert_eq(session.refresh(), "", "refresh for 1")
	assert_eq(session.get_state()["frozen"], false, "refresh unfreezes")
	assert_eq(session.tier_up(), "Not enough gold", "tier up costs 5")


func test_end_turn_starts_next_round_4_1_2_4_6_3() -> void:
	var session: GameSession = GameSession.create(5, _library)
	assert_eq(session.end_turn(), "", "end turn")
	var state: Dictionary = session.get_state()
	assert_eq(state["round"], 2, "round 2")
	assert_eq(state["gold"], 3 + 4, "unspent gold carries over")
	assert_eq(state["tier_up_cost"], 4, "upgrade discount")
	var last: Dictionary = session.get_last_combat()
	assert_eq(_keys(last), ["damage", "events", "opponent_id", "round", "winner"], "fight record")
	assert_eq(last["round"], 1, "round 1's fight")
	var events: Array = last["events"]
	var start: Dictionary = events[0]
	assert_eq(start["player_ids"][0], 0, "the human is side 0")
	var summary: Dictionary = state["last_combat"]
	assert_eq(summary["damage"], last["damage"], "summary matches")


func test_empty_board_loses_and_takes_damage_10_1_1() -> void:
	var session: GameSession = GameSession.create(3, _library)
	session.end_turn()
	var last: Dictionary = session.get_last_combat()
	var health: int = session.get_state()["health"]
	if last["winner"] == 1:
		assert_eq(health, 30 - int(last["damage"]), "the loser takes the damage")
	else:
		assert_eq(health, 30, "an empty board can only tie or lose")


func test_actions_after_game_over() -> void:
	var session: GameSession = GameSession.create(3, _library)
	session._players[0].health = 0
	session.end_turn()
	var state: Dictionary = session.get_state()
	assert_true(session.is_over(), "the human is out: the game is over for them")
	assert_eq(state["phase"], "game_over", "phase")
	assert_eq(state["placement"], 8, "first out places 8th")
	assert_eq(session.buy(0), GameSession.GAME_OVER, "no actions")
	assert_eq(session.end_turn(), GameSession.GAME_OVER, "no more turns")


func test_same_round_eliminations_placed_by_health_10_2_2() -> void:
	var config := GameConfig.defaults()
	config.set_value("human_bot", "balanced")
	var session: GameSession = GameSession.create(4, _library, config)
	session._players[2].health = -5
	session._players[5].health = -1
	session.end_turn()
	var standings: Array[Dictionary] = session.get_standings()
	assert_false(standings[2]["alive"], "player 2 out")
	assert_eq(standings[2]["placement"], 8, "lower health places lower")
	assert_eq(standings[5]["placement"], 7, "higher health places higher")


func test_ghost_for_an_odd_player_out_2_1_2() -> void:
	var config := GameConfig.defaults()
	config.set_value("human_bot", "balanced")
	var session: GameSession = GameSession.create(4, _library, config)
	session._players[7].health = 0
	session.end_turn()
	var ghosts: int = 0
	for pair: Variant in session._pairings:
		var ids: Array = pair
		if ids[1] == Matchmaking.GHOST:
			ghosts += 1
	assert_eq(ghosts, 1, "7 alive: one fights the ghost")
	assert_eq(session._ghost_board.size(), 7, "the ghost is the eliminated player's board")


func test_eliminated_units_return_to_pool_5_3_8() -> void:
	var config := GameConfig.defaults()
	config.set_value("human_bot", "balanced")
	var session: GameSession = GameSession.create(6, _library, config)
	for _turn: int in 3:
		session.end_turn()
	var victim: PlayerState = session._players[4]
	var held: int = victim.owned_units().size() + victim.shop.size()
	assert_gt(held, 0, "the player holds units")
	var before: int = session._pool.total_copies()
	victim.health = -50
	session.end_turn()
	assert_eq(victim.owned_units().size(), 0, "nothing left on board or in hand")
	assert_eq(victim.shop.size(), 0, "nor in the shop")
	assert_gt(session._pool.total_copies(), before - 30, "copies came back")


func test_damage_cap_by_turn_and_alive_10_1_4() -> void:
	var session: GameSession = GameSession.create(4, _library)
	var caps: Array = []
	for round_number: int in [1, 3, 4, 7, 8, 30]:
		session._round = round_number
		caps.append(session._damage_cap())
	assert_eq(caps, [5, 5, 10, 10, 15, 15], "5 on turns 1-3, 10 on 4-7, 15 from 8")
	for id: int in [4, 5, 6, 7]:
		session._players[id].alive = false
	assert_eq(session._damage_cap(), 0, "no cap with 4 or fewer left")


func test_matchmaking_avoids_recent_opponents_2_3_2() -> void:
	var players: Array[PlayerState] = []
	for id: int in 8:
		var player := PlayerState.new()
		player.id = id
		players.append(player)
	players[0].recent_opponents = [1, 2, 3]
	players[1].recent_opponents = [0]
	players[2].recent_opponents = [0]
	players[3].recent_opponents = [0]
	var rng := RandomNumberGenerator.new()
	for fight_seed: int in 10:
		rng.seed = fight_seed
		var pairs: Array = Matchmaking.pair(players, rng)
		assert_eq(pairs.size(), 4, "four fights")
		for pair: Variant in pairs:
			var ids: Array = pair
			if ids[0] == 0:
				assert_false([1, 2, 3].has(ids[1]), "player 0 avoids its last 3 opponents")


func test_matchmaking_everyone_once() -> void:
	var players: Array[PlayerState] = []
	for id: int in 7:
		var player := PlayerState.new()
		player.id = id
		players.append(player)
	var rng := RandomNumberGenerator.new()
	var pairs: Array = Matchmaking.pair(players, rng)
	var seen: Array = []
	for pair: Variant in pairs:
		var ids: Array = pair
		seen.append(ids[0])
		if ids[1] != Matchmaking.GHOST:
			seen.append(ids[1])
	seen.sort()
	assert_eq(seen, [0, 1, 2, 3, 4, 5, 6], "every living player fights once")


func test_dev_actions_are_stubs_until_milestone_b() -> void:
	var session: GameSession = GameSession.create(1, _library)
	assert_eq(session.dev_add_gold(5), "Not built yet", "stub")
