# gdlint:disable=max-public-methods
extends GutTest
## Directed recruit and placement checks; no lobby creation or complete game runs.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	var config: GameConfig = GameConfig.full_game()
	config.set_value("pass3_preset", "B")
	kit.setup(config)
	kit.player.round_number = 9
	kit.player.tier = 4


func _brain(line: String = "hedgerow_supper") -> BotBrain:
	var brain: BotBrain = BenchSuites.create_bot("line_" + line) as BotBrain
	assert_true(brain is LineBrain, "exercise the registered measurement policy")
	brain._player = kit.player
	brain._rules = kit.rules
	brain._round_now = kit.player.round_number
	brain.value.library = kit.library
	brain.value.recruit_rules = kit.rules
	brain.value.board_owner = kit.player
	return brain


func _put(id: String, slot: int, added: int = 0) -> RecruitUnit:
	var unit: RecruitUnit = kit.put(id, slot)
	unit.perm_attack = added
	unit.perm_health = added
	unit.home_slot = slot
	kit.rules.board_changed(kit.player)
	return unit


func test_supper_holds_food_until_native_wake_then_feeds_the_carry() -> void:
	var carry: RecruitUnit = _put("alderman_dozey", 6)
	_put("sleeping_partner", 4)
	var brain: BotBrain = _brain()
	kit.rules.give_card(kit.player, "stash")
	carry.turns_in_slot = 1
	brain._feed_eaters()
	assert_eq(kit.player.items.size(), 1, "the second sleep turn holds its Larder")
	var before: int = carry.attack
	carry.turns_in_slot = 2
	brain._feed_eaters()
	assert_true(kit.player.items.is_empty(), "the third turn feeds all food")
	assert_gt(carry.attack, before, "the real item action permanently feeds Dozey")


func test_supper_cash_is_reserved_for_scheduled_climbs_and_priority_engines() -> void:
	_put("sleeping_partner", 4)
	_put("mr_crumb", 6)
	_put("mrs_sorrel", 5)
	var brain: BotBrain = _brain()
	kit.player.gold = 0
	kit.rules.give_card(kit.player, "stash")
	var mallow: RecruitUnit = kit.shop("mrs_mallow")
	var dozey: RecruitUnit = kit.shop("alderman_dozey")
	assert_false(BotHedgerow.cash_purchase(kit.player, brain.value, mallow))
	assert_true(BotHedgerow.cash_purchase(kit.player, brain.value, dozey))
	var offer: Dictionary = brain._best_offer()
	assert_false(offer.is_empty(), "a priority engine can use the held Larder")
	assert_eq(offer.get("index", -1), 1, "Mallow cannot spend Supper food")
	assert_false(brain._pay(1, 100.0, false), "an unscheduled action cannot cash food")
	assert_eq(kit.player.items.size(), 1)
	assert_true(brain._pay(1, 100.0, true), "a scheduled climb can cash food")


func test_third_dozey_waits_until_after_a_wake() -> void:
	var carry: RecruitUnit = _put("alderman_dozey", 6, 30)
	kit.put("alderman_dozey")
	var offer: RecruitUnit = kit.shop("alderman_dozey")
	var brain: BotBrain = _brain()
	assert_false(BotHedgerow.wants_purchase(kit.player, brain.value, offer))
	assert_eq(brain._unit_gain(offer), 0.0, "the actual line declines a third sleeping copy")
	carry.counters["hedgerow_last_wake_round"] = kit.player.round_number - 1
	assert_true(BotHedgerow.wants_purchase(kit.player, brain.value, offer))
	assert_gt(brain._unit_gain(offer), 0.0, "the actual line permits its triple after a wake")


func test_placement_preserves_sleep_then_moves_a_large_carry_after_a_wake() -> void:
	var carry: RecruitUnit = _put("alderman_dozey", 6, 100)
	var partner: RecruitUnit = _put("sleeping_partner", 4)
	_put("dr_urchin", 5)
	_put("mrs_mallow", 0)
	_put("beadle_warrenby", 1)
	carry.turns_in_slot = 2
	partner.turns_in_slot = 5
	var brain: BotBrain = _brain()
	BotPlacer.arrange(kit.player, kit.rules, brain.value, BotLevel.PLACE_BLIND, 0)
	assert_same(kit.player.board[6], carry, "B3 protects the current sleep")
	assert_null(kit.player.board[3], "F4 stays open for Pass and Hunker")
	assert_eq(carry.turns_in_slot, 2)
	assert_eq(partner.turns_in_slot, 5)
	carry.turns_in_slot = 3
	carry.counters["hedgerow_last_wake_round"] = kit.player.round_number - 1
	BotPlacer.arrange(kit.player, kit.rules, brain.value, BotLevel.PLACE_BLIND, 0)
	assert_same(kit.player.board[3], carry, "the free post-wake turn closes the Line")
	assert_eq(carry.turns_in_slot, 0, "the actual move starts his next sleep in F4")
	assert_same(kit.player.board[4], partner)
	assert_eq(partner.turns_in_slot, 5, "Partner was never a swap destination")


func test_crumb_is_played_into_dozey_before_his_real_sold_pass_lands() -> void:
	_put("mr_crumb", 6, 20)
	_put("sleeping_partner", 4)
	_put("dr_urchin", 5)
	var carry: RecruitUnit = kit.put("alderman_dozey")
	var brain: BotBrain = _brain()
	brain._play_hand()
	assert_same(kit.player.board[6], carry)
	assert_null(BotHedgerow.find(kit.player, "mr_crumb"), "the grown Crumb was sold")
	kit.rules.end_phase(kit.player)
	assert_gt(carry.perm_attack, 20, "the engine's sold Pass reached the new carry")


func test_parish_cash_and_floor_growth_value_are_live() -> void:
	_put("mrs_mallow", 0, 10)
	_put("standing_committee", 1, 10)
	_put("mrs_sorrel", 2, 10)
	var runt: RecruitUnit = _put("mr_crumb", 3)
	var brain: BotBrain = _brain("hedgerow_parish")
	kit.rules.give_card(kit.player, "stash")
	var before: int = kit.player.gold
	BotHedgerow.prepare(brain)
	assert_true(kit.player.items.is_empty())
	assert_gt(kit.player.gold, before, "Parish cashes its food before shopping")
	var committee: RecruitUnit = BotHedgerow.find(kit.player, "standing_committee")
	var low_value: float = brain.value.buy_value(committee, kit.player)
	runt.perm_attack += 10
	runt.perm_health += 10
	kit.rules.board_changed(kit.player)
	assert_gt(
		brain.value.buy_value(committee, kit.player),
		low_value,
		"raising the floor raises Committee's value"
	)
	assert_false(brain._can_replace(committee), "the actual route engine is retained")
	assert_true(brain._can_replace(kit.player.board[2]), "a support can make room for an engine")


func test_parish_sells_a_kit_only_when_mallow_will_not_double_it() -> void:
	_put("standing_committee", 0, 10)
	var token: RecruitUnit = _put("kit", 4)
	var brain: BotBrain = _brain("hedgerow_parish")
	BotHedgerow.prepare(brain)
	assert_false(kit.player.board.has(token), "without Mallow the runt reduces every payout")
	_put("mrs_mallow", 1, 10)
	token = _put("kit", 4)
	BotHedgerow.prepare(brain)
	assert_true(kit.player.board.has(token), "Mallow is due to double this runt")


func test_pinned_strategy_keeps_early_tempo_flexibility() -> void:
	var brain: BotBrain = _brain()
	kit.player.round_number = 3
	assert_true(brain.value.flexible_purchases(kit.player, 3))
	_put("sleeping_partner", 4)
	assert_true(brain.value.flexible_purchases(kit.player, 8))


func test_ordinary_native_routes_climb_for_their_actual_engines() -> void:
	var knowledge: BotKnowledge = BotKnowledge.shared()
	var expected: Dictionary = {
		"hedgerow_parish": [2, 4, 6, 8, 10],
		"hedgerow_supper": [2, 4, 7, 10, 12],
		"hedgerow_treasury": [2, 4, 7, 10, 12],
	}
	for id: String in expected:
		var curve: Array[int] = []
		for round_number: Variant in knowledge.strategy(id)["curve"]:
			curve.append(CoreUtil.to_int(round_number))
		assert_eq(curve, expected[id], id)

	assert_eq(LinePolicies.profiles()["line_hedgerow_supper"]["base_strategy"], "hedgerow_supper")


func test_optional_treasury_cashes_once_with_hayward_then_holds_again() -> void:
	_put("honorary_treasurer", 3, 20)
	_put("goodman_hayward", 0)
	var brain: BotBrain = _brain()
	brain.value.strategy = BotKnowledge.shared().strategy("hedgerow_treasury")
	kit.player.round_number = 13
	kit.rules.give_card(kit.player, "stash")
	BotHedgerow.prepare(brain)
	assert_true(kit.player.items.is_empty(), "the optional route makes its real Hayward cash-out")
	kit.rules.give_card(kit.player, "stash")
	BotHedgerow.prepare(brain)
	assert_eq(kit.player.items.size(), 1, "cash-out happens only once")


func test_parish_keeps_buying_engine_copies_for_real_triples_on_a_full_board() -> void:
	var ids: Array[String] = [
		"standing_committee",
		"mrs_mallow",
		"squire_lollop",
		"goodman_hayward",
		"mrs_mallow",
		"squire_lollop",
		"goodman_hayward"
	]
	for slot: int in BoardGeometry.SLOTS:
		_put(ids[slot], slot, 10)
	var brain: BotBrain = _brain("hedgerow_parish")
	kit.player.gold = 10
	var copy: RecruitUnit = kit.shop("standing_committee")
	assert_gt(brain._unit_gain(copy), 0.0, "a pair can wait in hand while all seven engines stand")
	assert_true(brain._buy_offer({"spell": false, "index": 0}))
	assert_true(kit.player.hand.has(copy), "the extra engine remains available for its triple")
	kit.shop("standing_committee")
	assert_true(brain._buy_offer({"spell": false, "index": 0}))
	var golden: RecruitUnit = BotHedgerow.find(kit.player, "standing_committee")
	assert_not_null(golden)
	assert_true(golden.golden, "the actual third buy creates and plays its golden engine")


func test_parish_sparse_board_keeps_a_single_unbroken_line() -> void:
	_put("standing_committee", 0, 20)
	_put("mrs_mallow", 2, 10)
	_put("mrs_clover", 3, 5)
	_put("dr_urchin", 6, 10)
	var brain: BotBrain = _brain("hedgerow_parish")
	BotPlacer.arrange(kit.player, kit.rules, brain.value, BotLevel.PLACE_BLIND, 0)
	var occupied: Array[bool] = kit.player.occupied()
	var start: int = kit.player.board.find(BotHedgerow.find(kit.player, "standing_committee"))
	assert_eq(
		BoardGeometry.touching(occupied, start).size(), 4, "the sparse Parish shares every payout"
	)


func test_native_cash_policy_does_not_run_on_frozen_hedgerow() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game(), false, LegacyWave1.with_hedgerow(UnitLibrary.load_dir()))
	kit.player.round_number = 9
	var brain: BotBrain = _brain("hedgerow_parish")
	kit.rules.give_card(kit.player, "stash")
	var gold: int = kit.player.gold
	assert_false(BotHedgerow.build(brain.value))
	brain._cast_spells(false)
	assert_eq(kit.player.larder(), 5, "native Parish cashing must not reach the rollback")
	assert_eq(kit.player.gold, gold)


func _actual_line(id: String, round_number: int) -> LineBrain:
	var brain: LineBrain = BenchSuites.create_bot(id) as LineBrain
	assert_not_null(brain, "the registered measurement policy must be a real LineBrain")
	assert_eq(brain.line_id, id)
	kit.player.round_number = round_number
	kit.player.health = 30
	kit.player.gold_next_turn = 0
	brain._player = kit.player
	brain._rules = kit.rules
	brain._round_now = round_number
	brain.value.library = kit.library
	brain.value.recruit_rules = kit.rules
	brain.value.board_owner = kit.player
	return brain


func test_actual_supper_line_reserves_only_the_next_scheduled_climb_shortfall() -> void:
	_put("sleeping_partner", 4)
	_put("mr_crumb", 6)
	_put("mr_pym", 0)
	kit.player.tier = 3
	kit.player.upgrade_cost = 13
	var brain: LineBrain = _actual_line("line_hedgerow_supper", 6)
	assert_eq(brain._target_round(3), 7, "the actual Supper profile schedules tier 4 for R7")
	assert_eq(kit.rules.tier_up_cost(kit.player), 13)
	assert_eq(kit.config.get_int_at("income_by_turn", 6), 9, "R7 pays nine gold")
	assert_eq(kit.config.get_int("upgrade_discount_per_turn"), 1)
	assert_eq(brain._held_back(), 3, "13 cost minus one discount and nine income needs three")
	kit.player.gold_next_turn = 2
	assert_eq(brain._held_back(), 1, "promised income reduces the reserve instead of keeping three")
	kit.player.gold_next_turn = 0
	kit.player.round_number = 5
	brain._round_now = 5
	assert_eq(kit.rules.tier_up_cost(kit.player), 13, "the R5 comparison keeps the same cost")
	assert_eq(brain._held_back(), 0, "two turns before the scheduled climb the reserve is zero")
	kit.player.tier = UnitLibrary.TIERS
	kit.player.round_number = 12
	brain._round_now = 12
	assert_eq(brain._held_back(), 0, "the top tier has no next climb to reserve for")


func test_actual_parish_line_uses_its_earlier_climb_and_next_turn_income() -> void:
	_put("mrs_mallow", 0)
	_put("mrs_clover", 4)
	_put("mr_crumb", 1)
	kit.player.tier = 3
	kit.player.upgrade_cost = 13
	var brain: LineBrain = _actual_line("line_hedgerow_parish", 5)
	assert_eq(brain._target_round(3), 6, "Parish reaches tier 4 one round before Supper")
	assert_eq(kit.config.get_int_at("income_by_turn", 5), 8, "R6 pays eight gold")
	assert_eq(brain._held_back(), 4, "13 cost minus one discount and eight income needs four")
	kit.player.upgrade_cost = 9
	assert_eq(brain._held_back(), 0, "next turn's income covers the discounted climb in full")
	kit.player.tier = UnitLibrary.TIERS
	kit.player.round_number = 10
	brain._round_now = 10
	assert_eq(brain._held_back(), 0, "Parish also stops saving at the top tier")


func test_actual_supper_declines_late_partner_and_pym_offers() -> void:
	_put("sleeping_partner", 4)
	_put("mr_crumb", 6)
	_put("mrs_sorrel", 5)
	var brain: LineBrain = _actual_line("line_hedgerow_supper", 7)
	kit.player.gold = 10
	var partner: RecruitUnit = kit.shop("sleeping_partner")
	var pym: RecruitUnit = kit.shop("mr_pym")
	assert_eq(brain._unit_gain(partner), 0.0, "a new Partner stops being a buy after R3")
	assert_eq(brain._unit_gain(pym), 0.0, "a new Pym stops being a buy after R6")
	assert_true(brain._best_offer().is_empty(), "the actual offer pipeline respects both windows")


func test_actual_supper_waits_for_written_climb_even_with_plenty_of_gold() -> void:
	_put("sleeping_partner", 4)
	_put("mr_pym", 0)
	_put("mr_crumb", 6)
	_put("mrs_sorrel", 5)
	kit.player.tier = 3
	kit.player.upgrade_cost = 13
	var brain: LineBrain = _actual_line("line_hedgerow_supper", 6)
	kit.player.gold = 40
	kit.rules.give_card(kit.player, "great_hoard")
	brain._climb(false)
	brain._climb(true)
	assert_eq(kit.player.tier, 3, "wealth cannot advance the written R7 climb")
	assert_eq(kit.player.gold, 40)
	assert_eq(kit.player.larder(), 16, "unscheduled climbing leaves the held Larder alone")
	kit.player.gold = 0
	kit.player.round_number = 7
	brain._round_now = 7
	brain._climb(false)
	assert_eq(kit.player.tier, 4, "the scheduled climb may use the held Larder")
	assert_eq(kit.player.larder(), 0)
	assert_eq(kit.player.gold, 3, "the real climb spends thirteen of the cashed sixteen")


func test_actual_supper_protects_reserved_gold_from_ordinary_offers_and_refreshes() -> void:
	_put("sleeping_partner", 4)
	_put("mr_pym", 0)
	_put("mr_crumb", 6)
	kit.player.tier = 3
	kit.player.upgrade_cost = 13
	var brain: LineBrain = _actual_line("line_hedgerow_supper", 6)
	kit.player.gold = 3
	kit.rules.give_card(kit.player, "stash")
	kit.shop("mrs_sorrel")
	assert_eq(brain._held_back(), 3)
	assert_true(brain._best_offer().is_empty(), "Sorrel cannot spend the next climb's bank")
	assert_false(brain._refresh_worth_it(), "held food cannot fund a speculative refresh")
	kit.shop("alderman_dozey")
	var offer: Dictionary = brain._best_offer()
	assert_false(offer.is_empty(), "a priority engine retains its Larder exception")
	assert_eq(offer.get("index", -1), 1)


func _parish_reserve_state(health: int = 30) -> LineBrain:
	_put("mrs_mallow", 0)
	_put("mr_crumb", 1)
	_put("mr_crumb", 2)
	kit.player.tier = 5
	kit.player.upgrade_cost = 12
	var brain: LineBrain = _actual_line("line_hedgerow_parish", 9)
	kit.player.health = health
	return brain


func test_parish_reserves_the_real_t6_shortfall_even_at_low_health() -> void:
	var brain: LineBrain = _parish_reserve_state(1)
	assert_eq(kit.rules.base_upgrade_cost(5), 13, "A2 C10 adopts the live T6 price")
	assert_eq(brain._held_back(), 1, "twelve minus a discount and next income ten needs one")
	kit.player.upgrade_cost = 13
	assert_eq(brain._held_back(), 2, "a late T5 arrival needs two, rather than a flat reserve")


func test_parish_last_orders_cannot_consume_the_next_climb_reserve() -> void:
	var brain: LineBrain = _parish_reserve_state()
	kit.player.gold = 3
	kit.rules.give_card(kit.player, "last_orders")
	brain._cast_spells(true)
	assert_eq(kit.player.gold, 3, "a spend-all spell waits while the written climb needs gold")
	assert_true(kit.item_ids().has("last_orders"))
	kit.player.tier = UnitLibrary.TIERS
	brain._cast_spells(true)
	assert_eq(kit.player.gold, 0, "the same spell is usable when the reserve ends")
	assert_false(kit.item_ids().has("last_orders"))


func test_parish_free_stat_spells_work_before_the_reserve_is_fully_banked() -> void:
	var brain: LineBrain = _parish_reserve_state()
	kit.player.gold = 0
	kit.rules.give_card(kit.player, "pinch_of_dust")
	brain._cast_spells(false)
	assert_false(kit.item_ids().has("pinch_of_dust"), "a free cast spends none of the reserve")


func test_parish_nonspare_power_cannot_consume_reserved_gold() -> void:
	var brain: LineBrain = _parish_reserve_state()
	kit.player.hero = kit.library.get_hero("jill_down_the_tree").duplicate(true)
	kit.player.hero["power"]["cost"] = 3
	kit.player.power_uses_left = 1
	kit.player.gold = 3
	brain._maybe_power()
	assert_eq(kit.player.gold, 3, "the triple-hunt plan also respects the climb reserve")
	assert_eq(kit.player.power_uses_left, 1)
	assert_eq(kit.player.tier, 5)


func test_parish_refreshes_twice_except_to_find_its_missing_late_engine() -> void:
	_put("mrs_mallow", 0)
	_put("mr_crumb", 1)
	_put("mrs_clover", 4)
	var brain: LineBrain = _actual_line("line_hedgerow_parish", 7)
	kit.player.tier = 4
	kit.player.gold = 20
	brain._refreshes = 1
	assert_true(brain._refresh_worth_it())
	brain._refreshes = 2
	assert_false(brain._refresh_worth_it(), "ordinary Parish shopping stops after two")
	kit.player.tier = 5
	assert_true(brain._refresh_worth_it(), "tier five may search for its first Committee")
	_put("standing_committee", 2)
	assert_false(brain._refresh_worth_it(), "finding the Committee ends extra refreshes")
	kit.player.tier = 6
	assert_true(brain._refresh_worth_it(), "tier six may search for its first Lollop")
	_put("squire_lollop", 6)
	assert_false(brain._refresh_worth_it(), "finding Lollop ends the tier-six exception")


func test_supper_refreshes_freely_from_r12_in_the_actual_shopping_loop() -> void:
	_put("alderman_dozey", 6, 20)
	_put("dr_urchin", 5)
	_put("sleeping_partner", 4)
	var brain: LineBrain = _actual_line("line_hedgerow_supper", 11)
	kit.player.tier = 6
	kit.player.gold = 10
	brain._refreshes = 30
	brain._shop_loop()
	assert_eq(brain._refreshes, 30, "before R12 the ordinary limit remains")
	kit.player.round_number = 12
	brain._round_now = 12
	brain._shop_loop()
	assert_gt(brain._refreshes, 30, "R12 shopping can spend spare gold beyond that limit")
	assert_eq(brain.level.max_refreshes, 30, "temporary route limits do not change the level")


func _sergeant_board() -> LineBrain:
	_put("sergeant_at_conkers", 0)
	_put("alderman_dozey", 6)
	_put("dr_urchin", 5)
	_put("sleeping_partner", 4)
	return _actual_line("line_hedgerow_supper", 8)


func test_supper_sergeant_uses_only_its_private_scout_snapshot_to_cash_loose_acorns() -> void:
	var brain: LineBrain = _sergeant_board()
	kit.player.scout = {
		"specs":
		[{"attack": 10, "health": 10}, {"attack": 100, "health": 100}, null, null, null, null, null]
	}
	kit.rules.give_card(kit.player, "acorn")
	kit.rules.give_card(kit.player, "stash")
	var gold: int = kit.player.gold
	BotHedgerow.remember_scout(kit.player, kit.rules, brain.value)
	kit.player.scout = {}
	brain._arrange()
	assert_eq(kit.item_ids(), ["stash"], "the Sergeant's smallest item is now a Stash")
	assert_eq(kit.player.gold, gold + 1)
	assert_false(brain.level.scouts, "placement stays blind")
	assert_true(kit.player.scout.is_empty())
	assert_false(kit.player.has_meta(BotHedgerow.SCOUT_META), "the private snapshot is cleared")


func test_supper_sergeant_keeps_a_great_hoard_against_a_dominant_enemy() -> void:
	var brain: LineBrain = _sergeant_board()
	kit.player.scout = {
		"specs":
		[{"attack": 100, "health": 100}, {"attack": 1, "health": 1}, null, null, null, null, null]
	}
	for id: String in ["acorn", "stash", "great_hoard"]:
		kit.rules.give_card(kit.player, id)
	var gold: int = kit.player.gold
	BotHedgerow.sergeant_cash(brain)
	assert_eq(kit.item_ids(), ["great_hoard"])
	assert_eq(kit.player.gold, gold + 6, "smaller items are cashed to expose the Hoard")


func test_supper_holds_larder_before_its_first_hedgerow_body() -> void:
	_put("wee_wobbly", 0)
	var brain: LineBrain = _actual_line("line_hedgerow_supper", 3)
	kit.player.gold = 0
	kit.rules.give_card(kit.player, "stash")
	kit.shop("mr_crumb")
	assert_false(BotHedgerow.active(kit.player))
	assert_true(BotHedgerow.holds(kit.player, brain.value))
	assert_true(brain._best_offer().is_empty(), "ordinary early tempo does not cash the feast")
	assert_eq(kit.player.larder(), 5)


func test_first_partner_is_played_in_b1_instead_of_buried_on_a_full_early_board() -> void:
	var holder: RecruitUnit = _put("mrs_posset", 0)
	for slot: int in [1, 2, 4, 5, 6]:
		var id: String = kit.card("hedge_early_%d" % slot, [], ["Hedgerow folk"], 1, 1)
		_put(id, slot)
	kit.player.tier = 2
	var brain: LineBrain = _actual_line("line_hedgerow_supper", 3)
	kit.player.gold = 10
	var partner: RecruitUnit = kit.shop("sleeping_partner")
	assert_gt(brain._unit_gain(partner), 0.0, "the existing early priority accepts the offer")
	assert_eq(brain._buy_belly(partner), -1)
	assert_true(brain._buy_offer({"spell": false, "index": 0}))
	assert_same(kit.player.board[4], partner, "the first Partner takes its permanent B1 slot")
	assert_false(holder.held.has(partner))
	assert_eq(partner.turns_in_slot, 0)


func test_supper_buys_an_affordable_first_partner_before_automatic_rainy_day() -> void:
	kit.player.tier = 1
	kit.player.upgrade_cost = kit.rules.base_upgrade_cost(1)
	var brain: LineBrain = _actual_line("line_hedgerow_supper", 1)
	kit.player.gold = 3
	var partner: RecruitUnit = kit.shop("sleeping_partner")
	kit.player.shop_spells.append(
		HandItem.make(kit.library.get_card("rainy_day"), kit.rules.new_iid())
	)
	brain._open_with_a_plan()
	assert_eq(
		kit.player.gold, 3, "Rainy Day cannot make the offered three-gold Partner unaffordable"
	)
	assert_eq(
		kit.player.shop_spells.size(), 1, "the automatic opener waits for this route purchase"
	)
	var offer: Dictionary = brain._best_offer()
	assert_false(offer.is_empty())
	if offer.is_empty():
		return
	assert_eq(offer.get("index", -1), 0)
	assert_false(CoreUtil.to_bool(offer.get("spell", true)))
	assert_true(brain._buy_offer(offer))
	assert_same(
		kit.player.board[4], partner, "the actual pipeline buys and fields the first Partner"
	)


func test_frozen_hedgerow_keeps_its_existing_automatic_rainy_day_opener() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game(), false, LegacyWave1.with_hedgerow(UnitLibrary.load_dir()))
	kit.player.tier = 1
	var brain: LineBrain = _actual_line("line_hedgerow_supper", 1)
	kit.player.gold = 3
	kit.shop("sleeping_partner")
	kit.player.shop_spells.append(
		HandItem.make(kit.library.get_card("rainy_day"), kit.rules.new_iid())
	)
	assert_false(BotHedgerow.build(brain.value))
	brain._open_with_a_plan()
	assert_eq(kit.player.gold, 2, "the non-native line still buys its one-gold economy opener")
	assert_eq(brain._opening_plan, "economy")
	assert_true(kit.player.shop_spells.is_empty())


func _normal_hard(strategy: String) -> BotBrain:
	var brain: BotBrain = BotBrain.from_name("hard:" + strategy)
	assert_false(
		brain is LineBrain, "exercise ordinary Hard rather than the committed-line override"
	)
	brain._player = kit.player
	brain._rules = kit.rules
	brain._round_now = kit.player.round_number
	brain.value.library = kit.library
	brain.value.recruit_rules = kit.rules
	brain.value.board_owner = kit.player
	return brain


func test_normal_hard_supper_and_treasury_hold_before_an_active_hedgerow_body() -> void:
	_put("wee_wobbly", 0)
	kit.player.gold = 0
	kit.rules.give_card(kit.player, "stash")
	kit.shop("mr_crumb")
	for strategy: String in ["hedgerow_supper", "hedgerow_treasury"]:
		var brain: BotBrain = _normal_hard(strategy)
		assert_false(BotHedgerow.active(kit.player))
		assert_true(BotHedgerow.holds(kit.player, brain.value), strategy)
		assert_true(brain._best_offer().is_empty(), strategy + " preserves food for its route")
		assert_eq(kit.player.larder(), 5)


func test_normal_hard_partner_frees_b1_by_selling_the_weakest_eligible_body() -> void:
	var holder: RecruitUnit = _put("mrs_posset", 0, 2)
	for slot: int in [1, 2, 4, 5, 6]:
		var id: String = kit.card("normal_hedge_early_%d" % slot, [], ["Hedgerow folk"], 1, 1)
		_put(id, slot)
	var weakest: RecruitUnit = kit.player.board[1]
	var previous_b1: RecruitUnit = kit.player.board[4]
	kit.player.round_number = 3
	kit.player.tier = 2
	var brain: BotBrain = _normal_hard("hedgerow_supper")
	assert_lt(
		brain.value.keep_value(weakest),
		brain.value.keep_value(holder),
		"the intended retiring filler is worth less than the surviving Belly holder"
	)
	var partner: RecruitUnit = kit.put("sleeping_partner")
	brain._play_hand()
	assert_false(kit.player.board.has(weakest), "the real sale retires the weakest filler")
	assert_same(kit.player.board[1], previous_b1, "the surviving B1 body moves into the freed slot")
	assert_same(kit.player.board[4], partner, "ordinary Hard plays the first Partner into B1")
	assert_false(holder.held.has(partner))
	assert_eq(kit.player.board_count(), 6)


func test_normal_hard_postwake_move_uses_the_average_of_an_even_boards_middle_pair() -> void:
	var carry: RecruitUnit = _put("alderman_dozey", 6, 9)
	var urchin: RecruitUnit = _put("dr_urchin", 5)
	urchin.perm_attack = 1
	_put("sleeping_partner", 4)
	var mallow: RecruitUnit = _put("mrs_mallow", 0)
	mallow.perm_attack = 3
	kit.rules.board_changed(kit.player)
	carry.turns_in_slot = 3
	carry.counters["hedgerow_last_wake_round"] = kit.player.round_number - 1
	var brain: BotBrain = _normal_hard("hedgerow_supper")
	assert_eq(carry.attack + carry.health, 27)
	assert_true(BotHedgerow.move_ready(kit.player, carry), "bodies 3,8,10,27 have median9, not10")
	brain._arrange()
	assert_same(kit.player.board[3], carry, "27 meets three times the actual median")
	assert_eq(carry.turns_in_slot, 0)
