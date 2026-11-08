extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CANDIDATE := preload("res://tools/sim/candidates/acorn_stash.gd")
var _kit: KIT
var _brain: CANDIDATE


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_kit.player.gold = 0
	_kit.player.health = 40
	_kit.player.tier = 6
	_kit.player.round_number = 12
	_brain = BenchSuites.create_bot("acorn_stash") as CANDIDATE
	_brain._player = _kit.player
	_brain._rules = _kit.rules
	_brain._round_now = 12
	_brain.value.library = _kit.library
	_brain.value.board_owner = _kit.player


func after_each() -> void:
	_brain.value.board_owner = null
	_brain._player = null
	_brain._rules = null


func _give(id: String) -> HandItem:
	_kit.rules.give_card(_kit.player, id)
	return _kit.player.items[-1]


func test_cash_a_surplus_acorn_without_losing_a_treasurer_step() -> void:
	var treasurer: RecruitUnit = _kit.put("honorary_treasurer", 0)
	_give("stash")
	_give("acorn")
	_give("acorn")
	var before: int = treasurer.attack + treasurer.health
	assert_eq(_brain._hold_value(1), 0.0, "7 to 6 keeps both real steps")
	assert_true(_brain._pay(1, 1.0))
	assert_eq(_kit.player.gold, 1)
	assert_eq(treasurer.attack + treasurer.health, before)


func test_cash_that_crosses_a_real_threshold_has_a_real_cost() -> void:
	_kit.put("honorary_treasurer", 0)
	_give("acorn")
	_give("acorn")
	# A third Acorn combines immediately into a five-gold Stash, still one Treasury step.
	_give("acorn")
	assert_eq(_kit.item_ids(), ["stash"])
	assert_eq(_brain._hold_value(1), 2.0)
	assert_false(_brain._pay(1, 1.0))
	assert_true(_brain._pay(1, 3.0))
	assert_eq(_kit.player.gold, 5, "overpayment remains banked")


func test_golden_treasurer_uses_golden_steps_and_the_printed_cap() -> void:
	_kit.put("honorary_treasurer", 0, true)
	_give("great_hoard")
	_give("great_hoard")
	assert_eq(_brain.retained_value(_kit.player.items), 32.0)
	assert_eq(_brain._hold_value(16), 12.0, "32 to 16 held gold loses three doubled steps")


func test_known_partner_payout_preserves_a_nearly_complete_batch() -> void:
	var partner: RecruitUnit = _kit.put("sleeping_partner", 0)
	partner.turns_in_slot = 2
	_give("acorn")
	assert_eq(_brain._hold_value(1), 5.0)
	assert_false(_brain._pay(1, 4.0))
	assert_true(_brain._pay(1, 6.0))


func test_exhausted_or_recently_moved_partner_does_not_invent_a_payout() -> void:
	var partner: RecruitUnit = _kit.put("sleeping_partner", 0)
	_give("acorn")
	assert_eq(_brain._hold_value(1), 0.0)
	partner.turns_in_slot = 2
	partner.counters["paid_wakes"] = 3
	assert_eq(_brain._hold_value(1), 0.0)


func test_mast_prices_the_hoard_bonus_only_with_a_real_board_and_shop() -> void:
	_give("great_hoard")
	assert_eq(_brain._hold_value(1), 0.0)
	_kit.put("old_mother_mast", 0)
	_kit.shop("standing_committee")
	assert_eq(_brain._hold_value(1), 5.0)
	assert_false(_brain._pay(1, 4.0))


func test_feed_the_small_acorn_before_doubling_and_keep_the_stash() -> void:
	var dozey: RecruitUnit = _kit.put("alderman_dozey", 0)
	dozey.turns_in_slot = 2
	_give("stash")
	_give("acorn")
	_brain._feed_eaters()
	assert_eq(_kit.item_ids(), ["stash"])
	assert_eq(dozey.perm_attack, 1)
	assert_eq(dozey.perm_health, 1)


func test_dont_feed_points_that_the_pending_double_would_give_for_free() -> void:
	var dozey: RecruitUnit = _kit.put("alderman_dozey", 0)
	dozey.turns_in_slot = 2
	dozey.add_permanent(11, 11)
	var item: HandItem = _give("acorn")
	assert_eq(_brain.feed_value(dozey, item), 0.0)
	_brain._feed_eaters()
	assert_eq(_kit.item_ids(), ["acorn"])


func test_spent_double_does_not_get_counted_again() -> void:
	var dozey: RecruitUnit = _kit.put("alderman_dozey", 0)
	dozey.turns_in_slot = 5
	dozey.counters["fired_wakes"] = 1
	var item: HandItem = _give("acorn")
	assert_eq(_brain.feed_value(dozey, item), 2.0)
	_brain._feed_eaters()
	assert_eq(_kit.item_ids(), ["acorn"])


func test_planning_does_not_mutate_the_hand_board_gold_or_rng() -> void:
	_give("stash")
	var item: HandItem = _give("acorn")
	var before: int = _kit.player.bot_rng.state
	var plan: Dictionary = _brain.cash_plan(1)
	assert_false(plan.is_empty())
	assert_eq(_kit.player.bot_rng.state, before)
	assert_eq(_kit.player.gold, 0)
	assert_eq(_kit.player.board_count(), 0)
	assert_same(_kit.player.items[-1], item)


func test_candidate_inherits_promoted_carrier_replacement() -> void:
	var wolf: RecruitUnit = _kit.put("brother_wolf", 0)
	wolf.attack = 8
	wolf.health = 4
	for slot: int in range(1, BoardGeometry.SLOTS):
		var id: String = _kit.card("pack_%d" % slot, [{"id": "pack", "repeat": false}], [], 30, 30)
		_kit.library.get_unit(id)["tier"] = 4
		_kit.put(id, slot)
	var grizel: RecruitUnit = _kit.shop("grizel")
	assert_eq(BotCarrier.upgrade_plan(_brain, grizel).get("slot"), 0)
	assert_gt(_brain._unit_gain(grizel), 0.0)


func test_burner_cash_uses_one_scored_batch_instead_of_a_different_greedy_sequence() -> void:
	_kit.put("charcoal_burner", 0)
	_kit.put("mr_crumb", 4)
	_kit.player.gold = 5
	_give("acorn")
	_give("acorn")
	_brain._cash_for_burn()
	assert_eq(_kit.player.gold, 7)
	assert_true(_kit.player.items.is_empty())


func test_danger_does_not_price_a_partner_payout_after_another_fight() -> void:
	var partner: RecruitUnit = _kit.put("sleeping_partner", 0)
	partner.turns_in_slot = 1
	_kit.player.health = BotBrain.LOW_HEALTH
	_give("acorn")
	assert_eq(_brain._hold_value(1), 0.0)
	partner.turns_in_slot = 2
	assert_eq(_brain._hold_value(1), 5.0, "this End of Turn pays before the next fight")


func test_cash_the_stash_when_a_small_acorn_is_the_better_conkers_ammunition() -> void:
	_kit.put("sergeant_at_conkers", 0)
	var seen: Array = []
	seen.resize(BoardGeometry.SLOTS)
	seen[BoardGeometry.across(0)] = {"health": 10}
	_kit.player.scout = {"specs": seen}
	_give("stash")
	_give("acorn")
	var plan: Dictionary = _brain.cash_plan(1)
	assert_eq(plan["cash"], 5, "the cheapest-first prefix is not the best retained payoff")
	assert_true(_brain._pay(1, 1.0))
	assert_eq(_kit.item_ids(), ["acorn"])
	assert_eq(_kit.player.gold, 5)
