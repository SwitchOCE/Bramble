extends GutTest
## Quick (library entry 24): Weasel Second's First Bite and Ermine Duellist. In a Quick exchange
## the Quick side's damage resolves and deaths are checked first (SPEC 4.2, rulebook 9.6.2).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func test_weasel_gives_first_bite_to_the_units_in_front_9_3() -> void:
	var mine: Array = Kit.board({0: Kit.plain(1, 9), 1: Kit.plain(1, 9), 4: Kit.u("weasel_second")})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 9)}))
	var given: Array = Kit.status_on(result, "first_bite")
	given.sort()
	assert_eq(given, [1, 2], "B1 has F1 and F2 in front (8.2.1)")


func test_first_bite_strikes_first_and_kills_without_a_return_blow() -> void:
	var mine: Array = Kit.board({0: Kit.plain(3, 3), 4: Kit.u("weasel_second", 0, 9)})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(3, 3)}))
	var attack: Dictionary = Kit.of_type(result, "attack")[0]
	assert_eq([attack["attacker"], attack["quick"]], [1, true], "a Quick exchange")
	var hits: Array[Dictionary] = Kit.of_type(result, "damage")
	assert_eq(hits.size(), 1, "only the Quick unit's damage lands")
	assert_eq(Kit.last(result)["winner"], 0, "and wins")


func test_first_bite_is_used_up_by_the_first_exchange() -> void:
	var mine: Array = Kit.board({0: Kit.plain(1, 30), 4: Kit.u("weasel_second", 0, 9)})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(1, 30)}))
	var offs: int = 0
	for event: Dictionary in Kit.of_type(result, "status"):
		if event["status"] == "first_bite" and not event["on"]:
			offs += 1
	assert_eq(offs, 1, "removed once")
	var attacks: Array[Dictionary] = Kit.of_type(result, "attack")
	assert_true(attacks[0]["quick"], "the first exchange is Quick")
	assert_false(attacks[1]["quick"], "the second isn't")


func test_first_bite_works_when_defending() -> void:
	var mine: Array = Kit.board({0: Kit.plain(3, 3), 4: Kit.u("weasel_second", 0, 9)})
	var theirs: Array = Kit.board({0: Kit.plain(3, 3), 1: Kit.plain(0, 9), 2: Kit.plain(0, 9)})
	var result: Dictionary = Kit.run(mine, theirs)
	var attack: Dictionary = Kit.of_type(result, "attack")[0]
	assert_eq([attack["side"], attack["defender"]], [1, 1], "the enemy attacks my only front unit")
	var hit: Dictionary = Kit.of_type(result, "damage")[0]
	assert_eq([hit["source"], hit["target"]], [1, 3], "the defender with First Bite hits first")
	for other: Dictionary in Kit.of_type(result, "damage"):
		assert_ne(other["source"], 3, "and the attacker dies without hitting")


func test_both_quick_is_simultaneous() -> void:
	var mine: Array = Kit.board({0: Kit.u("ermine_duellist", 3, 3)})
	var theirs: Array = Kit.board({0: Kit.u("ermine_duellist", 3, 3)})
	var result: Dictionary = Kit.run(mine, theirs)
	assert_false(Kit.of_type(result, "attack")[0]["quick"], "not a Quick exchange")
	assert_eq(Kit.of_type(result, "damage").size(), 2, "both hit")
	assert_eq(Kit.last(result)["winner"], -1, "both die together in the BG baseline")


func test_ermine_is_quick_while_undamaged() -> void:
	var mine: Array = Kit.board({0: Kit.u("ermine_duellist")})
	var theirs: Array = Kit.board({0: Kit.plain(5, 5)})
	var result: Dictionary = Kit.run(mine, theirs, 2)
	assert_eq(Kit.of_type(result, "damage").size(), 1, "6 kills the 5/5 first")
	assert_eq(Kit.last(result)["survivors"], [[1], []], "untouched")


func test_ermine_loses_quick_once_damaged() -> void:
	var mine: Array = Kit.board({0: Kit.u("ermine_duellist", 1, 20)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 30)})
	var result: Dictionary = Kit.run(mine, theirs)
	var attacks: Array[Dictionary] = Kit.of_type(result, "attack")
	assert_true(attacks[0]["quick"], "Quick at first")
	assert_false(attacks[2]["quick"], "not after the first exchange damaged it")


func test_ermine_pricked_by_both_ends_exchanges_without_quick() -> void:
	var mine: Array = Kit.board({0: Kit.u("hedgehog_twin"), 3: Kit.u("hedgehog_twin")})
	var theirs: Array = Kit.board(
		{0: Kit.u("ermine_duellist", 6, 20), 4: Kit.plain(0, 9), 5: Kit.plain(0, 9)}
	)
	var result: Dictionary = Kit.run(mine, theirs)
	var attack_hits: Array = []
	for hit: Dictionary in Kit.of_type(result, "damage").slice(0, 3):
		attack_hits.append(hit["kind"])
	assert_eq(attack_hits, ["effect", "attack", "attack"], "damaged by the prick: both hit")


func test_peck_second_strike_meets_an_ermine_damaged_by_the_first() -> void:
	var mine: Array = Kit.board({0: Kit.u("drumming_woodpecker", 4, 3), 4: Kit.plain(0, 9)})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.u("ermine_duellist", 6, 20)}))
	var sources: Array = []
	for hit: Dictionary in Kit.of_type(result, "damage").slice(0, 3):
		sources.append([hit["source"], hit["strike"]])
	assert_eq(sources, [[1, 1], [1, 2], [3, 2]], "strike 2 lands: no longer Quick")
