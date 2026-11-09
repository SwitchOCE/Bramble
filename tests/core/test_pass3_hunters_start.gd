# gdlint:disable=max-public-methods
extends GutTest
## Frozen bell identities coexist with late biggest picks and the final deterministic Jack step.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())


func _fight(
	mine: Dictionary, theirs: Dictionary, seed_value: int = 1, start: bool = true
) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat._recalc_auras(false)
	Pass3BogCombat.prepare(combat)
	if start:
		combat._start_of_combat()
	return combat


func _answer() -> void:
	kit.card(
		"hunter_late_answer",
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


func _bird(slot_iid: int, attack: int) -> Dictionary:
	var spec: Dictionary = CK.u("chiffchaff", attack, attack)
	spec["iid"] = slot_iid
	return spec


func test_sable_mirrors_read_the_same_pre_strike_bell_snapshots_for_every_seed() -> void:
	for seed_value: int in 12:
		var combat: Combat = _fight(
			{0: CK.u("sable", 2, 100)}, {0: CK.u("sable", 5, 100)}, seed_value
		)
		assert_eq([combat.unit_at(0, 0).attack, combat.unit_at(1, 0).attack], [7, 7])
		var prey: Dictionary = Pass3HunterCombat.prey(combat, combat.unit_at(1, 0))
		assert_eq(prey["attack"], 5)


func test_golden_sable_adds_twice_the_quarrys_frozen_attack() -> void:
	var combat: Combat = _fight({0: CK.u("sable", 4, 100, true)}, {0: CK.plain(9, 12)})
	assert_eq(combat.unit_at(0, 0).attack, 22)


func test_sable_with_empty_across_gets_the_strike_after_a_brock_or_isegrim_loan() -> void:
	for lender: String in ["old_brock", "old_isegrim"]:
		var slot: int = 4 if lender == "old_brock" else 1
		var prey_slot: int = 4 if lender == "old_brock" else 6
		var combat: Combat = _fight(
			{0: CK.u("sable", 2, 100), slot: lender}, {prey_slot: CK.plain(9, 12)}
		)
		var sable: CombatUnit = combat.unit_at(0, 0)
		assert_eq(sable.quarry, combat.unit_at(1, prey_slot).uid)
		assert_eq(sable.attack, 11)


func test_printed_and_borrowed_sable_use_strongest_strike_once_with_guard_off_counterexample(
) -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var spec: Dictionary = CK.u("sable", 2, 100)
		spec["grants"] = [
			{"entry": {"id": "pass3_hunter", "ability": "sable", "factor": 1}, "golden": true}
		]
		var combat: Combat = _fight({0: spec}, {0: CK.plain(9, 12)})
		assert_eq(combat.unit_at(0, 0).attack, 20 if guarded else 38)


func test_syllabub_dispatches_repeat_sable_addition_without_repeating_borrowed_ability() -> void:
	var spec: Dictionary = CK.u("sable", 2, 100)
	spec["grants"] = [
		{"entry": {"id": "pass3_hunter", "ability": "sable", "factor": 1}, "golden": true}
	]
	var combat: Combat = _fight(
		{0: spec, 4: CK.u("mr_syllabub", -1, -1, true)}, {0: CK.plain(9, 12)}
	)
	var sable: CombatUnit = combat.unit_at(0, 0)
	assert_eq(sable.attack, 20)
	CombatHeld._syllabub(combat, sable)
	assert_eq(sable.attack, 56, "two distinct replays each add the strongest frozen 18 once")


func test_brock_loan_and_reach_persist_after_brock_faints() -> void:
	var combat: Combat = _fight(
		{0: "mountain_glutton", 4: "old_brock"}, {0: CK.plain(1, 100), 4: CK.plain(9, 12)}
	)
	var hunter: CombatUnit = combat.unit_at(0, 0)
	var quarry: CombatUnit = combat.unit_at(1, 4)
	combat.deal_effect_damage(null, combat.unit_at(0, 4), 10000)
	combat._resolve_deaths(0)
	assert_eq(hunter.quarry, quarry.uid)
	assert_true(hunter.quarry_reach)
	assert_eq(CombatLanes.choose_target(combat, hunter), quarry)


func test_across_quarry_identity_is_fixed_before_jennys_movement() -> void:
	var combat: Combat = _fight(
		{0: "little_nip", 1: "jenny_greenteeth"}, {0: CK.plain(90, 100), 1: CK.plain(1, 3)}
	)
	var quarry: CombatUnit = combat.unit_at(1, 1)
	assert_eq(quarry.attack, 90)
	assert_eq(combat.unit_at(0, 0).quarry, quarry.uid)


func test_isegrim_own_hunt_beats_loans_and_lenders_compete_in_reading_order() -> void:
	var combat: Combat = _fight(
		{0: "old_isegrim", 1: "old_brock", 2: "mountain_glutton"},
		{0: CK.plain(1, 3), 1: CK.plain(9, 12), 6: CK.plain(90, 100)}
	)
	var big: CombatUnit = combat.unit_at(1, 6)
	assert_eq(combat.unit_at(0, 0).quarry, big.uid)
	assert_eq(combat.unit_at(0, 1).quarry, big.uid)
	assert_eq(
		combat.unit_at(0, 2).quarry,
		combat.unit_at(1, 1).uid,
		"Brock lends his across, not his newly borrowed quarry"
	)
	assert_true(combat.unit_at(0, 2).quarry_reach)


func test_lenders_hunt_only_hunters_and_golden_isegrim_reaches_neighbours() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{
				0: CK.u("old_isegrim", -1, -1, golden),
				1: "mountain_glutton",
				4: "lodger",
				5: "chiffchaff"
			},
			{6: CK.plain(90, 100)}
		)
		var big: CombatUnit = combat.unit_at(1, 6)
		assert_eq(combat.unit_at(0, 1).quarry, big.uid)
		assert_eq(combat.unit_at(0, 4).quarry, big.uid if golden else 0)
		assert_eq(combat.unit_at(0, 5).quarry, 0)
	var other: Combat = _fight(
		{0: "old_brock", 1: "chiffchaff", 4: "mountain_glutton"}, {0: CK.plain(9, 12)}
	)
	assert_eq(other.unit_at(0, 1).quarry, 0)
	assert_eq(other.unit_at(0, 4).quarry, other.unit_at(1, 0).uid)


func test_isegrim_sees_ordinary_gathered_stats_and_respects_across_own_quarry() -> void:
	var combat: Combat = _fight(
		{0: "old_isegrim", 1: "little_nip"},
		{0: "granny_stir_up", 1: CK.plain(20, 20), 4: CK.u("moss_ooze", 90, 100)}
	)
	assert_eq(combat.unit_at(0, 0).quarry, combat.unit_at(1, 0).uid)
	assert_eq(combat.unit_at(0, 1).quarry, combat.unit_at(1, 1).uid)


func test_isegrim_sees_through_belly_without_releasing_it_and_keeps_exact_identity() -> void:
	var holder_spec: Dictionary = CK.u("moss_ooze", 1, 10)
	holder_spec["held"] = [CK.plain(90, 100)]
	var combat: Combat = _fight({0: "old_isegrim"}, {0: holder_spec, 6: CK.plain(1, 1)})
	var holder: CombatUnit = combat.unit_at(1, 0)
	assert_eq(holder.held_specs.size(), 1)
	var selected: CombatUnit = holder.held_specs[0]["_pass3_fighter"]
	assert_eq(combat.unit_at(0, 0).quarry, selected.uid)
	assert_false(selected.on_board)
	var emerged: CombatUnit = CombatHeld.pop_one(combat, holder, false)
	assert_eq(emerged, selected)
	assert_eq(CombatLanes.choose_target(combat, combat.unit_at(0, 0)), selected)


func test_full_fetch_twin_and_copied_isegrim_both_wait_and_pick_the_real_original() -> void:
	var fairy: Dictionary = CK.u("silky", 10, 10)
	fairy["grants"] = [
		{"entry": {"id": "pass3_hunter", "ability": "isegrim", "factor": 1}, "golden": false}
	]
	var combat: Combat = _fight(
		{0: "cradle_fetch", 4: fairy}, {0: "cradle_fetch", 4: CK.u("silky", 90, 100)}, 1, false
	)
	combat.slot_effects[1] = [
		[{"name": "Ring", "count": 10, "ring_size": 1.0, "attack": 10, "health": 10}],
		[],
		[],
		[],
		[],
		[],
		[]
	]
	combat._slots_active = true
	combat._start_of_combat()
	var real: CombatUnit = combat.unit_at(1, 4)
	var twin: CombatUnit = combat.unit_at(1, 0)
	assert_true(twin.copied_this_fight)
	assert_gt(twin.attack + twin.health, real.attack + real.health)
	assert_eq(combat.unit_at(0, 0).quarry, real.uid)
	assert_eq(combat.unit_at(0, 4).quarry, real.uid)


func test_isegrim_falls_back_to_a_copy_when_no_original_enemy_remains() -> void:
	var combat: Combat = _fight({0: "old_isegrim"}, {0: CK.plain(9, 12)}, 1, false)
	combat.unit_at(1, 0).copied_this_fight = true
	combat._start_of_combat()
	assert_eq(combat.unit_at(0, 0).quarry, combat.unit_at(1, 0).uid)


func test_new_hunter_entries_and_extra_start_triggers_do_not_make_late_marks() -> void:
	var combat: Combat = _fight({0: "little_nip"}, {0: CK.plain(9, 12)})
	var entrant: CombatUnit = combat.summon_into("old_isegrim", false, 0, 4, null)
	entrant.scripts[0].on_start_of_combat(combat, entrant, entrant.params[0])
	assert_eq(entrant.quarry, 0)
	var fresh: CombatUnit = combat.summon_into("little_nip", false, 0, 5, null)
	assert_eq(fresh.quarry, 0)


func test_jack_runs_after_both_sides_ranked_answers_and_bog_stages_with_seed_invariant_recipient(
) -> void:
	_answer()
	for seed_value: int in 12:
		var combat: Combat = _fight(
			{0: "jack_daw", 1: _bird(101, 40), 4: _bird(104, 50), 6: _bird(106, 30)},
			{0: CK.u("hunter_late_answer", 20, 20), 4: "lantern_man", 5: "jenny_greenteeth"},
			seed_value
		)
		assert_eq(combat.unit_at(0, 1).attack, 45)
		var rewards: Array[Dictionary] = []
		for change: Dictionary in combat.carry:
			if str(change["op"]) == "buff":
				rewards.append(change)
		assert_eq(rewards.size(), 1)
		assert_eq(rewards[0]["iid"], 101)
		var last_trigger: String = ""
		for event: Dictionary in combat.events:
			if str(event["type"]) == "trigger":
				last_trigger = str(event["mechanic"])
		assert_eq(last_trigger, "jack_daw")


func test_copied_jack_also_uses_the_final_queue() -> void:
	_answer()
	var fairy: Dictionary = CK.u("silky", 1, 10)
	fairy["grants"] = [
		{"entry": {"id": "pass3_bird", "ability": "jack_daw", "factor": 1}, "golden": false}
	]
	for seed_value: int in 8:
		var combat: Combat = _fight(
			{0: "cradle_fetch", 1: _bird(101, 40), 2: _bird(102, 39), 4: fairy},
			{0: CK.u("hunter_late_answer", 20, 20), 4: CK.plain(20, 20)},
			seed_value
		)
		assert_true(combat.unit_at(0, 0).copied_this_fight)
		assert_eq(combat.unit_at(0, 1).attack, 20)
		assert_eq(combat.unit_at(0, 2).attack, 49)
