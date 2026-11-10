extends GutTest

const ORIGINAL_B := preload("res://tests/core/pass3_original_b.gd")
## Fixed recruit boards: exact normal/golden rules and guard-off counterexamples.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")
const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(ORIGINAL_B.apply(GameConfig.full_game()))
	kit.player.round_number = 1
	kit.player.gold = 100


func _end() -> void:
	kit.rules.end_phase(kit.player)
	kit.player.round_number += 1


func test_crumb_play_and_sale_pass_normal_and_golden_exclude_tribe_and_keep_permanent() -> void:
	for golden: bool in [false, true]:
		kit.player.board.fill(null)
		kit.player.pending_passes.clear()
		var carry: RecruitUnit = kit.put("field_vole", 6)
		var crumb: RecruitUnit = kit.play("mr_crumb", 0, golden)
		crumb.add_permanent(9, 11)
		kit.player.hedgerow_bonus = 20
		kit.rules.board_changed(kit.player)
		assert_eq(kit.rules.sell(kit.player, 0), "")
		_end()
		var scale: int = 2 if golden else 1
		assert_eq(carry.perm_attack, scale + (scale + 9) * scale)
		assert_eq(carry.perm_health, scale + (2 * scale + 11) * scale)


func test_dozey_food_uses_all_three_real_larder_values_normal_and_golden() -> void:
	for golden: bool in [false, true]:
		kit.player.board.fill(null)
		var dozey: RecruitUnit = kit.put("alderman_dozey", 6, golden)
		for id: String in ["acorn", "stash", "great_hoard"]:
			kit.rules.give_card(kit.player, id)
			assert_eq(kit.rules.play_item(kit.player, 0, 6), "")
		assert_eq(dozey.perm_attack, 88 if golden else 44)
		assert_eq(dozey.perm_health, 88 if golden else 44)


func test_wake_repeats_every_three_turns_after_all_acorn_and_pass_listeners() -> void:
	kit.put("sleeping_partner", 4)
	kit.put("beadle_warrenby", 0)
	var dozey: RecruitUnit = kit.put("alderman_dozey", 6)
	for _turn: int in 3:
		_end()
	assert_eq(Vector2i(dozey.attack, dozey.health), Vector2i(22, 28))
	assert_eq(dozey.counters["hedgerow_last_wake_round"], 3)
	for _turn: int in 3:
		_end()
	assert_gt(dozey.attack, 44, "the second wake is not once or capped")


func test_wake_includes_standing_bonus_but_not_slot_or_next_combat_stats() -> void:
	var dozey: RecruitUnit = kit.put("alderman_dozey", 6)
	kit.player.hedgerow_bonus = 10
	BoardUpkeep.add_ring(kit.player, 6, {"attack": 40, "health": 50})
	dozey.add_combat(100, 200)
	for _turn: int in 3:
		_end()
	assert_eq(Vector2i(dozey.perm_attack, dozey.perm_health), Vector2i(13, 16))


func test_move_and_triple_restart_wake_without_losing_food() -> void:
	var dozey: RecruitUnit = kit.put("alderman_dozey", 6)
	dozey.add_permanent(20, 30)
	_end()
	_end()
	assert_eq(kit.rules.move(kit.player, 6, 5), "")
	_end()
	assert_eq(dozey.perm_attack, 20)
	var other: RecruitUnit = kit.put("alderman_dozey")
	var third: RecruitUnit = kit.put("alderman_dozey")
	kit.rules.combine(kit.player, [dozey, other, third], true)
	var merged: RecruitUnit = kit.player.hand.back()
	assert_true(merged.golden)
	assert_eq(merged.turns_in_slot, 0)
	assert_eq(merged.perm_attack, 20)


func test_golden_wake_is_not_fourfold_and_c_uses_threefold() -> void:
	var dozey: RecruitUnit = kit.put("alderman_dozey", 6, true)
	for _turn: int in 3:
		_end()
	assert_eq(Vector2i(dozey.attack, dozey.health), Vector2i(12, 24))
	kit = KIT.new()
	var config: GameConfig = ORIGINAL_B.apply(GameConfig.full_game())
	ORIGINAL_B.clear(config)
	config.set_value("pass3_preset", "C")
	kit.setup(config)
	kit.player.round_number = 1
	dozey = kit.put("alderman_dozey", 6, true)
	for _turn: int in 3:
		_end()
	assert_eq(Vector2i(dozey.attack, dozey.health), Vector2i(18, 36))


func test_mallow_b_doubles_two_and_golden_four_smallest_hedgerow_only() -> void:
	for golden: bool in [false, true]:
		kit.player.board.fill(null)
		kit.card("runt", [], ["Hedgerow folk"], 1, 1)
		kit.put("mrs_mallow", 6, golden)
		for slot: int in 4:
			kit.put("runt", slot)
		var foreign: RecruitUnit = kit.put("pill_bug", 4)
		_end()
		for slot: int in 4:
			assert_eq(kit.player.board[slot].attack, 2 if golden or slot < 2 else 1)
		assert_eq(foreign.perm_attack, 0)


func test_doubling_and_timed_payout_ignore_extra_end_turn_firings_with_guard_off_proof() -> void:
	kit.put("sleeping_partner", 4)
	kit.put("alderman_dozey", 6)
	kit.card("twice", [{"id": "end_turn_doubler"}])
	kit.put("twice", 0)
	for _turn: int in 3:
		_end()
	assert_eq(kit.player.board[6].attack, 6)
	kit.config.set_value("pass3_loop_guards", false)
	kit.rules.board_changed(kit.player)
	for _turn: int in 3:
		_end()
	assert_eq(kit.player.board[6].attack, 24, "unfixed doubler repeats the wake")


func test_partner_counts_only_touching_hedgerow_and_golden_doubles_payout() -> void:
	for golden: bool in [false, true]:
		kit.player.board.fill(null)
		kit.player.items.clear()
		kit.put("sleeping_partner", 4, golden)
		kit.put("field_vole", 0)
		kit.put("pill_bug", 1)
		kit.put("field_vole", 6)
		for _turn: int in 3:
			_end()
		# Two connected Hedgerow, B3 is outside the run; a non-Hedgerow bridge contributes no count.
		assert_eq(kit.player.larder(), 12 if golden else 6)


func test_clover_recruit_shares_source_stats_no_limit_normal_and_golden() -> void:
	for golden: bool in [false, true]:
		kit.player.board.fill(null)
		kit.put("mrs_clover", 0, golden)
		for _summon: int in 3:
			kit.rules.place_summons(kit.player, "kit", false, [4])
			var baby: RecruitUnit = kit.player.board[4]
			assert_eq(
				Vector2i(baby.attack, baby.health), Vector2i(9, 17) if golden else Vector2i(3, 5)
			)
			kit.player.board[4] = null


func test_pym_counts_combining_and_beadle_counts_only_actual_acorns_uncapped() -> void:
	kit.put("beadle_warrenby", 0)
	kit.put("mr_pym", 4)
	var last: RecruitUnit = kit.put("field_vole", 6)
	for _gain: int in 3:
		kit.rules.give_card(kit.player, "acorn")
	_end()
	assert_eq(Vector2i(last.perm_attack, last.perm_health), Vector2i(9, 9))


func test_golden_pym_and_beadle_double_pass_values() -> void:
	kit.put("beadle_warrenby", 0, true)
	kit.put("mr_pym", 4, true)
	var last: RecruitUnit = kit.put("field_vole", 6)
	for _gain: int in 3:
		kit.rules.give_card(kit.player, "acorn")
	_end()
	assert_eq(last.perm_attack, 18)


func test_hayward_cash_and_feed_create_uncapped_bonus_on_future_owned_and_held_units() -> void:
	for golden: bool in [false, true]:
		before_each()
		kit.player.board.fill(null)
		kit.player.items.clear()
		kit.player.hedgerow_bonus = 0
		kit.put("goodman_hayward", 0, golden)
		kit.put("alderman_dozey", 6)
		kit.rules.give_card(kit.player, "stash")
		kit.rules.play_item(kit.player, 0)
		kit.rules.give_card(kit.player, "great_hoard")
		kit.rules.play_item(kit.player, 0, 6)
		var fresh: RecruitUnit = kit.shop("mr_crumb")
		kit.rules.observe_shop(kit.player)
		assert_eq(
			fresh.tribe_attack, 42 if golden else 21, "Hayward previews its standing shop bonus"
		)
		var displayed: Vector2i = Vector2i(fresh.attack, fresh.health)
		assert_eq(Vector2i(fresh.perm_attack, fresh.perm_health), Vector2i.ZERO)
		assert_eq(kit.rules.buy(kit.player, 0), "")
		assert_eq(fresh.tribe_attack, 42 if golden else 21)
		assert_eq(Vector2i(fresh.attack, fresh.health), displayed, "buying keeps the preview once")
		var holder: RecruitUnit = kit.put("little_dollop", 5)
		kit.player.hand.erase(fresh)
		holder.held.append(fresh)
		kit.rules.board_changed(kit.player)
		assert_eq(fresh.tribe_attack, 42 if golden else 21, "owned Belly contents keep the bonus")
		assert_eq(kit.player.harvest_supper_round, -1)


func test_treasurer_keeps_larder_growth_after_cashing_normal_and_golden() -> void:
	for golden: bool in [false, true]:
		kit.player.board.fill(null)
		kit.player.items.clear()
		var bank: RecruitUnit = kit.put("honorary_treasurer", 6, golden)
		kit.rules.give_card(kit.player, "great_hoard")
		_end()
		assert_eq(bank.perm_attack, 32 if golden else 16)
		kit.rules.play_item(kit.player, 0)
		_end()
		assert_eq(bank.perm_attack, 32 if golden else 16)


func test_committee_reads_runt_once_and_only_touches_hedgerow() -> void:
	kit.put("standing_committee", 4).add_permanent(20, 20)
	var one: RecruitUnit = kit.put("field_vole", 0)
	var other: RecruitUnit = kit.put("field_vole", 1)
	kit.put("pill_bug", 5)
	_end()
	assert_eq(Vector2i(one.perm_attack, one.perm_health), Vector2i(0, 0))
	assert_eq(Vector2i(other.perm_attack, other.perm_health), Vector2i(0, 0))
	# Runt2/3 produces floor quarter zero; grow it and next reading pays everybody.
	one.add_permanent(6, 5)
	other.add_permanent(6, 5)
	_end()
	assert_eq(one.perm_attack, 8)
	assert_eq(other.perm_attack, 8)


func test_lollop_copies_freeze_biggest_and_never_feed_it_guard_off_counterexample() -> void:
	kit.config.set_value("hedgerow_lollop_share", 1.0)
	kit.rules.library = ScaleOverlay.library_for(kit.library, kit.config)
	kit.library = kit.rules.library
	var carry: RecruitUnit = kit.put("field_vole", 0)
	carry.add_permanent(8, 7)
	kit.put("squire_lollop", 4)
	kit.put("squire_lollop", 1)
	kit.rules.board_changed(kit.player)
	Pass3Hedgerow.start_turn(kit.rules, kit.player)
	assert_eq(Vector2i(carry.attack, carry.health), Vector2i(10, 10))
	kit.config.set_value("pass3_loop_guards", false)
	kit.rules.board_changed(kit.player)
	Pass3Hedgerow.start_turn(kit.rules, kit.player)
	assert_gt(carry.attack, 10, "unfixed re-reading feeds last night's biggest")


func test_mast_caps_each_source_and_caps_off_counterexample() -> void:
	kit.put("old_mother_mast", 4)
	for _held: int in 2:
		kit.rules.give_card(kit.player, "great_hoard")
	kit.rules.events.fire(kit.player, "start_of_turn")
	assert_eq(kit.player.larder(), 39, "5 acorns combine into5+1+1 gold")
	kit.config.set_value("card_rate_limits", false)
	kit.player.card_rate_limits = false
	kit.rules.events.fire(kit.player, "start_of_turn")
	assert_gt(kit.player.larder(), 46, "uncapped payout reads7 instead of5")


func test_wake_view_pips_cycle_and_reset_on_move() -> void:
	var dozey: RecruitUnit = kit.put("alderman_dozey", 6)
	_end()
	assert_eq(dozey.view()["turns_in_slot"], 1)
	_end()
	_end()
	assert_eq(dozey.view()["turns_in_slot"], 0)
	assert_eq(dozey.view()["turns_goal"], 3)


func test_hayward_frozen_shop_preview_precedes_observer_and_excludes_shy_and_other_tribes() -> void:
	kit.card("hedge_shy_offer", [{"id": "shy", "gold": 2}], ["Hedgerow folk"], 5, 7)
	var offer: RecruitUnit = kit.shop("mr_crumb")
	var shy: RecruitUnit = kit.shop("hedge_shy_offer")
	var other: RecruitUnit = kit.shop("pill_bug")
	kit.player.tribe_bonuses["Hedgerow folk"] = 3
	kit.player.hedgerow_bonus = 21
	kit.player.frozen = true
	kit.rules.board_changed(kit.player)
	assert_eq(Vector2i(offer.tribe_attack, offer.tribe_health), Vector2i(24, 24))
	assert_eq(Vector2i(shy.tribe_attack, shy.tribe_health), Vector2i.ZERO)
	assert_eq(Vector2i(other.tribe_attack, other.tribe_health), Vector2i.ZERO)
	assert_eq(Vector2i(offer.perm_attack, offer.perm_health), Vector2i.ZERO)
	var observed: Array[Vector2i] = []
	kit.rules.shop_observer = func(_player: PlayerState) -> void:
		observed.append(Vector2i(offer.tribe_attack, offer.tribe_health))
	kit.player.hedgerow_bonus = 42
	kit.rules.observe_shop(kit.player)
	assert_eq(observed, [Vector2i(45, 45)], "observer sees current frozen-offer standing stats")
