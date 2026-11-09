extends GutTest
## Fox Notary (library entry 13): Bystander.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func _run(golden: bool) -> Dictionary:
	var notary: Dictionary = Kit.u("fox_notary", 0, 6 if golden else 3, golden)
	var mine: Array = Kit.board({0: Kit.plain(0, 30), 4: notary})
	return _run_frozen(mine, Kit.board({0: Kit.plain(1, 50)}))


func test_gains_when_another_friendly_unit_is_attacked() -> void:
	var result: Dictionary = _run(false)
	var stats: Dictionary = Kit.of_type(result, "stats")[0]
	assert_eq([stats["target"], stats["attack_delta"], stats["health_delta"]], [2, 1, 1], "+1/+1")
	assert_eq(stats["max_health"], 4, "Health gain raises max Health")


func test_golden_gains_double() -> void:
	var stats: Dictionary = Kit.of_type(_run(true), "stats")[0]
	assert_eq([stats["attack_delta"], stats["health_delta"]], [2, 2], "+2/+2")


func test_not_when_itself_is_attacked() -> void:
	var mine: Array = Kit.board({0: Kit.u("fox_notary", 0, 30)})
	var result: Dictionary = _run_frozen(mine, Kit.board({0: Kit.plain(1, 50)}))
	assert_eq(Kit.of_type(result, "stats").size(), 0, "its other units only")


func _run_frozen(a: Array, b: Array, fight_seed: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var library: UnitLibrary = LegacyWave1.with_hunters(UnitLibrary.load_dir())
	var combat := Combat.create(library, GameConfig.defaults(), rng)
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	return combat.run([a, b], tiers, ids, 0)
