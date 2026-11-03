extends GutTest
## Hazel Dormouse (library entry 9): Bide (Slumber). While waiting it skips its attacks and gains
## +1/+1 each time it's chosen; it wakes on damage or when no other friendly unit that isn't
## waiting can attack (SPEC 4.2, rulebook 9.4.5).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func test_waits_grows_and_passes_the_turn_on() -> void:
	var mine: Array = Kit.board({0: Kit.u("hazel_dormouse"), 1: Kit.plain(1, 30)})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 50)}))
	var skip: Dictionary = Kit.of_type(result, "skip")[0]
	assert_eq([skip["uid"], skip["reason"]], [1, "bide"], "the Dormouse waits")
	var stats: Dictionary = Kit.of_type(result, "stats")[0]
	assert_eq([stats["target"], stats["attack_delta"], stats["health_delta"]], [1, 1, 1], "+1/+1")
	assert_eq(Kit.of_type(result, "attack")[0]["attacker"], 2, "the turn goes to F2")
	var skips: int = Kit.of_type(result, "skip").size()
	assert_eq(skips, Kit.of_type(result, "attack").size(), "it waits every turn")


func test_alone_it_wakes_and_attacks() -> void:
	var result: Dictionary = Kit.run(
		Kit.board({0: Kit.u("hazel_dormouse")}), Kit.board({0: Kit.plain(0, 9)})
	)
	assert_eq(Kit.of_type(result, "skip").size(), 0, "no waiting")
	assert_eq(Kit.of_type(result, "attack")[0]["attacker"], 1, "attacks at once")


func test_damage_wakes_it() -> void:
	var mine: Array = Kit.board({0: Kit.u("hazel_dormouse", 1, 30), 4: Kit.plain(1, 30)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 50), 4: Kit.plain(0, 9), 5: Kit.plain(0, 9)})
	var result: Dictionary = Kit.run(mine, theirs)
	var attacks: Array[Dictionary] = Kit.of_type(result, "attack")
	assert_eq(attacks[0]["defender"], 1, "the enemy hits the Dormouse")
	assert_eq(attacks[1]["attacker"], 1, "awake, it attacks on its side's next turn")
	assert_eq(Kit.of_type(result, "skip").size(), 0, "never waited")


func test_of_two_dormice_the_first_wakes_and_the_second_waits() -> void:
	var mine: Array = Kit.board({0: Kit.u("hazel_dormouse"), 1: Kit.u("hazel_dormouse")})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 50)}))
	assert_eq(Kit.of_type(result, "attack")[0]["attacker"], 1, "no other unit was awake")
	var waiting: Array = []
	for skip: Dictionary in Kit.of_type(result, "skip"):
		if not waiting.has(skip["uid"]):
			waiting.append(skip["uid"])
	assert_eq(waiting, [2], "then F2 has an awake friend, so it waits")


func test_golden_grows_by_two() -> void:
	var mine: Array = Kit.board({0: Kit.u("hazel_dormouse", -1, -1, true), 1: Kit.plain(1, 30)})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 50)}))
	var stats: Dictionary = Kit.of_type(result, "stats")[0]
	assert_eq([stats["attack_delta"], stats["health_delta"]], [2, 2], "+2/+2")
