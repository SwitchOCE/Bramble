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
	var game := _game_in_fight()
	var key := _space()
	game._input(key)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "the first input shows the result")
	assert_true(game.fight.show_leaderboard, "with everyone's Health")
	var moment: Dictionary = game.fight.state["moment"]
	assert_true(moment.has("result"))
	game._result_age = GameController.RESULT_GUARD
	game._input(key)
	assert_eq(game.phase, GameController.Phase.RECRUIT, "the second moves on at once")
	assert_eq(game.flow.session.round_number, 2)


## The one rule, for Space and a click alike, at a fight's start, middle and end: the first input
## while the fight plays shows the result, with every card in its place; with the result on
## screen, an input moves on, but not in the result's first moments (it is seen first).
func test_skipping_is_one_rule_at_the_start_middle_and_end() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	for input: InputEvent in [_space(), click]:
		for at: String in ["start", "middle", "end"]:
			var game := _game_in_fight()
			var steps: int = game.fight._replay.steps.size()
			if at == "middle":
				game.fight._step = floori(steps / 2.0)
				game.fight._wait = 1.0
			elif at == "end":
				# the fight reached its result on its own a moment ago
				game.fight._step = steps - 2
				game.fight._wait = 0.0
				game.fight._process(0.0)
				assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "%s: result on screen" % at)
				game._input(input)
				assert_eq(
					game.phase,
					GameController.Phase.AFTER_FIGHT,
					"%s: an input as the result appears does not move on unseen" % at
				)
				game._process(GameController.RESULT_GUARD)
				game._input(input)
				assert_eq(
					game.phase, GameController.Phase.RECRUIT, "%s: the next input moves on" % at
				)
				remove_child(game)
				game.free()
				continue
			game._input(input)
			assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "%s: the result at once" % at)
			var moment: Dictionary = game.fight.state["moment"]
			assert_true(moment.has("result"), "%s: the result is drawn" % at)
			assert_false(game.fight._keeper.is_moving(), "%s: every card already in place" % at)
			game._process(GameController.RESULT_GUARD)
			game._input(input)
			assert_eq(game.phase, GameController.Phase.RECRUIT, "%s: the next input moves on" % at)
			remove_child(game)
			game.free()


func _game_in_fight() -> GameController:
	var game := GameController.new()
	add_child(game)
	game.start(GameContent.load_default(), 4)
	game.request({"type": "buy", "spell": false, "index": 0})
	game.request({"type": "play", "hand": 0, "slot": 0, "target": -1})
	game.request({"type": "end_turn"})
	assert_eq(game.phase, GameController.Phase.FIGHT)
	return game


static func _space() -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	return key


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


func test_the_others_play_on_over_frames_once_you_are_out() -> void:
	var game := GameController.new()
	add_child_autofree(game)
	game.start(GameContent.load_default(), 4)
	var ends: Array[int] = []
	game.game_finished.connect(func(_places: Array[Dictionary], out: int) -> void: ends.append(out))
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	for _round: int in 60:
		if game.phase != GameController.Phase.RECRUIT:
			break
		game.request({"type": "end_turn"})
		game._input(key)
		game._result_age = GameController.RESULT_GUARD
		game._input(key)
	assert_eq(game.phase, GameController.Phase.PLAY_OUT, "an empty board loses; the input returns")
	assert_eq(ends.size(), 0, "the others have not finished yet")
	for _frame: int in 600:
		if not ends.is_empty():
			break
		await get_tree().process_frame
	assert_eq(game.phase, GameController.Phase.OVER)
	assert_eq(ends.size(), 1)
	assert_true(game.flow.is_over())


func test_a_units_sources_say_where_its_extra_numbers_come_from() -> void:
	var content: GameContent = GameContent.load_default()
	var card: UnitDef = content.library.get_card(content.library.ids()[0])
	var unit: Unit = Unit.create(card, 1, false, content.registry, 1000)
	assert_eq(ViewAdapter.stat_sources(unit), [], "nothing for its printed numbers")
	unit.stats.aura_health = 8
	unit.stats.perm_attack = 2
	assert_eq(
		ViewAdapter.stat_sources(unit),
		[
			"Its own %d/%d." % [card.attack + 2, card.health],
			"From other units +0/+8.",
		]
	)


func test_start_screen_leaves_tribes_out_but_never_all() -> void:
	var start := StartScreen.new()
	start.tribes = PackedStringArray(["A", "B"])
	add_child_autofree(start)
	assert_eq(start.chosen(), PackedStringArray(), "all by default")
	start.toggle("A")
	assert_eq(start.chosen(), PackedStringArray(["B"]))
	start.toggle("B")
	assert_eq(start.chosen(), PackedStringArray(["B"]), "the last tribe stays in")


func test_start_screen_shows_in_and_out_and_only_picks_one() -> void:
	var start := StartScreen.new()
	start.tribes = PackedStringArray(["A", "B", "C"])
	add_child_autofree(start)
	start.toggle("B")
	var a: Control = start.find_child("Tribe_A", true, false)
	var b: Control = start.find_child("Tribe_B", true, false)
	assert_not_null(a.get_node_or_null("Ring"), "in: an amber ring")
	assert_null(a.get_node_or_null("Strike"))
	assert_not_null(b.get_node_or_null("Strike"), "out: struck through")
	assert_almost_eq(b.modulate.a, 0.4, 0.01, "and dimmed")
	start.only("C")
	assert_eq(start.chosen(), PackedStringArray(["C"]), "one click for that tribe alone")
	assert_not_null(start.find_child("Only_A", true, false))
	start.choose(PackedStringArray(["A", "B"]))
	assert_eq(start.chosen(), PackedStringArray(["A", "B"]), "a game's tribes, chosen again")


func test_result_offers_play_again_start_screen_and_quit() -> void:
	var result := ResultScreen.new()
	result.standings = [
		{"seat": 0, "name": "You", "portrait": "", "place": 1, "health": 9, "you": true}
	]
	result.round_number = 3
	add_child_autofree(result)
	watch_signals(result)
	for words: String in ["Play_again", "Start_screen", "Quit"]:
		assert_not_null(result.find_child("Button_" + words, true, false), words)
	var button: Control = result.find_child("Button_Start_screen", true, false)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	button.gui_input.emit(click)
	assert_signal_emitted(result, "start_screen_requested")


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
