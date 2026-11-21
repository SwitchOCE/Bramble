extends GutTest
## The game flow's plain screens and the controller's round on screen.

const SlotChecks := preload("res://tests/screens/slot_assertions.gd")
const CoreKit := preload("res://tests/core/core_kit.gd")

@warning_ignore_start("unsafe_call_argument")


func test_the_screens_action_reaches_the_core_and_its_picker_is_used() -> void:
	var game := GameController.new()
	add_child_autofree(game)
	game.start(FlowFixture.live(GameContent.load_default(), 4))
	_check_game_slots(game)
	game.recruit.action_requested.emit({"type": "buy", "spell": false, "index": 0})
	_check_game_slots(game)
	assert_eq(game.flow.human().hand.size(), 1, "the screen's action went to the core")
	assert_null(game.find_child("Discover", false, false), "no stand-in picker of the flow's own")
	assert_eq(game.fight.process_mode, Node.PROCESS_MODE_DISABLED, "the hidden fight gets no input")


func test_one_input_shows_the_result_and_the_next_moves_on() -> void:
	var game := _game_in_fight()
	var key := _space()
	get_viewport().push_input(key, true)
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "the first input shows the result")
	assert_true(game.fight.show_leaderboard, "with everyone's Health")
	var moment: Dictionary = game.fight.state["moment"]
	assert_true(moment.has("result"))
	game._result_age = GameController.RESULT_GUARD
	get_viewport().push_input(key, true)
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.RECRUIT, "the second moves on at once")
	assert_eq(game.flow.session.round_number, 2)
	remove_child(game)
	game.free()


## The rule for the skip keys at a fight's start, middle and end: the first input
## while the fight plays shows the result, with every card in its place; with the result on
## screen, an input moves on, but not in the result's first moments (it is seen first).
func test_skip_keys_work_at_the_start_middle_and_end() -> void:
	for input: InputEvent in [_space()]:
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
				_check_game_slots(game)
				assert_eq(
					game.phase,
					GameController.Phase.AFTER_FIGHT,
					"%s: an input as the result appears does not move on unseen" % at
				)
				game._process(GameController.RESULT_GUARD)
				_check_game_slots(game)
				game._input(input)
				_check_game_slots(game)
				assert_eq(
					game.phase, GameController.Phase.RECRUIT, "%s: the next input moves on" % at
				)
				remove_child(game)
				game.free()
				continue
			game._input(input)
			_check_game_slots(game)
			assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "%s: the result at once" % at)
			var moment: Dictionary = game.fight.state["moment"]
			assert_true(moment.has("result"), "%s: the result is drawn" % at)
			assert_false(game.fight._keeper.is_moving(), "%s: every card already in place" % at)
			game._process(GameController.RESULT_GUARD)
			_check_game_slots(game)
			game._input(input)
			_check_game_slots(game)
			assert_eq(game.phase, GameController.Phase.RECRUIT, "%s: the next input moves on" % at)
			remove_child(game)
			game.free()


func _game_in_fight(parent: Node = null) -> GameController:
	var game := GameController.new()
	(self if parent == null else parent).add_child(game)
	game.start(FlowFixture.live(GameContent.load_default(), 4))
	_check_game_slots(game)
	game.request({"type": "buy", "spell": false, "index": 0})
	_check_game_slots(game)
	game.request({"type": "play", "hand": 0, "slot": 0, "target": -1})
	_check_game_slots(game)
	game.request({"type": "end_turn"})
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.FIGHT)
	# Past the guard at the start of the fight.
	game._process(GameController.RESULT_GUARD)
	_check_game_slots(game)
	return game


## Only the skip keys leave playback, and the guard lets its opening beat show.
func test_only_space_skips_and_it_respects_the_fight_guard() -> void:
	var game := _game_in_fight()
	for keycode: Key in [KEY_ALT, KEY_SHIFT, KEY_PRINT, KEY_ESCAPE, KEY_A, KEY_ENTER, KEY_KP_ENTER]:
		game._input(_key(keycode))
		_check_game_slots(game)
		assert_eq(game.phase, GameController.Phase.FIGHT, "key %d does not skip" % keycode)
	game._input(_space())
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "Space skips")
	game._process(GameController.RESULT_GUARD)
	_check_game_slots(game)
	game._input(_key(KEY_SHIFT))
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "Shift does not move on")
	game._input(_key(KEY_ENTER))
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "Enter does not move on")
	game._input(_space())
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.RECRUIT, "Space moves on")
	game.request({"type": "end_turn"})
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.FIGHT)
	game._input(_space())
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.FIGHT, "Space respects the opening guard")
	remove_child(game)
	game.free()


func test_only_the_skip_button_advances_the_fight_on_a_click() -> void:
	# GUT's output panel covers part of the root viewport, including the right light.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var game := _game_in_fight(viewport)
	await wait_process_frames(2)
	var stage: Transform2D = game.fight._stage.get_global_transform_with_canvas()
	var button: Button = game.fight._skip_button
	var skip_at: Vector2 = button.get_global_transform_with_canvas() * (button.size / 2.0)
	var board_at: Vector2 = stage * (game.fight.unit_xy(0, 0) + game.fight.card_box() / 2.0)
	var step: int = game.fight._step
	game._fight_age = 0.0
	_click_at(viewport, skip_at)
	assert_eq(game.fight._step, step, "the button respects the opening guard")
	game._process(GameController.RESULT_GUARD)
	_click_at(viewport, board_at)
	assert_eq(game.fight._step, step, "clicking the board leaves playback alone")

	_mouse_button_at(viewport, skip_at, true)
	assert_true(button.button_pressed, "the Skip button received the press")
	# Playback can redraw the board between mouse-down and mouse-up.
	game.fight.show_state(game.fight.state)
	_mouse_button_at(viewport, skip_at, false)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "the Skip button shows the result")
	assert_false(button.visible, "Skip is hidden on the result")
	game._process(GameController.RESULT_GUARD)
	_click_at(viewport, stage * Vector2(960, 540))
	_click_at(viewport, skip_at)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "clicking the result leaves it showing")
	game._process(GameController.AFTER_FIGHT)
	assert_eq(game.phase, GameController.Phase.RECRUIT, "the result advances on its timer")
	viewport.remove_child(game)
	game.free()


func _click_at(viewport: Viewport, at: Vector2) -> void:
	_mouse_button_at(viewport, at, true)
	_mouse_button_at(viewport, at, false)


func _mouse_button_at(viewport: Viewport, at: Vector2, down: bool) -> void:
	if down:
		var motion := InputEventMouseMotion.new()
		motion.position = at
		viewport.push_input(motion, true)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = at
	click.pressed = down
	viewport.push_input(click, true)


static func _key(keycode: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	return key


static func _space() -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	return key


func test_the_result_shows_counters_after_the_fight() -> void:
	var game := GameController.new()
	add_child_autofree(game)
	game.start(FlowFixture.live(GameContent.load_default(), 4))
	_check_game_slots(game)
	game.request({"type": "buy", "spell": false, "index": 0})
	_check_game_slots(game)
	game.request({"type": "play", "hand": 0, "slot": 0, "target": -1})
	_check_game_slots(game)
	game.request({"type": "end_turn"})
	_check_game_slots(game)
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	game._input(key)
	_check_game_slots(game)
	var after: Array = ViewAdapter.counters(
		game.flow.content, game.flow.session.view_for(GameFlow.HUMAN)
	)
	assert_eq(game.fight.state["counters"], after)


func test_the_others_play_on_over_frames_once_you_are_out() -> void:
	var game := GameController.new()
	add_child_autofree(game)
	game.start(FlowFixture.live(GameContent.load_default(), 4))
	_check_game_slots(game)
	var ends: Array[int] = []
	game.game_finished.connect(func(_places: Array[Dictionary], out: int) -> void: ends.append(out))
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	for _round: int in 60:
		if game.phase != GameController.Phase.RECRUIT:
			break
		game.request({"type": "end_turn"})
		_check_game_slots(game)
		game._fight_age = GameController.RESULT_GUARD
		game._input(key)
		_check_game_slots(game)
		game._result_age = GameController.RESULT_GUARD
		game._input(key)
		_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.PLAY_OUT, "an empty board loses; the input returns")
	assert_eq(ends.size(), 0, "the others have not finished yet")
	for _frame: int in 600:
		if not ends.is_empty():
			break
		await get_tree().process_frame
	assert_eq(game.phase, GameController.Phase.OVER)
	assert_eq(ends.size(), 1)
	assert_true(game.flow.is_over())


func test_a_units_sources_name_where_its_extra_numbers_come_from() -> void:
	var content: GameContent = GameContent.load_default()
	if content.tribe_name("locust") == "":
		pass_test("no locust folder")
		return
	var flow: GameFlow = FlowFixture.live(content, 4, PackedStringArray(["locust"]))
	flow.start_round()
	var me: PlayerState = flow.human()
	var unit: Unit = CoreKit.put(flow.session, me, "husk-sentry", 0)
	flow.session.recruit.refresh_auras(me)
	assert_eq(ViewAdapter.stat_sources(content, flow.session, me, unit), [], "its printed numbers")
	me.counters[&"locust_tide"] = 2
	me.slots[0].renown = 1
	flow.session.recruit.refresh_auras(me)
	var lines: Array = ViewAdapter.stat_sources(content, flow.session, me, unit)
	assert_eq(lines, ["Printed 3/3.", "Tide +2/+0.", "Renown +1/+1."], "each part named")


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
	game.start(FlowFixture.live(GameContent.load_default(), 4))
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.RECRUIT)
	game.request({"type": "buy", "spell": false, "index": 0})
	_check_game_slots(game)
	game.request({"type": "play", "hand": 0, "slot": 0, "target": -1})
	_check_game_slots(game)
	assert_eq(game.flow.human().board_count(), 1, "bought and played")
	game.request({"type": "end_turn"})
	_check_game_slots(game)
	assert_eq(game.phase, GameController.Phase.FIGHT, "the human's fight plays")
	assert_true(game.fight.visible)
	game.fight.skip()
	_check_game_slots(game)
	await wait_seconds(0.2)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "the result with the leaderboard")
	game.call("_after_fight")
	assert_eq(game.phase, GameController.Phase.RECRUIT)
	assert_eq(game.flow.session.round_number, 2, "the next round")


func test_past_boards_show_the_ghost_that_fought_that_round() -> void:
	var content: GameContent = GameContent.load_default()
	var matched: Dictionary = GameFlow.create(content, 4, FlowFixture.test_store())
	assert_true(matched["ok"])
	var game := GameController.new()
	add_child_autofree(game)
	game.start(matched["flow"])
	assert_false(game._past_button.visible)
	game.request({"type": "end_turn"})
	var opening: Dictionary = game.fight._replay.steps[0]["state"]
	game.fight.skip()
	game._after_fight()
	assert_true(game._past_button.visible)
	var recruit: Dictionary = game.recruit.state
	game._open_past_boards()
	assert_eq(game.phase, GameController.Phase.PAST_BOARDS)
	assert_eq(game._past_screen.state["turn"], 1)
	assert_eq(game._past_screen.state["opponent"], opening["opponent"])
	assert_eq(game._past_screen.state["boards"], opening["boards"])
	game._close_past_boards()
	assert_eq(game.recruit.state, recruit)
	assert_eq(game.phase, GameController.Phase.RECRUIT)
	await wait_process_frames(2)


func _check_game_slots(game: GameController) -> void:
	if game.recruit.visible:
		assert_eq(SlotChecks.check(game.recruit), PackedStringArray(), "controller recruit slots")
	if game.fight.visible:
		assert_eq(SlotChecks.check(game.fight), PackedStringArray(), "controller fight slots")
