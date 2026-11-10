# gdlint:disable=max-public-methods
extends GutTest

const ORIGINAL_B := preload("res://tests/core/pass3_original_b.gd")
## Real Hunter rewards use immutable prey prices and the shared next-turn queue.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(ORIGINAL_B.apply(GameConfig.full_game()))


func _owned(id: String, attack: int = 1, health: int = 100, golden: bool = false) -> Dictionary:
	var spec: Dictionary = CK.u(id, attack, health, golden)
	spec["iid"] = 91
	return spec


func _fight(mine: Dictionary, theirs: Dictionary, seed_value: int = 1) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat._recalc_auras(false)
	combat._start_of_combat()
	return combat


func _kill(combat: Combat, side: int, slot: int, killer: CombatUnit = null) -> void:
	combat.deal_effect_damage(killer, combat.unit_at(side, slot), 10000)
	combat._resolve_deaths(side)


func _changes(combat: Combat, operation: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for change: Dictionary in combat.carry:
		if str(change["op"]) == operation:
			result.append(change)
	return result


func test_nip_and_lutra_take_frozen_stats_with_golden_share_and_no_fight_growth() -> void:
	for id: String in ["little_nip", "old_lutra"]:
		for golden: bool in [false, true]:
			var combat: Combat = _fight({0: _owned(id, 1, 100, golden)}, {0: CK.plain(9, 12)})
			var hunter: CombatUnit = combat.unit_at(0, 0)
			combat.unit_at(1, 0).combat_attack += 900
			_kill(combat, 1, 0)
			assert_eq(
				[hunter.pending_attack, hunter.pending_health], [12, 16] if golden else [6, 8]
			)
			assert_eq([hunter.attack, hunter.health], [1, 100])
			assert_eq(combat.takes[0], 1)


func test_take_floors_each_stat_and_the_floor_is_a_dial() -> void:
	var combat: Combat = _fight({0: _owned("little_nip")}, {0: CK.plain(0, 1)})
	var hunter: CombatUnit = combat.unit_at(0, 0)
	_kill(combat, 1, 0)
	assert_eq([hunter.pending_attack, hunter.pending_health], [1, 1])
	kit.config.set_value("hunters_take_floor", 0)
	combat = _fight({0: _owned("little_nip")}, {0: CK.plain(0, 1)})
	hunter = combat.unit_at(0, 0)
	_kill(combat, 1, 0)
	assert_eq([hunter.pending_attack, hunter.pending_health], [0, 0])


func test_only_one_reading_order_hunter_takes_a_shared_quarry_and_dying_witness_counts() -> void:
	var combat: Combat = _fight({0: _owned("little_nip"), 4: "old_isegrim"}, {0: CK.plain(9, 12)})
	var first: CombatUnit = combat.unit_at(0, 0)
	first.take_damage(1000)
	_kill(combat, 1, 0)
	assert_false(first.on_board)
	assert_eq([first.pending_attack, first.pending_health], [6, 8])
	assert_lte(first.health, 0, "pending reward cannot heal a dying fighter")
	assert_eq(combat.takes[0], 1)
	var events: Array[Dictionary] = CK.of_type({"events": combat.events}, "take")
	assert_eq(events[0]["hunter"], first.uid)


func test_a_hunter_that_died_in_an_earlier_batch_does_not_take() -> void:
	var combat: Combat = _fight({0: _owned("little_nip"), 4: "old_isegrim"}, {0: CK.plain(9, 12)})
	var first: CombatUnit = combat.unit_at(0, 0)
	_kill(combat, 0, 0)
	_kill(combat, 1, 0)
	assert_eq(first.pending_attack, 0)
	assert_eq(combat.takes[0], 1, "the surviving Isegrim claims the Take")


func test_laird_repeats_only_take_text_observers_get_one_raw_snapshot_share() -> void:
	var combat: Combat = _fight(
		{
			0: _owned("little_nip"),
			1: _owned("lodger"),
			2: _owned("mountain_glutton"),
			4: "laird_of_sett",
			5: CK.u("laird_of_sett", -1, -1, true)
		},
		{0: CK.plain(9, 12)}
	)
	var nip: CombatUnit = combat.unit_at(0, 0)
	var lodger: CombatUnit = combat.unit_at(0, 1)
	var glutton: CombatUnit = combat.unit_at(0, 2)
	_kill(combat, 1, 0)
	assert_eq(
		[nip.pending_attack, nip.pending_health], [18, 24], "strongest Laird is three repeats"
	)
	assert_eq([lodger.pending_attack, lodger.pending_health], [6, 8])
	assert_eq([glutton.pending_attack, glutton.pending_health], [6, 8])
	assert_eq(combat.takes[0], 1)


func test_laird_nonstack_guard_has_an_explicit_off_counterexample() -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var combat: Combat = _fight(
			{0: _owned("little_nip"), 4: "laird_of_sett", 5: "laird_of_sett"}, {0: CK.plain(9, 12)}
		)
		var nip: CombatUnit = combat.unit_at(0, 0)
		_kill(combat, 1, 0)
		assert_eq(nip.pending_attack, 12 if guarded else 24)


func test_fractional_laird_repeats_floor_with_minimum_one() -> void:
	for multiplier: float in [0.5, 1.9]:
		kit.config.set_value("hunters_laird_multiplier", multiplier)
		var combat: Combat = _fight(
			{0: _owned("little_nip"), 4: "laird_of_sett"}, {0: CK.plain(9, 12)}
		)
		var nip: CombatUnit = combat.unit_at(0, 0)
		_kill(combat, 1, 0)
		assert_eq(nip.pending_attack, 6)


func test_printed_and_borrowed_take_growth_deduplicate_with_guard_off_counterexample() -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var spec: Dictionary = _owned("little_nip")
		spec["grants"] = [
			{"entry": {"id": "pass3_hunter", "ability": "nip", "factor": 1}, "golden": false}
		]
		var combat: Combat = _fight({0: spec}, {0: CK.plain(9, 12)})
		var nip: CombatUnit = combat.unit_at(0, 0)
		_kill(combat, 1, 0)
		assert_eq(nip.pending_attack, 6 if guarded else 12)


func test_trophy_timing_switch_exposes_in_fight_growth_counterexample() -> void:
	kit.config.set_value("hunters_trophies_after_fight", false)
	var combat: Combat = _fight({0: _owned("little_nip")}, {0: CK.plain(9, 12)})
	var nip: CombatUnit = combat.unit_at(0, 0)
	_kill(combat, 1, 0)
	assert_eq([nip.attack, nip.health], [7, 108])
	assert_eq(nip.pending_attack, 0)
	assert_eq(_changes(combat, "buff").size(), 1)


func test_lodger_requires_adjacent_taker_but_glutton_hears_every_friendly_take() -> void:
	var combat: Combat = _fight(
		{0: _owned("little_nip"), 2: _owned("lodger"), 4: _owned("mountain_glutton")},
		{0: CK.plain(9, 12)}
	)
	_kill(combat, 1, 0)
	assert_eq(combat.unit_at(0, 2).pending_attack, 0)
	assert_eq(combat.unit_at(0, 4).pending_attack, 6)


func test_russet_poaches_bell_permanent_buffs_only_and_laird_repeats_copies() -> void:
	var prey: Dictionary = CK.u("little_nip", 30, 41)
	prey["tribe_attack"] = 10
	prey["tribe_health"] = 11
	var combat: Combat = _fight({0: _owned("mistress_russet"), 4: "laird_of_sett"}, {0: prey})
	combat.unit_at(1, 0).combat_attack += 100
	combat.unit_at(1, 0).combat_health += 100
	_kill(combat, 1, 0)
	var offers: Array[Dictionary] = _changes(combat, "poach")
	assert_eq(offers.size(), 2)
	assert_eq(
		[
			offers[0]["card"],
			offers[0]["discount"],
			offers[0]["perm_attack"],
			offers[0]["perm_health"]
		],
		["little_nip", 0, 12, 18]
	)


func test_lane_bard_pays_twice_for_quarry_attacks_without_shrinking_it() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight({0: CK.u("toll_bard", 0, 100, golden)}, {0: CK.plain(1, 100)})
		var attacker: CombatUnit = combat.unit_at(1, 0)
		for _time: int in 3:
			combat._attack(attacker, combat.unit_at(0, 0))
		assert_eq(attacker.attack, 1)
		var gold: Array[Dictionary] = _changes(combat, "gold_next_turn")
		assert_eq(gold.size(), 2)
		assert_eq(gold[0]["amount"], 2 if golden else 1)


func test_ermeline_pays_for_biggest_marked_quarry_even_if_both_survive_or_she_faints() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: CK.u("madame_ermeline", 1, 100, golden), 1: "little_nip", 4: "old_isegrim"},
			{1: CK.plain(3, 4), 6: CK.plain(90, 120)}
		)
		_kill(combat, 0, 0)
		Pass3HunterGains.finish(combat)
		var cards: Array[Dictionary] = _changes(combat, "add_card")
		assert_eq(cards.size(), 1)
		assert_eq(
			[cards[0]["card"], cards[0]["count"], cards[0]["attack"], cards[0]["health"]],
			["pelt", 2 if golden else 1, 30, 40]
		)
		assert_eq(cards[0]["prey"]["id"], "field_vole")


func test_ermeline_entering_midfight_does_not_earn_a_pelt() -> void:
	var combat: Combat = _fight({0: "little_nip"}, {0: CK.plain(9, 12)})
	combat.summon_into("madame_ermeline", false, 0, 4, null)
	Pass3HunterGains.finish(combat)
	assert_true(_changes(combat, "add_card").is_empty())


func test_ermeline_ties_use_enemy_reading_order_instead_of_marking_order() -> void:
	var combat: Combat = _fight(
		{1: "little_nip", 3: "madame_ermeline", 6: "old_isegrim"},
		{0: CK.u("little_nip", 9, 12), 1: CK.plain(9, 12)}
	)
	Pass3HunterGains.finish(combat)
	var cards: Array[Dictionary] = _changes(combat, "add_card")
	assert_eq(cards.size(), 1)
	assert_eq(cards[0]["prey"]["id"], "little_nip", "F1 ties ahead of the earlier-marked F2")
