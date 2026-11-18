extends GutTest
## Real mouse events through the recruit screen, with purchases handled by the real core.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")
const BUY: Dictionary = {"type": "buy", "spell": false, "index": 0}

var _content: GameContent
var _flow: GameFlow
var _screen: RecruitScreen
var _sent: Array[Dictionary] = []
var _refused: Array[String] = []


func before_all() -> void:
	_content = GameContent.load_default()


func after_each() -> void:
	await get_tree().process_frame


func before_each() -> void:
	_flow = GameFlow.create(_content, 3)
	_flow.start_round()
	_flow.human().gold = 30
	CoreKit.set_shop(_flow.session, _flow.human(), ["sentry"] as Array[String])
	_flow.human().shop_spells.assign([&"sp_sharpen"])
	_sent.clear()
	_refused.clear()
	_screen = SCREEN.instantiate()
	_screen.state = ViewAdapter.recruit_state(_flow)
	add_child_autofree(_screen)
	_screen.action_requested.connect(_act)
	_screen.settle()


func _act(action: Dictionary) -> void:
	_sent.append(action)
	var first: int = _flow.session.events.size()
	var refused: String = _flow.act(action)
	if refused != "":
		_refused.append(refused)
	_screen.show_state(ViewAdapter.recruit_state(_flow, refused, _flow.session.events.slice(first)))


func _button(at: Vector2, down: bool, double_click: bool = false) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.double_click = double_click
	event.position = at + _screen._frame.position
	_screen._gui_input(event)


func _move(at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at + _screen._frame.position
	_screen._gui_input(event)


func _double_click(at: Vector2) -> void:
	_button(at, true)
	_button(at, false)
	_button(at, true, true)
	_button(at, false)


func _shop() -> Vector2:
	return _screen.shop_xy(0) + _screen.card_box() / 2.0


func _slot() -> Vector2:
	return _screen.slot_xy(3) + _screen.card_box() / 2.0


func _drag(from: Vector2, to: Vector2) -> void:
	_button(from, true)
	_move(from.lerp(to, 0.5))
	_move(to)
	_button(to, false)


func test_double_click_buys_once_spends_the_price_and_leaves_every_free_slot_empty() -> void:
	var me: PlayerState = _flow.human()
	var gold: int = me.gold
	var price: int = _screen.state["shop_units"][0]["price"]
	_double_click(_shop())
	assert_eq(_sent, [BUY] as Array[Dictionary], "one normal buy, no play")
	assert_eq(me.gold, gold - price)
	assert_eq(me.shop_units[0], PlayerState.NO_CARD)
	assert_eq(me.hand.size(), 1)
	assert_eq(me.hand[0].def.id, &"sentry")
	assert_eq(me.board_units().size(), 0, "all seven free slots stay empty")
	assert_false(_screen.is_holding())
	_move(_slot())
	_button(_slot(), false)
	assert_eq(_sent.size(), 1, "no lingering press can drop or play the purchase")


func test_first_click_lifts_as_before_and_its_release_leaves_no_carry() -> void:
	var card: GlassCard = _screen.node_for("shop", 0) as GlassCard
	var at: Vector2 = _shop()
	_button(at, true)
	assert_true(card.is_held(), "a pressed shop unit still lifts in place")
	assert_false((card.get_node("ShopTag") as Control).visible)
	_button(at, false)
	assert_false(_screen._input.is_busy(), "first release clears the pending press")
	assert_null(_screen._input._carry, "no half-started drag")
	assert_eq(_sent.size(), 0)
	_button(at, true, true)
	_button(at, false)
	assert_eq(_sent, [BUY] as Array[Dictionary])


func test_single_click_still_only_shows_detail_and_sends_no_action() -> void:
	var before: Dictionary = _flow.session.view_for(GameFlow.HUMAN).duplicate(true)
	_button(_shop(), true)
	_button(_shop(), false)
	assert_eq(_sent.size(), 0)
	assert_eq(_flow.session.view_for(GameFlow.HUMAN), before)
	assert_false(_screen._input.is_busy())
	assert_true(_screen._tips.tip.visible)


func test_drag_after_pending_shop_press_still_buys_and_plays_onto_free_slot() -> void:
	var at: Vector2 = _shop()
	_button(at, true)
	_move(at + Vector2(RecruitInput.DRAG_START + 1.0, 0))
	assert_true(_screen._input._dragging)
	assert_true((_screen.node_for("shop", 0) as GlassCard).is_held())
	_move(_slot())
	_button(_slot(), false)
	assert_eq(_sent.size(), 2)
	assert_eq(_sent[0], BUY)
	assert_eq(str(_sent[1]["type"]), "play")
	assert_eq(_flow.human().board[3].def.id, &"sentry")
	assert_eq(_flow.human().hand.size(), 0)


func test_drag_below_shop_still_buys_into_hand() -> void:
	_drag(_shop(), Vector2(960, 1000))
	assert_eq(_sent, [BUY] as Array[Dictionary])
	assert_eq(_flow.human().hand[0].def.id, &"sentry")
	assert_eq(_flow.human().board_units().size(), 0)


func _refused_like_drag(expected: String) -> void:
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_screen.settle()
	var before: Dictionary = _flow.session.view_for(GameFlow.HUMAN).duplicate(true)
	var events: Array = _flow.session.events.duplicate(true)
	_double_click(_shop())
	assert_eq(_sent, [BUY] as Array[Dictionary], "even a barred buy reaches the normal handler")
	assert_eq(_refused, [expected] as Array[String])
	assert_eq(_flow.session.view_for(GameFlow.HUMAN), before, "refusal changes no game state")
	assert_eq(_flow.session.events, events, "refusal emits no rule events")
	var message: String = _screen.state["message"]
	assert_eq(message, expected)
	assert_false(_screen._input.is_busy())
	_sent.clear()
	_refused.clear()
	_screen.settle()
	_drag(_shop(), Vector2(960, 1000))
	assert_eq(_sent, [BUY] as Array[Dictionary])
	assert_eq(_refused, [expected] as Array[String])
	assert_eq(str(_screen.state["message"]), message, "same refusal feedback as drag-buy")
	assert_eq(_flow.session.view_for(GameFlow.HUMAN), before)
	assert_eq(_flow.session.events, events)


func test_not_enough_gold_matches_refused_drag_buy() -> void:
	_flow.human().gold = 0
	_refused_like_drag("not enough gold")


func test_full_hand_matches_refused_drag_buy_even_with_a_free_board() -> void:
	var me: PlayerState = _flow.human()
	while me.hand.size() < _flow.session.rules.hand_limit(me):
		me.hand.append(CoreKit.unit(_flow.session, "needle-page", true))
	_refused_like_drag("hand is full")


func test_buying_barred_matches_refused_drag_buy() -> void:
	_flow.human().turn_ended = true
	_refused_like_drag("not in a Recruit Phase")


func test_double_click_completes_a_triple_and_plays_the_existing_animation() -> void:
	var me: PlayerState = _flow.human()
	CoreKit.put(_flow.session, me, "sentry", 0)
	me.hand.append(CoreKit.unit(_flow.session, "sentry"))
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_screen.settle()
	var gold: int = me.gold
	var price: int = _screen.state["shop_units"][0]["price"]
	_double_click(_shop())
	assert_eq(_sent, [BUY] as Array[Dictionary])
	assert_eq(me.gold, gold - price)
	assert_eq(me.hand.size(), 2, "golden and reward arrive on formation")
	assert_true(me.hand[0].golden)
	assert_eq(me.hand[1].def.id, UnitLibrary.TRIPLE_REWARD_ID)
	assert_eq(me.hand[0].def.id, &"sentry")
	assert_eq(me.board_units().size(), 0)
	assert_true(_screen._triple.active())
	assert_eq(_screen._triple._runs.size(), 1)
	var sources: Array = _screen._triple._runs[0]["sources"]
	assert_eq(sources.size(), 3)
	var golden: Control = _screen.node_for("hand", 0)
	assert_false(golden.visible, "golden waits for its existing presentation")
	_screen._triple._process(RecruitTripleMotion.duration())
	assert_false(_screen._triple.active())
	assert_true(golden.visible)
	var place: Vector3 = _screen.hand_place(0, 2)
	assert_eq(golden.position, Vector2(place.x, place.y))


func test_double_click_after_refresh_uses_current_price_without_another_refresh() -> void:
	_act({"type": "refresh"})
	CoreKit.set_shop(_flow.session, _flow.human(), ["lance-corporal"] as Array[String])
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_screen.settle()
	_sent.clear()
	var me: PlayerState = _flow.human()
	var gold: int = me.gold
	var price: int = _screen.state["shop_units"][0]["price"]
	var paid: int = me.refreshes_paid
	_double_click(_shop())
	assert_eq(_sent, [BUY] as Array[Dictionary])
	assert_eq(me.gold, gold - price)
	assert_eq(me.refreshes_paid, paid)
	assert_eq(me.hand[0].def.id, &"lance-corporal")


func test_shop_spell_double_click_buys_it_into_the_hand() -> void:
	var me: PlayerState = _flow.human()
	var gold: int = me.gold
	var price: int = _screen.state["shop_spells"][0]["cost"]
	var spell: Control = _screen.node_for("spell", 0)
	var at: Vector2 = spell.position + spell.size / 2.0
	_double_click(at)
	assert_eq(_sent, [{"type": "buy", "spell": true, "index": 0}] as Array[Dictionary])
	assert_eq(me.gold, gold - price)
	assert_eq(me.hand.size(), 1)
	assert_eq(me.hand[0].def.id, &"sp_sharpen")
	assert_false(_screen._input.is_busy(), "nothing left carried")


func test_shop_spell_single_click_sends_nothing_and_drag_still_buys_it() -> void:
	var before: Dictionary = _flow.session.view_for(GameFlow.HUMAN).duplicate(true)
	var spell: Control = _screen.node_for("spell", 0)
	var at: Vector2 = spell.position + spell.size / 2.0
	_button(at, true)
	_button(at, false)
	assert_eq(_sent.size(), 0)
	assert_eq(_flow.session.view_for(GameFlow.HUMAN), before)
	_screen.settle()
	spell = _screen.node_for("spell", 0)
	_drag(spell.position + spell.size / 2.0, Vector2(960, 1000))
	assert_eq(_sent, [{"type": "buy", "spell": true, "index": 0}] as Array[Dictionary])
	assert_eq(_flow.human().hand[0].def.id, &"sp_sharpen")
