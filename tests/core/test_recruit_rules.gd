extends GutTest
## Recruit Phase rules on one player (rulebook chapters 3, 4, 6, 7 and 8.3).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = UnitLibrary.load_dir()
var _config: GameConfig
var _pool: UnitPool
var _rules: RecruitRules
var _player: PlayerState


func before_each() -> void:
	_config = GameConfig.defaults()
	_pool = UnitPool.create(_library, _config)
	_rules = RecruitRules.create(_library, _config, _pool)
	_player = PlayerState.new()
	_player.shop_rng.seed = 11
	_rules.setup_player(_player)


func _unit(def_id: String, origin: String = RecruitUnit.ORIGIN_BOUGHT) -> RecruitUnit:
	var unit := RecruitUnit.make(_library.get_unit(def_id), _rules.new_iid())
	unit.origin = origin
	unit.pool_copies = 1 if origin == RecruitUnit.ORIGIN_BOUGHT else 0
	if unit.pool_copies > 0:
		_pool.take(def_id)
	return unit


func test_income_and_carry_over_4_1_1_4_1_2() -> void:
	_rules.start_phase(_player, 1)
	assert_eq(_player.gold, 3, "turn 1 income")
	_player.gold = 2
	_rules.end_phase(_player)
	_rules.start_phase(_player, 2)
	assert_eq(_player.gold, 6, "2 carried plus 4")
	var incomes: Array = []
	for turn: int in range(1, 11):
		incomes.append(_config.get_int_at("income_by_turn", turn - 1))
	assert_eq(incomes, [3, 4, 5, 6, 7, 8, 9, 10, 10, 10], "income table, 10 from turn 8")


func test_shop_size_by_tier_6_1_1() -> void:
	_rules.start_phase(_player, 1)
	assert_eq(_player.shop.size(), 3, "tier 1 shows 3 units")
	_player.gold = 100
	_rules.tier_up(_player)
	_rules.refresh(_player)
	assert_eq(_player.shop.size(), 4, "tier 2 shows 4 units")


func test_buy_4_2_1() -> void:
	_rules.start_phase(_player, 1)
	var bought: RecruitUnit = _player.shop[1]
	assert_eq(_rules.buy(_player, 1), "", "buy succeeds")
	assert_eq(_player.gold, 0, "costs 3")
	assert_eq(_player.hand, [bought] as Array[RecruitUnit], "goes to hand")
	assert_eq(_player.shop.size(), 2, "its slot stays empty (4.2.3)")
	assert_eq(bought.origin, RecruitUnit.ORIGIN_BOUGHT, "Bought origin (4.3.1)")


func test_buy_needs_gold_4_1_5() -> void:
	_rules.start_phase(_player, 1)
	_player.gold = 2
	assert_eq(_rules.buy(_player, 0), "Not enough gold", "can't go below 0")
	assert_eq(_player.gold, 2, "gold unchanged")


func test_full_hand_cant_buy_4_2_2() -> void:
	_rules.start_phase(_player, 1)
	_player.gold = 100
	for _index: int in 10:
		_player.hand.append(_unit("field_vole"))
	assert_eq(_rules.buy(_player, 0), "Hand is full", "hand of 10 (7.1.1)")


func test_buy_with_full_board_4_2_4() -> void:
	_rules.start_phase(_player, 1)
	for slot: int in BoardGeometry.SLOTS:
		var vole: RecruitUnit = _unit("field_vole")
		vole.golden = true  # Goldens never triple (7.3.1), so the board stays full.
		_player.board[slot] = vole
	assert_eq(_rules.buy(_player, 0), "", "buying is allowed with a full board")
	assert_eq(_rules.play(_player, 0, 3), "That slot is taken", "but it can't be played (7.2.2)")


func test_sell_values_4_3_3_4_3_4() -> void:
	_player.board[0] = _unit("field_vole")
	_player.board[1] = _unit("field_vole", RecruitUnit.ORIGIN_CREATED)
	var golden: RecruitUnit = _unit("field_vole", RecruitUnit.ORIGIN_CREATED)
	golden.from_triple = true
	_player.board[2] = golden
	_rules.sell(_player, 0)
	assert_eq(_player.gold, 1, "Bought sells for 1")
	_rules.sell(_player, 1)
	assert_eq(_player.gold, 1, "Created sells for 0")
	_rules.sell(_player, 2)
	assert_eq(_player.gold, 2, "a triple's golden sells for 1")
	assert_null(_player.board[0], "the slot becomes empty (4.3.7)")


func test_sell_returns_pool_copies_5_3_4() -> void:
	var before: int = _pool.copies_left("field_vole")
	_player.board[4] = _unit("field_vole")
	assert_eq(_pool.copies_left("field_vole"), before - 1, "taken")
	_rules.sell(_player, 4)
	assert_eq(_pool.copies_left("field_vole"), before, "returned")


func test_only_board_units_sell_4_3_7() -> void:
	_player.hand.append(_unit("field_vole"))
	assert_eq(_rules.sell(_player, 0), "No unit there", "an empty slot can't be sold")


func test_refresh_cost_steps_4_4_3() -> void:
	_rules.start_phase(_player, 1)
	_player.gold = 1000
	var costs: Array = []
	for _index: int in 26:
		var before: int = _player.gold
		assert_eq(_rules.refresh(_player), "", "refresh")
		costs.append(before - _player.gold)
	var expected: Array = []
	for _index: int in 15:
		expected.append(1)
	expected.append_array([2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4])
	assert_eq(costs, expected, "1-15 cost 1, 16-20 cost 2, 21-25 cost 3, 26 costs 4")


func test_refresh_count_resets_4_4_4() -> void:
	_rules.start_phase(_player, 1)
	_player.gold = 100
	for _index: int in 16:
		_rules.refresh(_player)
	assert_eq(_rules.refresh_cost(_player), 2, "past the first step")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 2)
	assert_eq(_player.paid_refreshes, 0, "reset")
	assert_eq(_rules.refresh_cost(_player), 1, "back to 1")


func test_refresh_replaces_shop_and_returns_cards_4_4_1() -> void:
	_rules.start_phase(_player, 1)
	var total: int = _pool.total_copies() + _player.shop.size()
	var old_iids: Array = _iids(_player.shop)
	_player.gold = 5
	_rules.toggle_freeze(_player)
	assert_eq(_rules.refresh(_player), "", "refresh")
	assert_eq(_player.shop.size(), 3, "a full new shop")
	for iid: int in _iids(_player.shop):
		assert_false(old_iids.has(iid), "new card %d" % iid)
	assert_eq(_pool.total_copies() + _player.shop.size(), total, "copies conserved")
	assert_false(_player.frozen, "refreshing unfreezes")


func test_refresh_needs_gold_4_1_5() -> void:
	_rules.start_phase(_player, 1)
	_player.gold = 0
	assert_eq(_rules.refresh(_player), "Not enough gold", "no gold")


func test_freeze_toggles_5_times_4_5_1() -> void:
	_rules.start_phase(_player, 1)
	for index: int in 5:
		assert_eq(_rules.toggle_freeze(_player), "", "toggle %d" % (index + 1))
	assert_true(_player.frozen, "odd number of toggles leaves it frozen")
	assert_eq(_rules.toggle_freeze(_player), "No freezes left this turn", "sixth toggle fails")


func test_frozen_shop_keeps_cards_and_refills_empty_slots_4_5_2() -> void:
	_rules.start_phase(_player, 1)
	_rules.buy(_player, 0)
	var kept: Array = _iids(_player.shop)
	_rules.toggle_freeze(_player)
	var pool_before: int = _pool.total_copies()
	_rules.end_phase(_player)
	assert_eq(_pool.total_copies(), pool_before, "frozen cards stay out of the pool (4.5.4)")
	_rules.start_phase(_player, 2)
	var now: Array = _iids(_player.shop)
	assert_eq(now.slice(0, 2), kept, "the frozen cards are kept")
	assert_eq(now.size(), 3, "the bought slot refills")
	assert_false(_player.frozen, "the freeze ends after the refill (4.5.3)")


func test_unfrozen_shop_returns_at_end_of_turn_5_3_2() -> void:
	_rules.start_phase(_player, 1)
	var total: int = _pool.total_copies() + _player.shop.size()
	_rules.end_phase(_player)
	assert_eq(_player.shop.size(), 0, "shop emptied")
	assert_eq(_pool.total_copies(), total, "cards back in the pool")


func test_tier_up_costs_4_6_2_4_6_4() -> void:
	_rules.start_phase(_player, 1)
	_player.gold = 100
	var costs: Array = []
	while _player.tier < 6:
		var before: int = _player.gold
		assert_eq(_rules.tier_up(_player), "", "upgrade")
		costs.append(before - _player.gold)
	assert_eq(costs, [5, 7, 8, 11, 11], "base costs; several upgrades in one turn")
	assert_eq(_rules.tier_up(_player), "Already at the top tier", "tier 6 is the top (4.6.1)")


func test_upgrade_discount_from_turn_2_4_6_3() -> void:
	_rules.start_phase(_player, 1)
	assert_eq(_player.upgrade_cost, 5, "no discount on turn 1")
	for turn: int in range(2, 9):
		_rules.end_phase(_player)
		_rules.start_phase(_player, turn)
	assert_eq(_player.upgrade_cost, 0, "-1 a turn, never below 0")
	_rules.tier_up(_player)
	assert_eq(_player.upgrade_cost, 7, "resets to the next base cost")


func test_tier_up_needs_gold_4_1_5() -> void:
	_rules.start_phase(_player, 1)
	assert_eq(_rules.tier_up(_player), "Not enough gold", "3 gold, costs 5")


func test_upgrade_doesnt_refill_shop_4_6_5() -> void:
	_rules.start_phase(_player, 1)
	_player.gold = 10
	var before: Array = _iids(_player.shop)
	_rules.tier_up(_player)
	assert_eq(_iids(_player.shop), before, "same shop")


func test_play_into_any_empty_slot_7_2_1() -> void:
	_player.hand.append(_unit("field_vole"))
	_player.hand.append(_unit("marsh_frog"))
	assert_eq(_rules.play(_player, 1, 5), "", "into B2 with an empty front row (8.3.1)")
	assert_eq(_player.board[5].def_id(), "marsh_frog", "placed")
	assert_eq(_player.hand.size(), 1, "left the hand")
	assert_eq(_rules.play(_player, 0, 5), "That slot is taken", "occupied slot")
	assert_eq(_rules.play(_player, 3, 0), "No unit there", "bad hand index")
	assert_eq(_rules.play(_player, 0, 7), "No such slot", "bad slot")


func test_move_and_swap_8_3_3() -> void:
	var vole: RecruitUnit = _unit("field_vole")
	var frog: RecruitUnit = _unit("marsh_frog")
	_player.board[0] = vole
	_player.board[1] = frog
	assert_eq(_rules.move(_player, 0, 6), "", "move to an empty slot")
	assert_eq(_player.board[6], vole, "moved")
	assert_null(_player.board[0], "no packing (8.3.4)")
	assert_eq(_rules.move(_player, 6, 1), "", "swap")
	assert_eq(_player.board[1], vole, "swapped in")
	assert_eq(_player.board[6], frog, "swapped out")
	assert_eq(_rules.move(_player, 0, 2), "No unit there", "nothing to move")


func test_elimination_returns_everything_5_3_8() -> void:
	_rules.start_phase(_player, 1)
	var total: int = _pool.total_copies() + _player.shop.size()
	_player.board[0] = _unit("field_vole")
	_player.hand.append(_unit("marsh_frog"))
	_player.hand.append(_unit("hoglet", RecruitUnit.ORIGIN_CREATED))
	_rules.return_everything(_player)
	assert_eq(_pool.total_copies(), total, "every pool copy is back")
	assert_eq(_player.owned_units().size(), 0, "nothing left")


func _iids(units: Array[RecruitUnit]) -> Array:
	var out: Array = []
	for unit: RecruitUnit in units:
		out.append(unit.iid)
	return out
