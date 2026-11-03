extends GutTest
## Drumming Woodpecker (library entry 5): Peck 2, and +1 Attack to your other Birds on each
## strike. Each strike is its own hit; the return blow lands with the last (SPEC 4.2).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func _bird_board(attack: int) -> Array:
	# A 0-Attack second unit makes this side attack first (9.4.1, more units).
	return Kit.board({0: Kit.u("drumming_woodpecker", attack, 20), 4: Kit.plain(0, 9)})


func test_two_strikes_split_evenly_larger_first() -> void:
	var result: Dictionary = Kit.run(_bird_board(3), Kit.board({0: Kit.plain(2, 40)}))
	var attack: Dictionary = Kit.of_type(result, "attack")[0]
	assert_eq(attack["strikes"], 2, "2 strikes")
	var hits: Array = []
	for hit: Dictionary in Kit.of_type(result, "damage").slice(0, 3):
		hits.append([hit["source"], hit["amount"], hit["strike"]])
	assert_eq(hits, [[1, 2, 1], [1, 1, 2], [3, 2, 2]], "2 then 1; the return blow with strike 2")


func test_each_strike_pricks_on_bristle() -> void:
	var theirs: Array = Kit.board({0: Kit.u("hoglet_mother", 0, 40)})
	var result: Dictionary = Kit.run(_bird_board(2), theirs)
	var thorns: int = 0
	for hit: Dictionary in Kit.of_type(result, "damage").slice(0, 4):
		if hit["kind"] == "thorns":
			thorns += 1
	assert_eq(thorns, 2, "one prick per strike")


func test_early_kill_means_no_return_blow() -> void:
	var result: Dictionary = Kit.run(_bird_board(10), Kit.board({0: Kit.plain(5, 4)}))
	assert_eq(Kit.of_type(result, "damage").size(), 1, "strike 1 kills; no strike 2, no return")


func test_nightshade_halves_once_per_attack() -> void:
	var mine: Array = Kit.board(
		{0: Kit.u("drumming_woodpecker", 2, 40), 4: Kit.u("belladonna_sprite")}
	)
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 40)}))
	assert_eq(Kit.status_on(result, "nightshade"), [3], "the Sprite marks the only enemy")
	var types: Array = []
	for event: Dictionary in Kit.events(result):
		if event["type"] in ["attack", "health_loss", "damage"]:
			types.append(event["type"])
	assert_eq(
		types.slice(0, 4), ["attack", "health_loss", "damage", "damage"], "one loss, two strikes"
	)


func test_buffs_other_birds_each_strike() -> void:
	var mine: Array = Kit.board(
		{0: Kit.u("drumming_woodpecker", 2, 20), 4: Kit.u("fieldfare", 0, 9)}
	)
	var result: Dictionary = Kit.run(mine, Kit.board({0: Kit.plain(0, 40)}))
	var buffs: Array = []
	for stats: Dictionary in Kit.of_type(result, "stats").slice(0, 2):
		buffs.append([stats["target"], stats["attack"]])
	assert_eq(buffs, [[2, 1], [2, 2]], "the Fieldfare gets +1 per strike")


func test_bystander_fires_once_per_peck() -> void:
	var theirs: Array = Kit.board({0: Kit.plain(0, 40), 4: Kit.u("fox_notary", 0, 3)})
	var result: Dictionary = Kit.run(_bird_board(2), theirs)
	var at: int = Kit.index_of(result, "attack")
	var next_attack: int = -1
	for index: int in range(at + 1, Kit.events(result).size()):
		if Kit.events(result)[index]["type"] == "attack":
			next_attack = index
			break
	var fired: int = 0
	for event: Dictionary in Kit.events(result).slice(at, next_attack):
		if event["type"] == "trigger" and event["mechanic"] == "bystander":
			fired += 1
	assert_eq(fired, 1, "once for the whole attack")
