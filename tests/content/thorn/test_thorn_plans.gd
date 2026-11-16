extends GutTest
## The five Briar plans on their turn-9 boards from docs/ideation-track-2/tribes/thorn/README.md,
## through the core: the numbers the README promises come out of the fight log.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const ThornKit := preload("res://tests/content/thorn/thorn_kit.gd")
const HEAP: StringName = &"thorn_compost"

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = ThornKit.session()
	p = game.player(0)
	q = game.player(1)


func _board(player: PlayerState, spec: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for slot: Variant in spec:
		out[slot] = CoreKit.put(game, player, str(spec[slot]), CoreUtil.to_int(slot))
	return out


func _plain_heap(count: int) -> void:
	var ids: Array[String] = []
	for _i: int in count:
		ids.append("t1_plain")
	ThornKit.fill(game, p, ids)


## The unit's first buff event in the fight (its Start of fight Grow).
func _grown(combat: Combat, unit: Unit) -> Array:
	var buff: Dictionary = ThornKit.about(combat, "buff", ThornKit.uid_of(combat, unit))[0]
	return [CoreUtil.to_int(buff["attack"]), CoreUtil.to_int(buff["health"])]


func test_overgrowth_banks_twenty_and_starts_huge() -> void:
	_plain_heap(20)
	var board: Dictionary = _board(
		p,
		{
			0: "blackberry-sprawl",
			1: "blackberry-sprawl",
			2: "lone-hawthorn",
			3: "crab-apple",
			4: "ivy-climber",
			5: "ivy-climber",
			6: "hedge-layer"
		}
	)
	ThornKit.wall(game, q, 0, 1, 900)
	var combat: Combat = ThornKit.fight(game, p, q)
	assert_eq(_grown(combat, board[1]), [44, 48], "F2 Sprawl: Grow 4 (its 2 and both Ivies)")
	assert_eq(_grown(combat, board[0]), [34, 38], "F1 Sprawl: Grow 3")
	assert_eq(_grown(combat, board[2]), [16, 32], "Lone Hawthorn: Grow 1")


func test_thorn_wall_heap_eighteen_each_holly_knight_adds_six() -> void:
	_plain_heap(18)
	var board: Dictionary = _board(
		p,
		{
			0: "nettle-skirmisher",
			1: "lone-hawthorn",
			2: "nettle-skirmisher",
			3: "blackthorn-sapling",
			4: "holly-knight",
			5: "ivy-climber",
			6: "holly-knight"
		}
	)
	ThornKit.wall(game, q, 0, 1, 900)
	var combat: Combat = ThornKit.fight(game, p, q)
	var printed: Dictionary = {0: 4, 1: 8, 2: 4, 3: 0}
	var expected: Dictionary = {0: 16, 1: 20, 2: 16, 3: 12}
	for slot: int in expected:
		var view: Dictionary = ThornKit.start_view(combat, board[slot])
		var total: int = printed[slot] + ThornKit.granted(view, "thorn_thorns", "amount")
		assert_eq(total, expected[slot], "slot %d Thorns" % slot)
	for slot: int in [1, 2]:
		var view: Dictionary = ThornKit.start_view(combat, board[slot])
		assert_eq(ThornKit.granted(view, "thorn_grow", "amount"), 1, "the Ivy on F2 and F3")


func test_thorn_wall_small_attackers_die_before_they_land_a_hit() -> void:
	_plain_heap(18)
	_board(p, {0: "nettle-skirmisher", 1: "lone-hawthorn", 4: "holly-knight", 6: "holly-knight"})
	for slot: int in 7:
		ThornKit.wall(game, q, slot, 6, 12)
	var combat: Combat = ThornKit.fight(game, p, q)
	var q_attacks: int = 0
	for i: int in combat.events.size():
		var event: Dictionary = combat.events[i]
		if event["type"] != "attack" or CoreUtil.to_int(event["side"]) != 1:
			continue
		q_attacks += 1
		var thorned: Dictionary = combat.events[i + 2]
		assert_eq(CoreUtil.to_int(thorned["uid"]), CoreUtil.to_int(event["uid"]))
		assert_lte(CoreUtil.to_int(thorned["health"]), 0, "it died on the thorns before its hit")
	assert_gt(q_attacks, 0)
	assert_eq(CoreUtil.to_int(combat.result["winner"]), 0)
	assert_eq(
		ThornKit.triggers(combat, "thorn_lone_hawthorn").size(),
		q_attacks,
		"each Bought attacker the thorns killed went into the Compost"
	)


func test_coppice_returns_and_the_coppicer_pays_the_board_for_good() -> void:
	_plain_heap(10)
	var board: Dictionary = _board(
		p,
		{
			0: "blackthorn-sapling",
			1: "hawthorn-warden",
			2: "nettle-skirmisher",
			3: "crab-apple",
			4: "hazel-coppicer",
			5: "hedge-layer",
			6: "old-stump"
		}
	)
	for slot: int in 7:
		ThornKit.wall(game, q, slot, 40, 80)
	var combat: Combat = ThornKit.fight(game, p, q)
	var returns: int = ThornKit.events(combat, "return", 0).size()
	assert_gte(returns, 3, "the front row dies twice")
	var paid: int = ThornKit.triggers(combat, "thorn_coppicer").size()
	assert_gt(paid, 0)
	var layer: Unit = board[5]
	assert_eq(layer.stats.perm_attack, paid, "each return while it stood: +1/+1 for good")
	var sapling: Unit = board[0]
	assert_gte(sapling.stats.perm_attack, 2, "the Sapling grew when it returned")


func test_mulch_three_buries_a_turn() -> void:
	p.gold = 10
	_plain_heap(16)
	var board: Dictionary = _board(
		p,
		{
			0: "sweetbriar",
			1: "hawthorn-warden",
			2: "crab-apple",
			3: "sweetbriar",
			4: "hedge-layer",
			5: "leafmould-carter",
			6: "leafmould-carter"
		}
	)
	ThornKit.shop(game, p, ["old-stump", "ivy-climber", "crab-apple"])
	var mechanics: Array[String] = ["thorn_bury_gold", "thorn_bury_feed", "thorn_bury_feed"]
	for i: int in 3:
		assert_eq(game.act(0, ThornKit.bury(board[4 + i], mechanics[i], i)), "")
	assert_eq(p.gold, 11, "1 gold")
	assert_eq(p.heap(HEAP).size(), 19, "3 Compost")
	var warden: Unit = board[1]
	assert_eq(warden.stats.perm_attack, 4, "+4/+4 on every Briar")
	var sweet: Unit = board[0]
	assert_eq(sweet.stats.perm_attack, 4 + 3, "and each Sweetbriar 3 more")


func test_regrowth_elder_mother_brings_the_best_two_into_the_empty_slots() -> void:
	ThornKit.fill(game, p, ["t5_avenger", "t4_wall", "t4_cleaver", "t4_phoenix"])
	_plain_heap(10)
	_board(
		p,
		{0: "old-stump", 1: "old-stump", 4: "elder-mother", 5: "hedge-layer", 6: "leafmould-carter"}
	)
	ThornKit.wall(game, q, 0, 1, 900)
	var combat: Combat = ThornKit.fight(game, p, q)
	var summons: Array[Dictionary] = ThornKit.events(combat, "summon", 0).slice(0, 2)
	var placed: Array = []
	for event: Dictionary in summons:
		var buff: Dictionary = ThornKit.about(combat, "buff", CoreUtil.to_int(event["uid"]))[0]
		var base: UnitDef = game.library.get_card(StringName(str(event["id"])))
		placed.append(
			[
				str(event["id"]),
				CoreUtil.to_int(event["slot"]),
				CoreUtil.to_int(buff["attack"]) - base.attack
			]
		)
	assert_eq(placed, [["t5_avenger", 2, 14], ["t4_phoenix", 3, 14]], "F3 and F4, +14/+14 each")
