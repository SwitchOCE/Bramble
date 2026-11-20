extends GutTest
## SHARED-RULES 1 to 14 (Outnumbered, who fills an emptied slot, Renown) and 23 to 30
## (attacks, Hits and damage), with real cards from two or more tribes in one fight. One test per
## ruling, asserting the ruling's numbers.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/content/cross/cross_kit.gd")

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	p = game.player(0)
	q = Kit.opponent(game, p)


## The first buff after the first trigger of `mechanic` by `uid` (a Fury gain, say).
func _gain_after(combat: Combat, mechanic: String, uid: int) -> Dictionary:
	var at: int = Kit.index_of(combat, "trigger", {"mechanic": mechanic, "uid": uid})
	assert_gt(at, -1, "%s fired for uid %d" % [mechanic, uid])
	var buff: int = Kit.index_of(combat, "buff", {"uid": uid}, at)
	return combat.events[buff] if buff >= 0 else {}


## Events of `kind` between two log indexes.
func _between(combat: Combat, from: int, to: int, kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in range(from, to):
		if combat.events[i]["type"] == kind:
			out.append(combat.events[i])
	return out


# --- Outnumbered (1 to 5) ---


## Rulings 1 and 2: the count is taken before Start of fight and never moves. A Brock Cub on a
## board of 2 against 5 is outnumbered by 3; the Sky-darkener's 2 Hoppers don't change it, so the
## Cub's Fury 1 still gains 1 x (1 + 3) = 4 and its Grudge pays +3/+4 next turn.
func test_rulings_1_2_hoppers_summoned_at_start_do_not_change_the_count() -> void:
	var cub: Unit = Kit.put(game, p, "brock-cub", 0)
	Kit.put(game, p, "sky-darkener", 4)
	for slot: int in 5:
		Kit.wall(game, q, slot, 1, 100)
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(combat.events[0]["outnumbered_by"], [3, 0])
	assert_eq(Kit.where(combat, "summon", "id", "hopper").size(), 2, "two Hoppers joined")
	assert_eq(combat.outnumbered_by(0), 3, "still 3 with four units on the board")
	var gain: Dictionary = _gain_after(combat, "badger_fury", Kit.uid_of(combat, cub))
	assert_eq(gain["attack"], 2 + 1 * (1 + 3))
	game.finish_round()
	assert_eq(Kit.fight_of(game, p)["events"][0]["outnumbered_by"], [3, 0], "the round's fight")
	game.start_round()
	assert_eq(
		[cub.stats.perm_attack, cub.stats.perm_health],
		[3, 1 + 3],
		"Grudge 1 x 3, +1 Health, for good"
	)


## Rulings 3 and 4, and CROSS-TRIBE "Knights in the Colonel's hand": units in hand are never
## counted. A Hedge Knight and The Colonel against 4: outnumbered by 2 with a Knight in hand. The
## Knight in hand steps into the fallen Knight's slot and rages at the same count.
func test_rulings_3_4_a_knight_from_the_colonels_hand_rages_at_the_full_count() -> void:
	Kit.put(game, p, "hedge-knight", 0)
	Kit.put(game, p, "the-colonel", 4)
	var spare: Unit = Kit.hold(game, p, "hedge-knight")
	spare.grant(game.registry, &"pigeon_reserve")
	Kit.hold(game, q, "hedge-knight")
	for slot: int in 4:
		Kit.wall(game, q, slot, 30, 100)
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(combat.events[0]["outnumbered_by"], [2, 0], "neither hand counts")
	var stepped: Array[Dictionary] = Kit.events(combat, "reserve", 0)
	assert_eq(stepped.size(), 1)
	assert_eq(stepped[0]["recruit_uid"], spare.uid, "the spare Knight")
	assert_eq(stepped[0]["slot"], 0, "into the slot the first Knight died in")
	assert_eq(combat.outnumbered_by(0), 2)
	var gain: Dictionary = _gain_after(combat, "badger_fury", CoreUtil.to_int(stepped[0]["uid"]))
	assert_eq(gain["attack"], 2 + 1 * (1 + 2), "Fury 1 x (1 + the fight's count of 2)")


# --- Who fills an emptied slot (6 to 8) ---


## Ruling 6 and its "Weakens": a dying golden Green Recruit's own 2 Hoppers take its slot and the
## nearest empty one before a hand reservist or a Private can step in.
func test_ruling_6_own_death_summons_before_reserve_and_the_sergeant() -> void:
	Kit.put(game, p, "green-recruit", 0, true)
	Kit.put(game, p, "recruiting-sergeant", 4)
	Kit.hold(game, p, "territorial")
	Kit.wall(game, q, 0, 200, 5000)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var died: int = Kit.index_of(combat, "death", {"side": 0, "slot": 0})
	assert_gt(died, -1, "the Recruit died on its own attack")
	var landed: Array[Dictionary] = _between(combat, died, combat.events.size(), "summon")
	var privates: Array[Dictionary] = Kit.where(combat, "reserve", "id", "private")
	assert_eq(privates.size(), 0, "the Sergeant only replaces a death")
	assert_eq(
		landed.map(func(e: Dictionary) -> Array: return [e["id"], e["slot"]]),
		[["hopper", 0], ["hopper", 1]],
		"its own Hoppers: its slot first, then the nearest empty; no second Private"
	)
	assert_eq(Kit.events(combat, "reserve").size(), 0, "no slot left that a friend died in")


## Ruling 6, Reserve before waiting summons: with The Colonel, a Hedge Knight in hand. A golden
## Green Recruit dies on a full board: one Hopper takes its slot, the other waits. When that Hopper
## dies, the Knight steps into the slot from Reserve and the waiting Hopper doesn't land.
func test_ruling_6_reserve_takes_the_slot_before_a_waiting_hopper() -> void:
	Kit.put(game, p, "green-recruit", 0, true)
	for slot: int in [1, 2, 3, 5, 6]:
		Kit.wall(game, p, slot, 1, 100)
	Kit.put(game, p, "the-colonel", 4)
	var spare: Unit = Kit.hold(game, p, "hedge-knight")
	spare.grant(game.registry, &"pigeon_reserve")
	Kit.wall(game, q, 0, 4, 5000)
	game.config.attack_limit = 3
	var combat: Combat = Kit.fight(game, p, q)
	var hoppers: Array[Dictionary] = Kit.where(combat, "summon", "id", "hopper")
	assert_eq(hoppers.size(), 1, "one Hopper landed")
	assert_eq(hoppers[0]["slot"], 0, "into the Recruit's slot")
	assert_eq(Kit.where(combat, "summon_waiting", "id", "hopper").size(), 1, "the other waited")
	var died: int = Kit.index_of(combat, "death", {"uid": hoppers[0]["uid"]})
	assert_gt(died, -1, "the Hopper died")
	var stepped: Array[Dictionary] = Kit.events(combat, "reserve", 0)
	assert_eq(stepped.size(), 1)
	assert_eq([stepped[0]["recruit_uid"], stepped[0]["slot"]], [spare.uid, 0])
	assert_gt(Kit.index_of(combat, "reserve", {}, died), died, "after that round of deaths")
	assert_eq(_between(combat, died, combat.events.size(), "summon").size(), 0, "no Hopper landed")


## Ruling 6's "Weakens" (a Thimble Captain on a Reserve board): a 1/1 beside the Captain attacks
## and dies. With nothing in hand, a Cousin lands in its slot when the Captain's other neighbour
## attacks. With The Colonel and a Hedge Knight in hand, the Knight takes the slot first and no
## Cousin can land.
func test_ruling_6_reserve_reaches_the_slot_before_a_thimble_captains_cousin() -> void:
	var cousins: Array[int] = []
	var reserves: Array[int] = []
	for with_reserve: bool in [false, true]:
		game = Kit.session()
		p = game.player(0)
		q = Kit.opponent(game, p)
		Kit.wall(game, p, 0, 1, 1)
		Kit.put(game, p, "thimble-captain", 1)
		for slot: int in [2, 3, 5, 6]:
			Kit.wall(game, p, slot, 1, 100)
		Kit.put(game, p, "the-colonel", 4)
		if with_reserve:
			Kit.hold(game, p, "hedge-knight").grant(game.registry, &"pigeon_reserve")
		Kit.wall(game, q, 0, 1, 5000)
		game.config.attack_limit = 5
		var combat: Combat = Kit.fight(game, p, q)
		assert_eq(Kit.events(combat, "death", 0).size(), 1, "the 1/1 died attacking")
		assert_eq(Kit.triggers(combat, "mouse_captain").size(), 2, "two neighbour attacks")
		var landed: Array[Dictionary] = Kit.where(combat, "summon", "id", "cousin")
		cousins.append(landed.size())
		if landed.size() > 0:
			assert_eq(landed[0]["slot"], 0, "the Cousin takes the dead unit's slot")
		var stepped: Array[Dictionary] = Kit.events(combat, "reserve", 0)
		reserves.append(stepped.size())
		if stepped.size() > 0:
			assert_eq(stepped[0]["slot"], 0, "the Knight takes it instead")
	assert_eq(cousins, [1, 0], "a Cousin without Reserve, none with it")
	assert_eq(reserves, [0, 1])


# --- Renown across tribes ---


## A Hopper from a Green Recruit takes the slot even when the slot has Renown.
func test_a_hopper_lands_in_a_renown_slot_with_its_printed_stats() -> void:
	p.slots[0].renown = 8
	Kit.put(game, p, "green-recruit", 0)
	Kit.wall(game, q, 0, 200, 5000)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var first: Dictionary = Kit.where(combat, "summon", "id", "hopper")[0]
	assert_eq(first["slot"], 0)
	assert_eq([first["attack"], first["health"]], [2, 2])


## Molt in a slot with Renown still adds only its own +2/+2 to the return and recruit unit.
func test_a_return_has_its_own_stats_and_molts_gain() -> void:
	p.slots[0].renown = 3
	var sentry: Unit = Kit.put(game, p, "husk-sentry", 0)
	Kit.wall(game, q, 0, 200, 5000)
	var combat: Combat = Kit.fight(game, p, q)
	var back: Dictionary = Kit.where(combat, "return", "id", "husk-sentry")[0]
	assert_eq(Kit.start_view(combat, sentry)["attack"], 3 + 3, "it starts with Renown")
	assert_eq(back["attack"], 3 + 2, "printed Attack plus Molt")
	assert_eq([sentry.stats.perm_attack, sentry.stats.perm_health], [2, 2])


## An Armsbearer standing on 4 Renown lends its total, 7,
## to a Needle Page and a Sentry in front of it.
func test_lends_reaches_other_tribes_with_the_lenders_renown() -> void:
	p.slots[4].renown = 4
	var page: Unit = Kit.put(game, p, "needle-page", 0)
	var sentry: Unit = Kit.put(game, p, "sentry", 1)
	Kit.put(game, p, "armsbearer", 4)
	game.recruit.refresh_auras(p)
	assert_eq(page.attack(), 4 + 7, "Needle Page 4 + the Armsbearer's 3 + 4")
	assert_eq(sentry.attack(), 2 + 7)
	Kit.wall(game, q, 0, 0, 100)
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(Kit.start_view(combat, page)["attack"], 11, "the fight reads the same")


## Ruling 23: the attack triggers the Warden, but the accompanying Hit does not.
func test_ruling_23_a_pile_on_hit_sets_off_no_extra_is_attacked_effect() -> void:
	Kit.wall(game, p, 0, 1, 100)
	Kit.put(game, p, "needle-page", 4)
	var warden: Unit = Kit.put(game, q, "gate-warden", 0)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(Kit.events(combat, "hit", 0).size(), 1)
	assert_eq(Kit.triggers(combat, "badger_gate_warden").size(), 1)
	assert_eq(warden.stats.perm_attack, 1)


## Ruling 24: Thorns hurt only the attacker. A Needle Page piling on beside the attacker takes
## nothing from a Nettle Sprout's Thorns 2.
func test_ruling_24_thorns_hurt_the_attacker_not_the_unit_piling_on() -> void:
	var attacker: Unit = Kit.wall(game, p, 0, 10, 100)
	var page: Unit = Kit.put(game, p, "needle-page", 4)
	Kit.put(game, q, "nettle-sprout", 0)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var thorns: Array[Dictionary] = Kit.triggers(combat, "thorn_thorns")
	assert_eq(thorns.size(), 1)
	var to_p: Array[Dictionary] = Kit.events(combat, "damage", 0)
	assert_eq(to_p.size(), 2, "the Thorns, then the strike back")
	for hurt: Dictionary in to_p:
		assert_eq(hurt["uid"], Kit.uid_of(combat, attacker), "only the attacker")
	assert_eq(to_p[0]["amount"], 2, "Thorns 2")
	assert_false(to_p[0]["from_attack"], "Thorns are plain damage")
	assert_eq(Kit.where(combat, "hit", "uid", Kit.uid_of(combat, page)).size(), 1, "it piled on")


## Ruling 24, Overrun half: a unit reached by Overrun was not attacked. An Ironhide Berserker
## (8 Attack and Fury 3 x (1 + 0) when it attacks) kills a 1/1 and carries 10 into a Nettle
## Skirmisher behind it; the Skirmisher's Thorns 4 do nothing.
func test_ruling_24_a_unit_reached_by_overrun_was_not_attacked() -> void:
	var berserker: Unit = Kit.put(game, p, "ironhide-berserker", 0)
	Kit.wall(game, p, 5, 0, 1)
	Kit.wall(game, p, 6, 0, 1)
	Kit.wall(game, q, 0, 1, 1)
	var skirmisher: Unit = Kit.put(game, q, "nettle-skirmisher", 4)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var carried: Array[Dictionary] = Kit.where(
		combat, "damage", "uid", Kit.uid_of(combat, skirmisher)
	)
	assert_eq(carried.size(), 1)
	assert_eq(carried[0]["amount"], 8 + 3 - 1, "8 Attack and 3 from Fury, less the 1 it killed")
	assert_eq(carried[0]["source_uid"], Kit.uid_of(combat, berserker))
	assert_false(carried[0]["from_attack"])
	assert_eq(Kit.triggers(combat, "thorn_thorns").size(), 0)


## Ruling 25: Thorns that kill the attacker end the attack. A Hedgerow Scout (set to 4 Health)
## attacking a Lone Hawthorn dies to Thorns 8 before it acts: no Cousin, no pile-on by the Page
## behind it, no damage to the Hawthorn. The Hawthorn's Thorns killed a Mouse, so it goes into
## the Compost.
func test_ruling_25_thorns_that_kill_the_attacker_end_the_attack() -> void:
	var scout: Unit = Kit.put(game, p, "hedgerow-scout", 0)
	scout.stats.set_health = 4
	Kit.put(game, p, "needle-page", 4)
	var hawthorn: Unit = Kit.put(game, q, "lone-hawthorn", 0)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(Kit.events(combat, "attack")[0]["side"], 0)
	assert_eq(Kit.where(combat, "summon", "id", "cousin").size(), 0)
	assert_eq(Kit.events(combat, "hit").size(), 0)
	assert_eq(Kit.where(combat, "damage", "uid", Kit.uid_of(combat, hawthorn)).size(), 0)
	assert_eq(Kit.events(combat, "death", 0).size(), 1)
	var compost: Array = q.heap(Kit.COMPOST).entries.map(
		func(e: Dictionary) -> String: return str(e["id"])
	)
	assert_eq(compost, ["hedgerow-scout"], "Lone Hawthorn: a Mouse its Thorns killed")


## Ruling 26: an attack that takes no damage takes none from Thorns. A Hedge Lancer's Start of
## fight attack into a Lone Hawthorn: the Thorns' 8 are prevented.
func test_ruling_26_a_no_damage_attack_ignores_thorns() -> void:
	var lancer: Unit = Kit.put(game, p, "hedge-lancer", 0)
	Kit.put(game, q, "lone-hawthorn", 0)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var uid: int = Kit.uid_of(combat, lancer)
	var stopped: Array[Dictionary] = Kit.where(combat, "prevented", "uid", uid)
	assert_eq(stopped.size(), 2, "the Thorns and the strike back")
	assert_eq(stopped[0]["amount"], 8)
	assert_eq(stopped[0]["reason"], "takes_no_damage")
	assert_eq(Kit.where(combat, "damage", "uid", uid).size(), 0)


## Ruling 29: a kill belongs to the unit whose damage did it. A Needle Page piling on kills the
## Flying Ace's target first, so the Ace earns no Renown.
func test_ruling_29_a_pile_on_kill_is_not_the_attackers() -> void:
	var ace: Unit = Kit.put(game, p, "flying-ace", 0)
	var page: Unit = Kit.put(game, p, "needle-page", 4)
	Kit.wall(game, q, 4, 0, 3)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var death: Dictionary = Kit.events(combat, "death", 1)[0]
	assert_eq(death["killer_uid"], Kit.uid_of(combat, page), "the Page's Hit killed it")
	assert_eq(Kit.where(combat, "damage", "source_uid", Kit.uid_of(combat, ace)).size(), 0)
	assert_eq(Kit.triggers(combat, "pigeon_flying_ace").size(), 0)
	assert_eq(p.slots[0].renown, 0)


## Ruling 30: Overrun applies to a Sortie's attack, and carries on into the back row. A unit with
## Sortie (Squadron Leader, +4 Attack) and Overrun (Greatsword Bearer) kills a 1/2 in the back row
## and carries 7 into the other back-row unit, not the front.
func test_ruling_30_a_sortie_unit_with_overrun_carries_on_into_the_back_row() -> void:
	var striker: Unit = Kit.wall(game, p, 1, 5, 100)
	Kit.put(game, p, "squadron-leader", 4)
	Kit.put(game, p, "greatsword-bearer", 5)
	Kit.wall(game, p, 6, 0, 1)
	Kit.wall(game, q, 0, 1, 100)
	Kit.wall(game, q, 4, 1, 2)
	Kit.wall(game, q, 5, 1, 2)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var uid: int = Kit.uid_of(combat, striker)
	var dealt: Array[Dictionary] = Kit.where(combat, "damage", "source_uid", uid)
	assert_eq(dealt.size(), 3, "the attack, then two carries")
	assert_eq(dealt.map(func(e: Dictionary) -> int: return e["amount"]), [8, 6, 4])
	assert_true(dealt[0]["slot"] >= 4 and dealt[1]["slot"] >= 4, "both in the back row")
	assert_eq(dealt[2]["slot"], 0, "then the front, once the back row is empty")
