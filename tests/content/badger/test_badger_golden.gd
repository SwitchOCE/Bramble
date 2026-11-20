extends GutTest
## Each Badger unit's golden copy behaves as the design's `golden` line says (7.3.5), one test
## per unit, in a real fight or recruit turn. The golden texts are checked in
## test_badger_content.gd.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const BadgerKit := preload("res://tests/content/badger/badger_kit.gd")

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = BadgerKit.session()
	p = game.player(0)
	q = game.player(1)


func _enemies(count: int, attack: int = 1, health: int = 100) -> void:
	for slot: int in count:
		BadgerKit.plain(game, q, slot, attack, health)


## `count` plain enemies on the board of the player p fights at the end of the round.
func _rivals(count: int) -> void:
	var rival: PlayerState = BadgerKit.opponent(game, p)
	for slot: int in count:
		BadgerKit.plain(game, rival, slot, 1, 100)


## The Attack shown by the first buff `uid` gets after its first trigger of `mechanic`.
func _after_first(combat: Combat, mechanic: String, uid: int) -> int:
	var fired: Array[Dictionary] = BadgerKit.triggers(combat, mechanic, uid)
	if fired.is_empty():
		return -1
	var buff: Dictionary = BadgerKit.next_buff(combat, BadgerKit.index_of(combat, fired[0]), uid)
	return CoreUtil.to_int(buff.get("attack", -1))


## The Fury `uid` was given in this fight, as [params] of its effect events.
func _given(combat: Combat, uid: int) -> Array:
	return (
		BadgerKit
		. events(combat, "effect")
		. filter(func(e: Dictionary) -> bool: return CoreUtil.to_int(e["uid"]) == uid)
		. map(func(e: Dictionary) -> Dictionary: return e["params"])
	)


func test_golden_brock_cub_fury_2_and_grudge_2_health_and_2_2_for_each() -> void:
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 0, true)
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)), 4 + 2 * (1 + 3))
	game = BadgerKit.session()
	p = game.player(0)
	cub = BadgerKit.put(game, p, "brock-cub", 0, true)
	_rivals(4)
	game.finish_round()
	game.start_round()
	assert_eq([cub.stats.perm_attack, cub.stats.perm_health], [2 * 3, 2 * (1 + 3)])


func test_golden_hedge_knight_fury_2() -> void:
	BadgerKit.put(game, p, "hedge-knight", 0, true)
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)), 4 + 2 * (1 + 3))


func test_golden_sett_shield_bearer_lends_its_doubled_health_and_grudge_2() -> void:
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 0)
	var bearer: Unit = BadgerKit.put(game, p, "sett-shield-bearer", 4, true)
	assert_eq(cub.health(), 6 + 16, "lends its own Health, 16, not 32")
	_rivals(5)
	game.finish_round()
	game.start_round()
	assert_eq([bearer.stats.perm_attack, bearer.stats.perm_health], [2 * 4, 2 * (1 + 4)])


func test_golden_armsbearer_lends_its_doubled_attack_and_grudge_2() -> void:
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 0)
	var bearer: Unit = BadgerKit.put(game, p, "armsbearer", 4, true)
	assert_eq(cub.attack(), 2 + 6, "lends its own Attack, 6, not 12")
	_rivals(5)
	game.finish_round()
	game.start_round()
	assert_eq([bearer.stats.perm_attack, bearer.stats.perm_health], [2 * 4, 2 * (1 + 4)])


func test_golden_relic_seeker_pays_4_gold_plus_2_per_unit() -> void:
	BadgerKit.put(game, p, "brock-cub", 0)
	BadgerKit.put(game, p, "relic-seeker", 4, true)
	_rivals(5)
	game.finish_round()
	game.start_round()
	var paid: Array[Dictionary] = BadgerKit.game_log(game, p, "gold")
	assert_eq(paid.size(), 1)
	assert_eq(CoreUtil.to_int(paid[0]["amount"]), 12, "outnumbered by 4")
	game = BadgerKit.session()
	p = game.player(0)
	BadgerKit.put(game, p, "brock-cub", 0)
	BadgerKit.put(game, p, "relic-seeker", 4, true)
	_rivals(1)
	game.finish_round()
	game.start_round()
	paid = BadgerKit.game_log(game, p, "gold")
	assert_eq(paid.size(), 1)
	assert_eq(CoreUtil.to_int(paid[0]["amount"]), 4, "not outnumbered")


func test_golden_gate_warden_gains_2_6() -> void:
	var warden: Unit = BadgerKit.put(game, p, "gate-warden", 0, true)
	_enemies(2)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var fired: int = BadgerKit.triggers(combat, "badger_gate_warden").size()
	assert_gt(fired, 0)
	assert_eq([warden.stats.perm_attack, warden.stats.perm_health], [2 * fired, 6 * fired])


func test_golden_grudge_keeper_fury_2_and_gives_grudge_2_2() -> void:
	BadgerKit.put(game, p, "grudge-keeper", 0, true)
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)), 8 + 2 * (1 + 3))
	game = BadgerKit.session()
	p = game.player(0)
	BadgerKit.put(game, p, "grudge-keeper", 0, true)
	var knight: Unit = BadgerKit.put(game, p, "hedge-knight", 1)
	_rivals(5)
	game.finish_round()
	game.start_round()
	assert_eq(knight.stats.perm_attack, 2 * 3)
	assert_eq(knight.stats.perm_health, 2 * (1 + 3))


func test_golden_hedge_lancer_fury_2() -> void:
	BadgerKit.put(game, p, "hedge-lancer", 0, true)
	_enemies(3)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)), 12 + 2 * (1 + 2))


func test_golden_sword_heir_gains_double_the_attack_and_health_not_the_fury() -> void:
	BadgerKit.put(game, p, "hedge-knight", 1)
	BadgerKit.put(game, p, "sword-heir", 4, true)
	BadgerKit.plain(game, q, 0, 100, 100)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var heir: int = BadgerKit.uid_at(combat, 0, 4)
	var fired: Array[Dictionary] = BadgerKit.triggers(combat, "badger_sword_heir", heir)
	assert_eq(fired.size(), 1)
	var buff: Dictionary = BadgerKit.next_buff(combat, BadgerKit.index_of(combat, fired[0]), heir)
	assert_eq([buff["attack"], buff["health"]], [6 + 2 * (2 + 1), 18 + 2 * 8], "its Fury gave it 1")
	assert_eq(_given(combat, heir), [{"fury": 1}], "the Knight's Fury 1, once")


func test_golden_herald_of_the_charge_lends_2_fury() -> void:
	BadgerKit.plain(game, p, 0, 1, 30)
	BadgerKit.plain(game, p, 1, 1, 30)
	var herald: Unit = BadgerKit.put(game, p, "herald-of-the-charge", 4, true)
	assert_eq([herald.attack(), herald.health()], [8, 20])
	_enemies(3, 2, 30)
	var combat: Combat = BadgerKit.fight(game, p, q)
	for slot: int in [0, 1]:
		assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, slot)), 5)


func test_golden_greatsword_bearer_grants_overrun_to_the_front_row() -> void:
	var striker: Unit = BadgerKit.plain(game, p, 3, 30, 30)
	var bearer: Unit = BadgerKit.put(game, p, "greatsword-bearer", 4, true)
	assert_eq([bearer.attack(), bearer.health()], [8, 24])
	assert_true(striker.has_mechanic(&"badger_overrun"))
	var overruns: int = 0
	for bound: BoundMechanic in striker.hooks():
		overruns += 1 if bound.id == &"badger_overrun" else 0
	assert_eq(overruns, 1)


func test_golden_sett_sexton_gives_4_attack_still_2_a_fight() -> void:
	var knight: Unit = BadgerKit.put(game, p, "hedge-knight", 0)
	var sexton: Unit = BadgerKit.put(game, p, "sett-sexton", 4, true)
	assert_eq([sexton.attack(), sexton.health()], [6, 24])
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var uid: int = BadgerKit.uid_at(combat, 0, 0)
	assert_gt(BadgerKit.triggers(combat, "badger_fury", uid).size(), 3)
	assert_eq(BadgerKit.triggers(combat, "badger_sexton").size(), 2, "the limit isn't doubled")
	assert_eq(knight.stats.perm_attack, 4 * 2, "the amount is")


func test_golden_master_at_arms_gives_2_fury() -> void:
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 0)
	assert_true(
		game.recruit._gain(p, BadgerKit.CoreKit.unit(game, "master-at-arms", true), cub.uid)
	)
	var given: Array = cub.view()["effects"].filter(
		func(e: Dictionary) -> bool: return e["mechanic"] == "badger_fury"
	)
	assert_eq(given.map(func(e: Dictionary) -> int: return e["fury"]), [1, 2])


func test_golden_ironhide_berserker_fury_6() -> void:
	BadgerKit.put(game, p, "ironhide-berserker", 0, true)
	_enemies(7)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)), 16 + 6 * (1 + 6))


func test_golden_dame_gives_knights_4_fury() -> void:
	BadgerKit.put(game, p, "dame-of-the-old-sett", 0, true)
	BadgerKit.put(game, p, "hedge-knight", 1)
	_enemies(6)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var uid: int = BadgerKit.uid_at(combat, 0, 1)
	assert_eq(_after_first(combat, "badger_fury", uid), 2 + (1 + 4) * (1 + 4))


func test_golden_tourney_champion_fury_2() -> void:
	BadgerKit.put(game, p, "tourney-champion", 0, true)
	_enemies(3)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)), 28 + 2 * (1 + 2))


func test_golden_oakfeller_fury_6() -> void:
	BadgerKit.put(game, p, "the-oakfeller", 0, true)
	_enemies(3, 1, 200)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)), 24 + 6 * (1 + 2))


func test_golden_old_brock_gains_double() -> void:
	BadgerKit.put(game, p, "old-brock", 0, true)
	BadgerKit.put(game, p, "t1_guard", 1)
	BadgerKit.plain(game, q, 0, 50, 100)
	BadgerKit.plain(game, q, 1, 1, 100)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var brock: int = BadgerKit.uid_at(combat, 0, 0)
	var guard: Dictionary = BadgerKit.shown_at(combat, 0, 1)
	var fired: Array[Dictionary] = BadgerKit.triggers(combat, "badger_old_brock", brock)
	assert_gt(fired.size(), 0)
	var buff: Dictionary = BadgerKit.next_buff(combat, BadgerKit.index_of(combat, fired[0]), brock)
	assert_eq(buff["attack"], 16 + 2 * CoreUtil.to_int(guard["attack"]))


func test_golden_marshal_triples_fury_from_the_back_row_as_a_squire() -> void:
	BadgerKit.put(game, p, "marshal-of-the-red-mist", 4, true)
	BadgerKit.put(game, p, "brock-cub", 1)
	_enemies(5)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 1)), 2 + 3 * (1 + 4))
