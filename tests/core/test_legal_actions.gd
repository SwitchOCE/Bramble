extends GutTest
## LegalActions and the tools/play command layer: every action listed succeeds if taken, with
## spells, heroes, Discovers and merges in play. A whole game by random legal moves, replayed.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const MAX_ACTIONS: int = 800


## LegalActions names are the session's own methods.
func _take(session: GameSession, entry: Dictionary) -> String:
	var args: Array = entry["args"]
	var problem: String = session.callv(str(entry["action"]), args)
	return problem


func test_every_legal_action_succeeds_through_a_whole_game() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var session := GameSession.create(21, SoakContent.build(), GameConfig.full_game())
	var taken: int = 0
	var refused: int = 0
	while not session.is_over() and taken < MAX_ACTIONS:
		var legal: Array[Dictionary] = LegalActions.of(session.get_state())
		assert_gt(legal.size(), 0, "there's always something to do")
		var entry: Dictionary = legal[rng.randi_range(0, legal.size() - 1)]
		if rng.randf() < 0.1:
			for candidate: Dictionary in legal:
				if candidate["action"] == "end_turn":
					entry = candidate
		var problem: String = _take(session, entry)
		if problem != "":
			refused += 1
			gut.p("%s %s: %s" % [entry["action"], entry["args"], problem])
		taken += 1
	assert_eq(refused, 0, "no listed action was refused")
	assert_gt(taken, 50, "played a real game")


func test_nothing_is_legal_once_the_game_is_over() -> void:
	var config := GameConfig.defaults()
	var session := GameSession.create(3, UnitLibrary.load_dir(), config)
	var turns: int = 0
	while not session.is_over() and turns < 80:
		session.end_turn()
		turns += 1
	assert_eq(LegalActions.of(session.get_state()), [] as Array[Dictionary], "game over")


func test_while_choosing_only_choices_are_legal() -> void:
	var config := GameConfig.defaults()
	config.set_value("hero_choice", true)
	var session := GameSession.create(3, UnitLibrary.load_dir(), config)
	var legal: Array[Dictionary] = LegalActions.of(session.get_state())
	assert_eq(legal.size(), 3, "three heroes")
	assert_eq(legal[0]["action"], "choose", "and nothing else")


func _played(actions: Array) -> PlayGame:
	var game := PlayGame.start(5, "hard")
	for value: Variant in actions:
		assert_eq(game.run(PackedStringArray(value)), "", "ran %s" % str(value))
	return game


func test_play_tool_replays_to_the_same_state() -> void:
	var game := _played([["choose", "0"], ["buy", "0"], ["play", "0", "F2"], ["end"]])
	var again := PlayGame.from_save(game.to_save())
	assert_eq(PlayView.text(again, ""), PlayView.text(game, ""), "same screen from the save")


func test_play_tool_refuses_without_recording() -> void:
	var game := _played([["choose", "0"]])
	assert_eq(game.run(PackedStringArray(["sell", "F1"])), "No unit there", "nothing to sell")
	assert_eq(
		game.run(PackedStringArray(["dance"])).begins_with("Unknown command"), true, "no such"
	)
	assert_eq(game.to_save()["actions"].size(), 1, "only the good one is in the save")


func test_play_tool_shop_numbers_run_on_into_spells() -> void:
	var game := _played([["choose", "0"]])
	var state: Dictionary = game.session.get_state()
	var units: int = state["shop"].size()
	var cost: int = state["shop_spells"][0]["cost"]
	assert_lte(cost, 3, "affordable on round 1 with sample spells")
	assert_eq(game.run(PackedStringArray(["buy", str(units)])), "", "the spell's number")
	assert_eq(game.session.get_state()["hand_items"].size(), 1, "the spell is in hand")


func test_play_view_shows_what_a_player_needs() -> void:
	var game := _played([["choose", "0"], ["end"]])
	var screen: String = PlayView.text(game, "")
	for part: String in [
		"gold", "tier", "health", "SHOP", "BOARD", "HAND", "LOBBY", "LEGAL", "LAST FIGHT"
	]:
		assert_string_contains(screen, part, part)


func test_play_view_json_parses() -> void:
	var game := _played([["choose", "0"]])
	var parsed: Variant = JSON.parse_string(PlayView.json(game, ""))
	assert_eq(typeof(parsed), TYPE_DICTIONARY, "a JSON object")
