extends GutTest
## Worker Bee (library entry 25): Swarm. Joiners are later unflagged Swarm units in the leader's
## row (SPEC 4.2); the target hits back only the leader.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func _bees(attacks: Array[int]) -> Array:
	var units: Dictionary = {}
	for slot: int in attacks.size():
		units[slot] = Kit.u("worker_bee", attacks[slot], 20)
	return Kit.board(units)


func test_row_joins_and_only_the_leader_is_hit_back() -> void:
	var result: Dictionary = Kit.run(_bees([2, 2, 2]), Kit.board({0: Kit.plain(3, 50)}))
	var attack: Dictionary = Kit.of_type(result, "attack")[0]
	assert_eq([attack["attacker"], attack["joiners"]], [1, [2, 3]], "F2 and F3 join F1")
	var hits: Array = []
	for hit: Dictionary in Kit.of_type(result, "damage").slice(0, 4):
		hits.append([hit["source"], hit["target"]])
	assert_eq(hits, [[1, 4], [2, 4], [3, 4], [4, 1]], "three hits in, one back to the leader")


func test_joiners_are_flagged_9_4_5() -> void:
	var result: Dictionary = Kit.run(_bees([2, 2, 2]), Kit.board({0: Kit.plain(0, 50)}))
	var attacks: Array[Dictionary] = Kit.of_type(result, "attack")
	assert_eq(attacks[1]["attacker"], 1, "the joiners used their turn: the cycle restarts at F1")


func test_back_row_bees_dont_join_the_front() -> void:
	var mine: Array = Kit.board({0: Kit.u("worker_bee", 2, 20), 4: Kit.u("worker_bee", 2, 20)})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 50)}))
	assert_eq(Kit.of_type(result, "attack")[0]["joiners"], [], "row only")


func test_shell_caps_the_largest_simultaneous_hit() -> void:
	var theirs: Array = Kit.board({0: Kit.u("garden_snail", 0, 50)})
	var result: Dictionary = Kit.run(_bees([1, 9, 2]), theirs)
	var hits: Array = []
	for hit: Dictionary in Kit.of_type(result, "damage").slice(0, 3):
		hits.append([hit["amount"], hit["modifiers"]])
	assert_eq(hits, [[1, []], [4, ["shell"]], [2, []]], "the 9 is capped at 4")


func test_a_stalled_bee_doesnt_join() -> void:
	var theirs: Array = (
		Kit
		. board(
			{
				0: Kit.u("mudwallow_toad", 1, 50),
				4: Kit.plain(0, 9),
				5: Kit.plain(0, 9),
				6: Kit.plain(0, 9),
			}
		)
	)
	for fight_seed: int in range(1, 40):
		var result: Dictionary = Kit.run(_bees([2, 2, 2]), theirs, fight_seed)
		var attacks: Array[Dictionary] = Kit.of_type(result, "attack")
		if attacks[0]["defender"] != 3:
			continue
		assert_eq(Kit.status_on(result, "stalled").slice(0, 1), [3], "the Toad mires F3")
		assert_eq([attacks[1]["attacker"], attacks[1]["joiners"]], [1, [2]], "F3 stays out")
		return
	fail_test("no seed where the Toad hits F3 first")
