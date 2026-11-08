extends GutTest
## LegalActions and the tools/play command layer: every action listed succeeds if taken, with
## spells, heroes and Discovers in play. A whole game by random legal moves, replayed.
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
	assert_gt(taken, 20, "played a real game")


## A session whose human holds this board, with a real shop.
func _session_with(board: Dictionary) -> GameSession:
	var session := GameSession.create(5, UnitLibrary.load_dir(), GameConfig.full_game())
	while session.get_state()["pending_choice"] != null:
		session.choose(0)
	var human: PlayerState = session._players[0]
	human.gold = 10
	for slot: int in board:
		var def: Dictionary = session._rules.library.get_unit(str(board[slot]))
		human.board[slot] = RecruitUnit.make(def, session._rules.new_iid())
	return session


func _swallows(session: GameSession) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in LegalActions.of(session.get_state()):
		if entry["action"] == "swallow":
			out.append(entry)
	return out


func test_every_listed_swallow_goes_through_and_really_swallows() -> void:
	var first := _session_with({0: "wee_wobbly", 1: "mrs_sorrel"})
	var kinds: Dictionary = {}
	for entry: Dictionary in _swallows(first):
		var args: Array = entry["args"]
		kinds[args[0]] = true
		var session := _session_with({0: "wee_wobbly", 1: "mrs_sorrel"})
		assert_eq(_take(session, entry), "", "%s" % str(args))
		assert_eq(session._players[0].board[0].held.size(), 1, "%s" % str(args))
	assert_true(kinds.has(HeldUnits.SHOP), "from the shop")
	assert_true(kinds.has(HeldUnits.BOARD), "from the board")


func test_a_full_belly_lists_no_swallow() -> void:
	var session := _session_with({0: "wee_wobbly", 1: "mrs_sorrel"})
	session.swallow(HeldUnits.BOARD, 1, 0)
	assert_eq(_swallows(session), [] as Array[Dictionary])


func test_no_gold_lists_no_shop_swallow_but_a_discount_can_make_it_legal() -> void:
	var session := _session_with({0: "wee_wobbly"})
	session._players[0].gold = 0
	assert_eq(_swallows(session), [] as Array[Dictionary], "wobbly gives no discount")
	var cheap := _session_with({0: "little_dollop"})
	cheap._players[0].gold = cheap._rules.unit_cost(cheap._players[0]) - 1
	assert_false(_swallows(cheap).is_empty(), "a gold short, and Dollop makes up the gold")
	assert_eq(_take(cheap, _swallows(cheap)[0]), "")


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
	var game := PlayGame.start(5)
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


func test_play_tool_refuses_bad_words_without_recording() -> void:
	var game := PlayGame.start(5)
	for words: Array in [["choose", "abc"], ["choose"], ["choose", "1x"]]:
		assert_eq(game.run(PackedStringArray(words)), "choose needs a number: choose 1", str(words))
	assert_eq(game.to_save()["actions"].size(), 0, "none is in the save")
	assert_eq(game.run(PackedStringArray(["choose", "2"])), "", "a good one is")
	assert_string_contains(game.run(PackedStringArray(["power", "Z9"])), "No such slot", "bad slot")
	game.run(PackedStringArray(["buy", "0"]))
	assert_string_contains(
		game.run(PackedStringArray(["play", "0", "Z9"])), "No such slot", "here too"
	)
	assert_eq(game.to_save()["actions"].size(), 2, "only the two good ones")


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


func test_full_ring_is_excluded_only_for_ring_spells_using_live_hand_views() -> void:
	var session := _session_with({0: "pill_bug"})
	var human: PlayerState = session._players[0]
	var rules: RecruitRules = session._rules
	human.items.clear()
	BoardUpkeep.add_ring(human, 0, {"attack": 4, "health": 4})
	BoardUpkeep.add_ring(human, 1, {"attack": 3, "health": 3})
	rules.give_card(human, "spore_cloud")
	rules.give_card(human, "horseshoe")
	var state: Dictionary = session.get_state()
	assert_eq(state["hand_items"][0]["ring_add"], [2, 2])
	assert_false(state["hand_items"][1].has("ring_add"))
	var targets: Array = []
	for entry: Dictionary in LegalActions.of(state):
		if entry["action"] == "play_item":
			targets.append(entry["args"])
	assert_does_not_have(targets, [0, 0], "full Ring is not a legal Spore Cloud aim")
	assert_has(targets, [0, 1], "partial overflow remains legal")
	assert_has(targets, [1, 0], "Horseshoe remains legal on the same full slot")
	assert_eq(session.play_item(1, 0), "")
	assert_eq(session.play_item(0, 1), "")
