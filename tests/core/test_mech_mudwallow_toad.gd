extends GutTest
## Mudwallow Toad (library entry 11): Pin. A stalled unit, when chosen (rulebook 9.4.5), is
## flagged, loses the status, and its side picks the next unit in the same turn (SPEC 4.2).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func test_damaged_enemy_is_stalled_and_skips() -> void:
	var mine: Array = Kit.board({0: Kit.u("mudwallow_toad", 2, 60), 1: Kit.plain(0, 60)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 60), 1: Kit.plain(1, 60)})
	for fight_seed: int in 30:
		var result: Dictionary = Kit.run(mine, theirs, fight_seed)
		if Kit.of_type(result, "attack")[0]["defender"] != 3:
			continue
		assert_eq(Kit.status_on(result, "stalled")[0], 3, "the toad's target is stalled")
		var at: int = Kit.index_of(result, "skip")
		var skip: Dictionary = Kit.events(result)[at]
		assert_eq([skip["uid"], skip["reason"]], [3, "stalled"], "F1 skips its turn")
		var next: Dictionary = Kit.events(result)[at + 1]
		assert_eq([next["type"], next["side"], next["attacker"]], ["attack", 1, 4], "F2 attacks")
		return
	fail_test("no seed where the toad hit F1")


func test_lone_stalled_unit_passes_the_turn() -> void:
	var mine: Array = Kit.board({0: Kit.u("mudwallow_toad", 2, 60), 1: Kit.plain(0, 60)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 60)})
	var result: Dictionary = Kit.run(mine, theirs)
	var at: int = Kit.index_of(result, "skip")
	assert_eq(Kit.events(result)[at + 1]["type"], "pass", "skipped and nothing else to choose")


func test_attacking_the_toad_doesnt_mire_without_damage_from_it() -> void:
	var mine: Array = Kit.board({0: Kit.u("mudwallow_toad", 0, 60)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 60)})
	var result: Dictionary = Kit.run(mine, theirs)
	assert_eq(Kit.status_on(result, "stalled"), [], "damage from the toad only (library text)")


func test_mire_doesnt_stack() -> void:
	var mine: Array = Kit.board({0: Kit.u("mudwallow_toad", 1, 60), 1: Kit.plain(0, 60)})
	var theirs: Array = Kit.board({0: Kit.plain(0, 60)})
	var result: Dictionary = Kit.run(mine, theirs)
	assert_eq(Kit.status_on(result, "stalled"), [3], "a unit that can't attack keeps one status")
