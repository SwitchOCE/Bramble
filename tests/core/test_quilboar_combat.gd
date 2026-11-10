extends GutTest
## Phase-1 reference rewards use the same combat hooks and carry-back as real fights.
@warning_ignore_start("unsafe_call_argument")

const CK := preload("res://tests/core/combat_kit.gd")
var library: UnitLibrary
var config: GameConfig


func before_each() -> void:
	library = UnitLibrary.load_dir()
	for id: String in [
		"sanguine_refiner",
		"sanguine_champion",
		"bramble_tunneler",
		"crater_miner",
		"fearless_foodie"
	]:
		var path: String = "res://content/reference/quilboar/units/qb_%s.json" % id
		var card: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_eq(library.register_unit(card), "")
	config = GameConfig.defaults()
	config.set_value("reference_quilboar", true)


func _fight(id: String, golden: bool = false, rates: Dictionary = {}) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var combat := Combat.create(library, config, rng)
	var spec: Dictionary = CK.u(id, 10, 100, golden)
	spec["iid"] = 15
	combat._setup([CK.board({0: spec}), CK.board({0: CK.plain(0, 1000)})])
	combat._tiers = [6, 6]
	combat.side_rules = [{"quilboar_ref": rates}, {}]
	return combat


func _fire(combat: Combat, event: String) -> void:
	var unit: CombatUnit = combat.unit_at(0, 0)
	for index: int in unit.scripts.size():
		if event == "on_attack":
			unit.scripts[index].on_before_attack(combat, unit, unit.params[index])
		else:
			unit.scripts[index].on_death(combat, unit, unit.params[index])


func test_refiner_every_attack_raises_future_gems_only_and_persists() -> void:
	var combat: Combat = _fight("qb_sanguine_refiner")
	var unit: CombatUnit = combat.unit_at(0, 0)
	var world := CombatWorld.make(combat, unit, 0, {}, "on_attack")
	world.gem(unit, 1)
	assert_eq(unit.combat_gem_attack, 1)
	_fire(combat, "on_attack")
	assert_eq(unit.combat_gem_attack, 1, "size changes don't rewrite earlier gems")
	world.gem(unit, 1)
	assert_eq(unit.combat_gem_attack, 3, "1.5 rounds up independently for this gem")
	_fire(combat, "on_attack")
	assert_eq(combat.side_rules[0]["gem_attack_halves"], 4)
	assert_eq(combat.carry.size(), 2)
	assert_eq(combat.carry[0], {"side": 0, "op": "gem_size_add", "attack": 1, "health": 1})


func test_golden_champion_death_doubles_size_not_the_number_of_deaths() -> void:
	var combat: Combat = _fight("qb_sanguine_champion", true)
	_fire(combat, "on_death")
	assert_eq(combat.side_rules[0]["gem_attack_halves"], 6)
	assert_eq(combat.side_rules[0]["gem_health_halves"], 4)
	assert_eq(combat.carry.size(), 1)


func test_c_and_uncut_use_whole_size_steps() -> void:
	var combat: Combat = _fight("qb_sanguine_refiner", false, {"gem_size_step": 1.0})
	_fire(combat, "on_attack")
	assert_eq(combat.side_rules[0]["gem_attack_halves"], 4)
	assert_eq(combat.side_rules[0]["gem_health_halves"], 4)


func test_tunneler_once_a_fight_golden_returns_two_created_choose_one_cards() -> void:
	var combat: Combat = _fight("qb_bramble_tunneler", true)
	_fire(combat, "on_attack")
	_fire(combat, "on_attack")
	assert_eq(combat.carry.size(), 2)
	for reward: Dictionary in combat.carry:
		assert_eq(reward["op"], "add_card")
		assert_false(reward["from_pool"])
		var card: Dictionary = library.get_unit(str(reward["card"]))
		var modes: Array = card.get("modes", [])
		assert_false(modes.is_empty())


func test_uncut_tunneler_rewards_each_attack_and_rng_repeats_exactly() -> void:
	var first: Combat = _fight("qb_bramble_tunneler", false, {"tunneler_per_fight": null})
	var second: Combat = _fight("qb_bramble_tunneler", false, {"tunneler_per_fight": null})
	for _index: int in 3:
		_fire(first, "on_attack")
		_fire(second, "on_attack")
	assert_eq(first.carry.size(), 3)
	assert_eq(first.carry, second.carry)


func test_combat_gem_ledger_separates_temporary_and_permanent_stats() -> void:
	var combat: Combat = _fight("qb_sanguine_refiner")
	var unit: CombatUnit = combat.unit_at(0, 0)
	var world := CombatWorld.make(combat, unit, 0, {}, "on_attack")
	world.gem(unit, 2)
	world.gem(unit, 3, true)
	assert_eq([unit.combat_gem_attack, unit.combat_gem_health], [2, 2])
	assert_eq([unit.gem_attack, unit.gem_health], [3, 3])
	assert_eq(combat.carry.size(), 2, "temporary gems do not carry back")
	assert_eq(combat.carry[0]["op"], "buff")
	assert_eq(combat.carry[1], {"side": 0, "op": "gem_ledger", "iid": 15, "attack": 3, "health": 3})


func test_gem_size_does_not_mutate_captured_rules_reused_by_another_fight() -> void:
	var combat: Combat = _fight("qb_sanguine_refiner")
	var captured: Dictionary = {"gem_attack_halves": 2, "gem_health_halves": 2}
	combat.side_rules[0] = captured
	_fire(combat, "on_attack")
	assert_eq(captured, {"gem_attack_halves": 2, "gem_health_halves": 2})


func test_combat_scaling_exempt_keeps_flat_spell_effects_flat() -> void:
	var combat: Combat = _fight("qb_sanguine_refiner")
	config.set_value("scale_hero_spell_stats", true)
	var world := CombatWorld.make(combat, null, 0, {}, "cast")
	assert_gt(world.flat_gain_percent(), 0)
	world.params["scaling_exempt"] = true
	assert_eq(world.flat_gain_percent(), 0)


func test_combat_copy_preserves_each_gem_ledger_layer() -> void:
	var spec: Dictionary = CK.u("qb_sanguine_refiner")
	spec.merge({"gem_attack": 3, "gem_health": 5, "combat_gem_attack": 7, "combat_gem_health": 9})
	var unit := CombatUnit.make(library.get_unit("qb_sanguine_refiner"), spec, 1, 0)
	assert_eq([unit.gem_attack, unit.gem_health], [3, 5])
	assert_eq([unit.combat_gem_attack, unit.combat_gem_health], [7, 9])
