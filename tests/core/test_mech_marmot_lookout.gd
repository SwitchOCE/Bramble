extends GutTest
## Marmot Lookout (library entry 10): Whistle. Never attacks; on its turn the highest-Attack
## enemy not already warned deals half damage, rounded up, with its next attack (SPEC 4.2).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func test_warns_the_strongest_and_halves_its_next_hit() -> void:
	var mine: Array = Kit.board(
		{0: Kit.u("marmot_lookout"), 1: Kit.plain(1, 30), 4: Kit.plain(0, 9)}
	)
	var theirs: Array = Kit.board({0: Kit.plain(5, 30), 1: Kit.plain(2, 30)})
	var result: Dictionary = Kit.run(mine, theirs)
	var whistle: Dictionary = Kit.of_type(result, "whistle")[0]
	assert_eq([whistle["uid"], whistle["warned"]], [1, [4]], "the 5-Attack enemy")
	var hit: Dictionary = Kit.of_type(result, "damage")[0]
	assert_eq([hit["source"], hit["amount"], hit["modifiers"]], [4, 3, ["whistle"]], "5 -> 3")
	var offs: Array = []
	for event: Dictionary in Kit.of_type(result, "status"):
		if event["status"] == "warned" and not event["on"]:
			offs.append(event["target"])
	assert_eq(offs.slice(0, 1), [4], "used up by that attack")


func test_never_attacks_and_uses_the_turn() -> void:
	var mine: Array = Kit.board(
		{0: Kit.u("marmot_lookout"), 1: Kit.plain(1, 30), 4: Kit.plain(0, 9)}
	)
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(1, 30)}))
	for attack: Dictionary in Kit.of_type(result, "attack"):
		assert_ne(attack["attacker"], 1, "the Marmot never attacks")
	var types: Array = []
	for event: Dictionary in Kit.events(result):
		if event["type"] in ["whistle", "attack"]:
			types.append([event["type"], event["side"]])
	assert_eq(types.slice(0, 3), [["whistle", 0], ["attack", 1], ["attack", 0]], "a full turn")


func test_skips_enemies_already_warned() -> void:
	var mine: Array = (
		Kit
		. board(
			{
				0: Kit.u("marmot_lookout"),
				1: Kit.u("marmot_lookout"),
				4: Kit.plain(0, 9),
				5: Kit.plain(0, 9),
			}
		)
	)
	var theirs: Array = Kit.board({0: Kit.plain(1, 30), 4: Kit.plain(4, 30), 5: Kit.plain(2, 30)})
	var result: Dictionary = Kit.run(mine, theirs)
	var warned: Array = []
	for whistle: Dictionary in Kit.of_type(result, "whistle").slice(0, 2):
		warned.append(whistle["warned"])
	assert_eq(warned, [[6], [7]], "the 4, then the 2 (the 4 hasn't attacked yet)")


func test_whistlers_alone_cant_attack_9_9_1() -> void:
	var result: Dictionary = Kit.run(
		Kit.board({0: Kit.u("marmot_lookout")}), Kit.board({0: Kit.u("marmot_lookout")})
	)
	assert_eq(Kit.last(result)["reason"], "no_attacks", "the fight ends at once")
	assert_eq(Kit.of_type(result, "whistle").size(), 0, "no whistles")


func test_a_lookout_with_attack_still_never_attacks() -> void:
	var mine: Array = Kit.board({0: Kit.u("marmot_lookout", 3, 4)})
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 9)}))
	assert_eq(Kit.last(result)["reason"], "no_attacks", "Attack doesn't make it attack")


func test_a_lone_lookout_keeps_whistling_while_the_enemy_attacks() -> void:
	var result: Dictionary = Kit.run(
		Kit.board({0: Kit.u("marmot_lookout")}), Kit.board({0: Kit.plain(2, 30)})
	)
	assert_gt(Kit.of_type(result, "whistle").size(), 0, "it whistles on its turns")
	assert_eq(Kit.last(result)["winner"], 1, "and loses once it falls")
