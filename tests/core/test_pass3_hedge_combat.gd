# gdlint:disable=max-public-methods
extends GutTest
## Fixed boards exercise native normal/golden Hedgerow combat and their targeting boundaries.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())


func _fight(
	mine: Dictionary, theirs: Dictionary, ammo: Array = [], opening: bool = false
) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var combat := Combat.create(kit.library, kit.config, rng)
	combat.side_rules = [{"ammo": ammo.duplicate()}, {}]
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat._recalc_auras(false)
	if opening:
		combat._start_of_combat()
	return combat


func _hit(
	combat: Combat,
	source: CombatUnit,
	target: CombatUnit,
	kind: String = Hit.ATTACK,
	defending: bool = true,
	amount: int = 9
) -> Hit:
	var hit: Hit = Hit.make(source, target, amount, kind)
	hit.on_defender = defending
	combat._apply_hits([hit])
	return hit


func _spends(combat: Combat) -> Array:
	var result: Array = []
	for change: Dictionary in combat.carry:
		if str(change["op"]) == "spend_item":
			result.append(change["gold"])
	return result


func test_urchin_has_native_body_and_normal_golden_bristle_without_the_old_pass() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: CK.u("dr_urchin", 0, 30, golden), 4: CK.u("kit", 1, 20)}, {0: CK.u("drip", 2, 20)}
		)
		var doctor: CombatUnit = combat.unit_at(0, 0)
		assert_eq(
			[doctor.base_attack_now(), doctor.base_health_now()], [4, 10] if golden else [2, 5]
		)
		combat._attack(combat.unit_at(1, 0), doctor)
		assert_eq(combat.unit_at(1, 0).health, 16 if golden else 18)
		assert_eq(combat.unit_at(0, 4).attack, 1, "native Bristle no longer Passes Attack")


func test_urchin_protects_last_other_hedgerow_across_gaps_and_ignores_other_tribes() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{3: CK.u("dr_urchin", -1, -1, golden), 5: "kit", 6: "kit", 2: "drip"}, {}
		)
		assert_true(combat.unit_at(0, 6).has_status("hunker"))
		assert_eq(combat.unit_at(0, 5).has_status("hunker"), golden)
		assert_false(combat.unit_at(0, 3).has_status("hunker"), "the source never picks itself")
		assert_false(combat.unit_at(0, 2).has_status("hunker"))


func test_urchin_alone_has_no_hunker_target() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight({3: CK.u("dr_urchin", -1, -1, golden)}, {})
		assert_false(combat.unit_at(0, 3).has_status("hunker"))


func test_hunker_halves_only_incoming_defending_attack_damage_rounded_up() -> void:
	for kind: String in [Hit.ATTACK, Hit.EFFECT, Hit.THORNS]:
		for defending: bool in [false, true]:
			var combat: Combat = _fight(
				{0: "dr_urchin", 3: CK.u("kit", 1, 100)}, {0: CK.u("drip", 1, 100)}
			)
			var hit: Hit = _hit(combat, combat.unit_at(1, 0), combat.unit_at(0, 3), kind, defending)
			assert_eq(hit.amount, 5 if kind == Hit.ATTACK and defending else 9)


func test_hunker_does_not_stack_with_intrinsic_hunker() -> void:
	var spec: Dictionary = CK.u("kit", 1, 100)
	spec["grants"] = [{"entry": {"id": "hunker"}, "golden": false}]
	var combat: Combat = _fight({0: "dr_urchin", 3: spec}, {0: CK.u("drip", 1, 100)})
	var hit: Hit = _hit(combat, combat.unit_at(1, 0), combat.unit_at(0, 3))
	assert_eq(hit.amount, 5)
	assert_eq(hit.modifiers.count("hunker"), 1)


func test_hunker_retargets_when_the_last_unit_dies_and_ends_when_urchin_dies() -> void:
	var combat: Combat = _fight({0: "dr_urchin", 3: "kit", 6: CK.u("kit", 1, 100)}, {})
	var last: CombatUnit = combat.unit_at(0, 3)
	var next: CombatUnit = combat.unit_at(0, 6)
	last.take_damage(1000)
	combat._resolve_deaths(0)
	assert_false(last.has_status("hunker"))
	assert_true(next.has_status("hunker"))
	combat.unit_at(0, 0).take_damage(1000)
	combat._resolve_deaths(0)
	assert_false(next.has_status("hunker"))


func test_hunker_follows_relocation_and_new_last_summon_and_cleans_departed_targets() -> void:
	var combat: Combat = _fight({0: "dr_urchin", 6: "kit"}, {3: "drip"})
	var earlier: CombatUnit = combat.unit_at(0, 6)
	var summoned: CombatUnit = combat.summon_into("kit", false, 0, 3, combat.unit_at(0, 0))
	assert_false(earlier.has_status("hunker"))
	assert_true(summoned.has_status("hunker"))
	CombatMoves.trade_sides(combat, combat.unit_at(0, 0), combat.unit_at(1, 3))
	assert_false(summoned.has_status("hunker"), "the aura follows its source's current side")


func test_overlapping_urchins_keep_protection_until_the_last_source_leaves() -> void:
	var combat: Combat = _fight({0: "dr_urchin", 1: "dr_urchin", 3: "kit"}, {})
	var target: CombatUnit = combat.unit_at(0, 3)
	combat.unit_at(0, 0).take_damage(1000)
	combat._resolve_deaths(0)
	assert_true(target.has_status("hunker"))
	combat.unit_at(0, 1).take_damage(1000)
	combat._resolve_deaths(0)
	assert_false(target.has_status("hunker"))


func test_hunker_stops_while_urchin_is_inside_and_returns_when_he_comes_out() -> void:
	var combat: Combat = _fight({0: "dr_urchin", 3: "kit"}, {0: "drip"})
	var doctor: CombatUnit = combat.unit_at(0, 0)
	var target: CombatUnit = combat.unit_at(0, 3)
	var holder: CombatUnit = combat.unit_at(1, 0)
	CombatHeld.swallow(combat, holder, doctor)
	assert_false(target.has_status("hunker"))
	CombatHeld.return_inside(combat, holder)
	assert_true(target.has_status("hunker"))


func test_hunker_text_theft_moves_protection_to_the_thiefs_current_side() -> void:
	var combat: Combat = _fight({0: "dr_urchin", 3: "kit"}, {0: "drip", 3: "kit"})
	CombatHeld.steal_text(combat, combat.unit_at(1, 0), combat.unit_at(0, 0))
	assert_false(combat.unit_at(0, 3).has_status("hunker"))
	assert_true(combat.unit_at(1, 3).has_status("hunker"))


func test_stealing_a_protected_units_text_does_not_steal_its_borrowed_aura() -> void:
	var combat: Combat = _fight({0: "dr_urchin", 3: "mr_crumb"}, {0: "drip"})
	CombatHeld.steal_text(combat, combat.unit_at(1, 0), combat.unit_at(0, 3))
	assert_true(combat.unit_at(0, 3).has_status("hunker"))
	assert_false(combat.unit_at(1, 0).has_status("hunker"))


func test_clover_uses_current_source_stats_and_golden_share_without_a_limit() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight({0: CK.u("mrs_clover", 7, 11, golden)}, {})
		var clover: CombatUnit = combat.unit_at(0, 0)
		clover.take_damage(2)
		combat.buff(clover, 2, 3, clover)
		for slot: int in [1, 2, 3]:
			var kit_unit: CombatUnit = combat.summon_into("kit", false, 0, slot, clover)
			assert_eq([kit_unit.attack, kit_unit.health], [19, 25] if golden else [10, 13])
		assert_true(combat.carry.is_empty(), "summoned gains are only for this fight")


func test_clover_fraction_dial_floors_each_current_stat_and_reads_ring_aura() -> void:
	kit.config.set_value("hedgerow_clover_share", 0.5)
	kit.setup(kit.config)
	var combat: Combat = _fight({0: CK.u("mrs_clover", 5, 7)}, {})
	combat.slot_effects = [[[{"name": "Ring", "attack": 2, "health": 2}]], []]
	combat._slots_active = true
	combat._recalc_auras(false)
	var summoned: CombatUnit = combat.summon_into("kit", false, 0, 3, combat.unit_at(0, 0))
	assert_eq([summoned.attack, summoned.health], [4, 5])


func test_clover_ignores_offtribe_and_enemy_summons_and_dead_sources() -> void:
	var combat: Combat = _fight({0: CK.u("mrs_clover", 20, 30)}, {})
	var clover: CombatUnit = combat.unit_at(0, 0)
	var offtribe: CombatUnit = combat.summon_into("drip", false, 0, 1, clover)
	var enemy: CombatUnit = combat.summon_into("kit", false, 1, 0, clover)
	assert_eq([offtribe.attack, offtribe.health], [1, 1])
	assert_eq([enemy.attack, enemy.health], [1, 1])
	clover.take_damage(1000)
	var summoned: CombatUnit = combat.summon_into("kit", false, 0, 3, clover)
	assert_eq([summoned.attack, summoned.health], [1, 1])


func test_sorrel_normal_golden_summon_plain_tokens_and_denied_space_spills() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: CK.u("mrs_sorrel", 1, 100, golden)}, {0: CK.u("drip", 0, 100)}
		)
		combat._attack(combat.unit_at(0, 0), combat.unit_at(1, 0))
		var token: CombatUnit = combat.unit_at(0, 4)
		assert_eq(token.def_id(), "shrewlet")
		assert_eq([token.attack, token.health], [1, 1])
		assert_false(token.golden)
		var spills: Array = CK.of_type({"events": combat.events}, "spill")
		assert_eq(spills.size(), 1 if golden else 0)


func test_backrow_sorrel_spills_each_attempt_and_clover_cannot_buff_a_denied_body() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{0: "mrs_clover", 4: CK.u("mrs_sorrel", 1, 100, golden)}, {0: CK.u("drip", 0, 100)}
		)
		combat._attack(combat.unit_at(0, 4), combat.unit_at(1, 0))
		assert_eq(CK.of_type({"events": combat.events}, "spill").size(), 2 if golden else 1)
		assert_eq(combat.units_of(0).size(), 2)


func test_sergeant_throws_the_smallest_item_across_and_only_spends_one() -> void:
	var combat: Combat = _fight(
		{5: "sergeant_at_conkers"},
		{0: CK.u("drip", 900, 900), 5: CK.u("drip", 99, 101)},
		[1, 5, 16],
		true
	)
	assert_eq([combat.unit_at(1, 5).attack, combat.unit_at(1, 5).health], [90, 91])
	assert_eq([combat.unit_at(1, 0).attack, combat.unit_at(1, 0).health], [900, 900])
	assert_eq(_spends(combat), [1])


func test_golden_sergeant_takes_two_sequential_current_stat_shares_without_doubling_share() -> void:
	var combat: Combat = _fight(
		{0: CK.u("sergeant_at_conkers", -1, -1, true)},
		{0: CK.u("drip", 100, 101)},
		[5, 5, 16],
		true
	)
	assert_eq([combat.unit_at(1, 0).attack, combat.unit_at(1, 0).health], [25, 26])
	assert_eq(_spends(combat), [5, 5])


func test_sergeant_no_enemy_or_ammo_spends_nothing_and_golden_one_item_only_throws_once() -> void:
	for golden: bool in [false, true]:
		var mine: Dictionary = {5: CK.u("sergeant_at_conkers", -1, -1, golden)}
		assert_true(_spends(_fight(mine, {0: "drip"}, [5], true)).is_empty())
		assert_true(_spends(_fight(mine, {5: "drip"}, [], true)).is_empty())
		var combat: Combat = _fight(mine, {5: CK.u("drip", 100, 100)}, [5], true)
		assert_eq(_spends(combat), [5])
		assert_eq([combat.unit_at(1, 5).attack, combat.unit_at(1, 5).health], [50, 50])


func test_sergeant_hoard_clamps_at_zero_attack_one_health_and_shares_ammo_between_sources() -> void:
	var combat: Combat = _fight(
		{0: "sergeant_at_conkers", 1: CK.u("sergeant_at_conkers", -1, -1, true)},
		{0: CK.u("drip", 100, 100), 1: CK.u("drip", 100, 100)},
		[1, 16],
		true
	)
	assert_eq([combat.unit_at(1, 0).attack, combat.unit_at(1, 0).health], [90, 90])
	assert_eq([combat.unit_at(1, 1).attack, combat.unit_at(1, 1).health], [0, 1])
	assert_eq(_spends(combat), [1, 16])


func test_sergeant_carry_consumes_actual_items_after_the_fight() -> void:
	kit.put("sergeant_at_conkers", 0, true)
	kit.rules.give_card(kit.player, "great_hoard")
	kit.rules.give_card(kit.player, "stash")
	kit.rules.give_card(kit.player, "acorn")
	kit.fight_board({0: CK.u("drip", 0, 100)})
	assert_eq(kit.item_ids(), ["great_hoard"])


func test_borrowed_clover_uses_strongest_once_on_every_summon_with_guard_off_counterexample(
) -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var spec: Dictionary = CK.u("mrs_clover", 7, 11)
		spec["grants"] = [
			{
				"entry":
				{"id": "pass3_hedgerow", "ability": "mrs_clover", "factor": 1, "share": 1.0},
				"golden": true
			}
		]
		var combat: Combat = _fight({0: spec}, {})
		for slot: int in [1, 2, 3]:
			var summoned: CombatUnit = combat.summon_into(
				"kit", false, 0, slot, combat.unit_at(0, 0)
			)
			assert_eq([summoned.attack, summoned.health], [15, 23] if guarded else [22, 34])


func test_borrowed_sergeant_uses_strongest_once_and_can_replay_with_guard_off_counterexample(
) -> void:
	for guarded: bool in [true, false]:
		kit.config.set_value("pass3_loop_guards", guarded)
		var spec: Dictionary = CK.u("sergeant_at_conkers")
		spec["grants"] = [
			{
				"entry":
				{
					"id": "pass3_hedgerow",
					"ability": "sergeant_at_conkers",
					"factor": 1,
					"throws": 1,
					"share_per_gold": 0.1
				},
				"golden": true
			}
		]
		var combat: Combat = _fight(
			{0: spec}, {0: CK.u("drip", 10000, 10000)}, [1, 1, 1, 1, 1, 1], true
		)
		assert_eq(_spends(combat).size(), 2 if guarded else 3)
		CombatHeld.start_again(combat, combat.unit_at(0, 0))
		assert_eq(_spends(combat).size(), 4 if guarded else 6)


func test_hedgerow_native_audit_preserves_all_sixteen_and_rejects_unknown_abilities() -> void:
	var input: Dictionary = {"config": kit.config._values.duplicate(true)}
	var prepared: Dictionary = UpsetCombat.prepare(input, kit.library)
	assert_true(prepared["supported"], str(prepared["unsupported"]))
	var masked: UnitLibrary = prepared["library"]
	var observed: Dictionary = {}
	for card: Dictionary in kit.library.all_units():
		for entry: Dictionary in card.get("mechanics", []):
			if str(entry.get("id", "")) != "pass3_hedgerow":
				continue
			var name: String = str(entry["ability"])
			observed[name] = true
			assert_true(UpsetCombat.AUDITED_HEDGEROW.has(name), name)
			assert_false(UpsetCombat.AUDITED_HEDGEROW[name], name)
			assert_eq(masked.get_unit(str(card["id"]))["mechanics"], card["mechanics"], name)
	assert_eq(observed.size(), 16)
	var changed: Dictionary = kit.library.get_unit("dr_urchin").duplicate(true)
	changed["mechanics"].append({"id": "pass3_hedgerow", "ability": "future_hedge", "factor": 1})
	kit.library.register_unit(changed)
	assert_false(UpsetCombat.prepare(input, kit.library)["supported"])
