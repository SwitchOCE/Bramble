extends GutTest
## Real core -> adapter -> recruit UI: destination, deferred buy, interruption and replay safety.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")

var _content: GameContent
var _flow: GameFlow
var _screen: RecruitScreen
var _sent: Array[Dictionary] = []


func before_all() -> void:
	_content = GameContent.load_default()


func before_each() -> void:
	_flow = GameFlow.create(_content, 3)
	_flow.start_round()
	var me: PlayerState = _flow.human()
	me.gold = 30
	CoreKit.put(_flow.session, me, "brock-cub", 0)
	me.hand.append(CoreKit.unit(_flow.session, "brock-cub"))
	CoreKit.set_shop(_flow.session, me, ["brock-cub"] as Array[String])
	_screen = SCREEN.instantiate()
	_screen.state = ViewAdapter.recruit_state(_flow)
	add_child_autofree(_screen)
	_screen.action_requested.connect(_act)
	_sent.clear()


func _act(action: Dictionary) -> void:
	_sent.append(action)
	var first: int = _flow.session.events.size()
	assert_eq(_flow.act(action), "", "core accepts the action")
	_screen.show_state(ViewAdapter.recruit_state(_flow, "", _flow.session.events.slice(first)))


func _buy() -> void:
	_act({"type": "buy", "spell": false, "index": 0})


func _press(at: Vector2, down: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = at + _screen._frame.position
	_screen._gui_input(event)


func _drag(from: Vector2, to: Vector2) -> void:
	_press(from, true)
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = to + _screen._frame.position
	_screen._gui_input(event)
	_press(to, false)


func test_triple_gathers_three_drawn_copies_then_lands_golden_in_hand() -> void:
	assert_false(_screen._triple.active(), "no celebration for initial state")
	_buy()
	assert_true(_screen._triple.active())
	assert_eq(_screen._triple._runs.size(), 1)
	var run: Dictionary = _screen._triple._runs[0]
	var sources: Array = run["sources"]
	assert_eq(sources.size(), 3, "board, hand and shop copies")
	var source: Control = sources[0]["node"]
	var start: Vector2 = source.position
	_screen._triple._process(0.5)
	assert_ne(source.position, start, "gather actually changes position")
	var target: Control = _screen.node_for("hand", 0)
	assert_false(target.visible, "the golden has one presentation, not two")
	assert_true(_flow.human().hand[0].golden, "core already authoritative")
	assert_null(_flow.human().board[0])
	assert_eq(_flow.human().hand.size(), 1, "known 7.3.6 gap: reward waits until play")
	_screen._triple._process(RecruitTripleMotion.duration())
	assert_false(_screen._triple.active())
	assert_true(target.visible)
	var place: Vector3 = _screen.hand_place(0, 1)
	assert_eq(target.position, Vector2(place.x, place.y))
	assert_eq(_screen._triple.get_child_count(), 0, "no ghost remains")


func test_drop_onto_empty_slot_keeps_triple_in_hand_and_starts_after_deferred_draw() -> void:
	_drag(
		_screen.shop_xy(0) + _screen.card_box() / 2.0, _screen.slot_xy(3) + _screen.card_box() / 2.0
	)
	assert_eq(_sent.size(), 1, "a triple never auto-plays its golden")
	assert_eq(str(_sent[0]["type"]), "buy")
	assert_true(_screen._triple.active(), "deferred draw did not lose the event")
	assert_true(_flow.human().hand[0].golden)
	assert_null(_flow.human().board[3])


func test_mouse_press_in_every_beat_finishes_and_executes_same_click() -> void:
	for frame: int in [0, 14, 30, 44, 50, 60, 78, 98]:
		# Each iteration needs a new triple, with the previous golden removed.
		if frame > 0:
			_flow.human().hand.clear()
			CoreKit.put(_flow.session, _flow.human(), "brock-cub", 0)
			_flow.human().hand.append(CoreKit.unit(_flow.session, "brock-cub"))
			CoreKit.set_shop(_flow.session, _flow.human(), ["brock-cub"] as Array[String])
			_flow.human().gold = 30
			_screen.show_state(ViewAdapter.recruit_state(_flow))
		_buy()
		_screen._triple._process(frame / 60.0)
		var button: Control = _screen.find_child("Button_refresh", true, false)
		var at: Vector2 = button.position + button.size / 2.0
		var requests: int = _sent.size()
		_press(at, true)
		_press(at, false)
		assert_eq(_sent.size(), requests + 1, "frame %d accepted the same click" % frame)
		assert_eq(str(_sent[-1]["type"]), "refresh")
		assert_false(_screen._triple.active())
		assert_true(_screen.node_for("hand", 0).visible)


func test_golden_can_be_played_immediately_during_build_up() -> void:
	_buy()
	var place: Vector3 = _screen.hand_place(0, 1)
	_drag(
		Vector2(place.x, place.y) + Vector2(_screen.card_box().x / 2.0, 40),
		_screen.slot_xy(3) + _screen.card_box() / 2.0
	)
	assert_true(_flow.human().board[3].golden)
	assert_eq(
		_flow.human().hand[0].def.id,
		UnitLibrary.TRIPLE_REWARD_ID,
		"the actual core grants the reward on play"
	)
	assert_false(_screen._triple.active())


func test_repeated_event_and_unrelated_state_cannot_replay_or_leave_hidden_card() -> void:
	_buy()
	var same: Dictionary = _screen.state.duplicate(true)
	_screen.show_state(same)
	assert_false(_screen._triple.active(), "same event UID is already in the old state")
	assert_true(_screen.node_for("hand", 0).visible)
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	assert_eq(_screen._triple.get_child_count(), 0)


func test_full_hand_three_board_copies_land_in_first_vacated_slot() -> void:
	var me: PlayerState = _flow.human()
	me.remove_from_board(me.board[0])
	me.hand.clear()
	CoreKit.put(_flow.session, me, "brock-cub", 5)
	CoreKit.put(_flow.session, me, "brock-cub", 2)
	for _i: int in 7:
		me.hand.append(CoreKit.unit(_flow.session, "hedge-knight", true))
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	# Third copy arrives and combines in the same action: no intermediate drawn state.
	RecruitContext.new(_flow.session, _flow.session.recruit, me).summon(&"brock-cub", 6)
	_act({"type": "end_turn"})
	assert_true(_screen._triple.active())
	assert_not_null(me.board[2])
	assert_true(me.board[2].golden)
	assert_null(me.board[5])
	assert_null(me.board[6])
	_screen.settle()
	assert_true(_screen.node_for("board", 2).visible)
	assert_eq(_screen.node_for("board", 2).position, _screen.slot_xy(2))
	assert_eq(me.hand.size(), 7)


func test_gaining_a_golden_without_triple_event_does_not_animate() -> void:
	_flow.human().hand.append(CoreKit.unit(_flow.session, "hedge-knight", true))
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	assert_false(_screen._triple.active())
	assert_true(_screen.node_for("hand", 1).visible)


func test_multiple_triples_in_one_action_are_all_presented() -> void:
	_flow.human().hand.append(CoreKit.unit(_flow.session, "brock-cub"))
	CoreKit.put(_flow.session, _flow.human(), "hedge-knight", 1)
	CoreKit.put(_flow.session, _flow.human(), "hedge-knight", 4)
	_flow.human().hand.append(CoreKit.unit(_flow.session, "hedge-knight"))
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_act({"type": "end_turn"})
	assert_eq(_screen._triple._runs.size(), 2)
	var first_hub: Vector2 = _screen._triple._runs[0]["hub"]
	var second_hub: Vector2 = _screen._triple._runs[1]["hub"]
	assert_ne(first_hub, second_hub, "separate reveals")
	_screen.settle()
	for target: Dictionary in _screen.targets_of("hand"):
		var node: Control = target["node"]
		assert_true(node.visible)
	assert_eq(_screen._triple.get_child_count(), 0)


func test_buying_one_of_two_identical_shop_cards_preserves_the_other() -> void:
	CoreKit.set_shop(_flow.session, _flow.human(), ["brock-cub", "brock-cub"] as Array[String])
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_act({"type": "buy", "spell": false, "index": 1})
	assert_true(_screen._triple.active())
	assert_true(_screen.node_for("shop", 0).visible, "the unbought duplicate is never hidden")
	_screen.settle()
	assert_true(_screen.node_for("shop", 0).visible)


func test_keyboard_press_finishes_animation_and_keeps_its_normal_action() -> void:
	_buy()
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_TAB
	event.pressed = true
	_screen._unhandled_key_input(event)
	assert_false(_screen._triple.active())
	assert_true(_screen.show_leaderboard, "Tab still toggles the leaderboard")


func test_hover_during_merge_ignores_hidden_golden_and_keeps_other_cards_live() -> void:
	CoreKit.set_shop(_flow.session, _flow.human(), ["brock-cub", "hedge-knight"] as Array[String])
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_buy()
	var node: Control = _screen.node_for("hand", 0)
	assert_true(_screen.target_at(node.position + Vector2(node.size.x / 2.0, 40), true).is_empty())
	var shop: Control = _screen.node_for("shop", 1)
	assert_false(_screen.target_at(shop.position + shop.size / 2.0, true).is_empty())
	assert_true(_screen._hover_allowed(), "unaffected cards still accept hover")
