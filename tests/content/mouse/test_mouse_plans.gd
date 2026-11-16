extends GutTest
## The Mice's four plans (docs/ideation-track-2/tribes/mouse/README.md, "The four plans"): the
## key interaction of each turn-9 board, cut down to the units that make it, through the core.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const Kit := preload("res://tests/content/mouse/mouse_kit.gd")

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	p = game.player(0)
	q = game.player(1)


## Needles: "The Harrier attacks: the Pages and the Pikeman hit first. The enemy is dead, the
## Harrier is untouched and attacks again."
func test_needles_the_harrier_is_untouched_and_attacks_again() -> void:
	CoreKit.put(game, p, "shrew-harrier", 0)
	Kit.golden(game, p, "needle-page", 1).stats.set_attack = 16
	var pikeman: Unit = CoreKit.put(game, p, "needle-pikeman", 4)
	pikeman.stats.set_attack = 70
	Kit.wall(game, q, 0, 50, 86)
	Kit.wall(game, q, 4, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var harrier: int = Kit.uid_at(combat, 0, 0)
	var attacks: Array[Dictionary] = CoreKit.events_of(combat, "attack")
	assert_eq([attacks[0]["uid"], attacks[1]["uid"]], [harrier, harrier])
	var first: int = Kit.index_of(combat, "attack")
	var hits: Array[Dictionary] = Kit.between(combat, first, Kit.next_attack(combat, first), "hit")
	var total: int = 0
	for hit: Dictionary in hits:
		total += Kit.damage_by(combat, hit["uid"])[0]
	assert_eq(total, 86, "16 + 70 hit first")
	assert_eq(Kit.damage_to(combat, harrier), [] as Array[Dictionary], "untouched")
	assert_eq(attacks[1]["target_slot"], 4, "its second attack finds the next enemy")


## Needles: a Pikeman in the back row fires for the Master of Engines (a Hit is not an attack).
func test_needles_a_pikeman_hits_for_the_master_of_engines() -> void:
	CoreKit.put(game, p, "master-of-engines", 0)
	CoreKit.put(game, p, "needle-pikeman", 4)
	Kit.wall(game, q, 0, 0, 30)
	var combat: Combat = Kit.fight(game)
	var pikeman: int = Kit.uid_at(combat, 0, 4)
	var hits: Array[Dictionary] = Kit.between(combat, 0, Kit.index_of(combat, "attack"), "hit")
	assert_eq(hits.size(), 1)
	assert_eq(hits[0]["uid"], pikeman)
	assert_eq(Kit.where(combat, "attack", "uid", pikeman).size(), 0, "it still never attacks")


## Parish: seven Mice, and the Captain puts a Cousin in the gap at full strength.
func test_parish_a_cousin_lands_counted_by_the_standard_bearer() -> void:
	for slot: int in 4:
		CoreKit.put(game, p, "needle-page", slot)
	CoreKit.put(game, p, "thimble-captain", 4)
	CoreKit.put(game, p, "parish-standard-bearer", 5)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.start_view(combat, 0, 0)["attack"], 16, "six Mice: +12")
	var captain: int = Kit.uid_at(combat, 0, 4)
	var cousin: Dictionary = Kit.where(combat, "summon", "source_uid", captain)[0]
	assert_eq(cousin["slot"], 6, "the gap")
	assert_eq([cousin["attack"], cousin["health"]], [16, 2], "2 + 14: seven Mice now")


## Ground: a Cousin that lands on a sharp slot hits as hard as the slot, doubled.
func test_ground_a_cousin_on_a_sharp_slot_piles_on_hard() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	p.slots[1].attack = 15
	CoreKit.put(game, p, "edgewright", 2)
	Kit.wall(game, p, 3, 0, 1000)
	CoreKit.put(game, p, "thimble-captain", 4)
	Kit.wall(game, p, 5, 0, 1000)
	Kit.wall(game, p, 6, 0, 1000)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	var captain: int = Kit.uid_at(combat, 0, 4)
	var cousin: Dictionary = Kit.where(combat, "summon", "source_uid", captain)[0]
	assert_eq(cousin["slot"], 1, "into the sharp slot")
	assert_eq(cousin["attack"], 32, "2 + 15 x 2")
	assert_eq(Kit.damage_by(combat, cousin["uid"])[0], 32, "and it piles on with it")


## Ground: Vole and Miller lay Attack on the slots turn after turn; it outlives the units.
func test_ground_slot_attack_builds_up_and_stays_when_the_unit_is_sold() -> void:
	CoreKit.put(game, p, "whetstone-vole", 1)
	CoreKit.put(game, p, "grindstone-miller", 5)
	assert_eq(Kit.end_turn(game), "")
	game.finish_round()
	game.start_round()
	assert_eq(Kit.end_turn(game), "")
	assert_eq(p.view()["slots"][1]["attack"], 10, "two turns of +3 and +2")
	game.finish_round()
	game.start_round()
	assert_eq(game.act(0, {"type": "sell", "slot": 1}), "")
	assert_eq(p.view()["slots"][1]["attack"], 10, "the slot keeps it")


## Siege: before anyone attacks the back row Hits on doubled slots, then each Catapult Hits again
## on its turn.
func test_siege_the_back_row_hits_first_on_sharp_slots() -> void:
	Kit.wall(game, p, 0, 0, 1000)
	CoreKit.put(game, p, "master-of-engines", 1)
	CoreKit.put(game, p, "edgewright", 3)
	CoreKit.put(game, p, "spoon-catapult", 4)
	CoreKit.put(game, p, "grindstone-miller", 5)
	CoreKit.put(game, p, "spoon-catapult", 6)
	p.slots[4].attack = 9
	p.slots[5].attack = 6
	p.slots[6].attack = 9
	Kit.wall(game, q, 0, 0, 25)
	Kit.wall(game, q, 1, 0, 28)
	Kit.wall(game, q, 2, 0, 100)
	Kit.wall(game, q, 3, 0, 100)
	var combat: Combat = Kit.fight(game)
	var opening: Array[Dictionary] = Kit.between(combat, 0, Kit.index_of(combat, "attack"), "hit")
	var who: Array = opening.map(func(e: Dictionary) -> int: return e["uid"])
	assert_eq(who, [Kit.uid_at(combat, 0, 4), Kit.uid_at(combat, 0, 5), Kit.uid_at(combat, 0, 6)])
	var dealt: Array = opening.map(
		func(e: Dictionary) -> int: return Kit.damage_by(combat, e["uid"])[0]
	)
	assert_eq(dealt, [30, 15, 30], "12 + 9 x 2, 3 + 6 x 2")
	var catapult: int = Kit.uid_at(combat, 0, 4)
	assert_gt(Kit.where(combat, "instead_of_attack", "uid", catapult).size(), 0)
	assert_eq(Kit.where(combat, "attack", "uid", catapult).size(), 0, "the engines never attack")
