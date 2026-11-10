extends GutTest
## Fox Cub (library entry 40): Mark (2). Start of Combat: mark the enemy slot across; each enemy
## that later enters it takes 2. The unit already there is not hurt (rulebook 8.2.4, 9.3).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func test_marks_the_slot_across() -> void:
	var mine: Array = Kit.board({1: Kit.u("fox_cub")})
	var result: Dictionary = _run_frozen(mine, Kit.board({1: Kit.plain(0, 9)}))
	var mark: Dictionary = Kit.of_type(result, "slot_mark")[0]
	assert_eq(
		[mark["owner_side"], mark["side"], mark["slot"], mark["damage"], mark["source"]],
		[0, 1, 1, 2, 1],
		"F2 across from F2"
	)
	var before: Array = Kit.types_from(result, 0, Kit.index_of(result, "phase") + 4)
	assert_false(before.has("damage"), "the unit already there is not hurt")


func test_a_summon_into_the_slot_takes_the_damage() -> void:
	var mine: Array = Kit.board({0: Kit.u("fox_cub", 9, 30)})
	var result: Dictionary = _run_frozen(mine, Kit.board({0: Kit.u("hoglet_mother", 0, 1)}), 2)
	var summon: Dictionary = Kit.of_type(result, "summon")[0]
	assert_eq(summon["slot"], 0, "the Hoglet enters the marked slot")
	var uid: int = summon["unit"]["uid"]
	var marked: Array = []
	for hit: Dictionary in Kit.of_type(result, "damage"):
		if hit["target"] == uid and hit["kind"] == "effect":
			marked.append([hit["source"], hit["amount"]])
	assert_eq(marked, [[1, 2]], "2 from the Fox Cub")


func test_golden_marks_for_four() -> void:
	var mine: Array = Kit.board({0: Kit.u("fox_cub", -1, -1, true)})
	var result: Dictionary = _run_frozen(mine, Kit.board({0: Kit.plain(0, 9)}))
	assert_eq(Kit.of_type(result, "slot_mark")[0]["damage"], 4, "Mark (4)")


func _run_frozen(a: Array, b: Array, fight_seed: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var library: UnitLibrary = LegacyWave1.current_with_hunters()
	var combat := Combat.create(library, GameConfig.defaults(), rng)
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	return combat.run([a, b], tiers, ids, 0)
