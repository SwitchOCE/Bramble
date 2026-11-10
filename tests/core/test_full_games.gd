extends GutTest
## Whole bot-only games from several seeds run to the end without errors and end with one
## winner (rulebook 1.1.3, 10.2.3), and the same seed replays the same game (SPEC section 7).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const SharedLobby := preload("res://tests/core/shared_lobby.gd")
## Two seeds (was 5: 1, 2, 3, 42, 2026). The run's shared Hard lobby below plays the real game to
## its end with the same per-turn pool check, and the soak plays hundreds more.
const SEEDS: Array[int] = [1, 42]

var _library: UnitLibrary = TestLibraries.current()


func _bot_game(game_seed: int, pool_filter: String = "all") -> GameSession:
	var config := GameConfig.defaults()
	config.set_value("human_bot", "balanced")
	config.set_value("pool_filter", pool_filter)
	var library: UnitLibrary = (
		LegacyPrototypes.library() if config.card_set().is_empty() else _library
	)
	var session := GameSession.create(game_seed, library, config)
	var start_total: int = _copies_accounted(session)
	var turns: int = 0
	while not session.is_over() and turns < 60:
		assert_eq(session.end_turn(), "", "end_turn succeeds while the game runs")
		turns += 1
		assert_eq(_copies_accounted(session), start_total, "pool copies are conserved (5.3)")
	return session


## Copies in the pool plus every copy a player holds in shop, hand or board.
func _copies_accounted(session: GameSession) -> int:
	var total: int = session._pool.total_copies()
	for player: PlayerState in session._players:
		for unit: RecruitUnit in player.owned_units():
			total += unit.pool_copies
		for unit: RecruitUnit in player.shop:
			total += unit.pool_copies
	return total


func test_bot_games_end_with_one_winner_1_1_3() -> void:
	for game_seed: int in SEEDS:
		var session: GameSession = _bot_game(game_seed)
		assert_true(session.is_over(), "seed %d: the game ends" % game_seed)
		var places: Array = []
		var alive: int = 0
		for standing: Dictionary in session.get_standings():
			places.append(standing["placement"])
			if standing["alive"]:
				alive += 1
		places.sort()
		var state: Dictionary = session.get_state()
		var last_round: int = state["round"]
		var hit_round_limit: bool = last_round >= 50
		assert_eq(places, [1, 2, 3, 4, 5, 6, 7, 8], "seed %d: places 1-8 once each" % game_seed)
		if not hit_round_limit:
			assert_eq(alive, 1, "seed %d: one player left" % game_seed)


func test_skeleton_pool_games_end_10_2_3() -> void:
	# One seed (was 7 and 8); test_bot_games_end_with_one_winner_1_1_3 covers the full pool.
	for game_seed: int in [7]:
		var session: GameSession = _bot_game(game_seed, "skeleton")
		assert_true(session.is_over(), "seed %d: a skeleton-pool game ends" % game_seed)


func test_the_shared_hard_lobby_ends_with_places_and_conserves_the_pool_5_3() -> void:
	var lobby: Dictionary = SharedLobby.hard()
	assert_true(lobby["over"], "the real Hard lobby ends")
	assert_eq(lobby["end_turn_errors"], [], "end_turn succeeds while the game runs")
	var start: int = lobby["pool_start"]
	var turns: Array = lobby["pool_by_turn"]
	assert_gt(turns.size(), 0, "turns played")
	for turn: int in turns.size():
		assert_eq(turns[turn], start, "turn %d: pool copies are conserved (5.3)" % turn)
	var places: Array = []
	for standing: Dictionary in lobby["standings"]:
		places.append(standing["placement"])
	places.sort()
	assert_eq(places, [1, 2, 3, 4, 5, 6, 7, 8], "places 1-8 once each")


func test_same_seed_same_game_determinism() -> void:
	var first: GameSession = _bot_game(99)
	var second: GameSession = _bot_game(99)
	assert_eq(first.get_standings(), second.get_standings(), "same standings")
	assert_eq(first.get_last_combat(), second.get_last_combat(), "same last fight")


func test_different_seeds_differ() -> void:
	var first: GameSession = GameSession.create(1, LegacyPrototypes.library())
	var second: GameSession = GameSession.create(2, LegacyPrototypes.library())
	var shop_1: Array = first.get_state()["shop"]
	var shop_2: Array = second.get_state()["shop"]
	assert_ne(shop_1, shop_2, "different first shops")
