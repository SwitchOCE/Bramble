extends GutTest
## Full Fetch plus its own Ring must not screen the original carry from stat answers.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
const STAT_PICKS: Array[String] = ["biggest", "highest_attack", "highest_health"]
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup()
	kit.config.set_value("pass3_content", true)
	kit.config.set_value("pass3_loop_guards", true)
	kit.config.set_value("fairies_fetch_share", 1.0)
	kit.card("copy_carry", [], ["Fairies"], 100, 200)


func _fight(mine: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	return combat


func _ring(combat: Combat, slot: int, amount: int) -> void:
	var rows: Array = combat.slot_effects[1]
	if rows.is_empty():
		for _slot: int in 7:
			rows.append([])
	var effects: Array = rows[slot]
	effects.append(
		{"name": "Ring", "count": amount, "ring_size": 1.0, "attack": amount, "health": amount}
	)
	combat._slots_active = true


func _twins(
	source_id: String = "field_vole",
	golden: bool = false,
	second_original: bool = false,
	copy_now: bool = true
) -> Combat:
	var theirs: Dictionary = {0: CK.u("cradle_fetch", -1, -1, golden), 4: "copy_carry"}
	if second_original:
		theirs[5] = CK.u("copy_carry", 80, 150)
	var combat: Combat = _fight({0: source_id}, theirs)
	_ring(combat, 0, 100)
	_ring(combat, 4, 20)
	combat._recalc_auras(false)
	if copy_now:
		Pass3FairyCombat.start(combat, combat.unit_at(1, 0), "fetch")
	return combat


func _world(combat: Combat, side: int = 0) -> CombatWorld:
	return CombatWorld.make(combat, combat.unit_at(side, 0), side, {}, "start_of_combat")


func _pick(combat: Combat, how: String, select: String = "enemies") -> Array[BoardUnit]:
	return TargetSelect.pick({"select": select, "pick": how}, _world(combat))


func _mechanic(unit: CombatUnit, id: String) -> Mechanic:
	return unit.scripts[unit.mechanic_ids.find(id)]


func _kill(combat: Combat, unit: CombatUnit) -> void:
	unit.take_damage(unit.health)
	combat._resolve_deaths(unit.side)


func test_full_normal_and_golden_twin_is_bigger_but_each_enemy_stat_pick_hits_original() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _twins("field_vole", golden)
		var copy: CombatUnit = combat.unit_at(1, 0)
		var original: CombatUnit = combat.unit_at(1, 4)
		assert_eq([original.attack, original.health], [120, 220])
		assert_eq([copy.attack, copy.health], [220, 320], "full Fairy plus Fetch's own Ring")
		assert_eq(copy.golden, golden)
		assert_true(copy.copied_this_fight)
		assert_false(original.copied_this_fight)
		for how: String in STAT_PICKS:
			assert_eq(_pick(combat, how), [original], how)
			assert_eq(
				TargetSelect.pick({"select": "enemies", "pick": how, "count": 7}, _world(combat)),
				[original],
				"copies do not fill a larger count while an original remains: " + how
			)
			if golden:
				assert_eq(
					TargetSelect.pick(
						{"select": "enemies", "pick": how, "golden": true}, _world(combat)
					),
					[copy],
					"non-golden originals cannot block a golden-only pick: " + how
				)


func test_each_stat_pick_removes_original_candidates_before_falling_back_to_copy() -> void:
	for how: String in STAT_PICKS:
		for golden: bool in [false, true]:
			var combat: Combat = _twins("field_vole", golden, true)
			var copy: CombatUnit = combat.unit_at(1, 0)
			var first: CombatUnit = combat.unit_at(1, 4)
			var second: CombatUnit = combat.unit_at(1, 5)
			assert_eq(_pick(combat, how), [first], how)
			_kill(combat, first)
			assert_eq(_pick(combat, how), [second], how)
			_kill(combat, second)
			assert_eq(_pick(combat, how), [copy], "only the copy remains: " + how)


func test_native_whistle_skips_copy_then_uses_it_when_all_originals_are_warned() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _twins("marmot_lookout", golden)
		var source: CombatUnit = combat.unit_at(0, 0)
		var copy: CombatUnit = combat.unit_at(1, 0)
		var original: CombatUnit = combat.unit_at(1, 4)
		var whistle: Mechanic = _mechanic(source, "whistle")
		whistle.choose_turn_action(combat, source, {})
		assert_true(original.has_status("warned"))
		assert_false(copy.has_status("warned"))
		whistle.choose_turn_action(combat, source, {})
		assert_true(copy.has_status("warned"), "warned originals are no longer eligible")


func test_native_highest_health_marks_only_original_then_falls_back_to_twin() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _twins("belladonna_sprite", golden)
		var source: CombatUnit = combat.unit_at(0, 0)
		var copy: CombatUnit = combat.unit_at(1, 0)
		var original: CombatUnit = combat.unit_at(1, 4)
		var marker: Mechanic = _mechanic(source, "nightshade_mark")
		marker.on_start_of_combat(combat, source, {"count": 2})
		assert_true(original.has_status("nightshade"))
		assert_false(copy.has_status("nightshade"), "a count of two does not fill with copies")
		marker.on_start_of_combat(combat, source, {"count": 2})
		assert_true(copy.has_status("nightshade"), "already marked originals are ineligible")


func test_lantern_snap_prefers_original_only_within_its_mired_candidates() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _twins("lantern_man", golden)
		var source: CombatUnit = combat.unit_at(0, 0)
		var copy: CombatUnit = combat.unit_at(1, 0)
		var original: CombatUnit = combat.unit_at(1, 4)
		var snap: Mechanic = _mechanic(source, "snap")
		combat.set_status(copy, "mired", true, source)
		combat.set_status(original, "mired", true, source)
		assert_eq(snap.attack_target(combat, source, {}), original)
		combat.set_status(original, "mired", false, source)
		assert_eq(
			snap.attack_target(combat, source, {}), copy, "non-Mired originals cannot block Snap"
		)
		combat.set_status(copy, "mired", false, source)
		assert_null(snap.attack_target(combat, source, {}), "Snap gains no reach outside Mire")


func test_native_and_data_scale_answers_hit_original_after_fetch_for_both_strengths() -> void:
	kit.config.set_value("scale_levers", ["scale_answer", "scale_biggest_answer"])
	kit.config.set_value("scale_answer_percent", 50)
	kit.library = ScaleOverlay.library_for(kit.library, kit.config)
	for source_id: String in ["scale_answer", "scale_biggest_answer"]:
		for golden: bool in [false, true]:
			var combat: Combat = _twins(source_id, golden, false, false)
			combat._start_of_combat()
			var copy: CombatUnit = combat.unit_at(1, 0)
			var original: CombatUnit = combat.unit_at(1, 4)
			assert_true(copy.copied_this_fight)
			assert_eq([copy.attack, copy.health], [220, 320], source_id)
			assert_eq([original.attack, original.health], [60, 110], source_id)


func test_friendly_biggest_all_enemy_and_positional_selection_keep_copy() -> void:
	var combat: Combat = _twins()
	var copy: CombatUnit = combat.unit_at(1, 0)
	var original: CombatUnit = combat.unit_at(1, 4)
	for how: String in STAT_PICKS:
		assert_eq(
			TargetSelect.pick({"select": "friendly", "pick": how}, _world(combat, 1)), [copy], how
		)
		assert_eq(_pick(combat, how, "enemy_front_row"), [copy], "front reach remains: " + how)
	assert_eq(Pass3Combat.biggest(combat.units_of(1)), [copy], "native friendly biggest unchanged")
	assert_eq(TargetSelect.pick({"select": "enemies"}, _world(combat)), [copy, original])
	assert_eq(TargetSelect.pick({"select": "across"}, _world(combat)), [copy])
	assert_eq(CombatLanes.normal_targets(combat, combat.unit_at(0, 0)), [copy])
	EffectRunner.run_step(
		{"effect": "buff", "target": {"select": "enemies"}, "attack": -1}, {}, _world(combat)
	)
	assert_eq([copy.attack, original.attack], [219, 119], "all-enemy effects still hit both")
	var hob: CombatUnit = combat.summon_into("hob_in_the_hearth", false, 1, 2, original)
	Pass3FairyCombat.start(combat, hob, "hob")
	assert_true(copy.has_status("shield"), "friendly Hob still protects the bigger twin")
	assert_false(original.has_status("shield"))


func test_seven_whistlers_across_and_all_enemy_effects_still_hit_copies() -> void:
	var combat: Combat = _twins("seven_whistlers")
	var source: CombatUnit = combat.unit_at(0, 0)
	var copy: CombatUnit = combat.unit_at(1, 0)
	var original: CombatUnit = combat.unit_at(1, 4)
	Pass3BirdCombat.start(combat, source, "whistlers")
	assert_eq([copy.attack, copy.health], [110, 160], "across still hits the copy")
	assert_eq([original.attack, original.health], [120, 220])
	kit.config.set_value("birds_whistlers_flock_count", 1)
	Pass3BirdCombat.start(combat, source, "whistlers")
	assert_eq([copy.attack, copy.health], [55, 80], "all-enemy branch includes the copy")
	assert_eq([original.attack, original.health], [60, 110])


func test_ordinary_summons_held_releases_and_recruit_copies_remain_original_candidates() -> void:
	var combat: Combat = _twins()
	var copy: CombatUnit = combat.unit_at(1, 0)
	var summoned: CombatUnit = combat.enter_from_spec(CK.u("copy_carry", 500, 500), 1, 1, copy)
	assert_false(summoned.copied_this_fight)
	assert_eq(_pick(combat, "biggest"), [summoned])
	copy.held_specs.append(CK.u("copy_carry", 700, 700))
	var released: CombatUnit = CombatHeld.pop_one(combat, copy, false)
	assert_false(released.copied_this_fight)
	assert_eq(_pick(combat, "biggest"), [released])
	var recruit_copy := RecruitUnit.make(kit.library.get_unit("copy_carry"), 98)
	recruit_copy.plain_copy = true
	combat = _fight({0: "field_vole"}, {0: recruit_copy.combat_spec()})
	assert_false(combat.unit_at(1, 0).copied_this_fight)
	assert_eq(_pick(combat, "biggest"), [combat.unit_at(1, 0)])


func test_copy_marker_survives_swallow_release_and_resets_on_next_fight() -> void:
	var combat: Combat = _twins()
	var copy: CombatUnit = combat.unit_at(1, 0)
	var original: CombatUnit = combat.unit_at(1, 4)
	CombatHeld.swallow(combat, original, copy)
	assert_true(copy.copied_this_fight)
	assert_eq(_pick(combat, "biggest"), [original], "hidden copied fighters remain excluded")
	CombatHeld.return_inside(combat, original)
	assert_true(copy.copied_this_fight)
	assert_eq(_pick(combat, "biggest"), [original])
	var next_spec: Dictionary = copy.view()
	assert_false(next_spec.has("copied_this_fight"), "marker is not serialized")
	combat = _fight({0: "field_vole"}, {0: next_spec, 4: "copy_carry"})
	assert_false(combat.unit_at(1, 0).copied_this_fight)
	assert_eq(_pick(combat, "biggest"), [combat.unit_at(1, 0)], "new fight has no stale exclusion")


func test_legacy_copy_path_is_unmarked_without_changing_legacy_event_shape() -> void:
	for enabled: bool in [false, true]:
		var combat: Combat = _fight({0: "field_vole"}, {0: "field_vole", 4: "copy_carry"})
		combat.notes["test_pass3_start_order"] = enabled
		CombatMoves.become_copy(combat, combat.unit_at(1, 0), combat.unit_at(1, 4), 0)
		assert_false(combat.unit_at(1, 0).copied_this_fight)
		assert_eq(_pick(combat, "highest_health"), [combat.unit_at(1, 0)])
		var copied_events: Array[Dictionary] = combat.events.filter(
			func(event: Dictionary) -> bool: return event.has("copied")
		)
		assert_eq(copied_events.size(), 1 if enabled else 0)
