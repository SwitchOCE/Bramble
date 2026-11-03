extends GutTest
## Whole bot-only games from several seeds run to the end without errors and end with one
## winner (rulebook 1.1.3, 10.2.3), and the same seed replays the same game (SPEC section 7).

const SEEDS: Array[int] = [1, 2, 3, 42, 2026]

var _library: UnitLibrary = UnitLibrary.load_dir()


func _bot_game(game_seed: int, pool_filter: String = "all") -> GameSession:
	var config := GameConfig.defaults()
	config.set_value("human_bot", "balanced")
	config.set_value("pool_filter", pool_filter)
	var session := GameSession.create(game_seed, _library, config)
	var turns: int = 0
	while not session.is_over() and turns < 60:
		assert_eq(session.end_turn(), "", "end_turn succeeds while the game runs")
		turns += 1
	return session


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
	for game_seed: int in [7, 8]:
		var session: GameSession = _bot_game(game_seed, "skeleton")
		assert_true(session.is_over(), "seed %d: a skeleton-pool game ends" % game_seed)


func test_same_seed_same_game_determinism() -> void:
	var first: GameSession = _bot_game(99)
	var second: GameSession = _bot_game(99)
	assert_eq(first.get_standings(), second.get_standings(), "same standings")
	assert_eq(first.get_last_combat(), second.get_last_combat(), "same last fight")


func test_different_seeds_differ() -> void:
	var first: GameSession = GameSession.create(1, _library)
	var second: GameSession = GameSession.create(2, _library)
	var shop_1: Array = first.get_state()["shop"]
	var shop_2: Array = second.get_state()["shop"]
	assert_ne(shop_1, shop_2, "different first shops")
