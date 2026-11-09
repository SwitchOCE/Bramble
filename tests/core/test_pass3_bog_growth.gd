# gdlint:disable=max-public-methods
extends GutTest
## Shared kisses, exact permanent growth and explicit guard-off counterexamples.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup()
	kit.config.set_value("pass3_content", true)
	kit.config.set_value("pass3_loop_guards", true)


func _fight(mine: Dictionary, theirs: Dictionary, kisses: int = 0) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat.side_rules[0] = {"bog_kisses": kisses}
	combat._recalc_auras(false)
	Pass3BogCombat.prepare(combat)
	combat._start_of_combat()
	return combat


func _sink(combat: Combat, slot: int, killer: CombatUnit = null) -> void:
	var target: CombatUnit = combat.unit_at(1, slot)
	combat.set_status(target, "mired", true, killer)
	combat.deal_effect_damage(killer, target, 10000)
	combat._resolve_deaths(1)


func _count(combat: Combat, kind: String) -> int:
	return CK.of_type({"events": combat.events}, kind).size()


func _gold(combat: Combat) -> int:
	var total: int = 0
	for change: Dictionary in combat.carry:
		if str(change["op"]) == "gold_next_turn":
			total += CoreUtil.to_int(change["amount"])
	return total


func test_cutter_once_fight_guard_and_counterexample() -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var combat: Combat = _fight(
			{0: "peat_cutter"}, {0: CK.plain(0, 10), 1: CK.plain(0, 10), 2: CK.plain(0, 10)}
		)
		for slot: int in 3:
			_sink(combat, slot)
		assert_eq(_gold(combat), 1 if guarded else 3)


func test_pretender_gold_requires_its_actual_killing_hit_and_has_no_fight_cap() -> void:
	var combat: Combat = _fight(
		{0: CK.u("young_pretender", 3, 100), 1: "peat_cutter"},
		{0: CK.plain(0, 10), 1: CK.plain(0, 10), 2: CK.plain(0, 10)}
	)
	var pretender: CombatUnit = combat.unit_at(0, 0)
	_sink(combat, 0, pretender)
	_sink(combat, 1, pretender)
	_sink(combat, 2, combat.unit_at(0, 1))
	assert_eq(_gold(combat), 3, "two kills plus one Cutter payout")


func test_shared_kiss_once_fight_guard_and_counterexample() -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var combat: Combat = _fight(
			{0: "his_highness", 2: "his_highness"},
			{0: CK.plain(0, 10), 1: CK.plain(0, 10), 2: CK.plain(0, 10)}
		)
		for slot: int in 3:
			_sink(combat, slot)
		assert_eq(combat.notes["bog_kisses"][0], 1 if guarded else 3)
		assert_eq(
			_count(combat, "kiss"), 2 if guarded else 6, "all frogs show the same owner count"
		)


func test_no_frog_on_board_pauses_owner_kisses() -> void:
	var combat: Combat = _fight({0: "bridge_toad"}, {0: CK.plain(0, 10)}, 2)
	_sink(combat, 0)
	assert_eq(combat.notes["bog_kisses"][0], 2)
	assert_eq(_count(combat, "kiss"), 0)


func test_overlapping_frogs_use_strongest_multiplier_once_and_guard_off_repeats() -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var combat: Combat = _fight(
			{
				0: "his_highness",
				1: CK.u("bridge_toad", 10, 20),
				2: CK.u("his_highness", -1, -1, true)
			},
			{0: CK.plain(0, 10)},
			2
		)
		var target: CombatUnit = combat.unit_at(0, 1)
		_sink(combat, 0)
		assert_eq(target.attack, 30 if guarded else 60)
		assert_eq(target.max_health, 60 if guarded else 120)
		assert_eq(combat.unit_at(0, 0).def_id(), "prince_restored")
		assert_true(combat.unit_at(0, 2).golden)


func test_curse_reads_only_base_and_permanent_layers_and_preserves_identity_damage() -> void:
	var spec: Dictionary = CK.u("bridge_toad", 10, 20)
	spec["iid"] = 88
	var frog_spec: Dictionary = CK.u("his_highness", 10, 20)
	frog_spec["iid"] = 89
	var combat: Combat = _fight({0: frog_spec, 1: spec}, {0: CK.plain(0, 10)}, 2)
	var target: CombatUnit = combat.unit_at(0, 1)
	var frog: CombatUnit = combat.unit_at(0, 0)
	var frog_uid: int = frog.uid
	target.tribe_attack = 7
	target.tribe_health = 11
	target.combat_attack = 50
	target.combat_health = 50
	frog.damage_taken = 4
	_sink(combat, 0)
	assert_eq([target.attack, target.max_health], [77, 101], "only 10/20 is added")
	assert_eq([frog.uid, frog.iid, frog.slot, frog.damage_taken], [frog_uid, 89, 0, 4])
	assert_eq([frog.perm_attack, frog.perm_health], [7, 15], "Prince preserves earned buffs")
	assert_eq(target.counters["bog_frog_turn"], combat.round_number)


func test_curse_never_heals_a_same_batch_dying_witness() -> void:
	var combat: Combat = _fight(
		{0: "his_highness", 1: CK.u("bridge_toad", 10, 20)}, {0: CK.plain(0, 10)}, 2
	)
	var target: CombatUnit = combat.unit_at(0, 1)
	target.take_damage(100)
	_sink(combat, 0)
	assert_false(target.on_board)
	assert_lte(target.health, 0)
	assert_eq(_count(combat, "permanent_reward"), 1)


func test_persisted_turn_guard_prevents_a_second_encounter_double() -> void:
	var target_spec: Dictionary = CK.u("bridge_toad", 10, 20)
	target_spec["bog_frog_turn"] = 1
	var combat: Combat = _fight({0: "his_highness", 1: target_spec}, {0: CK.plain(0, 10)}, 2)
	_sink(combat, 0)
	assert_eq(combat.unit_at(0, 1).attack, 10)


func test_frog_doubles_non_bog_units_beside_it_as_the_face_says() -> void:
	var combat: Combat = _fight({0: "his_highness", 1: CK.plain(10, 20)}, {0: CK.plain(0, 10)}, 2)
	_sink(combat, 0)
	assert_eq([combat.unit_at(0, 1).attack, combat.unit_at(0, 1).max_health], [20, 40])


func test_king_successful_summon_guard_and_counterexample() -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var combat: Combat = _fight(
			{0: "peat_king"}, {0: CK.plain(7, 13), 1: CK.plain(11, 17), 2: CK.plain(19, 23)}
		)
		for slot: int in 3:
			_sink(combat, slot)
		assert_eq(combat.units_of(0).size(), 3 if guarded else 4)


func test_king_copies_starting_stats_bitter_only_and_golden_does_not_double_them() -> void:
	var combat: Combat = _fight({0: CK.u("peat_king", -1, -1, true)}, {0: CK.plain(17, 23)})
	var enemy: CombatUnit = combat.unit_at(1, 0)
	enemy.combat_attack -= 10
	enemy.take_damage(10)
	_sink(combat, 0)
	var token: CombatUnit = combat.unit_at(0, 1)
	assert_eq([token.attack, token.max_health], [17, 23])
	assert_false(token.golden)
	assert_eq(token.mechanic_ids, PackedStringArray(["bitter"]))
	assert_true(token.params[0]["pass3"])


func test_full_board_does_not_spend_king_guard_and_same_batch_king_can_raise() -> void:
	var mine: Dictionary = {0: "peat_king"}
	for slot: int in range(1, 7):
		mine[slot] = CK.plain(0, 100)
	var combat: Combat = _fight(mine, {0: CK.plain(7, 13), 1: CK.plain(11, 17)})
	var king: CombatUnit = combat.unit_at(0, 0)
	_sink(combat, 0)
	assert_eq(CoreUtil.to_int(king.limits.get("bog_king", 0)), 0)
	king.take_damage(100)
	_sink(combat, 1)
	assert_eq(CoreUtil.to_int(king.limits.get("bog_king", 0)), 1)
	assert_eq(combat.unit_at(0, 0).def_id(), "peatling")


func test_own_and_borrowed_soak_ability_uses_one_bitter_and_strongest_keep() -> void:
	var spec: Dictionary = CK.u("bridge_toad", 0, 100)
	spec["iid"] = 11
	spec["grants"] = [
		{"entry": {"id": "pass3_bog", "ability": "soak", "factor": 1}, "golden": true}
	]
	var combat: Combat = _fight({0: spec}, {0: CK.plain(8, 100)})
	var target: CombatUnit = combat.unit_at(0, 0)
	CombatLanes.bitter(combat, target, combat.unit_at(1, 0))
	assert_eq(combat.unit_at(1, 0).attack, 6)
	assert_eq(target.pending_attack, 8)
