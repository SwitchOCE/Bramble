extends GutTest
@warning_ignore_start("unsafe_call_argument")
const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT
var _player: PlayerState
var _brain: BotBrain


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game(), false, LegacyWave1.current_with_neutrals())
	_player = _kit.player
	_player.gold = 11
	_player.tier = 5
	for slot: int in BoardGeometry.SLOTS:
		var filler: RecruitUnit = _kit.put("field_vole", slot)
		filler.plain_copy = true
	_kit.put("charcoal_burner", 1)
	_player.shop.clear()
	_player.shop_spells.clear()
	_brain = BotBrain.from_name("hard")
	_brain._player = _player
	_brain._rules = _kit.rules
	_brain._round_now = 15
	_brain.value.board_owner = _player


func test_forecast_matches_normal_golden_caps_and_rounding() -> void:
	assert_eq(BotBurner.forecast(_player, 11), 12.0)
	assert_eq(BotBurner.forecast(_player, 100), 12.0)
	assert_eq(BotBurner.forecast(_player, 6), 0.0)
	assert_eq(BotBurner.forecast(_player, 7), 4.0)
	_player.board[1].golden = true
	assert_eq(BotBurner.forecast(_player, 17), 24.0)


func test_forecast_requires_real_targets_and_accounts_for_shy() -> void:
	_player.board[4] = null
	_player.board[5] = null
	assert_eq(BotBurner.forecast(_player, 11), 0.0)
	_kit.put("hob_in_the_hearth", 4)
	assert_eq(BotBurner.forecast(_player, 11), 0.0, "Shy ignores the gift")


func test_missing_most_forecasts_the_real_uncapped_burn_for_normal_and_golden() -> void:
	var config := GameConfig.full_game()
	config.set_value("card_size_caps", false)
	config.set_value("card_rate_limits", false)
	var library: UnitLibrary = ScaleOverlay.library_for(_kit.library, config)
	for golden: bool in [false, true]:
		_player.board[1] = RecruitUnit.make(library.get_unit("charcoal_burner"), 991, golden)
		_player.gold = 101
		var forecast: float = BotBurner.forecast(_player, _player.gold)
		var before: int = _player.board[4].attack + _player.board[4].health
		before += _player.board[5].attack + _player.board[5].health
		_kit.rules.end_phase(_player)
		var after: int = _player.board[4].attack + _player.board[4].health
		after += _player.board[5].attack + _player.board[5].health
		assert_eq(forecast, float(after - before), "forecast matches uncapped execution")
		assert_gt(forecast, 24.0, "missing cap permits more than the golden capped maximum")


func test_spending_compares_the_burn_lost_not_a_fixed_gold_reserve() -> void:
	assert_eq(BotBurner.spend_loss(_player, 2), 4.0)
	assert_false(_brain._pay(2, 3.0), "weak purchase loses more burn stats")
	assert_true(_brain._pay(2, 5.0), "better purchase wins")
	_player.gold = 12
	assert_eq(BotBurner.spend_loss(_player, 1), 0.0)
	assert_true(_brain._pay(1, 1.0), "harmless surplus can be spent")


func test_weak_shop_purchase_is_skipped_and_the_real_burn_fires() -> void:
	_player.shop_spells.append(HandItem.make(_kit.library.get_card("pinch_of_dust"), 901))
	var before: int = _player.board[4].attack
	_brain._shop_loop()
	assert_eq(_player.gold, 11)
	assert_eq(_player.shop_spells.size(), 1)
	_kit.rules.end_phase(_player)
	assert_eq(_player.gold, 5, "the actual card burns six")
	assert_eq(_player.board[4].attack, before + 3)
	assert_eq(_player.board[5].attack, before + 3)


func test_offer_choice_preserves_a_better_kin_spell() -> void:
	_player.shop_spells.append(HandItem.make(_kit.library.get_card("pinch_of_dust"), 901))
	_player.shop_spells.append(HandItem.make(_kit.library.get_card("stand_behind_me"), 902))
	var offer: Dictionary = _brain._best_offer()
	assert_true(offer["spell"])
	assert_eq(offer["index"], 1, "eight kin stats beat the four burn stats lost")


func test_prospective_burner_values_only_an_actual_funded_plan() -> void:
	_player.board[1] = null
	var candidate := RecruitUnit.make(_kit.library.get_unit("charcoal_burner"), 903)
	_player.gold = 14
	assert_eq(_brain.value.buy_value(candidate, _player), 22.0)
	_player.gold = 3
	assert_eq(_brain.value.buy_value(candidate, _player), 10.0)
	_player.gold = 14
	for slot: int in BoardGeometry.BACK:
		_player.board[slot] = null
	assert_eq(_brain.value.buy_value(candidate, _player), 10.0)


func test_no_burner_leaves_existing_pay_policy_unchanged() -> void:
	_player.board[1] = null
	assert_true(_brain._pay(2, 0.0), "ordinary leftover climb is still allowed")
	assert_eq(BotBurner.spend_loss(_player, 2), 0.0)


func test_multiple_burners_share_gold_instead_of_counting_the_same_six_twice() -> void:
	_kit.put("charcoal_burner", 2)
	assert_eq(BotBurner.forecast(_player, 11), 12.0)
	assert_eq(BotBurner.forecast(_player, 17), 24.0)


func _acorns(count: int) -> void:
	for index: int in count:
		_player.items.append(HandItem.make(_kit.library.get_card("acorn"), 910 + index))


func test_cash_batches_complete_a_pair_without_wasting_surplus_acorns() -> void:
	_player.gold = 5
	_acorns(10)
	_brain._cash_for_burn()
	assert_eq(_player.gold, 11)
	assert_eq(_player.items.size(), 4, "stop at the cap, not after cashing everything")


func test_valuable_larder_and_eater_fuel_are_kept() -> void:
	_player.gold = 5
	_acorns(2)
	_brain.value.strategy = {"larder_value": 3.0}
	_brain._cash_for_burn()
	assert_eq(_player.items.size(), 2)
	_brain.value.strategy = {}
	_kit.put("alderman_dozey", 0)
	_brain._cash_for_burn()
	assert_eq(_player.items.size(), 2)


func test_a_funded_hand_burner_keeps_its_draft_value_until_it_can_be_played() -> void:
	_player.board[1] = null
	var burner := RecruitUnit.make(_kit.library.get_unit("charcoal_burner"), 950)
	_player.hand.append(burner)
	assert_eq(_brain.value.keep_value(burner), 22.0)
	_player.gold = 5
	assert_eq(_brain.value.keep_value(burner), 10.0)


func test_real_front_swap_makes_later_owned_and_spend_values_consistent() -> void:
	var burner: RecruitUnit = _player.board[1]
	_player.board[1] = _player.board[6]
	_player.board[6] = burner
	var before: Array[RecruitUnit] = _player.board.duplicate()
	var best: int = BotBurner.best_front_slot(_player, burner, [])
	assert_eq(_player.board, before, "forecast never mutates the real board")
	assert_true(best in [1, 2])
	_brain._place_burner_now(burner)
	assert_eq(_player.board.find(burner), best)
	assert_eq(_brain.value.keep_value(burner), 22.0)
	assert_eq(BotBurner.spend_loss(_player, 2), 4.0)
	assert_eq(_player.board.size(), 7)
	for unit: RecruitUnit in before:
		assert_true(_player.board.has(unit), "a legal swap keeps every unit")


func test_unfunded_or_pinned_burner_is_not_forced_to_move() -> void:
	var burner: RecruitUnit = _player.board[1]
	_player.board[1] = _player.board[6]
	_player.board[6] = burner
	_player.gold = 5
	assert_eq(BotBurner.best_front_slot(_player, burner, []), 6)
	_player.gold = 11
	var pinned: Array[int] = [6]
	assert_eq(BotBurner.best_front_slot(_player, burner, pinned), 6)


func test_multiple_burners_ignore_the_excluded_unit_sentinel_without_mutation() -> void:
	var front: RecruitUnit = _player.board[1]
	var back: RecruitUnit = _kit.put("charcoal_burner", 4)
	var before: Array[RecruitUnit] = _player.board.duplicate()
	assert_eq(BotBurner.forecast(_player, 11), 12.0)
	assert_eq(BotBurner.owned_value(back, _player), 6.0, "excluded back body receives no gift")
	assert_eq(BotBurner.owned_value(front, _player), 12.0)
	var excluded := RecruitUnit.new()
	assert_eq(BotBurner.forecast(_player, 11, excluded, 4), 6.0, "empty sentinel adds no stats")
	assert_eq(_player.board, before, "exclusion uses a copied layout")
	assert_eq(_player.board[4], back)
