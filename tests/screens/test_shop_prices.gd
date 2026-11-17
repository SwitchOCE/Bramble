extends GutTest
## Prices stay tied to the core; the screen only draws them, including zero and mixed origins.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")

var _content: GameContent
var _screen: RecruitScreen


func before_all() -> void:
	_content = GameContent.load_default()


func after_each() -> void:
	# Redrawn panes use queue_free; let those nodes leave before GUT counts orphans.
	await get_tree().process_frame
	await get_tree().process_frame


func _flow() -> GameFlow:
	var flow: GameFlow = GameFlow.create(_content, 3)
	flow.start_round()
	return flow


func _make(state: Dictionary) -> void:
	_screen = SCREEN.instantiate()
	_screen.state = state
	add_child_autofree(_screen)
	_screen.settle()


func _coin(node: Node) -> GoldCoin:
	for child: Node in node.find_children("*", "GoldCoin", true, false):
		return child as GoldCoin
	return null


func test_shop_shows_core_prices_for_every_unit_tier_and_every_spell() -> void:
	var flow: GameFlow = _flow()
	var me: PlayerState = flow.human()
	me.gold = 2
	var units: Array[StringName] = [
		&"private",
		&"old-campaigner",
		&"colour-sergeant",
		&"lieutenant",
		&"colour-ensign",
		&"regimental-sergeant-major"
	]
	for card_id: StringName in units:
		var def: UnitDef = flow.session.library.get_card(card_id)
		assert_not_null(def, str(card_id))
		if def == null:
			continue
		me.shop_units = [card_id]
		me.shop_spells = [&"sp_sharpen", &"sp_seek", &"sp_forage"]
		var state: Dictionary = ViewAdapter.recruit_state(flow)
		_make(state)
		var card: Control = _screen.node_for("shop", 0)
		var coin: GoldCoin = _coin(card)
		assert_not_null(coin)
		assert_eq(coin.amount, def.tier + 1)
		assert_eq(coin.poor, coin.amount > me.gold)
		assert_eq(card.modulate, Color.WHITE, "art stays bright")
		for i: int in 3:
			var spell: Control = _screen.node_for("spell", i)
			var cost: GoldCoin = spell.get_node("Cost")
			var expected: Array[int] = [1, 3, 5]
			assert_eq(cost.amount, expected[i], "spell's own price")
			assert_eq(cost.poor, expected[i] > me.gold)
		me.gold = 20
		_screen.show_state(ViewAdapter.recruit_state(flow))
		assert_false(_coin(_screen.node_for("shop", 0)).poor, "coin brightens when gold changes")
		assert_false(_coin(_screen.node_for("spell", 2)).poor, "spells follow the same update")
		me.gold = 2
		_screen.hide()


func test_counter_and_cost_update_together_and_top_tier_has_no_upgrade_button() -> void:
	var flow: GameFlow = _flow()
	flow.human().refreshes_paid = 9
	flow.human().gold = 10
	_make(ViewAdapter.recruit_state(flow))
	var counter: GlassText = _screen.find_child("RefreshCounter", true, false)
	assert_eq(counter.words, "1 left at this price")
	assert_eq(_coin(_screen.find_child("Button_refresh", true, false)).amount, 1)
	assert_eq(flow.session.act(0, {"type": "refresh"}), "")
	_screen.show_state(ViewAdapter.recruit_state(flow))
	counter = _screen.find_child("RefreshCounter", true, false)
	assert_eq(counter.words, "5 left at this price")
	assert_eq(_coin(_screen.find_child("Button_refresh", true, false)).amount, 2)
	flow.human().tier = 6
	_screen.show_state(ViewAdapter.recruit_state(flow))
	assert_null(_screen.find_child("Button_tier*", true, false))


func test_sell_cue_uses_origin_and_golden_value_and_clears_on_release_or_focus_loss() -> void:
	var flow: GameFlow = _flow()
	var unit: Unit = CoreKit.put(flow.session, flow.human(), "briar-king", 0)
	unit.golden = true
	unit.bought_copies = 2
	_make(ViewAdapter.recruit_state(flow))
	_carry_to_shop()
	var cue: Control = _screen.find_child("SellCue", true, false)
	assert_true(cue.visible)
	assert_eq(_coin(cue).amount, 6, "two bought tier-6 copies, created copy contributes zero")
	var caption: Control = cue.get_node("SellCaption")
	assert_lt(
		cue.position.x + caption.position.x + caption.size.x,
		960.0,
		"caption stays to the left of a card carried on the right"
	)
	RecruitShop.show_sell(_screen, 6, true, 700.0)
	assert_gt(
		cue.position.x + caption.position.x,
		1040.0,
		"caption moves right when the card crosses left"
	)
	_screen._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_null(_screen.find_child("SellCue", true, false), "cue cleared with the carry")
	unit.bought_copies = 0
	_screen.show_state(ViewAdapter.recruit_state(flow))
	_carry_to_shop()
	cue = _screen.find_child("SellCue", true, false)
	assert_eq(_coin(cue).amount, 0, "created unit")
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = _frame_at() + Vector2(960, 220)
	_screen._gui_input(release)
	assert_false(is_instance_valid(cue) and cue.visible)


func test_shop_tag_is_hidden_during_carry_and_restored_after_a_refused_drop() -> void:
	_make(ViewAdapter.recruit_state(_flow()))
	var card: Control = _screen.node_for("shop", 0)
	var tag: Control = card.get_node("ShopTag")
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = _frame_at() + card.position + card.size / 2.0
	_screen._gui_input(press)
	assert_false(tag.visible)
	_screen._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(tag.visible)
	assert_null(_screen.node_for("board", 0), "prices only on offers")


func _frame_at() -> Vector2:
	var frame: Control = _screen.get_node("Frame")
	return frame.position


func _carry_to_shop() -> void:
	_screen.settle()
	var card: Control = _screen.node_for("board", 0)
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = _frame_at() + card.position + card.size / 2.0
	_screen._gui_input(press)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = _frame_at() + Vector2(960, 220)
	_screen._gui_input(motion)
