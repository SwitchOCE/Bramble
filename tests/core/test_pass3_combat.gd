extends GutTest
## Real cards plus explicit guard-off counterexamples and frozen c74c2b9 combat logs.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup()
	kit.config.set_value("pass3_content", true)
	kit.config.set_value("pass3_loop_guards", true)


func _fight(mine: Dictionary, theirs: Dictionary, seed_value: int = 1) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	return combat


func _ring(combat: Combat, side: int, slot: int, count: int, size_value: float = 1.0) -> void:
	var rows: Array = combat.slot_effects[side]
	if rows.is_empty():
		for _slot: int in 7:
			rows.append([])
	var effects: Array = rows[slot]
	effects.append(
		{
			"name": "Ring",
			"count": count,
			"ring_size": size_value,
			"attack": ceili(count * size_value),
			"health": ceili(count * size_value)
		}
	)
	combat._slots_active = true


func _nest(
	combat: Combat, slot: int, attack: int, health: int, bird: String = "chiffchaff"
) -> void:
	var rules: Dictionary = combat.side_rules[0]
	var nests: Array = rules.get("nests", [])
	nests.append(
		{
			"slot": slot,
			"def_id": bird,
			"attack": attack,
			"health": health,
			"spec": {"def_id": bird, "attack": attack, "health": health}
		}
	)
	rules["nests"] = nests


func test_jack_daw_steals_both_stats_to_biggest_bird_permanently() -> void:
	var target: Dictionary = CK.u("chiffchaff", 40, 60)
	target["iid"] = 91
	var combat: Combat = _fight({0: "jack_daw", 4: target}, {0: CK.plain(11, 17)})
	combat._start_of_combat()
	assert_eq([combat.unit_at(1, 0).attack, combat.unit_at(1, 0).health], [8, 12])
	assert_eq([combat.unit_at(0, 4).attack, combat.unit_at(0, 4).health], [43, 65])
	assert_eq(combat.carry[0]["iid"], 91)
	assert_eq(combat.carry[0]["attack"], 3)
	kit.config.set_value("birds_jack_daw_share", 0.5)
	kit.config.set_value("birds_jack_daw_permanent", false)
	combat = _fight({0: "jack_daw", 4: target}, {0: CK.plain(11, 17)})
	combat._start_of_combat()
	assert_eq(combat.unit_at(0, 4).attack, 46)
	assert_true(combat.carry.is_empty())


func test_golden_jack_daw_doubles_the_share() -> void:
	var combat: Combat = _fight({0: CK.u("jack_daw", -1, -1, true)}, {0: CK.plain(11, 17)})
	combat._start_of_combat()
	assert_eq([combat.unit_at(1, 0).attack, combat.unit_at(1, 0).health], [5, 8])


func test_tom_tit_protects_biggest_other_bird_and_ends_when_source_dies() -> void:
	var combat: Combat = _fight(
		{0: "tom_tit", 1: CK.u("tom_tit", 100, 100), 4: CK.u("chiffchaff", 50, 60)},
		{0: CK.plain(1, 100)}
	)
	combat._start_of_combat()
	var carry: CombatUnit = combat.unit_at(0, 1)
	assert_true(carry.has_status("damage_reduction"))
	combat.deal_effect_damage(combat.unit_at(1, 0), carry, 10)
	assert_eq(carry.health, 95)
	combat.unit_at(0, 0).take_damage(100)
	combat._resolve_deaths(0)
	assert_false(carry.has_status("damage_reduction"), "a Tom Tit cannot protect itself")
	combat.deal_effect_damage(combat.unit_at(1, 0), carry, 10)
	assert_eq(carry.health, 85)


func test_golden_tom_tit_chooses_two_and_no_nonbird() -> void:
	var combat: Combat = _fight(
		{
			0: CK.u("tom_tit", -1, -1, true),
			1: CK.u("chiffchaff", 10, 20),
			2: CK.u("mrs_jay", 10, 20),
			4: CK.plain(100, 100)
		},
		{0: CK.plain(0, 100)}
	)
	combat._start_of_combat()
	assert_true(combat.unit_at(0, 1).has_status("damage_reduction"))
	assert_true(combat.unit_at(0, 2).has_status("damage_reduction"))
	assert_false(combat.unit_at(0, 4).has_status("damage_reduction"))


func test_mag_pye_gives_stolen_text_to_biggest_bird_before_other_text() -> void:
	var combat: Combat = _fight({0: "mag_pye", 4: CK.u("chiffchaff", 100, 100)}, {0: "great_lump"})
	combat._start_of_combat()
	assert_true(combat.unit_at(0, 4).has_mechanic("cleave"))
	assert_false(combat.unit_at(0, 0).has_mechanic("cleave"))
	assert_false(combat.unit_at(1, 0).has_mechanic("cleave"))


func test_stolen_golden_text_keeps_its_compiled_strength_on_plain_carry() -> void:
	var combat: Combat = _fight(
		{0: "mag_pye", 4: CK.u("chiffchaff", 100, 100)},
		{0: CK.u("belladonna", -1, -1, true), 4: CK.plain(1, 20), 5: CK.plain(1, 20)}
	)
	combat._start_of_combat()
	assert_true(combat.unit_at(1, 4).has_status("nightshade"))
	assert_true(combat.unit_at(1, 5).has_status("nightshade"))


func test_lump_adds_current_nest_bird_stats_and_cleave_without_moving_it() -> void:
	var combat: Combat = _fight({0: "great_lump"}, {0: CK.plain(0, 100)})
	_nest(combat, 0, 101, 203)
	combat._recalc_auras(false)
	assert_eq([combat.unit_at(0, 0).attack, combat.unit_at(0, 0).health], [106, 211])
	assert_true(combat.unit_at(0, 0).has_mechanic("cleave"))
	combat.side_rules[0]["nests"] = []
	combat._recalc_auras(false)
	assert_eq(combat.unit_at(0, 0).attack, 5)


func test_redwing_raises_only_two_biggest_eggs_and_ends_with_source() -> void:
	var combat: Combat = _fight(
		{0: "redwing", 1: "nest_egg", 2: "nest_egg", 3: "nest_egg"}, {0: CK.plain(0, 100)}
	)
	_nest(combat, 1, 3, 5)
	_nest(combat, 2, 11, 13)
	_nest(combat, 3, 21, 23)
	combat._recalc_auras(false)
	assert_eq([combat.unit_at(0, 1).attack, combat.unit_at(0, 1).health], [0, 1])
	assert_eq([combat.unit_at(0, 2).attack, combat.unit_at(0, 2).health], [6, 7])
	assert_eq([combat.unit_at(0, 3).attack, combat.unit_at(0, 3).health], [11, 12])
	combat.unit_at(0, 0).take_damage(100)
	combat._resolve_deaths(0)
	assert_eq(combat.unit_at(0, 3).attack, 0)


func test_ratchet_drops_current_bird_once_and_golden_doubles_both_stats() -> void:
	var combat: Combat = _fight(
		{0: CK.u("gabble_ratchet", -1, -1, true), 4: "nest_egg"}, {0: CK.plain(0, 100)}
	)
	_nest(combat, 4, 11, 17)
	combat.unit_at(0, 4).take_damage(1)
	combat._resolve_deaths(0)
	assert_eq([combat.unit_at(0, 4).attack, combat.unit_at(0, 4).health], [22, 34])
	combat.unit_at(0, 4).take_damage(100)
	combat._resolve_deaths(0)
	assert_null(combat.unit_at(0, 4), "drop-in is once per Nest, even if that Bird dies")
	assert_false(combat.notes.has("homecoming"))


func test_ratchet_guard_off_recreates_the_same_bird_without_end() -> void:
	kit.config.set_value("pass3_loop_guards", false)
	var combat: Combat = _fight({0: "gabble_ratchet", 4: "nest_egg"}, {0: CK.plain(0, 100)})
	_nest(combat, 4, 11, 17)
	for _time: int in 3:
		combat.unit_at(0, 4).take_damage(100)
		combat._resolve_deaths(0)
	assert_not_null(combat.unit_at(0, 4), "the counterexample needs the once-per-Nest fix")


func test_whistlers_across_round_up_and_golden_halves_twice() -> void:
	var combat: Combat = _fight(
		{0: CK.u("seven_whistlers", -1, -1, true)}, {0: CK.plain(11, 17), 4: CK.plain(100, 100)}
	)
	combat._start_of_combat()
	assert_eq([combat.unit_at(1, 0).attack, combat.unit_at(1, 0).health], [3, 5])
	assert_eq(combat.unit_at(1, 4).attack, 100)
	kit.config.set_value("birds_whistlers_loss_share", 1.0 / 3.0)
	combat = _fight({0: "seven_whistlers"}, {0: CK.plain(9, 12)})
	combat._start_of_combat()
	assert_eq([combat.unit_at(1, 0).attack, combat.unit_at(1, 0).health], [6, 8])


func test_whistlers_seven_different_home_birds_hit_every_enemy() -> void:
	var combat: Combat = _fight(
		{
			0: "seven_whistlers",
			1: "mrs_jay",
			2: "one_swallow",
			3: "chiffchaff",
			4: "mrs_dunnock",
			5: "mr_redbreast",
			6: "redwing"
		},
		{0: CK.plain(10, 20), 4: CK.plain(100, 200)}
	)
	combat._start_of_combat()
	assert_eq(combat.unit_at(1, 0).attack, 5)
	assert_eq(combat.unit_at(1, 4).attack, 50)


func test_hedge_witch_reads_its_own_slot_ring_and_floors_attack_at_zero() -> void:
	var combat: Combat = _fight({0: CK.u("hedge_witch", -1, -1, true)}, {0: CK.plain(17, 30)})
	_ring(combat, 0, 0, 7, 1.25)
	combat._recalc_auras(false)
	combat._start_of_combat()
	assert_eq(combat.unit_at(1, 0).attack, 0)


func test_fetch_copies_half_current_fairy_stats_ring_then_own_ring() -> void:
	var combat: Combat = _fight(
		{0: "cradle_fetch", 4: CK.u("hedge_witch", 10, 20)},
		{0: CK.plain(100, 100), 4: CK.plain(100, 100)}
	)
	_ring(combat, 0, 4, 30)
	_ring(combat, 0, 0, 6)
	combat._recalc_auras(false)
	combat._start_of_combat()
	var copy: CombatUnit = combat.unit_at(0, 0)
	assert_eq(copy.def_id(), "hedge_witch")
	assert_eq([copy.attack, copy.health], [26, 31])
	assert_eq(combat.unit_at(1, 0).attack, 94, "copied Witch reads Fetch's own 6-point Ring")
	assert_eq(combat.unit_at(1, 4).attack, 70)


func test_fetch_uses_biggest_fairy_behind_and_never_reuses_target() -> void:
	var combat: Combat = _fight(
		{
			0: "cradle_fetch",
			1: "cradle_fetch",
			4: CK.u("hedge_witch", 10, 20),
			5: CK.u("nan_toadstool", 30, 40)
		},
		{0: CK.plain(100, 100)}
	)
	combat._start_of_combat()
	assert_eq(combat.unit_at(0, 0).def_id(), "hedge_witch")
	assert_eq(combat.unit_at(0, 1).def_id(), "nan_toadstool")
	combat = _fight({0: "cradle_fetch", 4: CK.plain(100, 100)}, {0: CK.plain(100, 100)})
	combat._start_of_combat()
	assert_eq(combat.unit_at(0, 0).def_id(), "cradle_fetch", "non-Fairy is not eligible")


func test_golden_fetch_copies_golden_text_and_half_current_stats() -> void:
	var combat: Combat = _fight(
		{0: CK.u("cradle_fetch", -1, -1, true), 4: CK.u("hedge_witch", 20, 40)},
		{0: CK.plain(100, 100), 4: CK.plain(100, 100)}
	)
	_ring(combat, 0, 0, 6)
	combat._recalc_auras(false)
	combat._start_of_combat()
	assert_true(combat.unit_at(0, 0).golden)
	assert_eq([combat.unit_at(0, 0).attack, combat.unit_at(0, 0).health], [16, 26])
	assert_eq(combat.unit_at(1, 0).attack, 88)


func test_hob_shields_biggest_fairy_after_fetch_even_when_hob_is_first() -> void:
	var combat: Combat = _fight(
		{
			0: "hob_in_the_hearth",
			1: "cradle_fetch",
			4: CK.u("hedge_witch", 10, 10),
			6: CK.plain(1000, 1000)
		},
		{0: CK.plain(100, 100)}
	)
	_ring(combat, 0, 1, 100)
	combat._recalc_auras(false)
	combat._start_of_combat()
	assert_true(combat.unit_at(0, 1).has_status("shield"))
	assert_false(combat.unit_at(0, 6).has_status("shield"))


func test_shy_fairies_ignore_rings_in_combat() -> void:
	var combat: Combat = _fight({0: "hob_in_the_hearth"}, {0: CK.plain(100, 100)})
	_ring(combat, 0, 0, 100)
	combat._recalc_auras(false)
	assert_eq([combat.unit_at(0, 0).attack, combat.unit_at(0, 0).health], [2, 5])


func test_will_lights_each_empty_ring_with_fairy_wisp_and_configurable_body() -> void:
	kit.config.set_value("fairies_wisp_attack", 3)
	kit.config.set_value("fairies_wisp_health", 4)
	var combat: Combat = _fight({0: CK.u("will_o_the_wisp", -1, -1, true)}, {0: CK.plain(0, 100)})
	_ring(combat, 0, 4, 20)
	combat._recalc_auras(false)
	combat._start_of_combat()
	assert_eq(combat.unit_at(0, 4).def_id(), "wisp")
	assert_true(combat.unit_at(0, 4).has_tribe("Fairies"))
	assert_eq([combat.unit_at(0, 4).attack, combat.unit_at(0, 4).health], [26, 28])
	assert_null(combat.unit_at(0, 5))


func test_belladonna_across_and_golden_beside_never_unrelated_back_row() -> void:
	var combat: Combat = _fight(
		{1: CK.u("belladonna", -1, -1, true)},
		{0: CK.plain(1, 20), 1: CK.plain(1, 20), 2: CK.plain(1, 20), 4: CK.plain(1000, 1000)}
	)
	combat._start_of_combat()
	for slot: int in [0, 1, 2]:
		assert_true(combat.unit_at(1, slot).has_status("nightshade"))
	assert_false(combat.unit_at(1, 4).has_status("nightshade"))


func test_golden_changeling_returns_after_two_attacks_and_rings_stay_home() -> void:
	var combat: Combat = _fight({0: CK.u("changeling", -1, -1, true)}, {0: CK.plain(1, 100)})
	_ring(combat, 0, 0, 10)
	combat._recalc_auras(false)
	combat._start_of_combat()
	var stolen: CombatUnit = combat.unit_at(0, 0)
	assert_eq(stolen.attack, 11)
	CombatMoves.after_attacked_once(combat, stolen)
	assert_eq(stolen.side, 0)
	CombatMoves.after_attacked_once(combat, stolen)
	assert_eq(stolen.side, 1)
	assert_eq(stolen.attack, 1)
	assert_eq(combat.unit_at(0, 0).def_id(), "changeling")


func test_dance_moves_all_rings_and_stops_each_cohort_at_two_moves() -> void:
	var combat: Combat = _fight(
		{0: "reel_mistress", 1: "nan_toadstool", 2: "hedge_witch"}, {0: CK.plain(0, 1000)}
	)
	_ring(combat, 0, 0, 10)
	_ring(combat, 0, 1, 5)
	combat._recalc_auras(false)
	CombatMoves.dance_rings(combat, combat.unit_at(0, 0))
	assert_eq(BoardUpkeep.ring_value(combat._slot_effects_at(0, 0)), Vector2i.ZERO)
	assert_eq(BoardUpkeep.ring_value(combat._slot_effects_at(0, 1)), Vector2i(15, 15))
	CombatMoves.dance_rings(combat, combat.unit_at(0, 1))
	assert_eq(BoardUpkeep.ring_value(combat._slot_effects_at(0, 2)), Vector2i(15, 15))
	CombatMoves.dance_rings(combat, combat.unit_at(0, 2))
	assert_eq(
		BoardUpkeep.ring_value(combat._slot_effects_at(0, 2)),
		Vector2i(10, 10),
		"exhausted incoming Rings stay"
	)
	assert_eq(
		BoardUpkeep.ring_value(combat._slot_effects_at(0, 0)),
		Vector2i(5, 5),
		"younger cohort moves once more"
	)


func test_dance_guard_off_reuses_an_exhausted_ring_every_attack() -> void:
	kit.config.set_value("pass3_loop_guards", false)
	var combat: Combat = _fight({0: "reel_mistress", 1: "nan_toadstool"}, {0: CK.plain(0, 1000)})
	_ring(combat, 0, 0, 10)
	for turn_value: int in 6:
		CombatMoves.dance_rings(combat, combat.unit_at(0, turn_value % 2))
	assert_eq(
		combat._slot_effects_at(0, 0)[0]["moves"], 6, "counterexample exceeds the two-move guard"
	)


func test_golden_dance_and_fractional_size_keep_slot_rounding_exact() -> void:
	var combat: Combat = _fight(
		{0: CK.u("reel_mistress", -1, -1, true), 1: "nan_toadstool"}, {0: CK.plain(0, 1000)}
	)
	_ring(combat, 0, 0, 1, 1.25)
	_ring(combat, 0, 1, 1, 1.25)
	for turn_value: int in 4:
		CombatMoves.dance_rings(combat, combat.unit_at(0, turn_value % 2))
	assert_eq(
		BoardUpkeep.ring_value(combat._slot_effects_at(0, 0)),
		Vector2i(3, 3),
		"ceil(2*1.25), never ceil(1.25)+ceil(1.25)"
	)
	CombatMoves.dance_rings(combat, combat.unit_at(0, 0))
	assert_eq(BoardUpkeep.ring_value(combat._slot_effects_at(0, 0)), Vector2i(2, 2))


func _answer() -> void:
	kit.card(
		"biggest_answer",
		[
			KIT.effect(
				"start_of_combat",
				{
					"effect": "stat_fraction",
					"operation": "reduce",
					"numerator": 1,
					"denominator": 2,
					"target": {"select": "enemies", "pick": "biggest"}
				}
			)
		]
	)


func test_biggest_enemy_effects_wait_for_both_sides_other_start_effects() -> void:
	_answer()
	for seed_value: int in 12:
		var combat: Combat = _fight(
			{0: "biggest_answer"}, {0: "granny_stir_up", 4: CK.u("moss_ooze", 100, 10)}, seed_value
		)
		combat._start_of_combat()
		assert_eq(
			combat.unit_at(1, 0).attack, 52, "gather precedes answer for seed %d" % seed_value
		)


func test_diagnostic_old_order_exposes_pre_gather_counterexample() -> void:
	_answer()
	var found: bool = false
	for seed_value: int in 12:
		var combat: Combat = _fight(
			{0: "biggest_answer"}, {0: "granny_stir_up", 4: CK.u("moss_ooze", 100, 10)}, seed_value
		)
		combat.notes["test_pass3_start_order"] = false
		combat._start_of_combat()
		found = found or combat.unit_at(1, 0).attack != 52
	assert_true(found, "old order has a same-seed early-answer counterexample")


func test_biggest_enemy_effect_sees_stored_belly_and_loss_survives_release() -> void:
	_answer()
	var holder: Dictionary = CK.u("hasty_pudding", 1, 100)
	holder["held"] = [CK.u("field_vole", 1000, 2000)]
	var combat: Combat = _fight({4: "biggest_answer"}, {0: holder})
	combat._start_of_combat()
	var host: CombatUnit = combat.unit_at(1, 0)
	var fighter: CombatUnit = CombatHeld.pop_one(combat, host, false)
	assert_eq([fighter.attack, fighter.health], [500, 1000])
	var input_held: Array = holder["held"]
	var input_spec: Dictionary = input_held[0]
	assert_false(input_spec.has("_pass3_fighter"), "input/recruit snapshot remains immutable")


func test_biggest_ties_use_reading_order_without_effect_random_draw() -> void:
	_answer()
	var combat: Combat = _fight({0: "biggest_answer"}, {0: CK.plain(10, 20), 4: CK.plain(10, 20)})
	var before: int = combat.effect_rng.state
	combat._start_of_combat()
	assert_eq(combat.unit_at(1, 0).attack, 5)
	assert_eq(combat.unit_at(1, 4).attack, 10)
	assert_eq(combat.effect_rng.state, before)


func test_diagnostic_old_order_exactly_replays_c74c2b9_other_tribes_and_neutrals() -> void:
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass3_legacy_replay.json")
	)
	var rows: Array = fixture["cases"]
	assert_eq(rows.size(), 12)
	for entry: Dictionary in rows:
		var config := GameConfig.defaults()
		var rng := RandomNumberGenerator.new()
		rng.seed = CoreUtil.to_int(entry["seed"])
		var combat := Combat.create(kit.library, config, rng)
		combat.notes["test_pass3_start_order"] = false
		combat.side_rules = entry["side_rules"]
		var result: Dictionary = combat.run(entry["boards"], [5, 5], [0, 1], 0)
		assert_true(
			JSON.stringify(result) == str(entry["result"]), "exact replay seed %d" % entry["seed"]
		)


func test_fetch_silence_and_granted_text_survive_copy() -> void:
	var combat: Combat = _fight({0: "cradle_fetch", 4: "hedge_witch"}, {0: CK.plain(100, 100)})
	combat.unit_at(0, 4).lend_text_to(combat.unit_at(1, 0))
	combat.unit_at(0, 4).add_grant({"entry": {"id": "cleave"}, "golden": false})
	combat._start_of_combat()
	var copy: CombatUnit = combat.unit_at(0, 0)
	assert_true(copy.has_mechanic("cleave"))
	var has_witch: bool = false
	for index: int in copy.params.size():
		has_witch = has_witch or Pass3FairyCombat.ability(copy, index) == "witch"
	assert_false(has_witch, "the copied Fairy remains silenced instead of restoring printed text")


func test_fetch_no_reuse_guard_off_copies_the_same_carry_twice() -> void:
	var mine: Dictionary = {0: "cradle_fetch", 1: "cradle_fetch", 4: CK.u("hedge_witch", 100, 100)}
	var combat: Combat = _fight(mine, {0: CK.plain(100, 100)})
	combat._start_of_combat()
	assert_eq(combat.unit_at(0, 1).def_id(), "cradle_fetch")
	kit.config.set_value("pass3_loop_guards", false)
	combat = _fight(mine, {0: CK.plain(100, 100)})
	combat._start_of_combat()
	assert_eq(
		combat.unit_at(0, 1).def_id(), "hedge_witch", "the no-reuse guard prevents this extra carry"
	)


func test_shy_ignores_rings_even_with_test_order_override_off() -> void:
	var combat: Combat = _fight({0: "hob_in_the_hearth"}, {0: CK.plain(100, 100)})
	combat.notes["test_pass3_start_order"] = false
	_ring(combat, 0, 0, 100)
	combat._recalc_auras(false)
	assert_eq([combat.unit_at(0, 0).attack, combat.unit_at(0, 0).health], [2, 5])


func test_biggest_enemy_hero_effect_waits_for_both_sides_units() -> void:
	for seed_value: int in 6:
		var combat: Combat = _fight(
			{0: CK.plain(1, 100)}, {0: "granny_stir_up", 4: CK.u("moss_ooze", 100, 10)}, seed_value
		)
		combat.hero_effects[0] = [
			KIT.effect(
				"start_of_combat",
				{
					"effect": "stat_fraction",
					"operation": "reduce",
					"numerator": 1,
					"denominator": 2,
					"target": {"select": "enemies", "pick": "biggest"}
				}
			)
		]
		combat._start_of_combat()
		assert_eq(combat.unit_at(1, 0).attack, 52)


func test_whistlers_duplicates_and_away_birds_do_not_complete_flock() -> void:
	var combat: Combat = _fight(
		{
			0: "seven_whistlers",
			1: "chiffchaff",
			2: "chiffchaff",
			3: "mrs_jay",
			4: "one_swallow",
			5: "redwing",
			6: "mrs_dunnock"
		},
		{0: CK.plain(10, 20), 4: CK.plain(100, 200)}
	)
	combat.side_rules[0] = {"away_birds": ["mother_goose", "old_tern"]}
	combat._start_of_combat()
	assert_eq(combat.unit_at(1, 0).attack, 5)
	assert_eq(combat.unit_at(1, 4).attack, 100)


func test_redwing_away_without_nest_still_uses_one_of_the_biggest_places() -> void:
	var combat: Combat = _fight({0: "redwing", 1: "nest_egg", 2: "nest_egg"}, {0: CK.plain(0, 100)})
	_nest(combat, 1, 10, 20)
	_nest(combat, 2, 30, 40)
	combat.side_rules[0]["away_specs"] = [
		{"slot": -1, "attack": 100, "health": 100},
		{"slot": 2, "attack": 30, "health": 40},
		{"slot": 1, "attack": 10, "health": 20}
	]
	combat._recalc_auras(false)
	assert_eq(combat.unit_at(0, 1).attack, 0)
	assert_eq(combat.unit_at(0, 2).attack, 15)


func test_two_ratchets_share_one_nest_drop_guard() -> void:
	var combat: Combat = _fight(
		{0: "gabble_ratchet", 1: CK.u("gabble_ratchet", -1, -1, true), 4: "nest_egg"},
		{0: CK.plain(0, 100)}
	)
	_nest(combat, 4, 11, 17)
	combat.unit_at(0, 4).take_damage(1)
	combat._resolve_deaths(0)
	assert_eq(combat.unit_at(0, 4).attack, 11, "first Ratchet in reading order lands the Bird once")
	assert_eq(combat._next_uid, 6, "one summon despite two listeners")


func test_dance_copies_slot_state_and_multiple_mistresses_share_ring_limit() -> void:
	var combat: Combat = _fight({0: "reel_mistress", 1: "reel_mistress"}, {0: CK.plain(0, 1000)})
	_ring(combat, 0, 0, 10)
	var original: Array = combat.slot_effects[0]
	for step: int in 4:
		CombatMoves.dance_rings(combat, combat.unit_at(0, step % 2))
	assert_eq(BoardUpkeep.ring_value(combat._slot_effects_at(0, 0)), Vector2i(10, 10))
	assert_eq(combat._slot_effects_at(0, 0)[0]["moves"], 2)
	assert_eq(BoardUpkeep.ring_value(original[0]), Vector2i(10, 10))
	var original_effects: Array = original[0]
	var original_ring: Dictionary = original_effects[0]
	assert_false(original_ring.has("moves"), "recruit Ring never acquires a combat move budget")


func test_golden_mag_pye_reaches_occupied_front_back_neighbour() -> void:
	var combat: Combat = _fight(
		{0: CK.u("mag_pye", -1, -1, true), 4: CK.u("chiffchaff", 100, 100)},
		{0: "great_lump", 4: "hob_in_the_hearth"}
	)
	combat._start_of_combat()
	assert_true(combat.unit_at(0, 4).has_mechanic("cleave"))
	assert_false(
		combat.unit_at(1, 4).has_mechanic("shy"),
		"next to includes behind, even with no enemy beside"
	)
	assert_true(combat.unit_at(0, 4).has_mechanic("shy"))


func test_biggest_enemy_sees_midfight_prisoner_with_its_current_stats() -> void:
	_answer()
	var combat: Combat = _fight(
		{0: "biggest_answer"}, {0: "granny_stir_up", 4: CK.u("moss_ooze", 100, 3000)}
	)
	combat._start_of_combat()
	var holder: CombatUnit = combat.unit_at(1, 0)
	assert_eq(holder.attack, 104, "one-time gather stays on Granny")
	assert_eq([holder.inside[0].attack, holder.inside[0].health], [50, 1500])
	CombatHeld.return_inside(combat, holder)
	assert_eq([combat.unit_at(1, 4).attack, combat.unit_at(1, 4).health], [50, 1500])


func test_biggest_enemy_never_targets_own_prisoner_in_enemy_belly() -> void:
	_answer()
	var combat: Combat = _fight(
		{0: CK.plain(1000, 1000), 4: "biggest_answer"}, {0: "hasty_pudding"}
	)
	combat._start_of_combat()
	var holder: CombatUnit = combat.unit_at(1, 0)
	assert_eq([holder.attack, holder.health], [1, 4])
	assert_eq([holder.inside[0].attack, holder.inside[0].health], [1000, 1000])


func test_selected_pass3_pool_enables_order_even_when_no_new_card_is_in_fight() -> void:
	kit.config.set_value("pass3_content", false)
	kit.config.set_value("pool_filter", GameConfig.SLICE)
	var combat: Combat = _fight({0: CK.plain(1, 10)}, {0: CK.plain(1, 10)})
	assert_true(Pass3Combat.enabled(combat))
	assert_null(kit.config.get_value("pass3_start_order"), "not a supported game setting")
	kit.config.set_value("pass3_start_order", false)
	assert_true(Pass3Combat.enabled(combat), "game config cannot turn off the content rule")
	combat.notes["test_pass3_start_order"] = false
	assert_false(Pass3Combat.enabled(combat), "isolated replay tests can request the old path")


func test_dead_hunter_still_gets_permanent_take_reward_with_pass3_enabled() -> void:
	var nip: Dictionary = CK.u("little_nip", 3, 1)
	nip["iid"] = 91
	var combat: Combat = _fight({0: nip}, {0: CK.plain(2, 1)})
	combat._start_of_combat()
	combat._perform_attack(combat.unit_at(0, 0), combat.unit_at(1, 0))
	assert_null(combat.unit_at(0, 0))
	var paid: bool = false
	for change: Dictionary in combat.carry:
		paid = (
			paid
			or (
				str(change.get("op", "")) == "buff"
				and CoreUtil.to_int(change.get("iid", 0)) == 91
				and CoreUtil.to_int(change.get("attack", 0)) == 1
			)
		)
	assert_true(
		paid, "a dying Take witness is not a hidden Belly target and retains its permanent gain"
	)


func test_fetch_copying_fetch_guard_off_recurses_until_combat_trigger_guard() -> void:
	var mine: Dictionary = {0: "cradle_fetch", 4: "cradle_fetch"}
	var combat: Combat = _fight(mine, {0: CK.plain(0, 100)})
	combat._start_of_combat()
	assert_eq(combat.unit_at(0, 0).def_id(), "cradle_fetch")
	assert_eq(combat._triggers, 0, "a Fetch cannot copy another Fetch")
	assert_false(combat._halted)
	kit.config.set_value("pass3_loop_guards", false)
	kit.config.set_value("trigger_limit_combat", 20)
	combat = _fight(mine, {0: CK.plain(0, 100)})
	combat._start_of_combat()
	assert_true(
		combat._halted, "without the Fetch exclusion, copies recurse to the global trigger guard"
	)
	assert_eq(combat._triggers, 21, "the small diagnostic trigger limit bounds this counterexample")
