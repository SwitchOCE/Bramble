extends GutTest
## Known answers for the test-only Choose One reference. Values below are preset B.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_setup()


func _setup(preset: String = "B", sizes: bool = true, rates: bool = true) -> void:
	var config := GameConfig.full_game()
	config.set_value("reference_quilboar", true)
	config.set_value("quilboar_ref_preset", preset)
	config.set_value("card_size_caps", sizes)
	config.set_value("card_rate_limits", rates)
	_kit = KIT.new()
	_kit.setup(config)
	_kit.library = _kit.rules.library
	_player = _kit.player
	_rules = _kit.rules
	_rules.start_phase(_player, 1)


func _size() -> Vector2i:
	return Vector2i(_player.gem_attack_halves, _player.gem_health_halves)


func _gem(target: RecruitUnit, count: int = 1) -> void:
	var ctx := RecruitContext.make(_rules, _player, "reference_test", {"chosen": target})
	EffectRunner.run_step(
		{"effect": "gem", "count": count, "target": {"select": "chosen"}}, {}, ctx
	)


func _choose_unit(id: String, slot: int, mode: int = 0) -> RecruitUnit:
	var unit: RecruitUnit = _kit.play(id, slot)
	assert_true(_player.is_choosing(), "Choose One uses the pending choice action")
	assert_eq(_rules.choose(_player, mode), "")
	return unit


func test_size_changes_only_future_gems_and_rounds_each_gem_up_separately() -> void:
	var target: RecruitUnit = _kit.put("qb_gem_rat", 0)
	var before := Vector2i(target.attack, target.health)
	_gem(target)
	assert_eq(Vector2i(target.attack, target.health), before + Vector2i.ONE)
	ReferenceQuilboar.gem_size_add(_player, 1, 3)
	assert_eq(_size(), Vector2i(3, 5))
	assert_eq(Vector2i(target.attack, target.health), before + Vector2i.ONE, "no retroactive gain")
	_gem(target, 2)
	assert_eq(Vector2i(target.attack, target.health), before + Vector2i(5, 7))
	assert_eq(Vector2i(target.gem_attack, target.gem_health), Vector2i(5, 7))
	assert_eq(_size(), Vector2i(3, 5), "rounding never consumes stored halves")


func test_hogrider_waits_for_mode_then_uses_the_increased_size() -> void:
	var hog: RecruitUnit = _kit.put("qb_turbo_hogrider", 0)
	var rat: RecruitUnit = _kit.put("qb_gem_rat", 1)
	var foodie: RecruitUnit = _kit.play("qb_fearless_foodie", 2)
	assert_eq([rat.gem_attack, foodie.gem_attack], [0, 0], "no trigger before mode resolves")
	assert_eq(_rules.choose(_player, 0), "")
	assert_eq(_size(), Vector2i(3, 3))
	assert_eq([rat.gem_attack, foodie.gem_attack], [2, 2], "the new size is rounded per gem")
	assert_eq(hog.gem_attack, 0, "budget Hogrider excludes itself")


func test_golden_hogrider_doubles_gems_without_doubling_the_counter() -> void:
	_setup("A")
	_kit.put("qb_turbo_hogrider", 0, true)
	var rat: RecruitUnit = _kit.put("qb_gem_rat", 1)
	_choose_unit("qb_crater_miner", 2)
	assert_eq(rat.gem_attack, 0, "A still waits for every second Choose One")
	_choose_unit("qb_crater_miner", 3)
	assert_eq(rat.gem_attack, 2, "golden gives two gems on the second card")
	_choose_unit("qb_crater_miner", 4)
	assert_eq(rat.gem_attack, 2, "golden never shortens the counter")


func test_extra_when_played_delivery_does_not_repeat_choose_one() -> void:
	_kit.put("qb_turbo_hogrider", 0)
	var rat: RecruitUnit = _kit.put("qb_gem_rat", 1)
	var foodie: RecruitUnit = _kit.play("qb_fearless_foodie", 2)
	# Click Beetle is absent from this tree. Deliver its extra on_play directly.
	_rules.events.fire(_player, "on_play", {"subject": foodie})
	assert_eq(_player.pending.size(), 1, "a When-played repeat creates no second choice")
	assert_eq(_rules.choose(_player, 0), "")
	_rules.events.fire(_player, "on_play", {"subject": foodie})
	assert_false(_player.is_choosing())
	assert_eq(_size(), Vector2i(3, 3), "mode resolves exactly once")
	assert_eq(rat.gem_attack, 2, "Hogrider fires exactly once")


func test_actual_spell_casts_fire_spell_listeners_but_unit_gems_do_not() -> void:
	_kit.card("qb_cast_listener", [KIT.effect("on_spell_cast", {"effect": "gold", "amount": 1})])
	_kit.put("qb_cast_listener", 0)
	var target: RecruitUnit = _kit.put("qb_gem_rat", 1)
	var before: int = _player.gold
	_gem(target, 3)
	assert_eq(_player.gold, before, "three unit-played gems are not three casts")
	assert_eq(_kit.cast("qb_blood_gem", 1), "")
	assert_eq(_player.gold, before + 1, "a hand gem is one real spell cast")
	assert_eq(target.gem_attack, 4)


func test_reference_spells_are_exempt_from_proportional_spell_scaling() -> void:
	_kit.config.set_value("scale_hero_spell_stats", true)
	_kit.config.set_value("scale_hero_spell_percent", 1000)
	var target: RecruitUnit = _kit.put("qb_gem_rat", 0)
	target.add_permanent(10000, 10000)
	var before := Vector2i(target.attack, target.health)
	assert_eq(_kit.cast("qb_blood_gem", 0), "")
	assert_eq(Vector2i(target.attack, target.health), before + Vector2i.ONE)
	var ctx := RecruitContext.make(
		_rules, _player, "cast", {"card_def": _kit.library.get_card("qb_blood_gem")}
	)
	assert_eq(ctx.flat_gain_percent(), 0)


func test_gem_day_is_a_choose_one_spell_with_one_cast_after_the_choice() -> void:
	_kit.put("qb_turbo_hogrider", 0)
	var rat: RecruitUnit = _kit.put("qb_gem_rat", 1)
	assert_eq(_kit.cast("qb_gem_day"), "")
	assert_true(_player.is_choosing())
	assert_eq(rat.gem_attack, 0)
	assert_eq(_rules.choose(_player, 0), "")
	assert_eq(_size(), Vector2i(3, 2))
	assert_eq([rat.gem_attack, rat.gem_health], [2, 1])
	assert_false(_player.is_choosing())


func test_scale_doubler_repeats_gem_rat_end_of_turn() -> void:
	var lever: UnitLibrary = UnitLibrary.load_dir("res://content/levers")
	assert_eq(_kit.library.register_unit(lever.get_unit("scale_doubler")), "")
	_kit.put("qb_gem_rat", 0)
	_kit.put("scale_doubler", 4)
	_rules.end_phase(_player)
	assert_eq(_kit.item_ids().count("qb_gem_day"), 2)


func test_trailblazer_combines_one_card_per_turn_and_golden_combines_two() -> void:
	_kit.put("qb_thorned_trailblazer", 0)
	_kit.play("qb_crater_miner", 1)
	if _player.is_choosing():
		assert_eq(_rules.choose(_player, 0), "")
	assert_eq(_kit.item_ids().count("qb_blood_gem"), 2)
	assert_eq(_kit.item_ids().count("qb_gem_day"), 1, "first card receives both modes")
	_choose_unit("qb_crater_miner", 2)
	assert_eq(_kit.item_ids().count("qb_blood_gem"), 4)
	assert_eq(_kit.item_ids().count("qb_gem_day"), 1, "second card receives only its chosen mode")
	_setup()
	_kit.put("qb_thorned_trailblazer", 0, true)
	for slot: int in [1, 2]:
		_kit.play("qb_crater_miner", slot)
		if _player.is_choosing():
			assert_eq(_rules.choose(_player, 0), "")
	assert_eq(_kit.item_ids().count("qb_gem_day"), 2)
	_choose_unit("qb_crater_miner", 3)
	assert_eq(_kit.item_ids().count("qb_gem_day"), 2)


func test_confiscation_moves_only_gem_stats_from_adjacent_units() -> void:
	var left: RecruitUnit = _kit.put("qb_gem_rat", 0)
	var target: RecruitUnit = _kit.put("qb_gem_rat", 1)
	var right: RecruitUnit = _kit.put("qb_gem_rat", 2)
	var behind: RecruitUnit = _kit.put("qb_gem_rat", 5)
	left.add_permanent(100, 200)
	_gem(left, 2)
	_gem(right, 4)
	_gem(behind, 8)
	assert_eq(_kit.cast("qb_gem_confiscation", 1), "")
	assert_eq(
		[left.gem_attack, target.gem_attack, right.gem_attack, behind.gem_attack], [0, 9, 0, 8]
	)
	assert_eq([left.perm_attack, left.perm_health], [100, 200], "ordinary permanent stats stay")
	assert_eq([right.perm_attack, right.perm_health], [0, 0])
	assert_eq([target.perm_attack, target.perm_health], [9, 9], "three new gems plus six stolen")


func test_random_quilboar_card_arrives_created_and_sells_for_zero() -> void:
	_choose_unit("qb_snare_trapper", 0)
	assert_eq(_player.hand.size(), 1)
	var created: RecruitUnit = _player.hand[0]
	assert_true(created.def_id().begins_with("qb_"))
	assert_true(created.has_tribe("quilboar"))
	assert_eq(created.origin, RecruitUnit.ORIGIN_CREATED)
	assert_eq(created.pool_copies, 0)
	assert_eq(_rules.sell_value(created, _player), 0)


func test_sly_free_refresh_and_trapper_income_are_resolved_mode_effects() -> void:
	_choose_unit("qb_sly_infiltrator", 0)
	assert_eq(_player.free_refreshes, 2)
	_choose_unit("qb_snare_trapper", 1, 1)
	assert_eq(_rules.ask("income", _player, 10), 11)


func test_caps_off_preserves_every_reference_rate_and_golden_budget() -> void:
	for preset: String in ["A", "B", "C", "uncut"]:
		_setup(preset)
		var expected: Dictionary = ReferenceQuilboar.rates(_kit.config)
		var hog: Dictionary = _kit.library.get_unit("qb_turbo_hogrider").duplicate(true)
		_setup(preset, false, false)
		assert_eq(ReferenceQuilboar.rates(_kit.config), expected, preset)
		var actual: Dictionary = _kit.library.get_unit("qb_turbo_hogrider")
		assert_eq(actual["mechanics"], hog["mechanics"], preset + " keeps golden factor and rates")
		assert_eq(_player.quilboar_ref, expected)


func _combat() -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var combat := Combat.create(_kit.library, _kit.config, rng)
	combat.side_rules = [_rules.fight_rules(_player), {}]
	combat._tiers = [6, 6]
	combat._setup([_player.combat_board(), KIT._board({0: "field_vole"})])
	return combat


func test_combat_gems_are_temporary_unless_explicitly_permanent_and_keep_ledger() -> void:
	var owned: RecruitUnit = _kit.put("qb_gem_rat", 0)
	_gem(owned)
	ReferenceQuilboar.gem_size_add(_player, 1, 1)
	var combat: Combat = _combat()
	var target: CombatUnit = combat.unit_at(0, 0)
	var world := CombatWorld.make(combat, target, 0, {}, "reference_test")
	assert_eq([target.gem_attack, target.gem_health], [1, 1], "capture carries the existing ledger")
	world.gem(target, 2)
	assert_eq([target.gem_attack, target.combat_gem_attack], [1, 4])
	assert_eq(combat.carry.size(), 0, "fight-only gems send no permanent reward")
	world.gem(target, 1, true)
	assert_eq([target.gem_attack, target.combat_gem_attack], [3, 4])
	for change: Dictionary in combat.carry:
		_rules.apply_carry(_player, change)
	assert_eq([owned.perm_attack, owned.gem_attack], [3, 3])
	assert_eq([owned.combat_attack, owned.combat_gem_attack], [0, 0])


func test_combat_size_reward_persists_but_does_not_mutate_captured_input() -> void:
	_kit.put("qb_sanguine_refiner", 0)
	var captured: Dictionary = _rules.fight_rules(_player)
	var combat: Combat = _combat()
	combat.side_rules[0] = captured
	var unit: CombatUnit = combat.unit_at(0, 0)
	QuilboarCombat.fire(combat, unit, {"kind": "sanguine_refiner", "factor": 1}, "on_attack")
	QuilboarCombat.fire(combat, unit, {"kind": "sanguine_refiner", "factor": 1}, "on_attack")
	assert_eq(captured["gem_attack_halves"], 2, "re-fight input stays immutable")
	assert_eq(combat.side_rules[0]["gem_attack_halves"], 4)
	assert_eq(_size(), Vector2i(2, 2), "player changes only when the result is applied")
	for change: Dictionary in combat.carry:
		_rules.apply_carry(_player, change)
	assert_eq(_size(), Vector2i(4, 4), "Refiner rewards every attack, not once a fight")


func test_tunneler_is_once_per_fight_golden_gives_two_and_uncut_removes_the_budget() -> void:
	for preset: String in ["B", "uncut"]:
		_setup(preset)
		_kit.put("qb_bramble_tunneler", 0, true)
		var combat: Combat = _combat()
		var unit: CombatUnit = combat.unit_at(0, 0)
		for _attack: int in 2:
			QuilboarCombat.fire(
				combat, unit, {"kind": "bramble_tunneler", "factor": 2}, "on_attack"
			)
		assert_eq(combat.carry.size(), 2 if preset == "B" else 4, preset)
		for change: Dictionary in combat.carry:
			var card: Dictionary = _kit.library.get_unit(str(change["card"]))
			assert_true(card.get("tags", []).has("choose_one"))
			assert_lte(CoreUtil.to_int(card["tier"]), 6)
			assert_false(CoreUtil.to_bool(change["from_pool"]))


func test_combat_reference_spell_exemption_applies_with_no_unit_source() -> void:
	_kit.config.set_value("scale_hero_spell_stats", true)
	_kit.config.set_value("scale_hero_spell_percent", 1000)
	_kit.put("qb_gem_rat", 0)
	var combat: Combat = _combat()
	var world := CombatWorld.make(combat, null, 0, {}, "cast")
	world.params = _kit.library.get_card("qb_blood_gem")
	assert_eq(world.flat_gain_percent(), 0)
