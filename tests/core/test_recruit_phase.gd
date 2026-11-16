extends GutTest
## The Recruit Phase: chapters 3-7 and 8.3, through Recruit.act.

@warning_ignore_start("unsafe_call_argument")

const CoreKit := preload("res://tests/core/core_kit.gd")

var game: GameSession
var p: PlayerState


func before_each() -> void:
	game = CoreKit.session(3)
	game.start_round()
	p = game.player(0)


func _filled(shop: Array[StringName]) -> int:
	return shop.filter(func(c: StringName) -> bool: return c != PlayerState.NO_CARD).size()


func test_6_1_1_shop_shows_5_units_and_2_spells() -> void:
	assert_eq(_filled(p.shop_units), 5)
	assert_eq(_filled(p.shop_spells), 2)


func test_6_1_2_draws_are_at_or_below_the_players_tier() -> void:
	for _i: int in 20:
		p.gold = 10
		game.act(0, {"type": "refresh"})
		for card_id: StringName in p.shop_units:
			assert_eq(game.library.get_card(card_id).tier, 1)


func test_4_2_buy_goes_to_hand_and_empties_the_slot() -> void:
	var card_id: StringName = p.shop_units[0]
	assert_eq(game.act(0, {"type": "buy", "spell": false, "index": 0}), "")
	assert_eq(p.gold, 3, "5 - 2")
	assert_eq(p.hand.size(), 1)
	assert_eq(p.hand[0].def.id, card_id)
	assert_eq(p.shop_units[0], PlayerState.NO_CARD, "4.2.3 the slot stays empty")
	assert_true(p.hand[0].is_bought(), "4.3.1 Bought")


func test_4_1_5_cant_buy_without_the_gold() -> void:
	p.gold = 1
	assert_eq(game.act(0, {"type": "buy", "spell": false, "index": 0}), "not enough gold")
	assert_eq(p.hand.size(), 0)


func test_4_2_2_and_7_1_1_full_hand_of_7_cant_buy() -> void:
	p.gold = 100
	for _i: int in 7:
		p.hand.append(CoreKit.unit(game, "t1_plain"))
	assert_eq(game.act(0, {"type": "buy", "spell": false, "index": 0}), "hand is full")


func test_7_2_1_play_into_any_chosen_empty_slot() -> void:
	p.hand.append(CoreKit.unit(game, "t1_plain"))
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": 5, "target": -1}), "")
	assert_not_null(p.board[5])
	assert_eq(p.board[5].slot, 5)
	assert_eq(p.hand.size(), 0)


func test_7_2_2_no_play_on_a_full_board() -> void:
	for slot: int in 7:
		CoreKit.put(game, p, "t1_plain", slot)
	p.hand.append(CoreKit.unit(game, "t1_guard"))
	assert_ne(game.act(0, {"type": "play", "hand": 0, "slot": 0, "target": -1}), "")
	assert_eq(p.hand.size(), 1)


func test_7_2_3_when_played_buffs_adjacent_units() -> void:
	var left: Unit = CoreKit.put(game, p, "t1_plain", 0)
	var far: Unit = CoreKit.put(game, p, "t1_plain", 3)
	p.hand.append(CoreKit.unit(game, "t1_herald"))
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": 1, "target": -1}), "")
	assert_eq([left.attack(), left.health()], [4, 6], "adjacent: +2/+2 permanently")
	assert_eq([far.attack(), far.health()], [2, 4], "not adjacent")


func test_6_1_5_a_spell_needs_its_target() -> void:
	var target: Unit = CoreKit.put(game, p, "t1_plain", 0)
	var spell: Unit = CoreKit.unit(game, "sp_sharpen")
	p.hand.append(spell)
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": -1, "target": -1}), "choose a target")
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": -1, "target": target.uid}), "")
	assert_eq(target.attack(), 4)
	assert_eq(p.hand.size(), 0, "single use")


func test_4_3_sell_gives_gold_and_returns_the_copy() -> void:
	game.act(0, {"type": "buy", "spell": false, "index": 0})
	var unit: Unit = p.hand[0]
	var left: int = game.units.copies_left(unit.def.id)
	game.act(0, {"type": "play", "hand": 0, "slot": 0, "target": -1})
	var gold: int = p.gold
	assert_eq(game.act(0, {"type": "sell", "slot": 0}), "")
	assert_eq(p.gold, gold + 1)
	assert_null(p.board[0], "4.3.7 the slot becomes empty")
	assert_eq(game.units.copies_left(unit.def.id), left + 1, "5.3.4 back in the pool")


func test_4_3_7_only_board_units_can_be_sold() -> void:
	p.hand.append(CoreKit.unit(game, "t1_plain"))
	assert_ne(game.act(0, {"type": "sell", "slot": 0}), "")


func test_4_4_1_refresh_replaces_the_shop_and_unfreezes() -> void:
	game.act(0, {"type": "freeze"})
	assert_true(p.frozen)
	var before: int = game.units.total_left()
	assert_eq(game.act(0, {"type": "refresh"}), "")
	assert_false(p.frozen)
	assert_eq(p.gold, 4)
	assert_eq(game.units.total_left(), before, "old cards back, new cards out")
	assert_eq(p.refreshes_paid, 1)


func test_4_5_1_freeze_toggles_up_to_5_times() -> void:
	for _i: int in 5:
		assert_eq(game.act(0, {"type": "freeze"}), "")
	assert_eq(game.act(0, {"type": "freeze"}), "no freezes left this turn")
	assert_true(p.frozen, "5 toggles from unfrozen leaves it frozen")


func test_4_5_2_frozen_shop_keeps_its_cards_and_refills_empty_slots() -> void:
	game.act(0, {"type": "buy", "spell": false, "index": 0})
	var kept: Array[StringName] = p.shop_units.slice(1)
	game.act(0, {"type": "freeze"})
	game.finish_round()
	game.start_round()
	assert_eq(p.shop_units.slice(1), kept)
	assert_ne(p.shop_units[0], PlayerState.NO_CARD, "the bought slot refilled")
	assert_false(p.frozen, "4.5.3 the freeze ends once refilled")


func test_5_3_2_unfrozen_shop_returns_at_end_of_turn() -> void:
	game.end_turn(0)
	assert_eq(_filled(p.shop_units), 0)
	assert_eq(_filled(p.shop_spells), 0)


func test_4_6_5_upgrading_doesnt_refill_the_shop() -> void:
	p.gold = 20
	var shop: Array[StringName] = p.shop_units.duplicate()
	game.act(0, {"type": "upgrade"})
	assert_eq(p.shop_units, shop)


func test_8_3_3_move_and_swap() -> void:
	var a: Unit = CoreKit.put(game, p, "t1_plain", 0)
	var b: Unit = CoreKit.put(game, p, "t1_guard", 1)
	assert_eq(game.act(0, {"type": "move", "from": 0, "to": 6}), "")
	assert_eq(a.slot, 6)
	assert_null(p.board[0], "8.3.4 no packing")
	assert_eq(game.act(0, {"type": "move", "from": 1, "to": 6}), "")
	assert_eq([a.slot, b.slot], [1, 6], "swap")


func test_12_2_1_auras_follow_the_board() -> void:
	var banner: Unit = CoreKit.put(game, p, "t3_banner", 1)
	var friend: Unit = CoreKit.put(game, p, "t1_plain", 2)
	game.act(0, {"type": "move", "from": 2, "to": 2 + 1})
	assert_eq(friend.attack(), 2, "not adjacent any more")
	game.act(0, {"type": "move", "from": 3, "to": 0})
	assert_eq(friend.attack(), 4, "adjacent: +2 Attack")
	game.act(0, {"type": "sell", "slot": banner.slot})
	assert_eq(friend.attack(), 2, "the aura ends with its source")


func test_3_4_1_end_of_turn_triggers_and_this_turn_ends() -> void:
	CoreKit.put(game, p, "t2_mentor", 0)
	var other: Unit = CoreKit.put(game, p, "t1_plain", 1)
	other.stats.turn_attack = 5
	game.end_turn(0)
	assert_eq(other.stats.turn_attack, 0, "this turn's buff is gone")
	assert_eq(other.stats.perm_attack, 2, "End of Turn: +2/+2 permanently")


func test_3_2_1_start_of_turn_trigger_after_income() -> void:
	CoreKit.put(game, p, "t5_hoard", 0)
	game.finish_round()
	game.start_round()
	assert_eq(p.gold, 5 + 7 + 2)


func test_6_2_discover_shows_3_different_units_out_of_the_pool() -> void:
	var before: int = game.units.total_left()
	var spell: Unit = CoreKit.unit(game, "sp_seek")
	p.hand.append(spell)
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": -1, "target": -1}), "")
	assert_eq(p.discover_options.size(), 3)
	var unique: Dictionary = {}
	for card_id: StringName in p.discover_options:
		unique[card_id] = true
	assert_eq(unique.size(), 3, "6.2.2 different units")
	assert_eq(game.units.total_left(), before - 3, "5.3.3 out while shown")
	assert_eq(game.act(0, {"type": "refresh"}), "choose a Discover option first")
	assert_eq(game.act(0, {"type": "pick", "index": 1}), "")
	assert_eq(game.units.total_left(), before - 1, "the others return")
	var picked: Unit = p.hand[p.hand.size() - 1]
	assert_false(picked.is_bought(), "4.3.2 a pick is Created")
	assert_eq(picked.pool_copies, 1, "and still a pool copy")


func test_7_1_2_card_gained_into_a_full_hand_is_lost() -> void:
	for _i: int in 6:
		p.hand.append(CoreKit.unit(game, "t1_plain", true))
	p.hand.append(CoreKit.unit(game, "sp_seek"))
	var before: int = game.units.total_left()
	game.act(0, {"type": "play", "hand": 6, "slot": -1, "target": -1})
	p.hand.append(CoreKit.unit(game, "t1_guard"))
	assert_eq(game.act(0, {"type": "pick", "index": 0}), "")
	assert_eq(p.hand.size(), 7)
	assert_eq(game.units.total_left(), before, "the lost pick went back to the pool")
	assert_eq(CoreKit.log_of(game, "card_lost").size(), 1)


func test_legal_actions_are_all_accepted() -> void:
	CoreKit.put(game, p, "t1_plain", 0)
	p.hand.append(CoreKit.unit(game, "sp_sharpen"))
	p.hand.append(CoreKit.unit(game, "t1_herald"))
	p.gold = 30
	var legal: Array[Dictionary] = game.legal_actions(0)
	assert_gt(legal.size(), 20)
	for action: Dictionary in legal:
		var copy: GameSession = CoreKit.session(3)
		copy.start_round()
		var q: PlayerState = copy.player(0)
		CoreKit.put(copy, q, "t1_plain", 0)
		q.hand.append(CoreKit.unit(copy, "sp_sharpen"))
		q.hand.append(CoreKit.unit(copy, "t1_herald"))
		q.gold = 30
		assert_eq(copy.act(0, action), "", str(action))
