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


func test_repeated_event_and_unrelated_state_preserve_age_without_replaying() -> void:
	_buy()
	_screen._triple._process(0.3)
	var copy: Control = _screen._triple._runs[0]["sources"][0]["node"]
	var same: Dictionary = _screen.state.duplicate(true)
	_screen.show_state(same)
	assert_true(_screen._triple.active())
	assert_eq(_screen._triple._runs.size(), 1)
	assert_eq(_screen._triple._age, 0.3)
	var kept: Control = _screen._triple._runs[0]["sources"][0]["node"]
	assert_same(kept, copy, "same event retains its current presentation, without new copies")
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	assert_true(
		_screen._triple.active(), "absence of event metadata does not cancel the current run"
	)
	_screen.settle()
	assert_true(_screen.node_for("hand", 0).visible)
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


func test_counter_arrival_redraw_keeps_drawing_the_same_running_triple() -> void:
	_buy()
	_screen._triple._process(0.4)
	var copy: Control = _screen._triple._runs[0]["sources"][0]["node"]
	var at: Vector2 = copy.position
	_screen._counts._held = {"gold": 30}
	_screen._counts.arrived()
	assert_true(_screen._triple.active())
	assert_eq(_screen._triple._age, 0.4, "counter redraw does not reset the clock")
	var kept: Control = _screen._triple._runs[0]["sources"][0]["node"]
	assert_same(kept, copy)
	assert_true(copy.is_visible_in_tree(), "drawn overlay survives layout")
	assert_false(_screen.node_for("hand", 0).visible)
	_screen._triple._process(0.15)
	assert_ne(copy.position, at, "the surviving animation continues moving")


func _unrelated_move_during_triple() -> Control:
	CoreKit.put(_flow.session, _flow.human(), "hedge-knight", 1)
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_buy()
	_screen._triple._process(0.2)
	_act({"type": "move", "from": 1, "to": 4})
	return _screen.node_for("board", 4)


func test_mouse_press_finishes_only_the_triple_not_another_cards_flight() -> void:
	var moving: Control = _unrelated_move_during_triple()
	var at: Vector2 = moving.position
	assert_true(_screen._triple.active(), "unrelated state update preserves the triple")
	assert_true(_screen._keeper.is_busy(moving))
	var button: Control = _screen.find_child("Button_freeze", true, false)
	_press(button.position + button.size / 2.0, true)
	assert_false(_screen._triple.active())
	assert_eq(moving.position, at, "press must not advance an unrelated tween to its end")
	assert_true(_screen._keeper.is_busy(moving))


func test_key_press_finishes_only_the_triple_not_another_cards_flight() -> void:
	var moving: Control = _unrelated_move_during_triple()
	var at: Vector2 = moving.position
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_A
	key.pressed = true
	_screen._unhandled_key_input(key)
	assert_false(_screen._triple.active())
	assert_eq(moving.position, at)
	assert_true(_screen._keeper.is_busy(moving))


func test_discover_pick_flies_from_the_drawn_option_at_its_drawn_size() -> void:
	var owned: Unit = _flow.human().hand[0]
	owned.stats.perm_attack = 4
	_flow.human().discover_options.assign([&"brock-cub", &"hedge-knight", &"lance-corporal"])
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	var option: Control = _screen.node_for("discover", 0)
	var center: Vector2 = option.position + option.size / 2.0
	_act({"type": "pick", "index": 0})
	assert_true(_screen._triple.active())
	var sources: Array = _screen._triple._runs[0]["sources"]
	var source: Dictionary = sources[2]
	var owned_card: Dictionary = sources[0]["card"]
	assert_eq(
		GlassPieces.as_int(owned_card["attack"]), owned.attack(), "drawn buffs survive capture"
	)
	assert_eq(str(source["origin"]), "discover")
	var start: Vector2 = source["at"]
	assert_eq(start, center, "not a fabricated start below the central gathering point")
	var scale: Vector2 = source["scale"]
	assert_eq(scale, Vector2.ONE * RecruitDiscover.SCALE)
	var copy: Control = source["node"]
	assert_true(copy.is_visible_in_tree())
	assert_eq(copy.position + copy.size / 2.0, center)
	assert_true(_flow.human().hand[0].golden)


func test_unseen_logged_copy_keeps_its_actual_buffed_stats() -> void:
	var first: int = _flow.session.events.size()
	var ctx: RecruitContext = RecruitContext.new(
		_flow.session, _flow.session.recruit, _flow.human()
	)
	var owned: Unit = _flow.human().hand[0]
	ctx.buff(owned, 4, 2, true, null)
	var third: Unit = ctx.give_card(&"brock-cub", null)
	ctx.buff(third, 7, 5, true, null)
	assert_eq(_flow.act({"type": "end_turn"}), "")
	_screen.show_state(ViewAdapter.recruit_state(_flow, "", _flow.session.events.slice(first)))
	var owned_source: Dictionary = _screen._triple._runs[0]["sources"][0]
	var owned_card: Dictionary = owned_source["card"]
	assert_eq(str(owned_source["stats_from"]), "log")
	assert_eq(
		GlassPieces.as_int(owned_card["attack"]),
		owned.attack(),
		"latest log beats older drawn stats"
	)
	assert_eq(GlassPieces.as_int(owned_card["health"]), owned.health())
	var source: Dictionary = _screen._triple._runs[0]["sources"][2]
	var card: Dictionary = source["card"]
	assert_eq(str(source["stats_from"]), "log")
	assert_eq(GlassPieces.as_int(card["attack"]), third.attack())
	assert_eq(GlassPieces.as_int(card["health"]), third.health())
	assert_eq(GlassPieces.as_int(card["uid"]), third.uid)
	var at: Vector2 = source["at"]
	var hub: Vector2 = _screen._triple._runs[0]["hub"]
	assert_eq(at, hub)


func test_unseen_definition_copies_start_at_each_triples_own_hub() -> void:
	_flow.human().hand.clear()
	CoreKit.put(_flow.session, _flow.human(), "brock-cub", 3)
	CoreKit.put(_flow.session, _flow.human(), "hedge-knight", 1)
	CoreKit.put(_flow.session, _flow.human(), "hedge-knight", 4)
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	# Deliberately no arrival log or intermediate state: only the normal definition is known.
	CoreKit.put(_flow.session, _flow.human(), "brock-cub", 5)
	CoreKit.put(_flow.session, _flow.human(), "hedge-knight", 6)
	_act({"type": "end_turn"})
	assert_eq(_screen._triple._runs.size(), 2)
	for run: Dictionary in _screen._triple._runs:
		var source: Dictionary = run["sources"][2]
		var at: Vector2 = source["at"]
		var hub: Vector2 = run["hub"]
		assert_eq(at, hub)
		assert_ne(hub, RecruitTripleMotion.HUB)
		assert_eq(str(source["stats_from"]), "definition")
		var card: Dictionary = source["card"]
		var normal: Dictionary = ViewAdapter.card_from_id(_content, _flow.session, str(card["id"]))
		assert_eq(card, normal, "normal text/stats, never a copy of the combined golden")


func test_a_state_change_to_the_golden_finishes_its_old_presentation() -> void:
	_buy()
	_flow.human().hand[0].stats.perm_attack += 2
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	assert_false(_screen._triple.active())
	assert_true(_screen.node_for("hand", 0).visible)
