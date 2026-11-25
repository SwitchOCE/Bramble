extends GutTest
## The recruit batch of animations (RecruitMotion, fix round step 12) against the real rules core:
## each move starts from what was drawn before, and ends where the state has everything. Motion
## itself is judged on films (tools/feel), not here.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")
## Every move in the batch is over within this long (the waiting slide: 0.12 + 0.32 + 0.2 s).
const DONE: float = 0.9

var _content: GameContent
var _screen: RecruitScreen
var _flow: GameFlow


func before_all() -> void:
	_content = GameContent.load_default()


func before_each() -> void:
	_flow = FlowFixture.live(_content, 7)
	_flow.start_round()
	var me: PlayerState = _flow.human()
	me.gold = 30
	CoreKit.put(_flow.session, me, "brock-cub", 0)
	CoreKit.put(_flow.session, me, "hedge-knight", 1)
	_flow.session.recruit.refresh_auras(me)
	_show()


func _show() -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = SCREEN.instantiate()
	_screen.state = ViewAdapter.recruit_state(_flow)
	add_child_autofree(_screen)
	_screen.action_requested.connect(_on_action)


func _on_action(action: Dictionary) -> void:
	var first: int = _flow.session.events.size()
	var refused: String = _flow.act(action)
	var events: Array = _flow.session.events.slice(first)
	_screen.show_state(ViewAdapter.recruit_state(_flow, refused, events))


func _shop_nodes() -> Array[Control]:
	var out: Array[Control] = []
	for child: Node in _screen._cards.get_children():
		var card: Control = child as Control
		if card != null and card.position.y < _screen.geom("shopBot"):
			out.append(card)
	return out


func _gold_shown() -> String:
	var label: GlassText = _screen._back.get_node("Button_gold/GoldValue")
	return label.words


func test_a_refresh_sinks_the_old_shop_and_drops_the_new_one_in() -> void:
	var old: Array[Control] = _shop_nodes()
	var gold: int = _flow.human().gold
	_screen.ask({"type": "refresh"})
	assert_true(_screen._motion.active())
	for node: Control in old:
		assert_true(is_instance_valid(node), "the old shop is still drawn, about to sink")
	for target: Dictionary in _screen.targets_of("shop"):
		var node: Control = target["node"]
		assert_false(old.has(node), "every place drops a new card in, even a same card")
		assert_eq(node.modulate.a, 0.0, "not shown yet")
	assert_eq(_gold_shown(), str(gold), "the gold counts down from what it was")
	await get_tree().create_timer(DONE).timeout
	assert_false(_screen._motion.active())
	for node: Control in old:
		assert_false(is_instance_valid(node) and node.is_inside_tree(), "the old shop is gone")
	for target: Dictionary in _screen.targets_of("shop"):
		var node: Control = target["node"]
		assert_eq(node.modulate.a, 1.0)
		var index: int = target["index"]
		assert_almost_eq(node.position, _screen.shop_xy(index), Vector2(0.5, 0.5))
		var coin: GoldCoin = node.get_node("ShopTag")
		assert_eq(coin.modulate.a, 1.0)
		assert_eq(node.position.y + coin.position.y, L1Layout.number("shop.price.y"))
	assert_eq(_gold_shown(), str(_flow.human().gold))


func test_a_refused_refresh_moves_nothing() -> void:
	_flow.human().gold = 0
	_show()
	var old: Array[Control] = _shop_nodes()
	_screen.ask({"type": "refresh"})
	assert_false(_screen._motion.active())
	for target: Dictionary in _screen.targets_of("shop"):
		assert_true(old.has(target["node"]), "the same shop stays")


func test_a_press_finishes_a_refresh_at_once() -> void:
	var old: Array[Control] = _shop_nodes()
	_screen.ask({"type": "refresh"})
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(5, 5)
	_screen._gui_input(event)
	assert_false(_screen._motion.active())
	for node: Control in old:
		assert_false(is_instance_valid(node) and node.is_inside_tree())
	for target: Dictionary in _screen.targets_of("shop"):
		var node: Control = target["node"]
		assert_eq(node.modulate.a, 1.0)
		var index: int = target["index"]
		assert_almost_eq(node.position, _screen.shop_xy(index), Vector2(0.5, 0.5))


func test_a_tier_up_rolls_the_tiers_over_and_sweeps_the_shop() -> void:
	var tier: int = _flow.human().tier
	_screen.ask({"type": "upgrade"})
	assert_eq(_flow.human().tier, tier + 1)
	var tiers: GlassText = _screen._back.find_child("Tiers", true, false)
	assert_eq(tiers.words, str(tier), "the old level until it turns over")
	assert_not_null(_screen._motion.get_node_or_null("TierSweep"))
	assert_true(_screen._hover_allowed(), "a flash and a count leave hover alone")
	await get_tree().create_timer(DONE).timeout
	assert_eq(tiers.words, str(tier + 1))
	assert_almost_eq(tiers.scale, Vector2.ONE, Vector2(0.001, 0.001))
	assert_null(_screen._motion.get_node_or_null("TierSweep"))
	assert_eq(_gold_shown(), str(_flow.human().gold))


func test_a_waiting_card_slides_from_the_stack_into_the_hand() -> void:
	var me: PlayerState = _flow.human()
	for id: String in ["lance-corporal", "master-at-arms", "sett-shield-bearer", "cousin"]:
		me.hand.append(CoreKit.unit(_flow.session, id))
	for id: String in ["private", "pip", "needle-page"]:
		me.hand.append(CoreKit.unit(_flow.session, id))
	me.waiting_pile.append(CoreKit.unit(_flow.session, "sentry"))
	_show()
	_screen.settle()
	var waiting: Control = _screen.node_for("waiting_pile", 0)
	var from: Vector2 = waiting.position
	_screen.ask({"type": "play", "hand": 3, "slot": 5})
	assert_eq(me.hand.size(), 7, "the waiting card joined")
	var joined: Control = _screen.node_for("hand", 6)
	assert_almost_eq(joined.position, from, Vector2(0.5, 0.5), "it starts on the stack")
	assert_true(_screen._motion.moving_cards())
	assert_not_null(_screen._front.get_node_or_null("WaitingCountGone"), "the count shrinks away")
	await get_tree().create_timer(DONE).timeout
	var place: Vector3 = _screen.hand_place(6, 7)
	assert_almost_eq(joined.position, Vector2(place.x, place.y), Vector2(0.5, 0.5))
	assert_almost_eq(joined.rotation_degrees, place.z, 0.01)
	assert_eq(joined.modulate, Color.WHITE)
	for i: int in 6:
		var card: Control = _screen.node_for("hand", i)
		var at: Vector3 = _screen.hand_place(i, 7)
		assert_almost_eq(card.position, Vector2(at.x, at.y), Vector2(0.5, 0.5))
	var count: GlassText = _screen._front.get_node("HandCount")
	assert_eq(count.words, "Hand 7/7")
	assert_null(_screen._front.get_node_or_null("WaitingCountGone"))
