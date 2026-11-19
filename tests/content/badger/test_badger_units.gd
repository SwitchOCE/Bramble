extends GutTest
## Each Badger unit's text, proved in a real fight or recruit turn through the core: the fight
## log, the game log or the recruit view. Enemies are plain neutral units with set stats.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const BadgerKit := preload("res://tests/content/badger/badger_kit.gd")

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = BadgerKit.session()
	p = game.player(0)
	q = game.player(1)


## `count` plain enemies with these stats on q's board, front row first.
func _enemies(count: int, attack: int = 1, health: int = 100) -> void:
	for slot: int in count:
		BadgerKit.plain(game, q, slot, attack, health)


## This round's fight of `player` (GameSession.fights).
func _fight_of(player: PlayerState) -> Dictionary:
	for fight: Dictionary in game.fights:
		if fight["players"].has(player.id):
			return fight
	return {}


## The Attack shown by the first buff `uid` gets after its first trigger of `mechanic`.
func _after_first(combat: Combat, mechanic: String, uid: int) -> int:
	var fired: Array[Dictionary] = BadgerKit.triggers(combat, mechanic, uid)
	if fired.is_empty():
		return -1
	var buff: Dictionary = BadgerKit.next_buff(combat, BadgerKit.index_of(combat, fired[0]), uid)
	return CoreUtil.to_int(buff.get("attack", -1))


func test_brock_cub_fury_gains_1_attack_and_1_more_for_each_unit_it_is_outnumbered_by() -> void:
	BadgerKit.put(game, p, "brock-cub", 0)
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(combat.events[0]["outnumbered_by"], [3, 0])
	var cub: int = BadgerKit.uid_at(combat, 0, 0)
	assert_eq(_after_first(combat, "badger_fury", cub), 2 + 1 * (1 + 3), "Fury 1 x (1 + 3)")
	var fired: Array[Dictionary] = BadgerKit.triggers(combat, "badger_fury", cub)
	assert_gt(fired.size(), 1, "on every attack it makes or takes")
	var buff: Dictionary = BadgerKit.next_buff(combat, BadgerKit.index_of(combat, fired[0]), cub)
	assert_false(buff["permanent"], "this fight only")


## Balance pass 1 (19 Nov 2026): Fury pays a floor, so a count of 0 still gives Fury N.
func test_brock_cub_fury_gives_1_attack_when_not_outnumbered() -> void:
	BadgerKit.put(game, p, "brock-cub", 0)
	_enemies(1)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(combat.outnumbered_by(0), 0)
	var cub: int = BadgerKit.uid_at(combat, 0, 0)
	assert_gt(BadgerKit.triggers(combat, "badger_fury", cub).size(), 0, "it rages anyway")
	assert_eq(_after_first(combat, "badger_fury", cub), 2 + 1, "Fury 1 at a count of 0: +1")


func test_fury_3_outnumbered_by_2_gives_3_times_3() -> void:
	BadgerKit.put(game, p, "ironhide-berserker", 0)
	_enemies(3)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(combat.outnumbered_by(0), 2)
	var uid: int = BadgerKit.uid_at(combat, 0, 0)
	assert_eq(_after_first(combat, "badger_fury", uid), 8 + 3 * 3, "N and 2N more: 3N")


func test_brock_cub_grudge_keeps_1_health_and_1_1_more_for_each_unit_even_dead() -> void:
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 0)
	var rival: PlayerState = BadgerKit.opponent(game, p)
	for slot: int in 4:
		BadgerKit.plain(game, rival, slot, 60, 100)
	game.finish_round()
	var fight: Dictionary = _fight_of(p)
	assert_false(fight["result"]["survivors"][fight["players"].find(p.id)].size() > 0, "it died")
	assert_eq(cub.stats.perm_attack, 3, "+1 Attack x 3")
	assert_eq(cub.stats.perm_health, 1 + 3, "+1 Health, and +1 x 3 more")


func test_grudge_gives_1_health_and_no_attack_when_not_outnumbered() -> void:
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 0)
	var rival: PlayerState = BadgerKit.opponent(game, p)
	BadgerKit.plain(game, rival, 0, 1, 100)
	game.finish_round()
	var fight: Dictionary = _fight_of(p)
	assert_eq(fight["result"]["outnumbered_by"][fight["players"].find(p.id)], 0)
	assert_eq(cub.stats.perm_attack, 0, "no Attack at a count of 0")
	assert_eq(cub.stats.perm_health, 1, "the Health floor")


func test_hedge_knight_has_guard_and_fury() -> void:
	BadgerKit.put(game, p, "hedge-knight", 0)
	BadgerKit.plain(game, p, 1, 1, 100)
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var knight: int = BadgerKit.uid_at(combat, 0, 0)
	var against: Array[Dictionary] = BadgerKit.events(combat, "attack").filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["side"]) == 1
	)
	for event: Dictionary in against.slice(0, 4):
		assert_eq(CoreUtil.to_int(event["target_uid"]), knight, "enemies attack the Guard first")
	assert_eq(_after_first(combat, "badger_fury", knight), 2 + 1 * (1 + 2), "attacked: 1 x (1 + 2)")


func test_sett_shield_bearer_lends_health_is_a_squire_and_has_grudge() -> void:
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 0)
	var friend: Unit = BadgerKit.plain(game, p, 1, 2, 4)
	var bearer: Unit = BadgerKit.put(game, p, "sett-shield-bearer", 4)
	assert_eq(cub.health(), 6 + 8, "lent to F1")
	assert_eq(friend.health(), 4 + 8, "and F2, any tribe")
	assert_eq(cub.stats.own_health(), 6, "lent Health is borrowed")
	var rival: PlayerState = BadgerKit.opponent(game, p)
	for slot: int in 5:
		BadgerKit.plain(game, rival, slot, 1, 100)
	game.finish_round()
	var fight: Dictionary = _fight_of(p)
	var side: int = fight["players"].find(p.id)
	assert_eq(fight["result"]["outnumbered_by"][side], 5 - 2, "the back-row Squire isn't counted")
	assert_eq(bearer.stats.perm_attack, 3, "Grudge")
	assert_eq(bearer.stats.perm_health, 1 + 3)


func test_a_squire_in_the_front_row_is_counted() -> void:
	BadgerKit.put(game, p, "brock-cub", 0)
	BadgerKit.put(game, p, "sett-shield-bearer", 1)
	_enemies(5)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(combat.outnumbered_by(0), 5 - 2)


func test_armsbearer_lends_attack_to_the_units_in_front() -> void:
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 1)
	BadgerKit.put(game, p, "armsbearer", 5)
	var far: Unit = BadgerKit.plain(game, p, 0, 2, 4)
	assert_eq(cub.attack(), 2 + 3, "B2 lends to F2 and F3")
	assert_eq(far.attack(), 2, "not to F1")
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var shown: Dictionary = BadgerKit.shown_at(combat, 0, 1)
	assert_eq(shown["attack"], 5, "lent in the fight too")
	assert_eq(combat.outnumbered_by(0), 4 - 2)
	assert_eq(_after_first(combat, "badger_fury", CoreUtil.to_int(shown["uid"])), 5 + 1 * (1 + 2))


func test_relic_seeker_pays_2_gold_when_outnumbered_by_3_or_more_and_only_one_pays() -> void:
	BadgerKit.put(game, p, "brock-cub", 0)
	var seeker: Unit = BadgerKit.put(game, p, "relic-seeker", 4)
	BadgerKit.put(game, p, "relic-seeker", 5)
	var rival: PlayerState = BadgerKit.opponent(game, p)
	for slot: int in 6:
		BadgerKit.plain(game, rival, slot, 1, 100)
	var before: int = p.gold
	game.finish_round()
	var paid: Array[Dictionary] = BadgerKit.game_log(game, p, "gold")
	assert_eq(paid.size(), 1, "only one Relic Seeker pays")
	assert_eq(CoreUtil.to_int(paid[0]["source_uid"]), seeker.uid, "the first, on a tie")
	assert_eq(p.gold - before, 2, "outnumbered by 5: 2 gold")


func test_relic_seeker_pays_1_gold_when_not_outnumbered() -> void:
	BadgerKit.put(game, p, "brock-cub", 0)
	var seeker: Unit = BadgerKit.put(game, p, "relic-seeker", 4)
	BadgerKit.plain(game, BadgerKit.opponent(game, p), 0, 1, 100)
	var before: int = p.gold
	game.finish_round()
	var fight: Dictionary = _fight_of(p)
	assert_eq(fight["result"]["outnumbered_by"][fight["players"].find(p.id)], 0)
	var paid: Array[Dictionary] = BadgerKit.game_log(game, p, "gold")
	assert_eq(paid.size(), 1)
	assert_eq(CoreUtil.to_int(paid[0]["source_uid"]), seeker.uid)
	assert_eq(p.gold - before, 1, "a count of 0: 1 gold")


func test_relic_seeker_pays_1_gold_at_a_count_of_2_and_2_at_exactly_3() -> void:
	for count: int in [2, 3]:
		game = BadgerKit.session()
		p = game.player(0)
		BadgerKit.put(game, p, "brock-cub", 0)
		BadgerKit.put(game, p, "relic-seeker", 4)
		var rival: PlayerState = BadgerKit.opponent(game, p)
		for slot: int in count + 1:
			BadgerKit.plain(game, rival, slot, 1, 100)
		var before: int = p.gold
		game.finish_round()
		var fight: Dictionary = _fight_of(p)
		assert_eq(fight["result"]["outnumbered_by"][fight["players"].find(p.id)], count)
		assert_eq(p.gold - before, 1 if count < 3 else 2, "outnumbered by %d" % count)


func test_a_golden_relic_seeker_pays_4_when_outnumbered_by_3_and_beats_a_plain_one() -> void:
	BadgerKit.put(game, p, "brock-cub", 0)
	BadgerKit.put(game, p, "relic-seeker", 4)
	var golden: Unit = BadgerKit.put(game, p, "relic-seeker", 5, true)
	var rival: PlayerState = BadgerKit.opponent(game, p)
	for slot: int in 5:
		BadgerKit.plain(game, rival, slot, 1, 100)
	game.finish_round()
	var paid: Array[Dictionary] = BadgerKit.game_log(game, p, "gold")
	assert_eq(paid.size(), 1)
	assert_eq(CoreUtil.to_int(paid[0]["source_uid"]), golden.uid, "the one that pays most")
	assert_eq(CoreUtil.to_int(paid[0]["amount"]), 4, "outnumbered by 4: golden 2 x 2")


func test_gate_warden_gains_1_3_permanently_whenever_it_is_attacked() -> void:
	var warden: Unit = BadgerKit.put(game, p, "gate-warden", 0)
	_enemies(2)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var uid: int = BadgerKit.uid_at(combat, 0, 0)
	var attacked: int = (
		BadgerKit
		. events(combat, "attack")
		. filter(func(e: Dictionary) -> bool: return CoreUtil.to_int(e["target_uid"]) == uid)
		. size()
	)
	assert_gt(attacked, 0)
	assert_eq(BadgerKit.triggers(combat, "badger_gate_warden", uid).size(), attacked)
	assert_eq(warden.stats.perm_attack, 1 * attacked, "kept on the real unit")
	assert_eq(warden.stats.perm_health, 3 * attacked)


func test_grudge_keeper_gives_every_knight_grudge_once_and_squires_keep_their_own() -> void:
	var keeper: Unit = BadgerKit.put(game, p, "grudge-keeper", 0)
	var knight: Unit = BadgerKit.put(game, p, "hedge-knight", 1)
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 2)
	var bearer: Unit = BadgerKit.put(game, p, "sett-shield-bearer", 4)
	var seeker: Unit = BadgerKit.put(game, p, "relic-seeker", 5)
	assert_true(knight.has_mechanic(&"badger_grudge"), "shown on the Knight")
	var rival: PlayerState = BadgerKit.opponent(game, p)
	for slot: int in 7:
		BadgerKit.plain(game, rival, slot, 1, 100)
	game.finish_round()
	assert_eq(keeper.stats.perm_attack, 4, "outnumbered by 4, itself included")
	assert_eq(knight.stats.perm_health, 1 + 4, "a Knight with no Grudge of its own")
	assert_eq(cub.stats.perm_attack, 4, "a Knight with Grudge gets it once")
	assert_eq(bearer.stats.perm_attack, 4, "a Squire keeps its own Grudge")
	assert_eq(seeker.stats.perm_attack, 0, "a Squire is not a Knight")
	assert_eq(seeker.stats.perm_health, 0, "not even the Health floor")


func test_a_golden_grudge_keeper_gives_the_bigger_grudge_and_two_keepers_do_not_stack() -> void:
	BadgerKit.put(game, p, "grudge-keeper", 0, true)
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 1)
	var plain_keeper: Unit = BadgerKit.put(game, p, "grudge-keeper", 2)
	var rival: PlayerState = BadgerKit.opponent(game, p)
	for slot: int in 6:
		BadgerKit.plain(game, rival, slot, 1, 100)
	game.finish_round()
	assert_eq(cub.stats.perm_attack, 2 * 3, "+2/+2 x 3, not +1 and +2 added")
	assert_eq(cub.stats.perm_health, 2 * (1 + 3), "and the floor is +2 Health")
	assert_eq(plain_keeper.stats.perm_attack, 2 * 3)


func test_hedge_lancer_attacks_first_and_takes_no_damage_from_it() -> void:
	BadgerKit.put(game, p, "hedge-lancer", 0)
	_enemies(1, 5, 30)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var lancer: int = BadgerKit.uid_at(combat, 0, 0)
	var attacks: Array[Dictionary] = BadgerKit.events(combat, "attack")
	assert_eq(CoreUtil.to_int(attacks[0]["uid"]), lancer, "Start of fight")
	var first: int = BadgerKit.index_of(combat, attacks[0])
	var second: int = BadgerKit.index_of(combat, attacks[1])
	for i: int in range(first, second):
		var event: Dictionary = combat.events[i]
		if event["type"] == "damage":
			assert_ne(CoreUtil.to_int(event["uid"]), lancer, "no strike back")
	var hurt: Array[Dictionary] = BadgerKit.events(combat, "damage").filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["uid"]) == lancer
	)
	assert_gt(hurt.size(), 0, "its later attacks are normal")


func test_sword_heir_takes_the_own_stats_and_fury_of_a_unit_that_dies_in_front() -> void:
	var knight: Unit = BadgerKit.put(game, p, "hedge-knight", 1)
	knight.stats.perm_attack = 3
	knight.stats.perm_health = 3
	BadgerKit.put(game, p, "sword-heir", 4)
	BadgerKit.put(game, p, "sett-shield-bearer", 5)
	p.slots[1].renown = 5
	game.recruit.refresh_auras(p)
	assert_eq(knight.health(), 8 + 3 + 5 + 8, "Renown and lent Health on the Knight")
	BadgerKit.plain(game, q, 0, 100, 100)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var heir: int = BadgerKit.uid_at(combat, 0, 4)
	var fired: Array[Dictionary] = BadgerKit.triggers(combat, "badger_sword_heir", heir)
	assert_eq(fired.size(), 1)
	var buff: Dictionary = BadgerKit.next_buff(combat, BadgerKit.index_of(combat, fired[0]), heir)
	assert_eq(
		buff["attack"],
		3 + 5 + 1,
		"the Knight's own 5 Attack and its 1 from Fury, excluding its Renown"
	)
	assert_eq(buff["health"], 9 + 11, "its own 11 Health, excluding lent Health and Renown")
	var fury: Array[Dictionary] = BadgerKit.events(combat, "effect").filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["uid"]) == heir
	)
	assert_eq(fury.size(), 1)
	assert_eq(fury[0]["mechanic"], "badger_fury")
	assert_eq(fury[0]["params"], {"fury": 1}, "and its Fury 1")
	assert_false(fury[0]["permanent"], "this fight")


func test_sword_heir_ignores_a_death_that_is_not_in_front_of_it() -> void:
	BadgerKit.put(game, p, "hedge-knight", 2)
	BadgerKit.put(game, p, "sword-heir", 4)
	BadgerKit.plain(game, q, 0, 100, 100)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(BadgerKit.triggers(combat, "badger_sword_heir").size(), 0)


func test_herald_of_the_charge_makes_the_units_in_front_attack_at_the_start() -> void:
	BadgerKit.plain(game, p, 0, 1, 30)
	BadgerKit.plain(game, p, 1, 1, 30)
	BadgerKit.put(game, p, "herald-of-the-charge", 4)
	_enemies(3, 2, 30)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var attacks: Array[Dictionary] = BadgerKit.events(combat, "attack")
	assert_eq(CoreUtil.to_int(attacks[0]["uid"]), BadgerKit.uid_at(combat, 0, 0), "left first")
	assert_eq(CoreUtil.to_int(attacks[1]["uid"]), BadgerKit.uid_at(combat, 0, 1))
	var herald: Array[Dictionary] = BadgerKit.triggers(combat, "badger_herald")
	assert_eq(herald.size(), 1)
	assert_lt(BadgerKit.index_of(combat, herald[0]), BadgerKit.index_of(combat, attacks[0]))
	var hurt: Array[Dictionary] = BadgerKit.events(combat, "damage").filter(
		func(e: Dictionary) -> bool:
			return CoreUtil.to_int(e["uid"]) == CoreUtil.to_int(attacks[0]["uid"])
	)
	assert_gt(hurt.size(), 0, "a normal attack: it takes the strike back")


func test_greatsword_bearer_gives_overrun_and_the_rest_carries_on() -> void:
	var striker: Unit = BadgerKit.plain(game, p, 0, 30, 30)
	BadgerKit.put(game, p, "greatsword-bearer", 4)
	assert_true(striker.has_mechanic(&"badger_overrun"), "any tribe in front")
	_enemies(3, 2, 4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var uid: int = BadgerKit.uid_at(combat, 0, 0)
	assert_eq(combat.result["winner"], 0)
	var mine: Array[Dictionary] = BadgerKit.events(combat, "attack").filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["uid"]) == uid
	)
	assert_eq(mine.size(), 1, "one attack killed what was left")
	assert_gt(BadgerKit.triggers(combat, "badger_overrun", uid).size(), 0)
	var deaths: Array[Dictionary] = BadgerKit.events(combat, "death").filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["side"]) == 1
	)
	assert_eq(deaths.size(), 3)
	for death: Dictionary in deaths:
		assert_eq(CoreUtil.to_int(death["killer_uid"]), uid, "Overrun's kills are the attacker's")
	var hits_back: Array[Dictionary] = BadgerKit.events(combat, "damage").filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["uid"]) == uid
	)
	assert_lte(hits_back.size(), 2, "only attacked targets strike back")


func test_overrun_does_not_carry_a_strike_back() -> void:
	for slot: int in 3:
		BadgerKit.plain(game, p, slot, 1, 2)
	BadgerKit.put(game, q, "ironhide-berserker", 0)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var berserker: int = BadgerKit.uid_at(combat, 1, 0)
	var attacks: Array[Dictionary] = BadgerKit.events(combat, "attack")
	assert_ne(CoreUtil.to_int(attacks[0]["uid"]), berserker, "the wider side attacks first")
	assert_gt(attacks.size(), 1, "the strike back didn't sweep the board")
	var end: int = (
		BadgerKit.index_of(combat, attacks[1]) if attacks.size() > 1 else combat.events.size()
	)
	for i: int in range(BadgerKit.index_of(combat, attacks[0]), end):
		var event: Dictionary = combat.events[i]
		if event["type"] == "trigger":
			assert_ne(event["mechanic"], "badger_overrun", "it was attacked: no carry")
	var deaths: Array[Dictionary] = BadgerKit.events(combat, "death").filter(
		func(e: Dictionary) -> bool: return BadgerKit.index_of(combat, e) < end
	)
	assert_eq(deaths.size(), 1, "only the attacker fell")


## A shield takes the whole 30: nothing was killed, so nothing carries to the enemy behind it.
func test_overrun_stops_at_a_divine_shield() -> void:
	BadgerKit.plain(game, p, 0, 30, 30)
	BadgerKit.put(game, p, "greatsword-bearer", 4)
	BadgerKit.plain(game, p, 5, 0, 1)
	BadgerKit.plain(game, p, 6, 0, 1)
	BadgerKit.put(game, q, "t2_shield", 0)
	BadgerKit.plain(game, q, 4, 1, 50)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var attacker: int = BadgerKit.uid_at(combat, 0, 0)
	var shield: int = BadgerKit.uid_at(combat, 1, 0)
	var behind: int = BadgerKit.uid_at(combat, 1, 4)
	var attacks: Array[Dictionary] = BadgerKit.events(combat, "attack")
	assert_eq(CoreUtil.to_int(attacks[0]["uid"]), attacker, "the wider side attacks first")
	assert_eq(CoreUtil.to_int(attacks[0]["target_uid"]), shield, "the only front-row enemy")
	var start: int = BadgerKit.index_of(combat, attacks[0])
	var end: int = BadgerKit.index_of(combat, attacks[1])
	var blocked: Array[int] = []
	for i: int in range(start, end):
		var event: Dictionary = combat.events[i]
		if event["type"] == "prevented":
			assert_eq(CoreUtil.to_int(event["uid"]), shield)
			blocked.append(CoreUtil.to_int(event["amount"]))
		elif event["type"] == "damage":
			assert_ne(CoreUtil.to_int(event["uid"]), behind, "nothing carried past the shield")
		elif event["type"] == "trigger":
			assert_ne(event["mechanic"], "badger_overrun")
	assert_eq(blocked, [30], "the shield took the whole attack")


## The Sexton's gains in a fight, as {uid: [permanent flags]} of the buffs it gave.
func _sexton_buffs(combat: Combat) -> Dictionary:
	var out: Dictionary = {}
	for i: int in combat.events.size():
		var event: Dictionary = combat.events[i]
		if (
			event["type"] != "buff"
			or str(combat.events[i - 1].get("mechanic", "")) != "badger_sexton"
		):
			continue
		var uid: int = CoreUtil.to_int(event["uid"])
		if not out.has(uid):
			out[uid] = []
		out[uid].append(event["permanent"])
	return out


func test_sett_sexton_gives_2_attack_for_good_after_fury_2_a_fight_for_each_unit() -> void:
	var knight: Unit = BadgerKit.put(game, p, "hedge-knight", 0)
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 1)
	BadgerKit.put(game, p, "sett-sexton", 4)
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var knight_uid: int = BadgerKit.uid_at(combat, 0, 0)
	var cub_uid: int = BadgerKit.uid_at(combat, 0, 1)
	var raged: int = BadgerKit.triggers(combat, "badger_fury", knight_uid).size()
	assert_gt(raged, 2, "the Guard rages more than 2 times")
	var paid: Dictionary = _sexton_buffs(combat)
	assert_eq(paid.get(knight_uid, []), [true, true], "2 a fight, each permanent")
	assert_eq(paid.get(cub_uid, []).size(), 2, "and 2 for the other unit in front")
	assert_eq(BadgerKit.triggers(combat, "badger_sexton").size(), 4)
	assert_eq(knight.stats.perm_attack, 2 * 2, "kept on the recruit unit")
	assert_eq(knight.stats.perm_health, 0, "Attack only")
	assert_eq(cub.stats.perm_attack, 2 * 2)
	var fired: Array[Dictionary] = BadgerKit.triggers(combat, "badger_fury", knight_uid)
	var first: Dictionary = BadgerKit.next_buff(
		combat, BadgerKit.index_of(combat, fired[0]), knight_uid
	)
	var after: Dictionary = BadgerKit.next_buff(
		combat, BadgerKit.index_of(combat, first), knight_uid
	)
	assert_eq(
		CoreUtil.to_int(after["attack"]) - CoreUtil.to_int(first["attack"]), 2, "in the fight too"
	)
	combat = BadgerKit.fight(game, p, q)
	assert_eq(_sexton_buffs(combat).get(BadgerKit.uid_at(combat, 0, 0), []).size(), 2, "next fight")
	assert_eq(knight.stats.perm_attack, 2 * 4, "2 more the next fight")


func test_sett_sexton_reaches_only_the_units_in_front_of_it() -> void:
	var near: Unit = BadgerKit.put(game, p, "brock-cub", 1)
	var far: Unit = BadgerKit.put(game, p, "hedge-knight", 2)
	var sexton: Unit = BadgerKit.put(game, p, "sett-sexton", 4)
	assert_eq(game.geometry.in_front_of(4), [0, 1] as Array[int])
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var far_uid: int = BadgerKit.uid_at(combat, 0, 2)
	assert_gt(BadgerKit.triggers(combat, "badger_fury", far_uid).size(), 0, "F3 rages")
	assert_false(_sexton_buffs(combat).has(far_uid), "but is not in front of B1")
	assert_eq(far.stats.perm_attack, 0)
	assert_gt(near.stats.perm_attack, 0, "F2 is in front of B1")
	assert_eq(sexton.stats.perm_attack, 0, "not itself")


func test_sett_sexton_pays_nothing_without_fury() -> void:
	BadgerKit.plain(game, p, 0, 2, 100)
	BadgerKit.put(game, p, "sett-sexton", 4)
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(BadgerKit.triggers(combat, "badger_sexton").size(), 0)


func test_master_at_arms_gives_a_unit_1_fury_for_good() -> void:
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 0)
	var master: Unit = BadgerKit.CoreKit.unit(game, "master-at-arms")
	assert_true(game.recruit._gain(p, master))
	var choices: Array[Dictionary] = game.legal_actions(p.id).filter(
		func(a: Dictionary) -> bool: return a["type"] == "recruit_target" and a["target"] == cub.uid
	)
	assert_gt(choices.size(), 0, "a bot can aim it")
	assert_eq(game.act(p.id, {"type": "recruit_target", "target": cub.uid}), "")
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 1}), "")
	assert_eq(
		cub.view()["effects"].filter(
			func(e: Dictionary) -> bool: return e["mechanic"] == "badger_fury"
		),
		[{"mechanic": "badger_fury", "fury": 1}, {"mechanic": "badger_fury", "fury": 1}],
		"its printed Fury 1 and the given +1"
	)
	var fury: int = 0
	for bound: BoundMechanic in cub.hooks():
		if bound.id == &"badger_fury":
			fury += bound.params.num(&"fury")
	assert_eq(fury, 2, "Fury 1 becomes Fury 2")
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)), 2 + 2 * (1 + 2))


func test_master_at_arms_may_give_its_fury_to_itself() -> void:
	BadgerKit.put(game, p, "brock-cub", 0)
	var master: Unit = BadgerKit.CoreKit.unit(game, "master-at-arms")
	assert_true(game.recruit._gain(p, master))
	var choices: Array[Dictionary] = game.legal_actions(p.id).filter(
		func(a: Dictionary) -> bool:
			return a["type"] == "recruit_target" and a["target"] == master.uid
	)
	assert_gt(choices.size(), 0, "itself included, with another unit on the board")
	assert_eq(game.act(p.id, {"type": "recruit_target", "target": master.uid}), "")
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 1}), "")
	assert_true(master.has_mechanic(&"badger_fury"))
	_enemies(4)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var uid: int = CoreUtil.to_int(BadgerKit.shown_at(combat, 0, master.slot)["uid"])
	assert_eq(_after_first(combat, "badger_fury", uid), 5 + 1 * (1 + 2), "Fury 1, outnumbered by 2")


func test_master_at_arms_gives_fury_to_another_tribes_unit() -> void:
	var friend: Unit = BadgerKit.plain(game, p, 0, 2, 50)
	assert_true(game.recruit._gain(p, BadgerKit.CoreKit.unit(game, "master-at-arms"), friend.uid))
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 1}), "")
	_enemies(5)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)), 2 + 1 * (1 + 3))


func test_ironhide_berserker_alone_against_seven_gains_21_a_trigger_and_overruns() -> void:
	var berserker: Unit = BadgerKit.put(game, p, "ironhide-berserker", 0)
	assert_true(berserker.has_mechanic(&"badger_overrun"))
	_enemies(7)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(combat.outnumbered_by(0), 6)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)), 8 + 3 * (1 + 6))


func test_dame_gives_knights_2_fury_and_overrun_and_not_squires() -> void:
	var dame: Unit = BadgerKit.put(game, p, "dame-of-the-old-sett", 0)
	var knight: Unit = BadgerKit.put(game, p, "hedge-knight", 1)
	var bearer: Unit = BadgerKit.put(game, p, "sett-shield-bearer", 6)
	assert_true(dame.has_mechanic(&"badger_overrun"), "herself included")
	assert_true(knight.has_mechanic(&"badger_overrun"))
	assert_false(bearer.has_mechanic(&"badger_overrun"), "a Squire isn't a Knight")
	assert_false(bearer.has_mechanic(&"badger_fury"))
	_enemies(6)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(combat.outnumbered_by(0), 4)
	var uid: int = BadgerKit.uid_at(combat, 0, 1)
	assert_eq(_after_first(combat, "badger_fury", uid), 2 + (1 + 2) * (1 + 4), "Fury 3")
	assert_eq(
		_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 0)),
		6 + 2 * (1 + 4),
		"Dame herself: Fury 2"
	)


func test_tourney_champion_strikes_the_enemy_with_the_most_attack_taking_no_damage() -> void:
	BadgerKit.put(game, p, "tourney-champion", 0)
	BadgerKit.put(game, q, "t1_guard", 0)
	BadgerKit.plain(game, q, 1, 3, 40)
	var big: Unit = BadgerKit.plain(game, q, 4, 15, 40)
	big.slot = 4
	var combat: Combat = BadgerKit.fight(game, p, q)
	var champion: int = BadgerKit.uid_at(combat, 0, 0)
	var attacks: Array[Dictionary] = BadgerKit.events(combat, "attack")
	assert_eq(CoreUtil.to_int(attacks[0]["uid"]), champion)
	assert_eq(
		CoreUtil.to_int(attacks[0]["target_uid"]),
		BadgerKit.uid_at(combat, 1, 4),
		"the back-row 15 Attack, past the Guard"
	)
	var first: int = BadgerKit.index_of(combat, attacks[0])
	var second: int = BadgerKit.index_of(combat, attacks[1])
	for i: int in range(first, second):
		var event: Dictionary = combat.events[i]
		if event["type"] == "damage":
			assert_ne(CoreUtil.to_int(event["uid"]), champion, "takes no damage")
	assert_eq(
		_after_first(combat, "badger_fury", champion), 10 + 1 * (1 + 2), "its Fury 1 triggers"
	)


func test_the_oakfeller_attacks_once_more_after_a_kill_and_never_chains() -> void:
	for fight_seed: int in range(1, 9):
		game = BadgerKit.session(fight_seed)
		p = game.player(0)
		q = game.player(1)
		BadgerKit.put(game, p, "the-oakfeller", 0)
		_enemies(3, 1, 20)
		var combat: Combat = BadgerKit.fight(game, p, q, fight_seed)
		var oak: int = BadgerKit.uid_at(combat, 0, 0)
		var extra: Array[Dictionary] = BadgerKit.triggers(combat, "badger_oakfeller", oak)
		assert_gt(extra.size(), 0, "seed %d: it killed with an attack" % fight_seed)
		var run: int = 0
		var last_attacker: int = -1
		for event: Dictionary in combat.events:
			if event["type"] == "trigger" and event["mechanic"] == "badger_oakfeller":
				assert_eq(last_attacker, oak, "only after its own attack, not a strike back")
			if event["type"] != "attack":
				continue
			last_attacker = CoreUtil.to_int(event["uid"])
			run = run + 1 if last_attacker == oak else 0
			assert_lte(run, 2, "seed %d: the extra attack earns no other" % fight_seed)


func test_old_brock_gains_a_dead_friends_own_stats_this_fight() -> void:
	BadgerKit.put(game, p, "old-brock", 0)
	var guard: Unit = BadgerKit.put(game, p, "t1_guard", 1)
	guard.stats.perm_attack = 2
	guard.stats.perm_health = 2
	p.slots[1].renown = 5
	game.recruit.refresh_auras(p)
	BadgerKit.plain(game, q, 0, 50, 100)
	BadgerKit.plain(game, q, 1, 1, 100)
	BadgerKit.plain(game, q, 2, 1, 100)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var brock: int = BadgerKit.uid_at(combat, 0, 0)
	var fired: Array[Dictionary] = BadgerKit.triggers(combat, "badger_old_brock", brock)
	assert_gt(fired.size(), 0)
	var buff: Dictionary = BadgerKit.next_buff(combat, BadgerKit.index_of(combat, fired[0]), brock)
	assert_eq(buff["attack"], 8 + 4, "the Guard's own 4 Attack, excluding its 5 Renown")
	assert_eq(buff["health"], 20 + 8, "and its own 8 Health, excluding its 5 Renown")
	assert_false(buff["permanent"])


func test_marshal_doubles_fury_and_two_marshals_do_not_stack() -> void:
	BadgerKit.put(game, p, "marshal-of-the-red-mist", 0)
	BadgerKit.put(game, p, "brock-cub", 1)
	_enemies(5)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 1)), 2 + 2 * (1 + 3))
	BadgerKit.put(game, p, "marshal-of-the-red-mist", 2)
	combat = BadgerKit.fight(game, p, q)
	assert_eq(
		_after_first(combat, "badger_fury", BadgerKit.uid_at(combat, 0, 1)),
		2 + 2 * (1 + 2),
		"outnumbered by 2 now, still doubled once"
	)
