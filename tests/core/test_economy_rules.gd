extends GutTest
## Chapter 4's numbers through the rule queries (Rules), and the unit layer and caps.

@warning_ignore_start("unsafe_call_argument")

const CoreKit := preload("res://tests/core/core_kit.gd")


class CheapRefresh:
	extends Mechanic

	func modify_int(
		query: StringName, value: int, _player: PlayerState, _unit: Unit, _params: MechanicParams
	) -> int:
		return value - 1 if query == Rules.REFRESH_COST else value


class FreeRefresh:
	extends Mechanic

	func modify_int(
		query: StringName, value: int, _player: PlayerState, _unit: Unit, _params: MechanicParams
	) -> int:
		return 0 if query == Rules.REFRESH_COST else value


class BigHand:
	extends Mechanic

	func modify_int(
		query: StringName, value: int, _player: PlayerState, _unit: Unit, _params: MechanicParams
	) -> int:
		return value + 1 if query == Rules.HAND_LIMIT else value


## Puts a plain unit on the board carrying `mechanic` as unit text.
func _put_with(game: GameSession, player: PlayerState, slot: int, mechanic: Mechanic) -> void:
	var unit: Unit = CoreKit.put(game, player, "t1_plain", slot)
	unit.mechanics.append(BoundMechanic.new(&"test_rule", mechanic, MechanicParams.new(), false))


func test_4_1_1_income_table() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	var got: Array[int] = []
	for turn: int in range(1, 13):
		got.append(game.rules.income(p, turn))
	assert_eq(got, [5, 7, 9, 11, 13, 15, 16, 17, 18, 19, 20, 21] as Array[int])


func test_4_1_2_unspent_gold_carries_over() -> void:
	var game: GameSession = CoreKit.session()
	game.start_round()
	var p: PlayerState = game.player(0)
	assert_eq(p.gold, 5)
	game.finish_round()
	game.start_round()
	assert_eq(p.gold, 12, "5 kept plus 7")


func test_4_2_1_unit_price_is_tier_plus_one() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	assert_eq(game.rules.unit_price(p, game.library.get_card(&"t1_plain")), 2)
	assert_eq(game.rules.unit_price(p, game.library.get_card(&"t6_titan")), 7)
	assert_eq(game.rules.spell_price(p, game.library.get_card(&"sp_seek")), 3, "4.2.5 own cost")


func test_4_3_3_sell_values_by_tier_and_origin() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	var want: Dictionary = {
		"t1_plain": 1, "t2_shield": 1, "t3_twin": 2, "t4_phoenix": 2, "t5_bomber": 3, "t6_titan": 3
	}
	for card_id: Variant in want:
		var unit: Unit = CoreKit.unit(game, str(card_id))
		assert_eq(game.rules.sell_value(p, unit), want[card_id], str(card_id))
		var created: Unit = game.new_unit(unit.def, false)
		assert_eq(game.rules.sell_value(p, created), want[card_id], "Created %s" % card_id)


func test_4_3_4_tripled_golden_sells_for_all_its_copies() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	var golden: Unit = CoreKit.unit(game, "t5_bomber", true)
	golden.copies = 3
	golden.bought_copies = 3
	assert_eq(game.rules.sell_value(p, golden), 9, "a triple of a 5 sells for 9")
	golden.bought_copies = 2
	assert_eq(game.rules.sell_value(p, golden), 9, "a Created copy adds the same value")


func test_4_3_2_created_real_discover_pick_sells_for_its_tier() -> void:
	var game: GameSession = CoreKit.session()
	game.start_round()
	var p: PlayerState = game.player(0)
	p.discover_options = [&"t3_twin"]
	assert_eq(game.act(p.id, {"type": "pick", "index": 0}), "")
	assert_false(p.hand[0].is_bought())
	var gold: int = p.gold
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_eq(p.gold, gold + 2, "a Created tier-3 card sells for 2")


func test_4_3_5_token_with_bought_origin_sells_for_its_bought_copy() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	var token: Unit = game.new_unit(game.library.get_card(&"tk_sprout"), false)
	assert_eq(game.rules.sell_value(p, token), 0, "a Created token sells for 0")
	token.bought_copies = 1  # Origin after a merge with a Bought unit.
	assert_eq(game.rules.sell_value(p, token), 1, "a Bought tier-1 token sells for 1")


func test_4_3_6_created_golden_without_a_triple_sells_for_one_copy() -> void:
	var game: GameSession = CoreKit.session()
	game.start_round()
	var p: PlayerState = game.player(0)
	# Model a golden Discover reward directly since standard Discover offers plain units.
	var golden: Unit = game.new_unit(game.library.get_card(&"t4_phoenix"), true)
	p.hand.append(golden)
	assert_false(golden.is_bought())
	assert_eq(golden.copies, 1)
	var gold: int = p.gold
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_eq(p.gold, gold + 2, "one Created golden at tier 4 sells for 2")


func test_4_3_8_unit_text_changes_its_sell_value() -> void:
	var game: GameSession = CoreKit.session()
	var merchant: Unit = CoreKit.unit(game, "t2_merchant")
	assert_eq(game.rules.sell_value(game.player(0), merchant), 2, "1 + sell_bonus 1")


func test_4_4_3_refresh_steps() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	var costs: Array[int] = []
	for paid: int in 26:
		p.refreshes_paid = paid
		costs.append(game.rules.refresh_cost(p))
	assert_eq(costs.slice(0, 10), [1, 1, 1, 1, 1, 1, 1, 1, 1, 1] as Array[int], "1-10 cost 1")
	assert_eq(costs.slice(10, 15), [2, 2, 2, 2, 2] as Array[int], "11-15 cost 2")
	assert_eq(costs.slice(15, 20), [3, 3, 3, 3, 3] as Array[int], "16-20 cost 3")
	assert_eq(costs[20], 4, "21 costs 4")


func test_refresh_counter_walks_two_price_steps_and_a_free_refresh_then_resets() -> void:
	var game: GameSession = CoreKit.session()
	game.start_round()
	var p: PlayerState = game.player(0)
	p.gold = 100
	var remaining: Array[int] = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 5, 4, 3, 2, 1, 5, 4]
	var prices: Array[int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3]
	for paid: int in remaining.size():
		var view: Dictionary = game.view_for(0)
		var costs: Dictionary = view["costs"]
		assert_eq(view["refreshes_left"], remaining[paid], "after %d paid" % paid)
		assert_eq(costs["refresh"], prices[paid], "next price after %d paid" % paid)
		if paid == 9 or paid == 14:
			# An effect makes the next refresh free, just before each price boundary.
			var giver: Unit = CoreKit.put(game, p, "t1_plain", 0)
			giver.mechanics.append(
				BoundMechanic.new(&"free", FreeRefresh.new(), MechanicParams.new(), false)
			)
			var before_free: int = p.gold
			p.frozen = true
			assert_eq(game.act(0, {"type": "refresh"}), "")
			assert_eq(p.gold, before_free, "free")
			assert_false(p.frozen, "free refresh still refreshes and unfreezes")
			assert_eq(p.refreshes_paid, paid, "free doesn't count")
			assert_eq(
				game.view_for(0)["refreshes_left"], remaining[paid], "free doesn't move the counter"
			)
			giver.mechanics.clear()
		var gold: int = p.gold
		assert_eq(game.act(0, {"type": "refresh"}), "")
		assert_eq(p.gold, gold - prices[paid], "the displayed cost is charged")
		assert_eq(p.refreshes_paid, paid + 1)
	game.finish_round()
	game.start_round()
	assert_eq(game.view_for(0)["refreshes_left"], 10, "new turn")
	assert_eq(game.rules.refresh_cost(p), 1)


func test_4_6_3_upgrade_discount_table() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	var want: Array = [
		[8, 7, 5, 2, 0, 0],
		[12, 11, 9, 6, 2, 0],
		[16, 15, 13, 10, 6, 1],
		[19, 18, 16, 13, 9, 4],
		[26, 25, 23, 20, 16, 11],
	]
	for row: int in 5:
		p.tier = row + 1
		var got: Array = []
		for waited: int in 6:
			p.turns_waited = waited
			got.append(game.rules.upgrade_cost(p))
		assert_eq(got, want[row], "to tier %d" % (row + 2))
	p.tier = 6
	assert_eq(game.rules.upgrade_cost(p), -1, "4.6.1 no tier 7 by upgrading")


func test_4_6_6_discount_stays_at_5_a_turn() -> void:
	var game: GameSession = CoreKit.session()
	assert_eq(game.rules.waiting_discount(5), 15)
	assert_eq(game.rules.waiting_discount(6), 20)
	assert_eq(game.rules.waiting_discount(7), 25)


func test_4_6_4_upgrade_resets_the_discount() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	game.start_round()
	p.gold = 20
	p.turns_waited = 2
	assert_eq(game.act(0, {"type": "upgrade"}), "")
	assert_eq(p.tier, 2)
	assert_eq(p.gold, 15, "paid 8 - 3")
	assert_eq(game.rules.upgrade_cost(p), 12, "full price for the next tier")


func test_10_1_3_loss_damage_by_round() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	var small: Array[int] = []
	var big: Array[int] = []
	for round_number: int in range(1, 11):
		small.append(game.rules.loss_damage(p, round_number, false))
		big.append(game.rules.loss_damage(p, round_number, true))
	assert_eq(small, [2, 3, 4, 5, 6, 7, 8, 9, 10, 10] as Array[int])
	assert_eq(big, [5, 6, 7, 8, 9, 10, 11, 12, 13, 13] as Array[int])


func test_unit_text_changes_only_its_owners_rule() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	_put_with(game, p, 0, CheapRefresh.new())
	assert_eq(game.rules.refresh_cost(p), 0, "board unit text changes its owner's rule")
	assert_eq(game.rules.refresh_cost(game.player(1)), 1, "and no one else's")


func test_caps_keep_costs_at_zero_or_more() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	_put_with(game, p, 0, CheapRefresh.new())
	_put_with(game, p, 1, CheapRefresh.new())
	assert_eq(game.rules.refresh_cost(p), 0)


func test_7_1_1_hand_limit_is_a_query() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	assert_eq(game.rules.hand_limit(p), 7)
	_put_with(game, p, 0, BigHand.new())
	assert_eq(game.rules.hand_limit(p), 8)
