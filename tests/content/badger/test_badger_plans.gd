extends GutTest
## The four Badger plans' key interactions (README, "The four plans", turn-9 boards) through real
## fights, and Lends reading the lender as it stands.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const BadgerKit := preload("res://tests/content/badger/badger_kit.gd")

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = BadgerKit.session()
	p = game.player(0)
	q = game.player(1)


func _wide_enemy(count: int = 7, attack: int = 20, health: int = 25) -> void:
	for slot: int in count:
		BadgerKit.plain(game, q, slot, attack, health)


func test_red_mist_one_knight_and_three_squires_is_outnumbered_by_6() -> void:
	BadgerKit.put(game, p, "ironhide-berserker", 1)
	BadgerKit.put(game, p, "sett-shield-bearer", 4)
	BadgerKit.put(game, p, "armsbearer", 5)
	BadgerKit.put(game, p, "relic-seeker", 6)
	var berserker: Unit = p.board[1]
	assert_eq(berserker.attack(), 8 + 3, "the Armsbearer lends to F2")
	assert_eq(berserker.health(), 18 + 8, "the Shield-bearer lends to F2")
	_wide_enemy()
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(combat.outnumbered_by(0), 6)
	var uid: int = BadgerKit.uid_at(combat, 0, 1)
	var fired: Array[Dictionary] = BadgerKit.triggers(combat, "badger_fury", uid)
	assert_gt(fired.size(), 0)
	var buff: Dictionary = BadgerKit.next_buff(combat, BadgerKit.index_of(combat, fired[0]), uid)
	assert_eq(buff["attack"], 11 + 3 * (1 + 6), "+21 a trigger")
	assert_gt(BadgerKit.triggers(combat, "badger_overrun", uid).size(), 0, "and it runs through")


func test_the_order_dame_and_marshal_stack_fury_and_the_keeper_banks_it() -> void:
	var knight: Unit = BadgerKit.put(game, p, "hedge-knight", 0)
	var keeper: Unit = BadgerKit.put(game, p, "grudge-keeper", 1)
	BadgerKit.put(game, p, "dame-of-the-old-sett", 2)
	BadgerKit.put(game, p, "sett-shield-bearer", 4)
	BadgerKit.put(game, p, "armsbearer", 5)
	BadgerKit.put(game, p, "marshal-of-the-red-mist", 6)
	var rival: PlayerState = BadgerKit.opponent(game, p)
	for slot: int in 7:
		BadgerKit.plain(game, rival, slot, 1, 200)
	var combat: Combat = BadgerKit.fight(game, p, rival)
	assert_eq(combat.outnumbered_by(0), 7 - 4, "the Marshal in the back row isn't a Squire")
	var uid: int = BadgerKit.uid_at(combat, 0, 0)
	var fired: Array[Dictionary] = BadgerKit.triggers(combat, "badger_fury", uid)
	var buff: Dictionary = BadgerKit.next_buff(combat, BadgerKit.index_of(combat, fired[0]), uid)
	var shown: int = CoreUtil.to_int(BadgerKit.shown_at(combat, 0, 0)["attack"])
	assert_eq(buff["attack"], shown + (1 + 2) * 2 * (1 + 3), "Fury 3 from Dame, doubled, x (1 + 3)")
	game.finish_round()
	assert_eq(knight.stats.perm_attack, 3, "the keeper's Grudge on the Hedge Knight")
	assert_eq(knight.stats.perm_health, 1 + 3)
	assert_eq(keeper.stats.perm_attack, 3)


func test_the_charge_lancer_opens_with_lent_attack_and_overrun_taking_nothing() -> void:
	BadgerKit.put(game, p, "gate-warden", 1)
	BadgerKit.put(game, p, "hedge-lancer", 2)
	BadgerKit.put(game, p, "armsbearer", 5)
	BadgerKit.put(game, p, "greatsword-bearer", 6)
	assert_eq(p.board[2].attack(), 6 + 3)
	_wide_enemy(5, 20, 6)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var lancer: int = BadgerKit.uid_at(combat, 0, 2)
	var first: Dictionary = BadgerKit.events(combat, "attack")[0]
	assert_eq(CoreUtil.to_int(first["uid"]), lancer)
	var deaths: Array[Dictionary] = BadgerKit.events(combat, "death").filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["killer_uid"]) == lancer
	)
	assert_gte(deaths.size(), 2, "the opening kills two or more through Overrun")
	var second: int = BadgerKit.index_of(combat, BadgerKit.events(combat, "attack")[1])
	for i: int in range(BadgerKit.index_of(combat, first), second):
		var event: Dictionary = combat.events[i]
		if event["type"] == "damage":
			assert_ne(CoreUtil.to_int(event["uid"]), lancer)


func test_herald_gives_a_lancer_in_front_a_second_opening_attack() -> void:
	BadgerKit.put(game, p, "hedge-lancer", 0)
	BadgerKit.put(game, p, "herald-of-the-charge", 4)
	_wide_enemy(3, 1, 100)
	var combat: Combat = BadgerKit.fight(game, p, q)
	var lancer: int = BadgerKit.uid_at(combat, 0, 0)
	var attacks: Array[Dictionary] = BadgerKit.events(combat, "attack")
	assert_eq(CoreUtil.to_int(attacks[0]["uid"]), lancer, "its own free attack")
	assert_eq(CoreUtil.to_int(attacks[1]["uid"]), lancer, "then the Herald's")


func test_the_last_oath_heir_takes_the_warden_but_not_its_lent_health() -> void:
	var warden: Unit = BadgerKit.put(game, p, "gate-warden", 1)
	warden.stats.perm_attack = 8
	warden.stats.perm_health = 8
	BadgerKit.put(game, p, "grudge-keeper", 2)
	BadgerKit.put(game, p, "sett-shield-bearer", 4)
	BadgerKit.put(game, p, "sword-heir", 5)
	BadgerKit.put(game, p, "sett-sexton", 6)
	BadgerKit.plain(game, q, 0, 200, 300)
	for slot: int in range(1, 6):
		BadgerKit.plain(game, q, slot, 1, 300)
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(combat.outnumbered_by(0), 6 - 2)
	var heir: int = BadgerKit.uid_at(combat, 0, 5)
	var took: Array[Dictionary] = BadgerKit.triggers(combat, "badger_sword_heir", heir)
	assert_gt(took.size(), 0)
	var warden_uid: int = BadgerKit.uid_at(combat, 0, 1)
	var died: Array[Dictionary] = BadgerKit.events(combat, "death").filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["uid"]) == warden_uid
	)
	assert_eq(died.size(), 1, "the Warden fell first, as a Guard")
	var buff: Dictionary = BadgerKit.next_buff(combat, BadgerKit.index_of(combat, took[0]), heir)
	var grown: int = BadgerKit.triggers(combat, "badger_gate_warden", warden_uid).size() * 3
	assert_eq(buff["health"], 9 + 11 + 8 + grown, "its own Health, not the 8 it was lent")
	var keeper: int = BadgerKit.uid_at(combat, 0, 2)
	var paid: Array[Dictionary] = BadgerKit.triggers(combat, "badger_sexton")
	assert_gt(paid.size(), 0, "and the Sexton pays the raging keeper in front of it")
	for event: Dictionary in paid:
		var next: Dictionary = combat.events[BadgerKit.index_of(combat, event) + 1]
		assert_eq(CoreUtil.to_int(next["uid"]), keeper, "B3 reaches F3, not the heir's Warden")


func test_lends_reads_the_lender_as_it_stands() -> void:
	var cub: Unit = BadgerKit.put(game, p, "brock-cub", 0)
	var lender: Unit = BadgerKit.put(game, p, "armsbearer", 4)
	lender.stats.perm_attack = 5
	var shield: Unit = BadgerKit.put(game, p, "sett-shield-bearer", 5)
	RecruitContext.new(game, game.recruit, p).slot_buff(5, 0, 4, null)
	game.recruit.refresh_auras(p)
	assert_eq(cub.attack(), 2 + 3 + 5, "the Armsbearer with +5 lends 8")
	assert_eq(shield.health(), 8 + 4)
	var front: Unit = BadgerKit.plain(game, p, 1, 1, 10)
	assert_eq(front.health(), 10 + 8 + 4, "the Shield-bearer lends its slot's Health too")
	assert_eq(front.attack(), 1 + 8, "and both lenders behind F2 count")
	var combat: Combat = BadgerKit.fight(game, p, q)
	assert_eq(BadgerKit.shown_at(combat, 0, 0)["attack"], 10, "lent as it stands in the fight")
