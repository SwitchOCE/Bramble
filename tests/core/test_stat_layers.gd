extends GutTest
## Stat layers (prototype-lessons section 4, rulebook 7.3.4, 12.1.1, 12.2.1): computed on read,
## independent of the order effects arrive in.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary


func before_all() -> void:
	_library = TestLibraries.current()


func _combat_unit(spec: Dictionary) -> CombatUnit:
	return CombatUnit.make(_library.get_unit(str(spec["def_id"])), spec, 1, 0)


func test_layers_add_up_on_read_12_1_1() -> void:
	var unit := RecruitUnit.make(_library.get_unit("hoglet_mother"), 1)
	unit.add_permanent(2, 3)
	unit.add_combat(1, 1)
	assert_eq([unit.attack, unit.health], [1 + 2 + 1, 3 + 3 + 1], "base + permanent + combat")
	unit.clear_combat_layer()
	assert_eq([unit.attack, unit.health], [3, 6], "the combat layer ends, the permanent stays")


func test_golden_doubles_only_the_base_7_3_4() -> void:
	var unit := RecruitUnit.make(_library.get_unit("hoglet_mother"), 1)
	unit.add_permanent(5, 5)
	unit.golden = true
	assert_eq([unit.attack, unit.health], [2 + 5, 6 + 5], "golden is computed from the flag")


func test_debuff_order_doesnt_matter_1_2_4() -> void:
	var one := RecruitUnit.make(_library.get_unit("hoglet_mother"), 1)
	one.add_combat(-5, 0)
	one.add_permanent(6, 0)
	var two := RecruitUnit.make(_library.get_unit("hoglet_mother"), 2)
	two.add_permanent(6, 0)
	two.add_combat(-5, 0)
	assert_eq(one.attack, two.attack, "either order, same Attack")
	one.add_combat(-50, 0)
	assert_eq(one.attack, 0, "Attack is never below 0")


func test_stat_clamp_on_read_1_2_4() -> void:
	var unit := RecruitUnit.make(_library.get_unit("hoglet_mother"), 1)
	unit.add_permanent(BoardUnit.STAT_CLAMP, BoardUnit.STAT_CLAMP)
	assert_eq([unit.attack, unit.health], [BoardUnit.STAT_CLAMP, BoardUnit.STAT_CLAMP], "clamped")


func test_assigning_stats_writes_the_permanent_layer() -> void:
	var unit := RecruitUnit.make(_library.get_unit("hoglet_mother"), 1)
	unit.attack += 3
	unit.health -= 1
	assert_eq([unit.perm_attack, unit.perm_health], [3, -1], "permanent layer")
	assert_eq([unit.attack, unit.health], [4, 2], "and the totals")


func test_damage_is_separate_from_max_health_9_6_3() -> void:
	var unit: CombatUnit = _combat_unit({"def_id": "hoglet_mother"})
	unit.take_damage(2)
	assert_eq([unit.health, unit.max_health], [1, 3], "damage lowers current Health only")
	assert_false(unit.is_undamaged(), "damaged now")
	unit.add_combat(0, 2)
	assert_eq([unit.health, unit.max_health], [3, 5], "a Health buff raises both")


func test_health_loss_is_not_damage_entry_75() -> void:
	var unit: CombatUnit = _combat_unit({"def_id": "hoglet_mother"})
	unit.lose_health(1)
	assert_eq(unit.health, 2, "Health went down")
	assert_true(unit.is_undamaged(), "but it isn't damage")


func test_losing_a_health_aura_never_kills_12_2_1() -> void:
	var unit: CombatUnit = _combat_unit({"def_id": "hoglet_mother"})
	unit.set_aura(1, 4)
	assert_eq([unit.attack, unit.health, unit.max_health], [2, 7, 7], "aura on")
	unit.take_damage(6)
	unit.set_aura(0, 0)
	assert_eq([unit.attack, unit.health, unit.max_health], [1, 1, 3], "aura off, Health at least 1")


func test_losing_a_health_aura_keeps_health_that_still_fits_12_2_1() -> void:
	var unit: CombatUnit = _combat_unit({"def_id": "hoglet_mother"})
	unit.set_aura(0, 4)
	unit.take_damage(1)
	unit.set_aura(0, 0)
	assert_eq([unit.health, unit.max_health], [3, 3], "6 of 7 becomes 3 of 3")


func test_board_stats_become_the_permanent_layer_9_1_1() -> void:
	var unit: CombatUnit = _combat_unit({"def_id": "hoglet_mother", "attack": 9, "health": 2})
	assert_eq([unit.attack, unit.health, unit.max_health], [9, 2, 2], "the board's numbers")
	assert_eq([unit.perm_attack, unit.perm_health], [8, -1], "stored as the permanent layer")


func test_recruit_buff_for_the_next_combat_reaches_it_12_1_1() -> void:
	var recruit := RecruitUnit.make(_library.get_unit("hoglet_mother"), 7)
	recruit.add_combat(2, 1)
	var fighter: CombatUnit = _combat_unit(recruit.combat_spec())
	assert_eq([fighter.attack, fighter.health], [3, 4], "the combat layer is copied")
	assert_eq(fighter.iid, 7, "knows its recruit unit")


func test_stopped_query_9_4_5() -> void:
	var unit: CombatUnit = _combat_unit({"def_id": "hoglet_mother"})
	assert_false(unit.is_stopped(), "not yet")
	unit.statuses["stalled"] = {}
	assert_true(unit.is_stopped(), "Pin stops it")
