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
	var brain: BotBrain = BotBrain.from_name("hard:hedgerow_treasury")
	brain.value.strategy = LinePolicies.strategy("line_" + line)
	brain.pinned_strategy = "line_" + line
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
	carry.counters["hedgerow_last_wake_round"] = kit.player.round_number - 1
	assert_true(BotHedgerow.wants_purchase(kit.player, brain.value, offer))


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
