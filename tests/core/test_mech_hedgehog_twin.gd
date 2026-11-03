extends GutTest
## Hedgehog Twin (library entry 45): Both Ends. A pair at F1 and F4 (or B1 and B3) has +1/+2
## each; an enemy attacking one is pricked for 2 by the other first (SPEC 4.2, rulebook 9.6.1).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


## The enemy gets more units so it attacks first (9.2.1).
func _attackers(front: Dictionary) -> Array:
	return Kit.board({0: front, 4: Kit.plain(0, 9), 5: Kit.plain(0, 9)})


func _start_stats(result: Dictionary, side: int) -> Array:
	var out: Array = []
	var boards: Array = Kit.events(result)[0]["boards"]
	for view: Variant in boards[side]:
		if view != null:
			var unit: Dictionary = view
			out.append([unit["attack"], unit["health"]])
	return out


func test_pair_at_the_row_ends_gets_the_aura() -> void:
	var mine: Array = Kit.board({0: Kit.u("hedgehog_twin"), 3: Kit.u("hedgehog_twin")})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 9)}))
	assert_eq(_start_stats(result, 0), [[3, 5], [3, 5]], "2/3 + 1/2 each")


func test_back_row_ends_count_too() -> void:
	var mine: Array = Kit.board({4: Kit.u("hedgehog_twin"), 6: Kit.u("hedgehog_twin")})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 9)}))
	assert_eq(_start_stats(result, 0), [[3, 5], [3, 5]], "B1 and B3")


func test_neighbours_are_not_a_pair() -> void:
	var mine: Array = Kit.board({0: Kit.u("hedgehog_twin"), 1: Kit.u("hedgehog_twin")})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 9)}))
	assert_eq(_start_stats(result, 0), [[2, 3], [2, 3]], "F1 and F2 aren't the ends")


func test_prick_that_kills_cancels_the_attack() -> void:
	var mine: Array = Kit.board({0: Kit.u("hedgehog_twin"), 3: Kit.u("hedgehog_twin")})
	var result: Dictionary = Kit.run(mine, _attackers(Kit.plain(5, 2)))
	var hit: Dictionary = Kit.of_type(result, "damage")[0]
	assert_eq([hit["target"], hit["amount"], hit["kind"]], [3, 2, "effect"], "the partner pricks")
	var cancel: Dictionary = Kit.of_type(result, "cancel")[0]
	assert_eq([cancel["uid"], cancel["reason"]], [3, "died_before_attacking"], "no attack")
	for other: Dictionary in Kit.of_type(result, "damage"):
		assert_false(other["target"] in [1, 2], "the twins take nothing")


func test_prick_then_the_attack_goes_ahead() -> void:
	var mine: Array = Kit.board({0: Kit.u("hedgehog_twin"), 3: Kit.u("hedgehog_twin")})
	var result: Dictionary = Kit.run(mine, _attackers(Kit.plain(1, 30)))
	var kinds: Array = []
	for hit: Dictionary in Kit.of_type(result, "damage").slice(0, 3):
		kinds.append(hit["kind"])
	assert_eq(kinds, ["effect", "attack", "attack"], "prick, then the exchange")


func test_prick_never_triggers_bristle() -> void:
	var mine: Array = Kit.board({0: Kit.u("hedgehog_twin"), 3: Kit.u("hedgehog_twin")})
	var result: Dictionary = Kit.run(mine, _attackers(Kit.u("hoglet_mother", 1, 30)))
	var kinds: Array = []
	for hit: Dictionary in Kit.of_type(result, "damage").slice(0, 4):
		kinds.append(hit["kind"])
	assert_eq(kinds, ["effect", "attack", "attack", "thorns"], "thorns only from the attack")


func test_losing_the_partner_removes_the_aura() -> void:
	var mine: Array = Kit.board({0: Kit.u("hedgehog_twin"), 3: Kit.u("hedgehog_twin")})
	var result: Dictionary = Kit.run(mine, _attackers(Kit.plain(9, 50)))
	var losses: Array = []
	for stats: Dictionary in Kit.of_type(result, "stats"):
		if stats["attack_delta"] < 0:
			losses.append([stats["attack_delta"], stats["health_delta"]])
	assert_eq(losses.slice(0, 1), [[-1, -2]], "the survivor drops to 2/3")


func test_golden_pair_doubles_aura_and_prick() -> void:
	var twin: Dictionary = Kit.u("hedgehog_twin", -1, -1, true)
	var mine: Array = Kit.board({0: twin, 3: twin.duplicate()})
	var result: Dictionary = Kit.run(mine, _attackers(Kit.plain(1, 30)))
	assert_eq(_start_stats(result, 0), [[6, 10], [6, 10]], "4/6 + 2/4")
	assert_eq(Kit.of_type(result, "damage")[0]["amount"], 4, "pricks for 4")
