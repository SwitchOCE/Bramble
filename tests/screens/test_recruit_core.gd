extends GutTest
## The recruit screen against the real rules core and the shipped tribes, through the game flow's
## own converter (ViewAdapter.recruit_state): what the screen asks for is the core's own legal
## action, and the core takes it. Board: Brock Cub and Hedge Knight in front, Lance Corporal
## (an Active with no target), Hedge-layer (a Bury that takes a shop unit) and Grenadier Guard (an
## Active that takes a slot) behind. Hand: Master-at-Arms (playing triggers nothing), then
## the shop spells Sharpen (a friendly unit), Seek (no target: a Discover).

const SlotChecks := preload("res://tests/screens/slot_assertions.gd")

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")
const BOARD: Dictionary = {
	0: "brock-cub", 1: "hedge-knight", 4: "lance-corporal", 5: "hedge-layer", 6: "grenadier-guard"
}
const HAND: Array[String] = ["master-at-arms", "sp_sharpen", "sp_seek"]

var _content: GameContent

var _screen: RecruitScreen
var _flow: GameFlow
var _sent: Array[Dictionary] = []


func before_all() -> void:
	_content = GameContent.load_default()


func before_each() -> void:
	assert_eq(_content.errors, PackedStringArray(), "the shipped content loads clean")
	_flow = _playable(_content, BOARD, HAND)
	_sent.clear()
	_screen = SCREEN.instantiate()
	_screen.state = ViewAdapter.recruit_state(_flow)
	add_child_autofree(_screen)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "initial slot rows")
	_screen.action_requested.connect(_on_action)


## Round 1 started, the human given gold and these units: {slot: card id} on the board, then the
## hand.
static func _playable(content: GameContent, board: Dictionary, hand: Array[String]) -> GameFlow:
	var flow: GameFlow = FlowFixture.live(content, 3)
	flow.start_round()
	var me: PlayerState = flow.human()
	me.gold = 30
	for slot: Variant in board:
		CoreKit.put(flow.session, me, str(board[slot]), CoreUtil.to_int(slot))
	for card_id: String in hand:
		me.hand.append(CoreKit.unit(flow.session, card_id))
	return flow


## The game flow's seam: the action to the core unchanged, then the adapter's new state.
func _on_action(action: Dictionary) -> void:
	_sent.append(action)
	var first: int = _flow.session.events.size()
	var refused: String = _flow.act(action)
	assert_eq(refused, "", "the core takes %s" % JSON.stringify(action))
	var events: Array = _flow.session.events.slice(first)
	_screen.show_state(ViewAdapter.recruit_state(_flow, refused, events))
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")


func _gui(event: InputEvent) -> void:
	_screen._gui_input(event)


func _press(at: Vector2, down: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = down
	event.position = at + (_screen.get_node("Frame") as Control).position
	_gui(event)


func _move(at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at + (_screen.get_node("Frame") as Control).position
	_gui(event)


func _drag(from: Vector2, to: Vector2) -> void:
	_press(from, true)
	_move(from.lerp(to, 0.5))
	_move(to)
	_press(to, false)


func _click(at: Vector2) -> void:
	_press(at, true)
	_press(at, false)


func _card_middle(i: int) -> Vector2:
	return _screen.shop_xy(i) + GlassCard.card_size(250.0) / 2.0


func _hand_grip(i: int) -> Vector2:
	var node: Control = _screen.node_for("hand", i)
	var place: Vector3 = _screen.hand_place(i, _screen.targets_of("hand").size())
	return Vector2(place.x, place.y) + Vector2(node.size.x / 2.0, 40.0)


func _board_middle(slot: int) -> Vector2:
	return _screen.slot_xy(slot) + GlassCard.card_size(250.0) / 2.0


func _uid_at(slot: int) -> int:
	return _flow.human().board[slot].uid


func _key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	_screen._unhandled_key_input(event)


func _lit_count() -> int:
	return _screen.find_children("Lit", "", true, false).size()


func _press_node(node: Control) -> void:
	var frame: Control = _screen.get_node("Frame")
	_click(node.global_position - frame.global_position + node.size / 2.0)


## The ability button for a mechanic id on the board, or null.
func _ability(mechanic: String) -> Control:
	for target: Dictionary in _screen.targets_of("ability"):
		if str(target["id"]) == mechanic:
			return target["node"]
	return null


static func _words(button: Control) -> String:
	for child: Node in button.get_children():
		if child is GlassText:
			return (child as GlassText).words
	return ""


# ---- the plain moves ----


func test_economy_readouts_redraw_from_core_after_upgrade_gold_and_turn_changes() -> void:
	var me: PlayerState = _flow.human()
	me.tier = 3
	me.turns_waited = 3
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	var back: Node = _screen.get_node("Frame/Stage/Back")
	var front: Node = _screen.get_node("Frame/Stage/Front")
	var income: GlassText = front.get_node("NextTurnIncome/Value")
	var drop: GlassText = back.get_node("TierUpDrop")
	assert_eq(income.words, "+%d" % _flow.session.rules.income(me, 2))
	assert_eq(drop.words, "−4 next turn")
	_on_action({"type": "upgrade"})
	drop = back.get_node("TierUpDrop")
	assert_eq(drop.words, "−1 next turn", "new tier immediately resets the drop")
	_on_action({"type": "refresh"})
	income = front.get_node("NextTurnIncome/Value")
	assert_eq(income.words, "+%d" % _flow.session.rules.income(me, 2), "spending is not income")
	_flow.session.round_number += 1
	_flow.session.recruit.start_turn(me)
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	income = front.get_node("NextTurnIncome/Value")
	drop = back.get_node("TierUpDrop")
	assert_eq(income.words, "+%d" % _flow.session.rules.income(me, 3))
	assert_eq(drop.words, "−2 next turn", "one more turn waited")
	me.turns_waited = 20
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	assert_null(back.get_node_or_null("TierUpDrop"), "hidden at cost zero")
	_on_action({"type": "upgrade"})
	drop = back.get_node("TierUpDrop")
	assert_eq(drop.words, "−1 next turn", "a free upgrade also resets the drop")
	_on_action({"type": "upgrade"})
	assert_eq(me.tier, _flow.session.config.max_tier)
	assert_null(back.get_node_or_null("TierUpDrop"), "hidden at the top tier")
	assert_not_null(front.get_node_or_null("NextTurnIncome"), "income remains visible")


func test_a_drag_out_of_the_shop_sends_the_cores_buy() -> void:
	var hand_before: int = _flow.human().hand.size()
	_drag(_card_middle(0), Vector2(960, 1000))
	assert_eq(_sent.size(), 1)
	assert_eq(_sent[0], {"type": "buy", "spell": false, "index": 0})
	assert_eq(_flow.human().hand.size(), hand_before + 1)


func test_buttons_send_the_cores_actions() -> void:
	var refresh: Control = _screen.find_child("Button_refresh", true, false)
	_press_node(refresh)
	assert_eq(_sent, [{"type": "refresh"}] as Array[Dictionary])


func test_a_move_on_the_board_is_the_cores_move() -> void:
	_drag(_board_middle(1), _board_middle(3))
	assert_eq(_sent, [{"type": "move", "from": 1, "to": 3}] as Array[Dictionary])
	assert_eq(_flow.human().board[3].def.id, &"hedge-knight")


func test_an_action_the_state_does_not_list_is_still_sent() -> void:
	_screen.action_requested.disconnect(_on_action)
	watch_signals(_screen)
	var state: Dictionary = _screen.state.duplicate()
	state["legal_actions"] = []
	_screen.show_state(state)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	_drag(_card_middle(0), Vector2(960, 1000))
	assert_signal_emitted_with_parameters(
		_screen, "action_requested", [{"type": "buy", "spell": false, "index": 0}]
	)


func test_matching_reads_numbers_from_json() -> void:
	var state: Dictionary = {"legal_actions": [{"type": "move", "from": 1.0, "to": 2.0}]}
	var found: Array[Dictionary] = RecruitActions.matching(state, {"type": "move", "from": 1})
	assert_eq(found.size(), 1)
	assert_true(RecruitActions.matching(state, {"type": "move", "from": 2}).is_empty())


# ---- spells, targets, abilities, Discover ----


func test_spells_in_hand_are_drawn_as_spells() -> void:
	assert_true(_screen.node_for("hand", 0) is GlassCard, "Master-at-Arms is a unit")
	for i: int in [1, 2]:
		assert_true(_screen.node_for("hand", i) is GlassSpell, "hand card %d is a spell" % i)


## The core's own Triple Reward (7.3.6), in the hand as a triple gives it: drawn as a spell with
## its words, cast on the table, it opens a Discover of a unit from the tier above.
func test_the_triple_reward_casts_from_the_hand_and_opens_a_discover() -> void:
	_flow.human().hand.append(CoreKit.unit(_flow.session, String(UnitLibrary.TRIPLE_REWARD_ID)))
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	var index: int = _flow.human().hand.size() - 1
	var card: Dictionary = _screen.state["hand"][index]
	assert_true(CoreUtil.to_bool(card["spell"]), "drawn as a spell")
	assert_ne(str(card["text"]), "", "with its words")
	assert_true(_screen.node_for("hand", index) is GlassSpell)
	_drag(_hand_grip(index), Vector2(1400, 600))
	assert_eq(str(_sent[0]["type"]), "play")
	assert_true(_screen.state.has("discover"), "the Triple Reward opened a Discover")
	assert_gt(_screen.targets_of("discover").size(), 0, "with options to pick")


func test_a_spell_with_no_target_casts_on_the_table_and_opens_a_discover() -> void:
	_drag(_hand_grip(2), Vector2(1400, 600))
	assert_eq(_sent[0], {"type": "play", "hand": 2, "slot": -1, "target": -1})
	assert_true(_screen.state.has("discover"), "Seek opened a Discover")
	var options: int = _screen.targets_of("discover").size()
	assert_gt(options, 0)
	_drag(_board_middle(0), _board_middle(3))
	assert_eq(_sent.size(), 1, "nothing but a pick while choosing")
	var option: Control = _screen.node_for("discover", options - 1)
	_click(option.position + option.size / 2.0)
	assert_eq(_sent[1], {"type": "pick", "index": options - 1})
	assert_false(_screen.state.has("discover"))


func test_a_targeted_spell_dropped_on_a_unit_casts_there() -> void:
	var cub: int = _uid_at(0)
	var before: int = _flow.human().board[0].attack()
	_drag(_hand_grip(1), _board_middle(0))
	assert_eq(_sent[0], {"type": "play", "hand": 1, "slot": -1, "target": cub})
	assert_gt(_flow.human().board[0].attack(), before, "Sharpen landed on the Brock Cub")


func test_a_targeted_spell_on_the_table_asks_for_a_target_and_escape_cancels() -> void:
	_drag(_hand_grip(1), Vector2(1400, 600))
	assert_true(_screen.is_aiming())
	assert_eq(_sent.size(), 0)
	assert_eq(_lit_count(), BOARD.size(), "every friendly unit is lit")
	_key(KEY_ESCAPE)
	assert_false(_screen.is_aiming())
	assert_eq(_lit_count(), 0)
	_screen.settle()
	_drag(_hand_grip(1), Vector2(1400, 600))
	assert_true(_screen.is_aiming(), "aiming again")
	_press(Vector2(1400, 600), true, MOUSE_BUTTON_RIGHT)
	assert_false(_screen.is_aiming(), "a right click cancels too")
	_screen.settle()
	_drag(_hand_grip(1), Vector2(1400, 600))
	_click(Vector2(1300, 600))
	assert_true(_screen.is_aiming(), "a click on nothing keeps waiting")
	var knight: int = _uid_at(1)
	_click(_board_middle(1))
	assert_eq(
		_sent, [{"type": "play", "hand": 1, "slot": -1, "target": knight}] as Array[Dictionary]
	)


func test_master_at_arms_playing_needs_no_target_and_gives_nothing() -> void:
	_drag(_hand_grip(0), _board_middle(3))
	assert_false(_screen.is_aiming())
	assert_eq(_sent[0], {"type": "play", "hand": 0, "slot": 3, "target": -1})
	assert_eq(_flow.human().board[3].def.id, &"master-at-arms")
	var drawn: Dictionary = _screen.state["board"][1]
	assert_true(_screen._pill_words(drawn).has("Fury 1"), "no Fury granted on play")


func test_lance_corporal_active_shows_its_cost_coin_and_the_core_takes_it() -> void:
	var order: Control = _ability("pigeon_lance_corporal")
	assert_not_null(order, "the Active shows on the Lance Corporal")
	assert_eq(_words(order), "", "no name: an Active is its cost")
	var coin: GoldCoin = order.get_node("PriceCoin")
	assert_eq(coin.amount, 1, "the cost in a gold coin")
	assert_false(coin.poor)
	var gold: int = _flow.human().gold
	_press_node(order)
	assert_false(_screen.is_aiming(), "this Active aims at nothing")
	assert_eq(str(_sent[0]["type"]), "ability")
	assert_eq(str(_sent[0]["mechanic"]), "pigeon_lance_corporal")
	assert_eq(_flow.human().gold, gold - 1, "paid for")


func test_grenadier_active_picks_a_slot() -> void:
	var order: Control = _ability("pigeon_grenadier")
	assert_not_null(order)
	_press_node(order)
	assert_true(_screen.is_aiming(), "a slot to choose")
	assert_gt(_lit_count(), 0, "the slots it can take are lit")
	_click(_board_middle(2))
	assert_eq(str(_sent[0]["mechanic"]), "pigeon_grenadier")
	assert_eq(GlassPieces.as_int(_sent[0]["target"]), 2)


func test_hedge_layer_bury_takes_a_shop_unit_into_the_compost() -> void:
	var bury: Control = _ability("thorn_bury_gold")
	assert_not_null(bury)
	assert_eq(_words(bury), "Bury", "its own word; no gold cost, so no coin")
	assert_null(bury.get_node_or_null("PriceCoin"))
	var shop_id: String = String(_flow.human().shop_units[0])
	_press_node(bury)
	assert_true(_screen.is_aiming(), "a shop unit to choose")
	_click(_card_middle(0))
	assert_eq(str(_sent[0]["mechanic"]), "thorn_bury_gold")
	assert_eq(GlassPieces.as_int(_sent[0]["target"]), 0)
	assert_eq(_flow.human().heap(&"thorn_compost").size(), 1, "one unit in the Compost")
	var plate: Dictionary = {}
	for chip: Variant in _screen.state["counters"]:
		var each: Dictionary = chip
		if str(each["id"]) == "thorn_compost":
			plate = each
	assert_eq(GlassPieces.as_int(plate.get("value", 0)), 1, "the plate counts it")
	var entries: Array = plate.get("entries", [])
	var first: Dictionary = entries[0]
	assert_eq(str(first["id"]), shop_id, "and names what is in it")
	var leaving: Dictionary = _screen.state.get("leaving", {})
	var went: Dictionary = leaving.get(shop_id, {})
	assert_eq(went, {"to": "heap", "id": "thorn_compost"}, "it goes to the plate")
	assert_true(_screen._keeper.is_moving(), "and is seen going there")


func test_ability_buttons_show_dimmed_when_the_state_does_not_list_them() -> void:
	var state: Dictionary = _screen.state.duplicate()
	state["legal_actions"] = []
	_screen.show_state(state)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	assert_eq(_screen.targets_of("ability").size(), 0, "nothing to press")
	var order: Control = _screen.find_child("Ability_pigeon_lance_corporal", true, false)
	assert_not_null(order, "still drawn")
	assert_eq(order.modulate, RecruitScreen.SHORT_DIM, "dimmed")


## Every shipped card with an ability, on the board, draws a button: a named ability (Bury) its
## display name, an Active (no name) its gold cost in a coin; a gold cost always shows as a coin.
## Never a letter N, and never the words "Order" or "Active".
func test_every_shipped_ability_draws_its_name_or_its_cost_coin() -> void:
	var checked: int = 0
	var actives: int = 0
	for card_id: StringName in _content.library.ids():
		var card: UnitDef = _content.library.get_card(card_id)
		if card.is_spell() or _content.folder_of(String(card_id)) == "":
			continue
		var flow: GameFlow = _playable(_content, {4: String(card_id)}, [])
		var state: Dictionary = ViewAdapter.recruit_state(flow)
		var unit: Dictionary = state["board"][4]
		var abilities: Array = unit.get("abilities", [])
		var hooks: int = 0
		for bound: BoundMechanic in flow.human().board[4].hooks():
			hooks += 1 if bound.mechanic.has_ability() else 0
		assert_eq(abilities.size(), hooks, "%s: every ability is in the state" % card_id)
		if abilities.is_empty():
			continue
		var screen: RecruitScreen = SCREEN.instantiate()
		screen.state = state
		add_child_autofree(screen)
		assert_eq(SlotChecks.check(screen), PackedStringArray(), "initial slot rows")
		for value: Variant in abilities:
			var ability: Dictionary = value
			var button: Control = screen.find_child("Ability_" + str(ability["id"]), true, false)
			assert_not_null(button, "%s draws %s" % [card_id, ability["id"]])
			var words: String = _words(button)
			# the words are the display table's name for that ability, or none for an Active
			var shown: String = _content.display_name(str(ability["id"]))
			assert_eq(words, shown, "%s: %s reads %s" % [card_id, words, shown])
			var cost: int = GlassPieces.as_int(ability["cost"])
			var coin: GoldCoin = button.get_node_or_null("PriceCoin")
			if shown == "" or cost > 0:
				assert_not_null(coin, "%s: its gold cost in a coin" % card_id)
				if coin != null:
					assert_eq(coin.amount, cost, "%s: the coin holds the cost" % card_id)
			else:
				assert_null(coin, "%s: no gold cost, no coin" % card_id)
			for banned: String in ["Order", "Active", "free"]:
				assert_false(words.contains(banned), "%s: no %s in %s" % [card_id, banned, words])
			assert_false(CardTerms.has_n(words), "%s: no letter N in %s" % [card_id, words])
			actives += 1 if shown == "" else 0
			checked += 1
	assert_gt(checked, 3, "Lance Corporal, Grenadier Guard and the Bury units at least")
	assert_eq(actives, 2, "the Lance Corporal's and the Grenadier Guard's are Actives")
