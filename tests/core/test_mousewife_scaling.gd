extends GutTest
## Tier supplies printed points; replacement Mice use the surviving board's corresponding stats.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/combat_kit.gd")


func _fight(config: GameConfig, allies: Dictionary, tier: int = 3) -> Combat:
	var library := TestLibraries.current()
	var combat := Combat.create(library, config, RandomNumberGenerator.new())
	combat._tiers = [tier, 1]
	combat.hero_effects[0] = HeroRules.effects_of(library.get_hero("old_mother_mousewife"))
	combat._setup([KIT.board(allies), KIT.board({0: KIT.plain(1, 1000)})])
	combat._recalc_auras(false)
	return combat


func _kill(combat: Combat, slot: int) -> void:
	var unit: CombatUnit = combat.unit_at(0, slot)
	combat.deal_effect_damage(null, unit, unit.health)
	combat._resolve_deaths(0)


func test_mouse_stats_scale_per_tier_point_with_json_presets_and_overrides() -> void:
	for sample: Array in [["B", 0, 30, 60], ["C", 0, 60, 120], ["B", 25, 75, 150]]:
		var config := GameConfig.full_game()
		config.set_value("pass3_preset", sample[0])
		if sample[1] != 0:
			config.set_value("scale_hero_spell_percent", sample[1])
		var combat: Combat = _fight(config, {0: KIT.plain(9999, 1), 4: KIT.plain(100, 200)})
		_kill(combat, 0)
		var mouse: CombatUnit = combat.unit_at(0, 0)
		assert_eq(mouse.def_id(), "mouse")
		assert_eq([mouse.attack, mouse.health], [sample[2], sample[3]], str(sample))
		var events: Array[Dictionary] = KIT.of_type({"events": combat.events}, "summon")
		assert_eq(
			events[0]["unit"]["attack"], sample[2], "the summon event contains the scaled stats"
		)
		assert_eq(events[0]["unit"]["health"], sample[3])


func test_living_board_average_excludes_the_dying_unit_and_rounds_before_scaling() -> void:
	var combat: Combat = _fight(
		GameConfig.full_game(),
		{0: KIT.plain(9999, 1), 4: KIT.plain(101, 203), 5: KIT.plain(200, 400)}
	)
	_kill(combat, 0)
	var mouse: CombatUnit = combat.unit_at(0, 0)
	assert_eq([mouse.attack, mouse.health], [45, 90], "average 150/301, then 30%, rounded down")


func test_last_unit_death_and_small_boards_keep_the_tier_floor() -> void:
	for allies: Dictionary in [
		{0: KIT.plain(9999, 1)}, {0: KIT.plain(9999, 1), 4: KIT.plain(1, 2)}
	]:
		var combat: Combat = _fight(GameConfig.full_game(), allies)
		_kill(combat, 0)
		var mouse: CombatUnit = combat.unit_at(0, 0)
		assert_eq([mouse.attack, mouse.health], [3, 3])


func test_explicit_comparison_off_and_legacy_off_keep_original_tier_stats() -> void:
	var comparison := GameConfig.full_game()
	comparison.set_value("scale_hero_spell_stats", false)
	for config: GameConfig in [comparison, GameConfig.defaults()]:
		var combat: Combat = _fight(config, {0: KIT.plain(9999, 1), 4: KIT.plain(100, 200)})
		_kill(combat, 0)
		var mouse: CombatUnit = combat.unit_at(0, 0)
		assert_eq([mouse.attack, mouse.health], [3, 3])


func test_twice_a_fight_and_no_mouse_replacement_guards_remain() -> void:
	var combat: Combat = _fight(
		GameConfig.full_game(),
		{0: KIT.plain(1, 1), 1: KIT.plain(1, 1), 2: KIT.plain(1, 1), 4: KIT.plain(100, 200)}
	)
	_kill(combat, 0)
	_kill(combat, 0)
	assert_null(combat.unit_at(0, 0), "a Mouse cannot replace itself before the limit is spent")
	_kill(combat, 1)
	_kill(combat, 2)
	assert_null(combat.unit_at(0, 2), "only two front-row deaths receive Mice")
	assert_eq(KIT.of_type({"events": combat.events}, "summon").size(), 2)
