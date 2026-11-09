# gdlint:disable=max-public-methods
extends GutTest
## The dependent opening selects after ordinary growth, and binds exact Belly identities.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup()
	kit.config.set_value("pass3_content", true)


func _fight(mine: Dictionary, theirs: Dictionary, toll: int = 0, start: bool = true) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat.side_rules[0] = {"bog_toll": toll}
	combat._recalc_auras(false)
	Pass3BogCombat.prepare(combat)
	if start:
		combat._start_of_combat()
	return combat


func _trigger_index(combat: Combat, mechanic: String) -> int:
	for index: int in combat.events.size():
		var event: Dictionary = combat.events[index]
		if event["type"] == "trigger" and event["mechanic"] == mechanic:
			return index
	return -1


func _holder() -> Dictionary:
	var spec: Dictionary = CK.u("moss_ooze", 2, 10)
	spec["held"] = [CK.plain(10, 20), CK.plain(500, 600)]
	return spec


func test_dependent_sequence_ordinary_lantern_jenny_patches_sal_remaining_answers() -> void:
	kit.card(
		"opening_growth",
		[
			KIT.effect(
				"start_of_combat",
				{"effect": "buff", "attack": 200, "health": 200, "target": {"select": "self"}}
			)
		],
		[],
		10,
		20
	)
	kit.card(
		"late_answer",
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
	var combat: Combat = _fight(
		{
			0: "jenny_greenteeth",
			1: "bridge_toad",
			3: "spitfire_sal",
			4: "late_answer",
			5: "lantern_man"
		},
		{0: CK.plain(20, 100), 1: "opening_growth", 6: CK.plain(500, 600)},
		30
	)
	assert_eq(combat.unit_at(1, 0).def_id(), "opening_growth", "Jenny sees the ordinary +200/+200")
	assert_eq(combat.unit_at(1, 0).health, 210, "three patches split prior Toll 10 each")
	assert_eq(combat.unit_at(1, 6).attack, 250, "late answer sees the fully patched, burned board")
	var lantern: int = _trigger_index(combat, "pass3_bog:lantern")
	var jenny: int = _trigger_index(combat, "pass3_bog:jenny")
	var sal: int = _trigger_index(combat, "pass3_bog:sal")
	assert_gt(lantern, _trigger_index(combat, "effect"))
	assert_gt(jenny, lantern)
	assert_gt(sal, jenny)
	var patches_before_sal: int = 0
	for index: int in range(jenny + 1, sal):
		if combat.events[index]["type"] == "bog_patch":
			patches_before_sal += 1
	assert_eq(patches_before_sal, 2, "Jenny and the ordinary mirer patch after both pulls")


func test_lantern_claims_before_across_mirer_and_golden_lures_two_biggest() -> void:
	var combat: Combat = _fight(
		{0: "bridge_toad", 4: CK.u("lantern_man", -1, -1, true)},
		{0: CK.plain(100, 100), 1: CK.plain(50, 50), 6: CK.plain(1, 1)}
	)
	var lantern: CombatUnit = combat.unit_at(0, 4)
	assert_eq(CombatLanes.maker_of(combat, combat.unit_at(1, 0)), lantern)
	assert_eq(CombatLanes.maker_of(combat, combat.unit_at(1, 1)), lantern)
	assert_null(CombatLanes.maker_of(combat, combat.unit_at(1, 6)))


func test_lantern_and_jenny_skip_full_fetch_twin_when_originals_remain() -> void:
	for answer: String in ["lantern_man", "jenny_greenteeth"]:
		var combat: Combat = _fight(
			{0: answer},
			{0: "cradle_fetch", 1: CK.plain(10, 10), 4: CK.u("silky", 200, 200)},
			0,
			false
		)
		combat._start_of_combat()
		if answer == "lantern_man":
			assert_eq(CombatLanes.maker_of(combat, combat.unit_at(1, 4)), combat.unit_at(0, 0))
			assert_null(CombatLanes.maker_of(combat, combat.unit_at(1, 0)))
		else:
			assert_eq(
				combat.unit_at(1, 0).def_id(),
				"field_vole",
				"Jenny selects the eligible row original"
			)
			assert_true(combat.unit_at(1, 1).copied_this_fight)


func test_jenny_pulls_only_across_row_skips_lantern_choice_and_keeps_slot_effects() -> void:
	var combat: Combat = _fight(
		{0: "jenny_greenteeth", 4: "lantern_man"},
		{0: CK.plain(1, 10), 1: CK.plain(80, 100), 2: CK.plain(50, 50), 6: CK.plain(1000, 1000)},
		0,
		false
	)
	combat.slot_effects[1] = [
		[{"name": "Ring", "count": 2, "ring_size": 1.0, "attack": 2, "health": 2}],
		[],
		[],
		[],
		[],
		[],
		[]
	]
	combat._slots_active = true
	combat._start_of_combat()
	assert_eq(combat.unit_at(1, 0).base_attack_now() + combat.unit_at(1, 0).perm_attack, 80)
	assert_eq(BoardUpkeep.ring_value(combat._slot_effects_at(1, 0)), Vector2i(2, 2))
	assert_eq(BoardUpkeep.ring_value(combat._slot_effects_at(1, 1)), Vector2i.ZERO)
	assert_eq(CombatLanes.maker_of(combat, combat.unit_at(1, 6)), combat.unit_at(0, 4))


func test_hidden_lantern_binds_exact_unit_without_releasing_or_luring_holder() -> void:
	var combat: Combat = _fight({4: "lantern_man"}, {0: _holder(), 6: CK.plain(1, 1)})
	var holder: CombatUnit = combat.unit_at(1, 0)
	assert_eq(holder.held_specs.size(), 2, "selection does not force a release")
	assert_null(CombatLanes.maker_of(combat, holder))
	var selected: CombatUnit = holder.held_specs[-1]["_pass3_fighter"]
	var emerged: CombatUnit = CombatHeld.pop_one(combat, holder, false)
	assert_eq(emerged, selected)
	assert_eq(CombatLanes.maker_of(combat, emerged), combat.unit_at(0, 4))
	assert_eq(holder.held_specs.size(), 1)


func test_hidden_jenny_pulls_exact_unit_when_it_emerges() -> void:
	var combat: Combat = _fight({0: "jenny_greenteeth"}, {0: _holder(), 6: CK.plain(1, 1)})
	var holder: CombatUnit = combat.unit_at(1, 0)
	assert_eq(holder.held_specs.size(), 2)
	var selected: CombatUnit = holder.held_specs[-1]["_pass3_fighter"]
	var emerged: CombatUnit = CombatHeld.pop_one(combat, holder, false)
	assert_eq(emerged, selected)
	assert_eq(combat.unit_at(1, 0), emerged)
	assert_eq(holder.slot, 1)
	assert_eq(CombatLanes.maker_of(combat, emerged), combat.unit_at(0, 0))


func test_pending_hidden_lure_does_nothing_after_lantern_dies() -> void:
	var combat: Combat = _fight({4: "lantern_man", 6: CK.plain(0, 100)}, {0: _holder()})
	var holder: CombatUnit = combat.unit_at(1, 0)
	combat.deal_effect_damage(null, combat.unit_at(0, 4), 10000)
	combat._resolve_deaths(0)
	var emerged: CombatUnit = CombatHeld.pop_one(combat, holder, false)
	assert_null(CombatLanes.maker_of(combat, emerged))


func test_sal_splits_previous_toll_after_patches_and_is_not_fed_by_current_toll() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: "bridge_toad", 1: "bridge_toad", 4: CK.u("spitfire_sal", -1, -1, golden)},
			{0: CK.plain(0, 100), 1: CK.plain(0, 100)},
			11
		)
		assert_eq(combat.unit_at(1, 0).health, 89 if golden else 95)
		assert_eq(combat.unit_at(1, 1).health, 89 if golden else 95)
		assert_eq(combat.notes["bog_toll"][0], 0)


func test_extra_start_trigger_repeats_sal_without_advancing_kisses() -> void:
	var combat: Combat = _fight(
		{0: "jenny_greenteeth", 4: "spitfire_sal"}, {0: CK.plain(0, 100), 1: CK.plain(10, 100)}, 20
	)
	var before: int = combat.unit_at(1, 0).health
	Pass3BogStart.invoke(combat, combat.unit_at(0, 4), "sal")
	assert_eq(combat.unit_at(1, 0).health, before - 20)
	assert_eq(combat.notes["bog_kisses"][0], 0)


func test_fetch_copy_with_borrowed_bog_start_waits_for_the_dependent_stage() -> void:
	kit.card("old_mirer", [{"id": "mire"}], ["Bog folk"], 1, 100)
	var fairy: Dictionary = CK.u("silky", 1, 100)
	fairy["grants"] = [
		{"entry": {"id": "pass3_bog", "ability": "sal", "factor": 1}, "golden": false}
	]
	var combat: Combat = _fight(
		{0: "cradle_fetch", 1: "old_mirer", 4: fairy}, {1: CK.plain(0, 100)}, 10
	)
	assert_true(combat.unit_at(0, 0).copied_this_fight)
	assert_eq(combat.unit_at(1, 1).health, 80, "copy and original each fire Sal once in its stage")
