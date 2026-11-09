# gdlint:disable=max-public-methods
extends GutTest
## Hasty and Granny have explicit dependencies, and only Hasty masks a ranked enemy pick.
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
	if start:
		combat._start_of_combat()
	return combat


func _hasty(golden: bool = false) -> Dictionary:
	var spec: Dictionary = CK.u("hasty_pudding", -1, -1, golden)
	spec["iid"] = 11
	return spec


func _own_params(unit: CombatUnit) -> Dictionary:
	return unit.params[unit.mechanic_ids.find("pass3_ooze")]


func test_hasty_swallows_biggest_anywhere_and_gives_own_biggest_ooze_a_permanent_fifth() -> void:
	var carry: Dictionary = CK.u("little_dollop", 60, 80)
	carry["iid"] = 12
	var combat: Combat = _fight({0: _hasty(), 4: carry}, {0: CK.plain(2, 2), 6: CK.plain(40, 50)})
	var hasty: CombatUnit = combat.unit_at(0, 0)
	assert_eq(hasty.inside.size(), 1)
	assert_eq([hasty.inside[0].attack, hasty.inside[0].health], [40, 50])
	assert_eq([combat.unit_at(0, 4).attack, combat.unit_at(0, 4).health], [68, 90])
	assert_eq(combat.carry[0]["iid"], 12)
	assert_eq([combat.carry[0]["attack"], combat.carry[0]["health"]], [8, 10])


func test_golden_hasty_swallows_two_and_does_not_double_the_share() -> void:
	var combat: Combat = _fight(
		{0: _hasty(true)}, {0: CK.plain(40, 50), 4: CK.plain(30, 40), 6: CK.plain(1, 1)}
	)
	var hasty: CombatUnit = combat.unit_at(0, 0)
	assert_eq(hasty.inside.size(), 2)
	assert_eq([hasty.attack, hasty.health], [20, 36])
	assert_eq(combat.carry.size(), 2)
	assert_eq(combat.carry[0]["attack"], 8)
	assert_eq(combat.carry[1]["attack"], 6)


func test_hasty_reads_body_stats_excluding_tribe_auras_and_combat_loans() -> void:
	var combat: Combat = _fight({0: _hasty()}, {0: CK.plain(40, 50), 6: CK.plain(1, 1)}, 1, false)
	var prey: CombatUnit = combat.unit_at(1, 0)
	prey.tribe_attack = 30
	prey.tribe_health = 30
	prey.add_combat(200, 300)
	prey.set_aura(20, 30)
	combat._start_of_combat()
	assert_eq([combat.carry[0]["attack"], combat.carry[0]["health"]], [8, 10])


func test_hasty_with_anything_inside_does_nothing_even_when_golden_has_room() -> void:
	var spec: Dictionary = _hasty(true)
	spec["held"] = [CK.plain(1, 1)]
	var combat: Combat = _fight({0: spec}, {0: CK.plain(40, 50), 6: CK.plain(1, 1)})
	assert_true(combat.unit_at(0, 0).inside.is_empty())
	assert_true(combat.carry.is_empty())


func test_hasty_sees_hidden_biggest_swallows_its_holder_and_reads_the_hidden_meal() -> void:
	var enemy: Dictionary = CK.u("little_dollop", 2, 3)
	enemy["held"] = [CK.plain(100, 120)]
	var combat: Combat = _fight({0: _hasty()}, {0: CK.plain(3, 3), 6: enemy})
	var hasty: CombatUnit = combat.unit_at(0, 0)
	assert_eq(hasty.inside[0].def_id(), "little_dollop")
	assert_eq(hasty.inside[0].held_specs.size(), 1)
	assert_eq([combat.carry[0]["attack"], combat.carry[0]["health"]], [20, 24])


func test_hasty_skips_a_full_fetch_twin_for_each_normal_and_golden_pick() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: _hasty(golden)},
			{
				0: "cradle_fetch",
				1: CK.u("hedge_witch", 10, 12),
				4: CK.u("rainbow_chaser", 100, 120),
				6: CK.plain(1, 1)
			},
			1,
			false
		)
		combat.slot_effects[1] = [
			[{"name": "Ring", "attack": 100, "health": 100}], [], [], [], [], [], []
		]
		combat._slots_active = true
		combat._recalc_auras(false)
		combat._start_of_combat()
		var hasty: CombatUnit = combat.unit_at(0, 0)
		assert_eq(hasty.inside.size(), 2 if golden else 1)
		assert_eq(hasty.inside[0].def_id(), "rainbow_chaser")
		assert_false(hasty.inside[0].copied_this_fight)
		if golden:
			assert_eq(hasty.inside[1].def_id(), "hedge_witch")
		var twin: CombatUnit = combat.unit_at(1, 0)
		assert_true(twin.copied_this_fight)
		assert_gte(twin.attack, 200, "a full twin plus its own Ring is bigger than the carry")


func test_golden_hasty_falls_back_to_copy_when_it_is_the_only_remaining_enemy() -> void:
	var combat: Combat = _fight(
		{0: _hasty(true)}, {0: CK.plain(40, 50), 6: CK.plain(200, 200)}, 1, false
	)
	combat.unit_at(1, 6).copied_this_fight = true
	combat._start_of_combat()
	var swallowed: Array[CombatUnit] = combat.unit_at(0, 0).inside
	# Empty enemy sides immediately get their prisoners back; inspect the ordered events instead.
	var events: Array = combat.events.filter(
		func(e: Dictionary) -> bool: return e["type"] == "swallowed"
	)
	assert_eq([events[0]["slot"], events[1]["slot"]], [0, 6])
	assert_true(swallowed.is_empty())


func test_hasty_releases_on_three_friendly_deaths_and_on_its_own_death() -> void:
	for own_death: bool in [false, true]:
		var combat: Combat = _fight(
			{0: _hasty(), 1: "drip", 2: "drip", 3: "drip"}, {0: CK.plain(40, 50), 6: CK.plain(1, 1)}
		)
		var hasty: CombatUnit = combat.unit_at(0, 0)
		var prisoner: CombatUnit = hasty.inside[0]
		if own_death:
			hasty.take_damage(1000)
			combat._resolve_deaths(0)
		else:
			for slot: int in [1, 2]:
				combat.unit_at(0, slot).take_damage(100)
				combat._resolve_deaths(0)
			assert_false(prisoner.on_board)
			combat.unit_at(0, 3).take_damage(100)
			combat._resolve_deaths(0)
		assert_eq(combat.unit_at(1, 0), prisoner)
		assert_true(hasty.inside.is_empty())


func test_granny_gathers_only_touching_oozes_and_golden_doubles_attack_only() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{
				0: CK.u("granny_stir_up", -1, -1, golden),
				4: CK.u("little_dollop", 10, 20),
				1: CK.plain(2, 2),
				5: CK.u("moss_ooze", 7, 9),
				3: "drip"
			},
			{0: CK.plain(1, 100)}
		)
		combat._start_of_combat()
		var granny: CombatUnit = combat.unit_at(0, 0)
		assert_eq(granny.inside.size(), 2, "non-Oozes keep the run connected but stay outside")
		assert_eq(granny.attack, 42 if golden else 21)
		assert_eq(granny.health, 16 if golden else 8)
		assert_not_null(combat.unit_at(0, 1))
		assert_not_null(combat.unit_at(0, 3), "the gap cuts off this Drip")


func test_granny_gathers_after_own_hasty_and_both_mirror_hasties_see_pre_gather_boards() -> void:
	for seed_value: int in 12:
		var board: Dictionary = {0: "granny_stir_up", 4: "hasty_pudding", 1: CK.u("drip", 40, 50)}
		var combat: Combat = _fight(board, board, seed_value)
		for side: int in 2:
			var granny: CombatUnit = combat.unit_at(side, 0)
			assert_not_null(granny)
			assert_eq(granny.inside.size(), 1)
			var hasty: CombatUnit = granny.inside[0]
			assert_eq(hasty.def_id(), "hasty_pudding")
			assert_eq(hasty.inside.size(), 1)
			assert_eq(hasty.inside[0].def_id(), "drip")


func test_granny_gathers_after_other_starts_and_stat_ranked_answers() -> void:
	kit.card(
		"ooze_attack_start",
		[
			KIT.effect(
				"start_of_combat",
				{"effect": "buff", "attack": 10, "health": 0, "target": {"select": "self"}}
			)
		],
		["Oozes"],
		10,
		10
	)
	kit.card(
		"ooze_biggest_answer",
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
	for seed_value: int in 8:
		var combat: Combat = _fight(
			{0: "granny_stir_up", 4: "ooze_attack_start"}, {0: "ooze_biggest_answer"}, seed_value
		)
		assert_eq(combat.unit_at(0, 0).attack, 14, "20 Attack halves before Granny gathers it")


func test_granny_has_cleave_on_normal_and_golden() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: CK.u("granny_stir_up", 10, 100, golden)},
			{0: CK.plain(0, 100), 1: CK.plain(0, 100), 2: CK.plain(0, 100)}
		)
		var granny: CombatUnit = combat.unit_at(0, 0)
		assert_true(granny.has_mechanic("cleave"))
		combat._attack(granny, combat.unit_at(1, 1))
		for slot: int in [0, 1, 2]:
			assert_eq(combat.unit_at(1, slot).health, 90)


func test_upset_audits_every_ooze_ability_and_masks_only_hasty() -> void:
	var manifest: Array = []
	var unsupported: Array = []
	for ability_name: String in UpsetCombat.AUDITED_OOZES:
		var entry: Dictionary = {"id": "pass3_ooze", "ability": ability_name, "factor": 1}
		var masked: Variant = UpsetCombat._walk(entry, "unit.mechanics[0]", manifest, unsupported)
		assert_eq(
			UpsetCombat.AUDITED_OOZES[ability_name], ability_name == "hasty_pudding", ability_name
		)
		if ability_name == "hasty_pudding":
			assert_null(masked, ability_name)
		else:
			assert_eq(masked, entry, ability_name)
	assert_true(unsupported.is_empty())
	assert_eq(manifest.size(), 1)
	UpsetCombat._walk(
		{"id": "pass3_ooze", "ability": "future_answer"}, "unit.mechanics[0]", manifest, unsupported
	)
	assert_eq(unsupported.size(), 1, "unseen variants remain unsupported")
