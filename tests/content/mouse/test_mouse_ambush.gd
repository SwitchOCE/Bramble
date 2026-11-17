extends GutTest
## Ambush belongs to the unit for the whole fight, regardless of which source asks for it.

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


func test_two_attack_cousin_ambushes_only_once() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	CoreKit.put(game, p, "cousin", 1)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var cousin: int = Kit.uid_at(combat, 0, 1)
	assert_eq(Kit.where(combat, "hit", "uid", cousin).size(), 1)
	assert_eq(Kit.damage_by(combat, cousin)[0], 1, "ceil(2 / 2)")


func test_ballista_opening_spends_the_same_charge_as_granted_pile_on() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	var ballista: Unit = CoreKit.put(game, p, "toothpick-ballista", 1)
	assert_true(ballista.grant(game.registry, &"mouse_pile_on"))
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var uid: int = Kit.uid_at(combat, 0, 1)
	assert_eq(Kit.where(combat, "hit", "uid", uid).size(), 1)
	assert_lt(Kit.index_of(combat, "hit", {"uid": uid}), Kit.index_of(combat, "attack"))
	assert_eq(Kit.damage_by(combat, uid)[0], 4)


func test_several_masters_buff_the_same_unit_without_another_ambush_or_replacement() -> void:
	CoreKit.put(game, p, "master-of-engines", 0)
	Kit.golden(game, p, "master-of-engines", 1)
	CoreKit.put(game, p, "needle-pikeman", 4)
	CoreKit.put(game, p, "needle-page", 5)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var pike: int = Kit.uid_at(combat, 0, 4)
	var opening: Array[Dictionary] = Kit.between(combat, 0, Kit.index_of(combat, "attack"), "hit")
	assert_eq(opening.size(), 1)
	assert_eq(opening[0]["uid"], pike)
	assert_eq(Kit.where(combat, "hit", "uid", pike).size(), 1, "Pile on cannot spend again")
	assert_eq(Kit.damage_by(combat, pike), [4] as Array[int], "first Master adds 4 before striking")
	assert_eq(p.board[4].view()["attack"], 4, "opening grants no permanent pile-on growth")
	var gifts: Array[Dictionary] = CoreKit.events_of(combat, "buff").filter(
		func(e: Dictionary) -> bool: return e["uid"] == pike
	)
	assert_eq(gifts.size(), 2, "both Masters still buff the selected unit")


func test_opening_ambush_does_not_pay_cutpurse_or_fencing_master() -> void:
	CoreKit.put(game, p, "master-of-engines", 0)
	var cutpurse: Unit = CoreKit.put(game, p, "shrew-cutpurse", 4)
	CoreKit.put(game, p, "fencing-master", 6)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var uid: int = Kit.uid_at(combat, 0, 4)
	assert_eq(Kit.where(combat, "hit", "uid", uid).size(), 1)
	assert_eq(p.gold_next_turn, 0)
	assert_eq(cutpurse.view()["attack"], 2, "Fencing Master pays only for Pile on")


func test_zero_attack_does_not_spend_a_charge_before_a_later_master_buff() -> void:
	var ballista: Unit = CoreKit.put(game, p, "toothpick-ballista", 4)
	ballista.stats.set_attack = 0
	CoreKit.put(game, p, "master-of-engines", 6)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var uid: int = Kit.uid_at(combat, 0, 4)
	assert_eq(Kit.where(combat, "hit", "uid", uid).size(), 1)
	assert_eq(Kit.damage_by(combat, uid)[0], 2, "the later +4 makes an Ambush possible")
	var gift: int = Kit.index_of(combat, "buff", {"uid": uid})
	assert_gt(Kit.index_of(combat, "hit", {"uid": uid}), gift, "no zero-damage opening")


func test_spent_returned_pikeman_cannot_ambush_or_grow_again() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	var pike: Unit = CoreKit.put(game, p, "needle-pikeman", 1)
	pike.stats.set_health = 1
	assert_true(pike.grant(game.registry, &"reborn"))
	assert_true(pike.grant(game.registry, &"taunt"))
	Kit.wall(game, p, 3, 0, 1000)
	Kit.wall(game, q, 0, 1, 1000)
	var combat: Combat = Kit.fight(game)
	var uid: int = Kit.uid_at(combat, 0, 1)
	var returns: Array[Dictionary] = Kit.where(combat, "return", "from_uid", uid)
	assert_eq(returns.size(), 1)
	assert_eq(Kit.where(combat, "hit", "uid", uid).size(), 1)
	assert_eq(Kit.where(combat, "hit", "uid", returns[0]["uid"]).size(), 0)
	assert_eq(pike.view()["attack"], 7, "one permanent gain across both lives")


func test_unspent_returned_pikeman_can_still_pile_on_and_grow() -> void:
	var pike: Unit = CoreKit.put(game, p, "needle-pikeman", 0)
	pike.stats.set_health = 1
	assert_true(pike.grant(game.registry, &"reborn"))
	assert_true(pike.grant(game.registry, &"taunt"))
	Kit.wall(game, p, 4, 1, 1000)
	Kit.wall(game, q, 0, 1, 1000)
	Kit.wall(game, q, 1, 0, 1000)
	Kit.wall(game, q, 2, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var uid: int = Kit.uid_at(combat, 0, 0)
	var returns: Array[Dictionary] = Kit.where(combat, "return", "from_uid", uid)
	assert_eq(returns.size(), 1)
	assert_eq(Kit.where(combat, "hit", "uid", uid).size(), 0)
	assert_eq(Kit.where(combat, "hit", "uid", returns[0]["uid"]).size(), 1)
	assert_eq(pike.view()["attack"], 7, "unspent allowance survives death too")


func test_odd_attack_ambush_rounds_half_up() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	var cousin: Unit = CoreKit.put(game, p, "cousin", 1)
	cousin.stats.set_attack = 3
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var uid: int = Kit.uid_at(combat, 0, 1)
	assert_eq(Kit.damage_by(combat, uid)[0], 2, "ceil(3 / 2)")
	assert_eq(Kit.where(combat, "hit", "uid", uid).size(), 1)
