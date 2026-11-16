extends GutTest
## The game flow's plain screens and the controller's round on screen.

@warning_ignore_start("unsafe_call_argument")


func test_the_screens_action_reaches_the_core_and_its_picker_is_used() -> void:
	var game := GameController.new()
	add_child_autofree(game)
	game.start(GameContent.load_default(), 4)
	game.recruit.action_requested.emit({"type": "buy", "spell": false, "index": 0})
	assert_eq(game.flow.human().hand.size(), 1, "the screen's action went to the core")
	assert_null(game.find_child("Discover", false, false), "no stand-in picker of the flow's own")
	assert_eq(game.fight.process_mode, Node.PROCESS_MODE_DISABLED, "the hidden fight gets no input")


func test_one_input_shows_the_result_and_the_next_moves_on() -> void:
	var game := GameController.new()
	add_child_autofree(game)
	game.start(GameContent.load_default(), 4)
	game.request({"type": "buy", "spell": false, "index": 0})
	game.request({"type": "play", "hand": 0, "slot": 0, "target": -1})
	game.request({"type": "end_turn"})
	assert_eq(game.phase, GameController.Phase.FIGHT)
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	game._input(key)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "the first input shows the result")
	assert_true(game.fight.show_leaderboard, "with everyone's Health")
	var moment: Dictionary = game.fight.state["moment"]
	assert_true(moment.has("result"))
	game._input(key)
	assert_eq(game.phase, GameController.Phase.RECRUIT, "the second moves on at once")
	assert_eq(game.flow.session.round_number, 2)


func test_the_result_shows_counters_after_the_fight() -> void:
	var game := GameController.new()
	add_child_autofree(game)
	game.start(GameContent.load_default(), 4)
	game.request({"type": "buy", "spell": false, "index": 0})
	game.request({"type": "play", "hand": 0, "slot": 0, "target": -1})
	game.request({"type": "end_turn"})
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	game._input(key)
	var after: Array = ViewAdapter.counters(
		game.flow.content, game.flow.session.view_for(GameFlow.HUMAN)
	)
	assert_eq(game.fight.state["counters"], after)


func test_start_screen_leaves_tribes_out_but_never_all() -> void:
	var start := StartScreen.new()
	start.tribes = PackedStringArray(["A", "B"])
	add_child_autofree(start)
	assert_eq(start.chosen(), PackedStringArray(), "all by default")
	start.toggle("A")
	assert_eq(start.chosen(), PackedStringArray(["B"]))
	start.toggle("B")
	assert_eq(start.chosen(), PackedStringArray(["B"]), "the last tribe stays in")


func test_ordinals() -> void:
	assert_eq(
		[1, 2, 3, 4, 8, 11, 21].map(ResultScreen.ordinal),
		["1st", "2nd", "3rd", "4th", "8th", "11th", "21st"]
	)


func test_controller_plays_a_round_with_its_fight() -> void:
	var game := GameController.new()
	add_child_autofree(game)
	game.start(GameContent.load_default(), 4)
	assert_eq(game.phase, GameController.Phase.RECRUIT)
	game.request({"type": "buy", "spell": false, "index": 0})
	game.request({"type": "play", "hand": 0, "slot": 0, "target": -1})
	assert_eq(game.flow.human().board_count(), 1, "bought and played")
	game.request({"type": "end_turn"})
	assert_eq(game.phase, GameController.Phase.FIGHT, "the human's fight plays")
	assert_true(game.fight.visible)
	game.fight.skip()
	await wait_seconds(0.2)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "the result with the leaderboard")
	game.call("_after_fight")
	assert_eq(game.phase, GameController.Phase.RECRUIT)
	assert_eq(game.flow.session.round_number, 2, "the next round")
