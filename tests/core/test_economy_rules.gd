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
	var created: Unit = CoreKit.unit(game, "t5_bomber")
	created.bought_copies = 0
	assert_eq(game.rules.sell_value(p, created), 0, "a Created unit sells for 0")


func test_4_3_4_golden_sells_for_its_bought_copies() -> void:
	var game: GameSession = CoreKit.session()
	var p: PlayerState = game.player(0)
	var golden: Unit = CoreKit.unit(game, "t5_bomber", true)
	golden.bought_copies = 3
	assert_eq(game.rules.sell_value(p, golden), 9, "a triple of a 5 sells for 9")
	golden.bought_copies = 2
	assert_eq(game.rules.sell_value(p, golden), 6, "a Created copy adds nothing")


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
