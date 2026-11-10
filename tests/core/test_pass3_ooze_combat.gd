# gdlint:disable=max-public-methods
extends GutTest
## Fixed boards prove printed and golden Ooze releases without running whole games.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())


func _fight(mine: Dictionary, theirs: Dictionary, start: bool = false) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat._recalc_auras(false)
	if start:
		combat._start_of_combat()
	return combat


func _spec(id: String, held: Array, golden: bool = false, health: int = -1) -> Dictionary:
	var spec: Dictionary = CK.u(id, -1, health, golden)
	spec["held"] = held
	return spec


func _mechanic(unit: CombatUnit, id: String) -> Dictionary:
	return unit.params[unit.mechanic_ids.find(id)]


func _hit(combat: Combat, target: CombatUnit, amount: int = 1) -> void:
	combat.deal_effect_damage(combat.unit_at(1, 0), target, amount)
	for index: int in target.scripts.size():
		target.scripts[index].on_survived_attack(
			combat, target, target.params[index], combat.unit_at(1, 0)
		)


func test_posset_halves_her_actual_effect_killer_and_records_its_reference() -> void:
	var combat: Combat = _fight({0: "mrs_posset"}, {0: CK.plain(3, 3), 6: CK.plain(11, 9)})
	var killer: CombatUnit = combat.unit_at(1, 6)
	var posset: CombatUnit = combat.unit_at(0, 0)
	combat.deal_effect_damage(killer, posset, 2)
	combat._resolve_deaths(0)
	assert_eq([killer.attack, killer.health], [6, 5], "loss rounds down")
	assert_eq(combat.unit_at(1, 0).attack, 3, "across is not the killer")
	var deaths: Array = combat.events.filter(
		func(e: Dictionary) -> bool: return e["type"] == "death"
	)
	assert_eq(deaths[0]["killer"], killer.uid)
	assert_true(combat.carry.is_empty(), "the halving lasts only the fight")


func test_golden_posset_halves_killer_and_beside_units_only() -> void:
	var combat: Combat = _fight(
		{0: CK.u("mrs_posset", -1, -1, true)},
		{0: CK.plain(8, 8), 1: CK.plain(10, 10), 2: CK.plain(6, 6), 4: CK.plain(14, 14)}
	)
	combat.deal_effect_damage(combat.unit_at(1, 1), combat.unit_at(0, 0), 9)
	combat._resolve_deaths(0)
	assert_eq([combat.unit_at(1, 0).attack, combat.unit_at(1, 1).attack], [4, 5])
	assert_eq(combat.unit_at(1, 2).attack, 3)
	assert_eq(combat.unit_at(1, 4).attack, 14, "next-to is wider than beside")


func test_posset_does_not_halve_a_friendly_killer_or_revive_a_dead_killer() -> void:
	for friendly: bool in [true, false]:
		var combat: Combat = _fight({0: "mrs_posset", 1: CK.plain(8, 8)}, {0: CK.plain(9, 9)})
		var killer: CombatUnit = combat.unit_at(0 if friendly else 1, 1 if friendly else 0)
		combat.deal_effect_damage(killer, combat.unit_at(0, 0), 2)
		if not friendly:
			killer.take_damage(20)
		combat._resolve_deaths(0)
		assert_eq(killer.attack, 8 if friendly else 9)
		if not friendly:
			assert_true(killer.is_dead())


func test_posset_never_takes_a_living_killer_below_one_health() -> void:
	var combat: Combat = _fight({0: "mrs_posset"}, {0: CK.plain(1, 1)})
	var killer: CombatUnit = combat.unit_at(1, 0)
	combat.deal_effect_damage(killer, combat.unit_at(0, 0), 1)
	combat._resolve_deaths(0)
	assert_eq(killer.health, 1)


func test_moss_shields_each_own_release_and_golden_reduces_damage_by_a_quarter() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: _spec("little_dollop", [CK.plain(10, 20)]), 4: CK.u("moss_ooze", -1, -1, golden)},
			{0: CK.plain(8, 100)}
		)
		var holder: CombatUnit = combat.unit_at(0, 0)
		holder.take_damage(100)
		combat._resolve_deaths(0)
		var released: CombatUnit = combat.unit_at(0, 0)
		assert_true(released.has_status("shield"))
		combat._recalc_auras(true)
		_hit(combat, released, 8)
		assert_eq(released.health, 20, "the first hit is fully Shielded")
		_hit(combat, released, 8)
		assert_eq(released.health, 14 if golden else 12)


func test_moss_does_not_shield_an_enemy_returned_by_hasty() -> void:
	var combat: Combat = _fight({0: "hasty_pudding", 4: "moss_ooze"}, {0: CK.plain(10, 20)})
	var hasty: CombatUnit = combat.unit_at(0, 0)
	var prisoner: CombatUnit = combat.unit_at(1, 0)
	CombatHeld.swallow(combat, hasty, prisoner)
	CombatHeld.return_inside(combat, hasty)
	assert_false(prisoner.has_status("shield"))


func test_moss_reduction_survives_a_stronger_tom_protection_ending() -> void:
	var combat: Combat = _fight(
		{
			0: _spec("sixpenny_pie", [CK.u("tom_tit"), CK.u("chiffchaff", 20, 40)]),
			4: CK.u("moss_ooze", -1, -1, true),
			5: "mr_syllabub"
		},
		{0: CK.plain(8, 100)}
	)
	combat.unit_at(0, 0).take_damage(100)
	combat._resolve_deaths(0)
	var bird: CombatUnit = combat.unit_at(0, 0)
	var tom: CombatUnit = combat.unit_at(0, 1)
	assert_eq(tom.def_id(), "tom_tit")
	_hit(combat, bird, 8)
	_hit(combat, bird, 8)
	assert_eq(bird.health, 36, "Tom's stronger half reduction takes priority")
	tom.take_damage(100)
	combat._resolve_deaths(0)
	_hit(combat, bird, 8)
	assert_eq(bird.health, 30, "Moss's quarter reduction persists")


func test_gathered_moss_returns_with_family_and_shields_earlier_siblings_too() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{
				0: "granny_stir_up",
				4: "little_dollop",
				1: "drip",
				5: CK.u("moss_ooze", -1, -1, golden)
			},
			{0: CK.plain(1, 100)},
			true
		)
		var granny: CombatUnit = combat.unit_at(0, 0)
		assert_eq(granny.inside.size(), 3)
		granny.take_damage(1000)
		combat._resolve_deaths(0)
		for slot: int in [4, 1, 5]:
			var returned: CombatUnit = combat.unit_at(0, slot)
			assert_not_null(returned)
			assert_true(returned.has_status("shield"), "Moss returns last in the zigzag")
			assert_eq(returned.has_status("damage_reduction"), golden)


func test_wobbly_releases_then_keeps_making_drips_beyond_the_old_two_hit_limit() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: _spec("wee_wobbly", [CK.plain(3, 3)], golden, 30), 4: "moss_ooze"},
			{0: CK.plain(1, 100)}
		)
		var wobbly: CombatUnit = combat.unit_at(0, 0)
		_hit(combat, wobbly)
		assert_true(wobbly.held_specs.is_empty())
		for _time: int in 3:
			_hit(combat, wobbly)
		var drips: Array[CombatUnit] = combat.units_of(0).filter(
			func(unit: CombatUnit) -> bool: return unit.def_id() == "drip"
		)
		assert_eq(drips.size(), 3)
		for drip: CombatUnit in drips:
			assert_eq([drip.attack, drip.health], [2, 2] if golden else [1, 1])
			assert_true(drip.has_status("shield"))


func test_bubble_ignores_a_hit_fully_stopped_by_shield_then_splits_a_damaging_hit() -> void:
	var combat: Combat = _fight({0: CK.u("bubble_and_squeak", 20, 40)}, {0: CK.plain(1, 100)})
	var bubble: CombatUnit = combat.unit_at(0, 0)
	combat.set_status(bubble, "shield", true, bubble)
	_hit(combat, bubble, 4)
	assert_eq(combat.units_of(0).size(), 1)
	assert_eq(bubble.health, 40)
	_hit(combat, bubble, 4)
	assert_eq(combat.units_of(0).size(), 2)
	assert_eq([bubble.attack, bubble.health], [10, 18])


func test_golden_wobbly_releases_both_reserves_lifo_with_no_drip_on_that_hit() -> void:
	var combat: Combat = _fight(
		{0: _spec("wee_wobbly", [CK.plain(3, 4), CK.plain(5, 6)], true, 30)}, {0: CK.plain(1, 100)}
	)
	var wobbly: CombatUnit = combat.unit_at(0, 0)
	_hit(combat, wobbly)
	assert_true(wobbly.held_specs.is_empty())
	assert_eq(combat.units_of(0).size(), 3)
	assert_eq(combat.unit_at(0, 1).attack, 5, "last in comes out first")
	assert_eq(combat.unit_at(0, 2).attack, 3)
	assert_eq(combat.unit_at(0, 1).def_id(), "field_vole", "no Drip while releasing")


func test_golden_wobbly_keeps_the_reserve_that_cannot_find_a_gap() -> void:
	var combat: Combat = _fight(
		{
			0: _spec("wee_wobbly", [CK.plain(3, 4), CK.plain(5, 6)], true, 30),
			2: "drip",
			3: "drip",
			4: "drip",
			5: "drip",
			6: "drip"
		},
		{0: CK.plain(1, 100)}
	)
	var wobbly: CombatUnit = combat.unit_at(0, 0)
	_hit(combat, wobbly)
	assert_eq(combat.units_of(0).size(), 7)
	assert_eq(wobbly.held_specs.size(), 1)
	assert_eq(wobbly.held_specs[0]["attack"], 3)
	assert_eq(combat.unit_at(0, 1).attack, 5)


func test_bubble_split_limit_and_empty_halves_normal_and_golden() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: _spec("bubble_and_squeak", [CK.plain(2, 2)], golden, 100)}, {0: CK.plain(1, 100)}
		)
		var bubble: CombatUnit = combat.unit_at(0, 0)
		for _time: int in 3:
			_hit(combat, bubble)
		assert_eq(combat.units_of(0).size(), 3 if golden else 2)
		for half: CombatUnit in combat.units_of(0):
			if half != bubble:
				assert_true(half.held_specs.is_empty())
				assert_true(half.copied_this_fight)


func test_bubble_halves_cannot_split_with_guard_off_counterexample() -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var combat: Combat = _fight({0: CK.u("bubble_and_squeak", 40, 80)}, {0: CK.plain(1, 100)})
		var bubble: CombatUnit = combat.unit_at(0, 0)
		_hit(combat, bubble)
		var half: CombatUnit = combat.units_of(0)[1]
		_hit(combat, half)
		assert_eq(combat.units_of(0).size(), 2 if guarded else 3)


func test_a_frumenty_half_keeps_borrowed_bubble_and_other_meal_text_but_never_splits() -> void:
	var spec: Dictionary = CK.u("frumenty", 40, 80, true)
	spec["held"] = [CK.plain(5, 5)]
	spec["grants"] = [
		{"entry": {"id": "bubble", "splits": 1, "pass3": true}, "golden": false},
		{"entry": {"id": "cleave"}, "golden": false},
		{
			"entry":
			{
				"id": "pass3_ooze",
				"ability": "hasty_pudding",
				"factor": 1,
				"share": 0.2,
				"count": 1,
				"after": 3
			},
			"golden": false
		}
	]
	var combat: Combat = _fight({0: spec}, {0: CK.plain(1, 100)})
	var frumenty: CombatUnit = combat.unit_at(0, 0)
	_hit(combat, frumenty)
	var half: CombatUnit = combat.units_of(0)[1]
	assert_true(half.has_mechanic("bubble"))
	assert_true(half.has_mechanic("cleave"))
	assert_true(Pass3OozeCombat.has(half, "hasty_pudding"))
	assert_eq(half.grants.size(), 3)
	assert_true(half.held_specs.is_empty())
	_hit(combat, half)
	assert_eq(combat.units_of(0).size(), 2, "borrowed Bubble remains used on the empty half")


func test_bubble_has_no_split_without_a_gap_or_if_the_hit_kills_it() -> void:
	var combat: Combat = _fight(
		{0: "bubble_and_squeak", 1: "drip", 2: "drip", 3: "drip", 4: "drip", 5: "drip", 6: "drip"},
		{0: CK.plain(1, 100)}
	)
	var bubble: CombatUnit = combat.unit_at(0, 0)
	_hit(combat, bubble)
	assert_eq(combat.units_of(0).size(), 7)
	assert_false(bubble.counters.has("split"))
	var lethal: Combat = _fight({0: "bubble_and_squeak"}, {0: CK.plain(1, 100)})
	_hit(lethal, lethal.unit_at(0, 0), 20)
	assert_eq(lethal.units_of(0).size(), 1)


func test_pie_pays_for_every_actual_release_and_golden_does_not_double_the_rate() -> void:
	for golden: bool in [false, true]:
		var held: Array = [CK.plain(2, 2), CK.plain(3, 3)]
		if golden:
			held.append_array([CK.plain(4, 4), CK.plain(5, 5)])
		var combat: Combat = _fight({0: _spec("sixpenny_pie", held, golden)}, {0: CK.plain(1, 100)})
		combat.unit_at(0, 0).take_damage(100)
		combat._resolve_deaths(0)
		assert_eq(combat.carry.size(), 1)
		assert_eq(combat.carry[0]["amount"], 4 if golden else 2)


func test_pie_does_not_pay_for_a_reserve_without_room() -> void:
	var combat: Combat = _fight(
		{
			0: _spec("sixpenny_pie", [CK.plain(2, 2), CK.plain(3, 3)]),
			1: "drip",
			2: "drip",
			3: "drip",
			4: "drip",
			5: "drip",
			6: "drip"
		},
		{0: CK.plain(1, 100)}
	)
	combat.unit_at(0, 0).take_damage(100)
	combat._resolve_deaths(0)
	assert_eq(combat.carry[0]["amount"], 1)


func test_syllabub_replays_a_returned_grannys_family_soc_normal_and_golden() -> void:
	for golden: bool in [false, true]:
		kit.card(
			"ooze_start_buff",
			[
				KIT.effect(
					"start_of_combat",
					{"effect": "buff", "attack": 3, "health": 0, "target": {"select": "self"}}
				)
			],
			["Oozes"],
			1,
			10
		)
		var combat: Combat = _fight(
			{0: "granny_stir_up", 1: "ooze_start_buff", 4: CK.u("mr_syllabub", -1, -1, golden)},
			{0: CK.plain(1, 100)}
		)
		var granny: CombatUnit = combat.unit_at(0, 0)
		var child: CombatUnit = combat.unit_at(0, 1)
		CombatHeld.swallow(combat, granny, child)
		granny.take_damage(100)
		combat._resolve_deaths(0)
		assert_eq(child.attack, 7 if golden else 4)


func test_starting_held_survivor_variant_is_off_by_default_and_counts_once_after_release() -> void:
	for flag: bool in [false, true]:
		kit.config.set_value("replay_starting_belly_survivors", flag)
		var combat: Combat = _fight(
			{0: _spec("little_dollop", [CK.plain(3, 10)])}, {0: CK.plain(1, 100)}
		)
		var holder: CombatUnit = combat.unit_at(0, 0)
		assert_eq(CombatMoves.starting_survivors(combat, 0), 2 if flag else 1)
		holder.take_damage(100)
		combat._resolve_deaths(0)
		assert_eq(CombatMoves.starting_survivors(combat, 0), 1 if flag else 0)
		var released: CombatUnit = combat.unit_at(0, 0)
		CombatHeld.swallow(combat, combat.unit_at(1, 0), released)
		assert_eq(CombatMoves.starting_survivors(combat, 0), 1 if flag else 0)
		CombatHeld.return_inside(combat, combat.unit_at(1, 0))
		assert_eq(CombatMoves.starting_survivors(combat, 0), 1 if flag else 0)


func test_starting_held_survivor_variant_does_not_count_a_new_split_as_another_starter() -> void:
	kit.config.set_value("replay_starting_belly_survivors", true)
	var combat: Combat = _fight(
		{0: _spec("little_dollop", [CK.u("bubble_and_squeak", 20, 60)])}, {0: CK.plain(1, 100)}
	)
	combat.unit_at(0, 0).take_damage(100)
	combat._resolve_deaths(0)
	var released: CombatUnit = combat.unit_at(0, 0)
	_hit(combat, released)
	assert_eq(combat.units_of(0).size(), 2)
	assert_eq(CombatMoves.starting_survivors(combat, 0), 1)


func _borrowed_hasties() -> Dictionary:
	var spec: Dictionary = CK.u("frumenty", 30, 40, true)
	var entry: Dictionary = {
		"id": "pass3_ooze",
		"ability": "hasty_pudding",
		"factor": 1,
		"count": 1,
		"share": 0.2,
		"after": 3
	}
	spec["grants"] = [{"entry": entry, "golden": false}, {"entry": entry, "golden": true}]
	return spec


func test_borrowed_hasties_use_strongest_once_per_start_and_syllabub_dispatch_guard_off() -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var combat: Combat = _fight(
			{0: _borrowed_hasties()},
			{0: CK.plain(10, 20), 1: CK.plain(8, 16), 2: CK.plain(1, 1)},
			true
		)
		var frumenty: CombatUnit = combat.unit_at(0, 0)
		assert_eq(frumenty.inside.size(), 2 if guarded else 1)
		CombatHeld.return_inside(combat, frumenty)
		CombatHeld.start_again(combat, frumenty)
		assert_eq(
			frumenty.inside.size(),
			2 if guarded else 1,
			"a new replay resets the claim and picks the strongest instance again"
		)


func test_borrowed_hasty_deaths_count_actual_friendly_deaths_once_guard_off() -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var combat: Combat = _fight(
			{0: _borrowed_hasties(), 1: "drip", 2: "drip", 3: "drip"},
			{0: CK.plain(10, 20), 1: CK.plain(8, 16), 2: CK.plain(1, 1)},
			true
		)
		var frumenty: CombatUnit = combat.unit_at(0, 0)
		for slot: int in [1, 2]:
			combat.unit_at(0, slot).take_damage(100)
			combat._resolve_deaths(0)
		assert_eq(
			frumenty.inside.size(),
			2 if guarded else 0,
			"duplicate callbacks must not release after only two actual deaths"
		)
		combat.unit_at(0, 3).take_damage(100)
		combat._resolve_deaths(0)
		assert_true(frumenty.inside.is_empty())
		assert_eq(frumenty.counters["pass3_hasty_deaths"], 3 if guarded else 6)


func test_borrowed_grannies_choose_golden_gather_before_the_weak_instance_guard_off() -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var spec: Dictionary = CK.u("frumenty", 30, 40, true)
		var entry: Dictionary = {
			"id": "pass3_ooze", "ability": "granny_stir_up", "factor": 1, "attack_multiplier": 1.0
		}
		spec["grants"] = [{"entry": entry, "golden": false}, {"entry": entry, "golden": true}]
		var combat: Combat = _fight({0: spec, 4: CK.u("drip", 10, 10)}, {0: CK.plain(1, 100)}, true)
		assert_eq(combat.unit_at(0, 0).attack, 50 if guarded else 40)
		assert_eq(combat.unit_at(0, 0).inside.size(), 1)


func test_frumentys_own_borrowed_syllabub_replays_its_other_hasty_meal_on_release() -> void:
	var spec: Dictionary = CK.u("frumenty", 30, 40, true)
	spec["grants"] = [
		{"entry": {"id": "syllabub", "times": 1, "pass3": true}, "golden": false},
		{
			"entry":
			{
				"id": "pass3_ooze",
				"ability": "hasty_pudding",
				"factor": 1,
				"count": 1,
				"share": 0.2,
				"after": 3
			},
			"golden": false
		}
	]
	var combat: Combat = _fight(
		{0: _spec("little_dollop", [spec])}, {0: CK.plain(10, 20), 1: CK.plain(8, 16)}
	)
	combat.unit_at(0, 0).take_damage(100)
	combat._resolve_deaths(0)
	var frumenty: CombatUnit = combat.unit_at(0, 0)
	assert_eq(frumenty.inside.size(), 1)
	assert_eq(frumenty.inside[0].attack, 10)


func test_self_syllabub_fires_normal_and_golden_counts_without_recursive_replay() -> void:
	for golden: bool in [false, true]:
		var spec: Dictionary = CK.u("frumenty", 10, 30, true)
		spec["grants"] = [
			{"entry": {"id": "syllabub", "times": 1, "pass3": true}, "golden": golden},
			{
				"entry":
				KIT.effect(
					"start_of_combat",
					{"effect": "buff", "attack": 3, "health": 0, "target": {"select": "self"}}
				),
				"golden": false
			}
		]
		var combat: Combat = _fight({0: _spec("little_dollop", [spec])}, {0: CK.plain(1, 100)})
		combat.unit_at(0, 0).take_damage(100)
		combat._resolve_deaths(0)
		assert_eq(combat.unit_at(0, 0).attack, 16 if golden else 13)


func test_duplicate_syllabubs_on_one_body_use_strongest_times_with_guard_off_counterexample(
) -> void:
	kit.card(
		"syllabub_borrowed_start",
		[
			KIT.effect(
				"start_of_combat",
				{"effect": "buff", "attack": 3, "health": 0, "target": {"select": "self"}}
			)
		],
		[],
		1,
		10
	)
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var spec: Dictionary = CK.u("frumenty", 10, 20, true)
		var entry: Dictionary = {"id": "syllabub", "times": 1, "pass3": true}
		spec["grants"] = [{"entry": entry, "golden": false}, {"entry": entry, "golden": true}]
		var combat: Combat = _fight(
			{0: _spec("little_dollop", [CK.u("syllabub_borrowed_start")]), 4: spec},
			{0: CK.plain(1, 100)}
		)
		combat.unit_at(0, 0).take_damage(100)
		combat._resolve_deaths(0)
		assert_eq(combat.unit_at(0, 0).attack, 7 if guarded else 10)
