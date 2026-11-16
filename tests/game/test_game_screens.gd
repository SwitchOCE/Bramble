extends GutTest
## The game flow's plain screens and the controller's round on screen.

@warning_ignore_start("unsafe_call_argument")

var _picked: int = -1


func _on_picked(index: int) -> void:
	_picked = index


func _release() -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	return click


func test_discover_options_are_clickable() -> void:
	var content: GameContent = GameContent.load_default()
	var flow: GameFlow = GameFlow.create(content, 2)
	flow.start_round()
	var options: Array = []
	for id: String in ["t1_plain", "t1_guard", "t1_herald"]:
		options.append(ViewAdapter.card_from_id(content, flow.session, id))
	var panel := DiscoverPanel.new()
	panel.discover = {"prompt": "Discover a unit", "options": options}
	add_child_autofree(panel)
	panel.picked.connect(_on_picked)
	var card: GlassCard = panel.find_child("Option_1", true, false)
	assert_eq(card.mouse_filter, Control.MOUSE_FILTER_STOP, "a card takes the pointer")
	card.gui_input.emit(_release())
	assert_eq(_picked, 1)


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
	await wait_seconds(2.0)
	assert_eq(game.phase, GameController.Phase.AFTER_FIGHT, "the result, then the leaderboard")
	game.call("_after_fight")
	assert_eq(game.phase, GameController.Phase.RECRUIT)
	assert_eq(game.flow.session.round_number, 2, "the next round")
