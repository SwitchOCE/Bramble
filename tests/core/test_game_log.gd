extends GutTest
## The game log for review (docs/ideation/engine.md): boards by round, placements, gold spent,
## per-tribe stats.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")


func _played_game() -> GameSession:
	var config := GameConfig.defaults()
	config.set_value("human_bot", "balanced")
	var session := GameSession.create(7, UnitLibrary.load_dir(), config)
	var turns: int = 0
	while not session.is_over() and turns < 80:
		session.end_turn()
		turns += 1
	return session


func test_log_has_every_player_and_their_placement() -> void:
	var session := _played_game()
	var game_log: Dictionary = session.get_game_log()
	var rows: Array = game_log["players"]
	assert_eq(rows.size(), 8, "the lobby")
	var seen: Array = []
	for row: Dictionary in rows:
		seen.append(row["placement"])
	seen.sort()
	assert_eq(seen, [1, 2, 3, 4, 5, 6, 7, 8], "one of each")


func test_log_has_boards_by_round() -> void:
	var game_log: Dictionary = _played_game().get_game_log()
	var row: Dictionary = game_log["players"][0]
	var rounds: Array = row["rounds"]
	assert_gt(rounds.size(), 0, "rounds played")
	var first: Dictionary = rounds[0]
	assert_eq(first["round"], 1, "starts at 1")
	assert_eq(first["board"].size(), BoardGeometry.SLOTS, "one entry per slot")
	var last: Dictionary = rounds[-1]
	assert_true(
		last["board"].any(func(unit: Variant) -> bool: return unit != null), "someone stood"
	)


func test_log_gold_spent_adds_up() -> void:
	var game_log: Dictionary = _played_game().get_game_log()
	for row: Dictionary in game_log["players"]:
		var total: int = 0
		for round_row: Dictionary in row["rounds"]:
			total += round_row["gold_spent"]
		assert_eq(row["gold_spent"], total, "%s's rounds sum to its total" % row["name"])


func test_log_tribe_stats_cover_main_tribes() -> void:
	var game_log: Dictionary = _played_game().get_game_log()
	var tribes: Dictionary = game_log["tribes"]
	var players: int = 0
	for tribe: String in tribes:
		var entry: Dictionary = tribes[tribe]
		players += entry["main_players"]
		if entry["main_players"] > 0:
			assert_between(float(entry["avg_placement"]), 1.0, 8.0, "%s's average" % tribe)
	assert_gt(players, 0, "someone played a tribe")


func test_log_is_available_mid_game() -> void:
	var config := GameConfig.defaults()
	var session := GameSession.create(7, UnitLibrary.load_dir(), config)
	assert_eq(session.get_game_log()["rounds"], 0, "nothing played")
	session.end_turn()
	assert_eq(session.get_game_log()["rounds"], 1, "one round")
