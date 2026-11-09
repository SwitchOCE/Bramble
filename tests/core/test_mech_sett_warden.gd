extends GutTest
## Sett Warden (library entry 1): Hunker, and +Attack to the units behind it (rulebook 8.2.1)
## when it survives being attacked.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func _warden_board(golden: bool = false, health: int = 4) -> Array:
	return (
		Kit
		. board(
			{
				1: Kit.u("sett_warden", 0, health * (2 if golden else 1), golden),
				4: Kit.plain(0, 10),
				5: Kit.plain(0, 10),
			}
		)
	)


func test_hunker_halves_attack_damage_when_defending() -> void:
	var result: Dictionary = _run_frozen(_warden_board(), Kit.board({0: Kit.plain(5, 50)}))
	var hit: Dictionary = Kit.of_type(result, "damage")[0]
	assert_eq([hit["raw"], hit["amount"], hit["modifiers"]], [5, 3, ["hunker"]], "5 -> 3, up")


func test_hunker_doesnt_apply_when_attacking() -> void:
	var mine: Array = Kit.board({0: Kit.u("sett_warden", 1, 20)})
	var theirs: Array = Kit.board({0: Kit.plain(4, 50), 1: Kit.plain(0, 50)})
	for fight_seed: int in 20:
		var result: Dictionary = _run_frozen(mine, theirs, fight_seed)
		for attack: Dictionary in Kit.of_type(result, "attack"):
			if attack["side"] == 0 and attack["defender"] == 2:
				var at: int = Kit.events(result).find(attack)
				var back: Dictionary = Kit.events(result)[at + 2]
				assert_eq([back["target"], back["amount"]], [1, 4], "the return blow lands in full")
				return
	fail_test("the Warden never attacked the 4/50")


func test_survivor_buffs_the_units_behind() -> void:
	var result: Dictionary = _run_frozen(_warden_board(), Kit.board({0: Kit.plain(2, 50)}))
	var triggers: Array[Dictionary] = Kit.of_type(result, "trigger")
	assert_eq(triggers[0]["mechanic"], "survive_buff_behind", "fires")
	var stats: Array[Dictionary] = Kit.of_type(result, "stats")
	assert_eq([stats[0]["target"], stats[0]["attack_delta"]], [2, 1], "B1 +1 Attack")
	assert_eq([stats[1]["target"], stats[1]["attack_delta"]], [3, 1], "B2 +1 Attack")
	assert_false(stats[0]["permanent"], "this combat only")


func test_no_buff_when_it_dies() -> void:
	var result: Dictionary = _run_frozen(_warden_board(), Kit.board({0: Kit.plain(20, 50)}))
	var at: int = Kit.index_of(result, "death")
	assert_eq(Kit.events(result)[at]["uid"], 1, "the Warden died first")
	assert_eq(Kit.of_type(result, "stats").size(), 0, "no buff")


func test_golden_gives_plus_2() -> void:
	var result: Dictionary = _run_frozen(_warden_board(true), Kit.board({0: Kit.plain(2, 50)}))
	assert_eq(Kit.of_type(result, "stats")[0]["attack_delta"], 2, "+2")


func _run_frozen(a: Array, b: Array, fight_seed: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var library: UnitLibrary = LegacyWave1.with_hunters(UnitLibrary.load_dir())
	var combat := Combat.create(library, GameConfig.defaults(), rng)
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	return combat.run([a, b], tiers, ids, 0)
