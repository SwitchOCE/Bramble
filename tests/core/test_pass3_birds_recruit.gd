extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT


func before_each() -> void:
	_kit = KIT.new()
	var config: GameConfig = GameConfig.full_game()
	_kit.setup(config)
	_kit.rules.start_phase(_kit.player, 1)


func _fly(id: String = "chiffchaff", slot: int = 0, golden: bool = false) -> RecruitUnit:
	var bird: RecruitUnit = _kit.put(id, slot, golden)
	bird.played_round = 0
	assert_eq(_kit.rules.sell(_kit.player, slot), "")
	return bird


func test_swallow_fast_trip_doubles_and_replay_pays_gold() -> void:
	var bird: RecruitUnit = _fly("one_swallow")
	assert_eq(_kit.player.away[0]["due"], 2)
	assert_eq(_kit.player.gold, 3, "Flight pays no sale gold")
	_kit.pass_turn()
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(2, 4))
	var gold: int = _kit.player.gold
	assert_eq(_kit.rules.play(_kit.player, _kit.player.hand.find(bird), 0), "")
	assert_eq(_kit.player.gold, gold + 1)


func test_chiffchaff_permanent_play_buff_compounds_and_supper_does_not() -> void:
	var bird: RecruitUnit = _kit.play("chiffchaff", 0)
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(2, 3))
	_kit.pass_turn()
	TribeBonus.grant(_kit.player, bird, 3)
	_kit.rules.board_changed(_kit.player)
	assert_eq(_kit.rules.sell(_kit.player, 0), "")
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(Vector2i(bird.perm_attack, bird.perm_health), Vector2i(3, 4))
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(7, 9))


func test_golden_bird_homecoming_multiplier_is_two_not_four() -> void:
	var bird: RecruitUnit = _fly("chiffchaff", 0, true)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(4, 8))


func test_mrs_jay_flight_gives_acorn_without_sale_gold() -> void:
	_fly("mrs_jay")
	assert_eq(_kit.item_ids(), ["acorn"])
	assert_eq(_kit.player.gold, 3)


func test_dunnock_shortens_biggest_trip_not_her_own_nest() -> void:
	_kit.put("mrs_dunnock", 6)
	var small: RecruitUnit = _fly("chiffchaff", 0)
	var big: RecruitUnit = _fly("mrs_jay", 1)
	big.add_permanent(10, 10)
	_kit.pass_turn()
	assert_true(_kit.player.hand.has(big))
	assert_false(_kit.player.hand.has(small))
	assert_eq(big.attack, 26)


func test_redbreast_share_uses_landed_body_rounding_up() -> void:
	var robin: RecruitUnit = _kit.put("mr_redbreast", 6)
	_fly("mrs_jay")
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(Vector2i(robin.perm_attack, robin.perm_health), Vector2i(1, 1))


func test_cuckoos_each_share_with_birds_in_play_including_themselves() -> void:
	var cuckoo: RecruitUnit = _kit.put("cuckoo", 5)
	var second: RecruitUnit = _kit.put("cuckoo", 6)
	var nonbird: RecruitUnit = _kit.put("field_vole", 4)
	_fly("mrs_jay")
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(cuckoo.perm_attack, 2)
	assert_eq(second.perm_health, 2)
	assert_eq(nonbird.perm_attack, 0)


func test_stork_counter_carries_and_calls_longest_then_biggest_eligible() -> void:
	var stork: RecruitUnit = _kit.put("mrs_stork", 6)
	var small: RecruitUnit = _fly("chiffchaff", 0)
	var big: RecruitUnit = _fly("mrs_jay", 1)
	big.add_permanent(20, 20)
	_kit.rules.spend(_kit.player, 4)
	_kit.rules.end_phase(_kit.player)
	_kit.rules.after_fights(_kit.player)
	_kit.rules.start_phase(_kit.player, 2)
	assert_eq(stork.counters.get("stork"), 4)
	_kit.rules.spend(_kit.player, 2)
	assert_true(_kit.player.hand.has(big))
	assert_false(_kit.player.hand.has(small))
	assert_eq(stork.counters.get("stork"), 0)


func test_tern_homecoming_calls_only_birds_that_missed_a_fight() -> void:
	var tern: RecruitUnit = _fly("old_tern", 0, true)
	var earlier: RecruitUnit = _fly("mrs_jay", 1)
	_kit.pass_turn()
	assert_true(_kit.player.hand.has(tern))
	assert_true(_kit.player.hand.has(earlier))
	var fresh: RecruitUnit = _fly("chiffchaff", 2)
	HeldUnits.land_flock(_kit.rules, _kit.player)
	assert_false(_kit.player.hand.has(fresh))


func test_homecoming_full_hand_waits_on_doorstep_and_doubles_once() -> void:
	var bird: RecruitUnit = _fly("one_swallow")
	for _index: int in 10:
		_kit.put("field_vole", -1, true)
	_kit.pass_turn()
	assert_true(_kit.player.doorstep.has(bird))
	assert_eq(bird.attack, 2)
	assert_eq(_kit.rules.play(_kit.player, 0, 0), "")
	assert_true(_kit.player.hand.has(bird))
	assert_eq(bird.attack, 2)


func test_goose_gets_golden_eggs_on_play_not_on_drop_in() -> void:
	_kit.play("mother_goose", 0, true)
	assert_eq(_kit.item_ids(), ["golden_egg", "golden_egg"])


func test_golden_egg_multiplies_permanent_body_only_and_triple_keeps_mark() -> void:
	var bird: RecruitUnit = _kit.put("chiffchaff", 0)
	bird.add_permanent(4, 5)
	bird.set_aura(20, 20)
	assert_eq(_kit.cast("golden_egg", 0), "")
	assert_eq(Vector2i(bird.perm_attack, bird.perm_health), Vector2i(9, 12))
	assert_ne(_kit.cast("golden_egg", 0), "")
	_kit.put("chiffchaff")
	_kit.put("chiffchaff")
	_kit.rules.check_triples(_kit.player)
	assert_true(_kit.player.hand[0].golden)
	assert_true(CoreUtil.to_bool(_kit.player.hand[0].counters.get("egged", false)))


func test_golden_egg_rejects_nonbirds_and_guard_survives_rate_overlay() -> void:
	_kit.put("field_vole", 0)
	assert_ne(_kit.cast("golden_egg", 0), "")
	var bird: RecruitUnit = _kit.put("mrs_jay", 1)
	_kit.player.card_rate_limits = false
	assert_eq(_kit.cast("golden_egg", 1), "")
	assert_ne(_kit.cast("golden_egg", 1), "")
	assert_eq(bird.attack, 6)


func test_data_dials_change_growth_shares_trip_and_stork_without_code() -> void:
	_kit.config.set_value("birds_homecoming_multiplier", 1.75)
	_kit.config.set_value("birds_swallow_trip_turns", 2)
	_kit.config.set_value("birds_redbreast_share", 0.5)
	var robin: RecruitUnit = _kit.put("mr_redbreast", 6)
	var bird: RecruitUnit = _fly("one_swallow")
	assert_eq(_kit.player.away[0]["due"], 3)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(2, 4))
	assert_eq(Vector2i(robin.perm_attack, robin.perm_health), Vector2i(1, 2))


func test_guard_newly_played_bird_cannot_fly_counterfactual_can() -> void:
	var bird: RecruitUnit = _kit.play("one_swallow", 0)
	assert_false(HeldUnits.flies(bird, _kit.player))
	_kit.player.pass3_loop_guards = false
	assert_true(
		HeldUnits.flies(bird, _kit.player), "Without guard a replay can fly again immediately"
	)


func test_guard_early_recall_requires_real_missed_fight_counterfactual_doubles() -> void:
	var bird: RecruitUnit = _fly("mrs_jay")
	HeldUnits.bring_home(_kit.rules, _kit.player, 1)
	assert_true(_kit.player.hand.is_empty())
	_kit.player.pass3_loop_guards = false
	HeldUnits.bring_home(_kit.rules, _kit.player, 1)
	assert_true(_kit.player.hand.has(bird))
	assert_eq(bird.attack, 6, "Without guard fresh flights earn an immediate doubling")


func test_guard_homecoming_extra_trigger_cannot_double_again_counterfactual_does() -> void:
	var bird: RecruitUnit = _kit.put("mrs_jay", 0)
	Pass3Birds.homecoming(_kit.rules, _kit.player, bird)
	Pass3Birds.homecoming(_kit.rules, _kit.player, bird)
	assert_eq(bird.attack, 6)
	_kit.player.pass3_loop_guards = false
	Pass3Birds.homecoming(_kit.rules, _kit.player, bird)
	assert_eq(bird.attack, 12, "Without once-per-homecoming guard the same event doubles again")


func test_guard_golden_egg_counterfactual_second_egg_doubles_again() -> void:
	var bird: RecruitUnit = _kit.put("mrs_jay", 0)
	assert_eq(_kit.cast("golden_egg", 0), "")
	assert_ne(_kit.cast("golden_egg", 0), "")
	_kit.player.pass3_loop_guards = false
	assert_eq(_kit.rules.play_item(_kit.player, 0, 0), "")
	assert_eq(bird.attack, 12)


func test_guard_extra_end_turn_cannot_move_dunnock_countdown_counterfactual_does() -> void:
	_kit.put("mrs_dunnock", 6)
	_fly("mrs_jay")
	_kit.player.away[0]["due"] = 7
	_kit.card("test_doubler", [{"id": "end_turn_doubler"}])
	_kit.put("test_doubler", 5)
	_kit.rules.end_phase(_kit.player)
	assert_eq(_kit.player.away[0]["due"], 6)
	_kit.config.set_value("pass3_loop_guards", false)
	_kit.rules.end_phase(_kit.player)
	assert_eq(_kit.player.away[0]["due"], 4)


func test_guard_any_data_doubler_cannot_repeat_multiplier_counterfactual_does() -> void:
	_kit.card(
		"test_double",
		[
			KIT.effect(
				"end_of_turn", {"effect": "multiply", "factor": 2, "target": {"select": "self"}}
			)
		]
	)
	_kit.card("test_extra", [{"id": "end_turn_doubler"}])
	var unit: RecruitUnit = _kit.put("test_double", 0)
	_kit.put("test_extra", 1)
	_kit.rules.end_phase(_kit.player)
	assert_eq(unit.attack, 2, "Extra trigger cannot double the body again")
	_kit.config.set_value("pass3_loop_guards", false)
	_kit.rules.end_phase(_kit.player)
	assert_eq(unit.attack, 8, "Without guard both firings double")


func test_guard_any_data_doubler_cannot_advance_counter_counterfactual_does() -> void:
	_kit.card(
		"test_clock",
		[
			KIT.effect(
				"end_of_turn",
				{"effect": "buff", "attack": 1, "health": 1, "target": {"select": "self"}},
				{"every": 3, "counter": "clock"}
			)
		]
	)
	_kit.card("test_extra", [{"id": "end_turn_doubler"}])
	var unit: RecruitUnit = _kit.put("test_clock", 0)
	_kit.put("test_extra", 1)
	_kit.rules.end_phase(_kit.player)
	assert_eq(unit.counters.get("clock"), 1)
	_kit.config.set_value("pass3_loop_guards", false)
	_kit.rules.end_phase(_kit.player)
	assert_eq(unit.counters.get("clock"), 0)
	assert_eq(unit.attack, 2, "Without guard a second end-turn already reaches the third tick")


func test_early_recall_distinguishes_an_older_departure_from_a_missed_fight() -> void:
	var bird: RecruitUnit = _fly("mrs_jay")
	# Recruit-only round advancement has no after_fights notification. The old
	# left-before-this-round predicate is true, but this Bird has not missed a real fight.
	_kit.player.round_number += 1
	var entry: Dictionary = _kit.player.away[0]
	assert_lt(CoreUtil.to_int(entry["left"]), _kit.player.round_number)
	assert_false(CoreUtil.to_bool(entry["missed_fight"]))
	HeldUnits.bring_home(_kit.rules, _kit.player, 1)
	assert_true(_kit.player.away.has(entry), "an older departure alone cannot earn a recall")
	assert_false(_kit.player.hand.has(bird))
	assert_eq(bird.attack, 3, "no homecoming doubling before a missed fight")
	Pass3Birds.missed_fight(_kit.player)
	HeldUnits.bring_home(_kit.rules, _kit.player, 1)
	assert_true(_kit.player.hand.has(bird), "the actual fight flag now permits that same recall")
	assert_eq(bird.attack, 6)
