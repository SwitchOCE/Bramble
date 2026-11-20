extends GutTest
## SHARED-RULES 15 to 22 (returns: Molt and Root) and 35 to 40 (permanent gains
## and after-fight effects), with real cards from two or more tribes in one fight. One test per
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


func _killer(slot: int = 0) -> Unit:
	return Kit.wall(game, q, slot, 200, 5000)


func _returns(combat: Combat, card_id: String) -> Array[Dictionary]:
	return Kit.where(combat, "return", "id", card_id)


## Ruling 17 and 16, the full order: a Blackthorn Sapling (Root 1) given Molt by a Skin-shedder,
## Compost 1, a 200/5000 killer opposite. Its first death returns by Root, as the recruit unit
## stands at full Health; its next by the given Molt, a plain copy with 1 Health then +2/+2. The
## Sapling's own "after this returns, +2/+2 permanently" pays on both.
func test_ruling_17_root_first_when_the_compost_pays_then_molt_on_a_later_death() -> void:
	Kit.fill(game, p, ["bramble-runner"])
	var sapling: Unit = Kit.put(game, p, "blackthorn-sapling", 0)
	Kit.put(game, p, "skin-shedder", 1)
	_killer()
	var combat: Combat = Kit.fight(game, p, q)
	var back: Array[Dictionary] = _returns(combat, "blackthorn-sapling")
	assert_eq(
		back.map(func(e: Dictionary) -> String: return e["mechanic"]), ["thorn_root", "locust_molt"]
	)
	assert_eq([back[0]["attack"], back[0]["health"]], [5 + 2, 6 + 2], "Root: full, then +2/+2")
	assert_eq(
		[back[1]["attack"], back[1]["health"]],
		[5 + 2 + 2, 1 + 2 + 2],
		"Molt: a plain 5/6 on 1 Health, +2/+2 from Molt and +2/+2 from the Sapling"
	)
	assert_eq(p.heap(Kit.COMPOST).size(), 0, "Root spent the one entry")
	assert_eq(sapling.stats.perm_attack, 2 + 2 + 2, "two Sapling gains and Molt's, for good")
	assert_eq(sapling.stats.perm_health, 2 + 2 + 2)


## Ruling 17, the other half: with an empty Compost, Molt takes the first death.
func test_ruling_17_molt_when_the_compost_cannot_pay() -> void:
	Kit.put(game, p, "blackthorn-sapling", 0)
	Kit.put(game, p, "skin-shedder", 1)
	_killer()
	var combat: Combat = Kit.fight(game, p, q)
	var back: Array[Dictionary] = _returns(combat, "blackthorn-sapling")
	assert_eq(back.map(func(e: Dictionary) -> String: return e["mechanic"]), ["locust_molt"])


## Ruling 15 and CROSS-TRIBE combination 4: a Locust's Molt pays a Briar's Hazel Coppicer, and a
## Briar's Root pays a Locust's Twice-shed Veteran. The Coppicer gives every friendly unit +1/+1
## for good on each return; the Veteran gives the returned unit and itself +6/+6 this fight.
func test_ruling_15_returns_of_either_kind_trigger_after_a_friendly_unit_returns() -> void:
	var sentry: Unit = Kit.put(game, p, "husk-sentry", 0)
	var coppicer: Unit = Kit.put(game, p, "hazel-coppicer", 4)
	_killer()
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(_returns(combat, "husk-sentry").size(), 1, "Molt once")
	assert_eq(Kit.triggers(combat, "thorn_coppicer").size(), 1, "the Coppicer heard the Molt")
	assert_eq(coppicer.stats.perm_attack, 1, "+1/+1 for good on the Coppicer")
	assert_eq(sentry.stats.perm_attack, 2 + 1, "Molt's +2 and the Coppicer's +1")

	game = Kit.session(2)
	p = game.player(0)
	q = Kit.opponent(game, p)
	Kit.fill(game, p, ["bramble-runner"])
	Kit.put(game, p, "blackthorn-sapling", 0)
	var veteran: Unit = Kit.put(game, p, "twice-shed-veteran", 4)
	_killer()
	combat = Kit.fight(game, p, q)
	var root: Dictionary = _returns(combat, "blackthorn-sapling")[0]
	assert_eq(root["mechanic"], "thorn_root")
	var fired: Array[Dictionary] = Kit.triggers(combat, "locust_veteran")
	assert_eq(fired.size(), 1, "the Veteran heard the Root")
	var after: int = combat.events.find(fired[0])
	var gains: Array[Dictionary] = []
	for i: int in range(after, combat.events.size()):
		var event: Dictionary = combat.events[i]
		if event["type"] == "buff" and CoreUtil.to_int(event["source_uid"]) == fired[0]["uid"]:
			gains.append(event)
		if gains.size() == 2:
			break
	assert_eq(gains[0]["uid"], root["uid"])
	assert_eq(gains[0]["attack"], root["attack"] + 6, "+6 to the returned Sapling")
	assert_eq(gains[1]["attack"], 6 + 6, "+6 to the Veteran")
	assert_false(gains[0]["permanent"], "this fight only")
	assert_eq(veteran.stats.perm_attack, 0)


## Ruling 19: a unit stepping in from Reserve and Hoppers landing are not returns, so a
## Twice-shed Veteran ignores them.
func test_ruling_19_reserve_and_hoppers_are_not_returns() -> void:
	Kit.put(game, p, "green-recruit", 0)
	Kit.put(game, p, "twice-shed-veteran", 4)
	Kit.put(game, p, "the-colonel", 5)
	Kit.hold(game, p, "brock-cub").grant(game.registry, &"pigeon_reserve")
	_killer()
	var combat: Combat = Kit.fight(game, p, q)
	assert_gt(Kit.where(combat, "summon", "id", "hopper").size(), 0, "Hoppers landed")
	assert_gt(Kit.events(combat, "reserve", 0).size(), 0, "a Brock Cub stepped in")
	assert_eq(Kit.events(combat, "return").size(), 0)
	assert_eq(Kit.triggers(combat, "locust_veteran").size(), 0)


## Ruling 20: every death of a returning unit is a real death. A Husk Sentry given a second
## Molt by a Skin-shedder dies three times; the Gleaner fires after each.
func test_ruling_20_each_death_of_a_returning_unit_is_a_real_death() -> void:
	var sentry: Unit = Kit.put(game, p, "husk-sentry", 0)
	Kit.put(game, p, "skin-shedder", 1)
	Kit.put(game, p, "gleaner", 4)
	_killer()
	var combat: Combat = Kit.fight(game, p, q)
	var line: Array[int] = Kit.lineage(combat, Kit.uid_of(combat, sentry))
	assert_eq(line.size(), 3, "printed Molt and the given one: two returns")
	var deaths: int = 0
	for event: Dictionary in Kit.events(combat, "death", 0):
		if line.has(CoreUtil.to_int(event["uid"])):
			deaths += 1
	assert_eq(deaths, 3)
	var gleans_before_shedder: int = 0
	var shedder: int = Kit.uid_of(combat, p.board[1])
	var shedder_death: int = Kit.index_of(combat, "death", {"uid": shedder})
	for event: Dictionary in Kit.triggers(combat, "locust_glean"):
		if shedder_death < 0 or combat.events.find(event) < shedder_death:
			gleans_before_shedder += 1
	assert_gte(gleans_before_shedder, 3, "one Gleaner shot for each of the Sentry's deaths")


## Ruling 22: a return is not joining the fight. A Pigeon (Sentry) given Molt by a Skin-shedder
## comes back; the Air Marshal doesn't hear it.
func test_ruling_22_a_return_is_not_joining_the_fight() -> void:
	var sentry: Unit = Kit.put(game, p, "sentry", 0)
	sentry.grant(game.registry, &"taunt")
	Kit.put(game, p, "skin-shedder", 1)
	Kit.put(game, p, "air-marshal", 4)
	_killer()
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(_returns(combat, "sentry").size(), 1, "the Pigeon Molted")
	assert_eq(Kit.triggers(combat, "pigeon_air_marshal").size(), 0)


## A plain return drops granted effects and lasting counters.
func test_a_plain_copy_return_drops_counters_and_given_fury_the_recruit_unit_keeps_them() -> void:
	var cub: Unit = Kit.put(game, p, "brock-cub", 0)
	Kit.put(game, p, "skin-shedder", 1)
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 2)
	Kit.ctx(game, p).give_effect(cub, &"badger_fury", {"fury": 1}, null)
	campaigner.counters[&"test_count"] = 2
	for slot: int in 4:
		Kit.wall(game, q, slot, 200, 5000)
	var combat: Combat = Kit.fight(game, p, q)
	var cub_view: Dictionary = Kit.start_view(combat, cub)
	assert_eq(Kit.total(cub_view, "badger_fury", "fury"), 1 + 1, "printed 1 and the given 1")
	var cub_back: Dictionary = _returns(combat, "brock-cub")[0]
	assert_eq(Kit.total(cub_back, "badger_fury", "fury"), 1, "the plain copy: printed Fury only")
	var camp_back: Dictionary = _returns(combat, "old-campaigner")[0]
	assert_eq(Kit.start_view(combat, campaigner)["counters"], {"test_count": 2})
	assert_eq(camp_back["counters"], {}, "no counters on the plain copy")
	assert_eq(campaigner.counter(&"test_count"), 2, "the recruit unit keeps its counter")
	assert_eq(cub.view()["totals"]["badger_fury"], {"fury": 2}, "and its given Fury")
	assert_eq(cub.stats.perm_attack, 2, "Molt's +2/+2 reached the recruit unit")


## A Campaigner that returned alive earns the survival bonus.
func test_start_of_turn_renown_for_a_surviving_return() -> void:
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	Kit.put(game, p, "skin-shedder", 1)
	Kit.put(game, p, "territorial", 4)
	Kit.wall(game, q, 0, 9, 7)
	game.finish_round()
	var record: Dictionary = Kit.fight_of(game, p)
	var fight_log: Array = record["events"]
	var back: Array = fight_log.filter(
		func(e: Dictionary) -> bool: return e["type"] == "return" and e["id"] == "old-campaigner"
	)
	assert_eq(back.size(), 1, "it died once and Molted")
	var end: Dictionary = fight_log[-1]
	assert_eq(end["winner"], 0)
	assert_eq(p.slots[0].renown, 0)
	game.start_round()
	assert_eq(p.slots[0].renown, 2)
	assert_eq(campaigner.stats.perm_attack, 2, "only Molt buffs the unit")


## Ruling 38 and CROSS-TRIBE (Pigeons lend to Locusts: "Padre: every death improves the slot"): a
## Green Recruit dying on a Padre's board gives its slot +1/+1 for good, on the real slot.
func test_ruling_38_padre_improves_the_slot_a_locust_died_in_for_good() -> void:
	Kit.put(game, p, "green-recruit", 0)
	Kit.put(game, p, "padre", 4)
	Kit.wall(game, q, 0, 3, 100)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var recruit_death: int = Kit.index_of(combat, "death", {"slot": 0, "side": 0})
	assert_gt(recruit_death, 0, "the Recruit died")
	var gift: int = Kit.index_of(combat, "renown", {"side": 0, "slot": 0}, recruit_death)
	assert_gt(gift, 0)
	assert_eq(combat.events[gift]["amount"], 1)
	assert_true(combat.events[gift]["permanent"])
	assert_eq(p.slots[0].renown, 1, "on the real slot")


## Ruling 21: a returned unit is the same unit for every "a fight" limit. A Needle Pikeman given
## Molt spends one Pile on use on either side of its return.
func test_ruling_21_fight_limits_carry_across_a_return() -> void:
	Kit.wall(game, p, 0, 1, 10000)
	var pikeman: Unit = Kit.put(game, p, "needle-pikeman", 1)
	pikeman.grant(game.registry, &"taunt")
	Kit.put(game, p, "skin-shedder", 2)
	var master: Unit = Kit.put(game, p, "fencing-master", 5)
	_killer()
	game.config.attack_limit = 3
	var combat: Combat = Kit.fight(game, p, q)
	var line: Array[int] = Kit.lineage(combat, Kit.uid_of(combat, pikeman))
	assert_eq(line.size(), 2, "the Pikeman Molted once")
	var back_at: int = combat.events.find(Kit.events(combat, "return")[0])
	var hits_after: Array[Dictionary] = Kit.where(combat, "hit", "uid", line[1])
	assert_eq(hits_after.size(), 1, "the returned Pikeman piled on again")
	assert_gt(combat.events.find(hits_after[0]), back_at)
	assert_eq(pikeman.stats.perm_attack, 6, "two pile-ons and Molt each give +2 Attack")
	assert_eq(master.stats.perm_attack, 6, "two Pikeman gains and its own pile-on")
	var left: Array[Dictionary] = Kit.where(combat, "uses", "uid", line[1]).filter(
		func(e: Dictionary) -> bool: return e["key"] == "mouse_pile_on"
	)
	assert_eq(
		left[-1]["left"], 5 - 2, "two of its five pile-ons used, one on each side of the return"
	)


## Rulings 35 and 36: a permanent gain made in a fight is written at once, and a Reserve unit's
## goes to the unit in hand. A Gate Warden steps in from The Colonel's hand and is attacked three
## times (+1/+3 for good each); between those a Wheat Raider Molts and the Hazel Coppicer gives
## every unit +1/+1 for good. The Warden in hand has +4/+10 after the fight and is still in hand.
func test_rulings_35_36_a_reserve_units_permanent_gains_reach_the_unit_in_hand() -> void:
	Kit.wall(game, p, 0, 1, 1)
	Kit.put(game, p, "wheat-raider", 1)
	Kit.put(game, p, "hazel-coppicer", 4)
	Kit.put(game, p, "the-colonel", 5)
	var warden: Unit = Kit.hold(game, p, "gate-warden")
	warden.grant(game.registry, &"pigeon_reserve")
	Kit.wall(game, q, 0, 3, 5000)
	game.config.attack_limit = 6
	var combat: Combat = Kit.fight(game, p, q)
	var stepped: Array[Dictionary] = Kit.events(combat, "reserve", 0)
	assert_eq(stepped.size(), 1)
	assert_eq(stepped[0]["recruit_uid"], warden.uid)
	assert_eq(Kit.triggers(combat, "badger_gate_warden").size(), 3)
	assert_eq(Kit.triggers(combat, "thorn_coppicer").size(), 1)
	assert_eq([warden.stats.perm_attack, warden.stats.perm_health], [1 * 3 + 1, 3 * 3 + 1])
	assert_eq(p.hand, [warden] as Array[Unit], "the hand is unchanged")
	assert_eq(warden.slot, -1)
