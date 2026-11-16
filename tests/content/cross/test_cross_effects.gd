extends GutTest
## SHARED-RULES 31 to 34 (death effects set off without a death), the Compost with other tribes'
## units, 41 to 42 (Start of fight), 44 to 46 (types and tribes), and the strongest combinations
## in CROSS-TRIBE.md, with real cards from two or more tribes. One test per ruling or combination,
## asserting its numbers.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/content/cross/cross_kit.gd")

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	p = game.player(0)
	q = Kit.opponent(game, p)


func _compost(player: PlayerState) -> Array:
	return player.heap(Kit.COMPOST).entries.map(func(e: Dictionary) -> String: return str(e["id"]))


# --- A death effect set off without a death (31 to 34) ---


## Rulings 31 and 32, and CROSS-TRIBE combination 3: a War-drummer's attack sets off the Crab-apple
## behind it. Its Seed adds a Crab-apple to the Compost (the Sweetbriar gains +1/+1 for good) and
## its Pip lands in the nearest empty slot. Nothing died: Old Brock and the Gleaner don't trigger,
## the side's death count stays 0.
func test_rulings_31_32_a_drumbeat_seeds_and_drops_a_pip_without_a_death() -> void:
	Kit.put(game, p, "war-drummer", 0)
	Kit.put(game, p, "crab-apple", 4)
	var sweetbriar: Unit = Kit.put(game, p, "sweetbriar", 5)
	Kit.put(game, p, "old-brock", 6)
	Kit.put(game, p, "gleaner", 3)
	Kit.wall(game, q, 0, 0, 1000)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(Kit.triggers(combat, "locust_drum").size(), 1)
	assert_eq(_compost(p), ["crab-apple"], "Seed added the Crab-apple")
	assert_eq(sweetbriar.stats.perm_attack, 1, "the Sweetbriar saw it, for good")
	var pips: Array[Dictionary] = Kit.where(combat, "summon", "id", "pip")
	assert_eq(pips.size(), 1)
	assert_eq(pips[0]["slot"], 1, "the Crab-apple's slot is taken: the nearest empty one")
	assert_eq(Kit.events(combat, "death").size(), 0)
	assert_eq(combat.bridge(0).deaths, 0)
	assert_eq(Kit.triggers(combat, "badger_old_brock").size(), 0)
	assert_eq(Kit.triggers(combat, "locust_glean").size(), 0)


## Ruling 33: a Dirge-singer doubles a death effect however it was set off. One drumbeat on the
## Crab-apple: two Seeds, two Pips, the Sweetbriar +2/+2.
func test_ruling_33_dirge_singer_doubles_a_drummed_death_effect() -> void:
	Kit.put(game, p, "war-drummer", 0)
	Kit.put(game, p, "crab-apple", 4)
	var sweetbriar: Unit = Kit.put(game, p, "sweetbriar", 5)
	Kit.put(game, p, "dirge-singer", 6)
	Kit.wall(game, q, 0, 0, 1000)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(_compost(p), ["crab-apple", "crab-apple"])
	assert_eq(sweetbriar.stats.perm_attack, 2)
	assert_eq(Kit.where(combat, "summon", "id", "pip").size(), 2)


## Rulings 7 and 32: a Pip never waits. A drumbeat on a Crab-apple on a full board: its slot is
## taken, so its Pip is lost; the same drumbeat on a Green Recruit makes Hoppers that wait.
func test_ruling_7_a_drummed_pip_with_no_room_is_lost_while_hoppers_wait() -> void:
	Kit.put(game, p, "war-drummer", 0)
	Kit.put(game, p, "crab-apple", 4)
	for slot: int in [1, 2, 3, 5, 6]:
		Kit.wall(game, p, slot, 0, 1000)
	Kit.wall(game, q, 0, 0, 1000)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(Kit.where(combat, "summon_failed", "id", "pip").size(), 1, "lost")
	assert_eq(Kit.where(combat, "summon_waiting", "id", "pip").size(), 0, "never waits")
	assert_eq(_compost(p), ["crab-apple"], "its Seed still resolved")
	p.remove_from_board(p.board[4])
	Kit.put(game, p, "green-recruit", 4)
	combat = Kit.fight(game, p, q)
	assert_eq(Kit.where(combat, "summon_waiting", "id", "hopper").size(), 2, "Hoppers wait")


## Ruling 34: in the shop, a death effect that needs a fight does nothing. A Gorger eats a sold
## Old Stump: it gains the Stump's 5/6 for good, the sale puts the Stump in the Compost, and no
## copy is summoned.
func test_ruling_34_an_eaten_old_stump_summons_nothing() -> void:
	var gorger: Unit = Kit.put(game, p, "gorger", 0)
	Kit.put(game, p, "old-stump", 1)
	var units_before: int = p.board_units().size()
	assert_eq(game.act(p.id, {"type": "sell", "slot": 1}), "")
	assert_eq([gorger.stats.perm_attack, gorger.stats.perm_health], [5, 6])
	assert_eq(_compost(p), ["old-stump"])
	assert_eq(p.board_units().size(), units_before - 1, "nothing summoned")


## The Compost with other tribes' units (brief: Seed and Compost with other tribes' units sold or
## dying): a Bought Brock Cub sold goes in and pays a Sweetbriar; a Created Hopper adds nothing;
## an eaten Bramble Runner's Seed adds a second entry beside the sale's own.
func test_the_compost_takes_any_tribes_bought_units_and_eaten_seeds() -> void:
	var sweetbriar: Unit = Kit.put(game, p, "sweetbriar", 4)
	Kit.put(game, p, "brock-cub", 0)
	var hopper: Unit = game.new_unit(game.library.get_card(&"hopper"), false)
	p.place(hopper, 1)
	assert_eq(game.act(p.id, {"type": "sell", "slot": 0}), "")
	assert_eq(_compost(p), ["brock-cub"])
	assert_eq(sweetbriar.stats.perm_attack, 1)
	assert_eq(game.act(p.id, {"type": "sell", "slot": 1}), "")
	assert_eq(_compost(p), ["brock-cub"], "a Created Hopper adds nothing")
	Kit.put(game, p, "gorger", 0)
	Kit.put(game, p, "bramble-runner", 1)
	assert_eq(game.act(p.id, {"type": "sell", "slot": 1}), "")
	assert_eq(_compost(p).count("bramble-runner"), 2, "the sale's entry and the eaten Seed's")
	assert_eq(sweetbriar.stats.perm_attack, 3)


# --- Start of fight (41, 42) ---


## Ruling 41's "Weakens": the main pass runs in reading order, so a Master of Engines in B1 makes
## the Blackberry Sprawl in B2 Hit with its 4 Attack before its own Grow 2 (Compost 4: +4/+4).
func test_ruling_41_master_of_engines_fires_a_briar_before_it_grows() -> void:
	Kit.fill(game, p, ["bramble-runner", "bramble-runner", "bramble-runner", "bramble-runner"])
	Kit.put(game, p, "master-of-engines", 4)
	var sprawl: Unit = Kit.put(game, p, "blackberry-sprawl", 5)
	Kit.wall(game, q, 0, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game, p, q)
	var uid: int = Kit.uid_of(combat, sprawl)
	var hit: int = Kit.index_of(combat, "hit", {"uid": uid})
	assert_gt(hit, -1, "the Sprawl Hit")
	assert_eq(combat.events[hit + 1]["amount"], 4, "with its printed 4")
	var grew: int = Kit.index_of(combat, "trigger", {"mechanic": "thorn_grow", "uid": uid})
	assert_gt(grew, hit, "and Grew after")
	assert_eq(combat.unit_at(0, 5).attack(), 4 + 4)


## Rulings 42 and 45: an Elder Mother's copy of a Sky-darkener arrives during Start of fight, so it
## doesn't summon Hoppers; the copy is a Locust, so it has the Tide. 4/8, +1/+1 for the one
## entry, +3 Tide Attack.
func test_rulings_42_45_a_compost_copy_runs_no_start_of_fight_and_keeps_its_tribe() -> void:
	Kit.fill(game, p, ["sky-darkener"])
	Kit.ctx(game, p).add_counter(Kit.TIDE, 3, null)
	Kit.put(game, p, "elder-mother", 4)
	Kit.wall(game, q, 0, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game, p, q)
	var copies: Array[Dictionary] = Kit.where(combat, "summon", "id", "sky-darkener")
	assert_eq(copies.size(), 1)
	var copy: CombatUnit = combat.unit_at(0, CoreUtil.to_int(copies[0]["slot"]))
	assert_false(copy.bought, "a copy is Created")
	assert_eq([copy.attack(), copy.health()], [4 + 1 + 3, 8 + 1])
	assert_eq(Kit.triggers(combat, "locust_sky_darken").size(), 0)
	assert_eq(Kit.where(combat, "summon", "id", "hopper").size(), 0)


# --- Own and borrowed stats (43) ---


## Ruling 43 and its "Weakens": Old Brock takes a dying unit's own stats only. Under Tide 3 and a
## Hopper bonus of 1, a Green Recruit is 5/2 and its Hoppers 6/3, but each is worth 2/2 to Brock.
func test_ruling_43_old_brock_gains_a_hoppers_own_2_2_not_the_tide_or_bonus() -> void:
	Kit.ctx(game, p).add_counter(Kit.TIDE, 3, null)
	Kit.ctx(game, p).add_counter(Kit.HOPPER_BONUS, 1, null)
	Kit.put(game, p, "green-recruit", 0)
	var brock: Unit = Kit.put(game, p, "old-brock", 4)
	Kit.wall(game, q, 0, 200, 5000)
	game.config.attack_limit = 3
	var combat: Combat = Kit.fight(game, p, q)
	var hoppers: Array[Dictionary] = Kit.where(combat, "summon", "id", "hopper")
	assert_eq(hoppers.size(), 2)
	for hopper: Dictionary in hoppers:
		assert_eq([hopper["attack"], hopper["health"]], [2 + 3 + 1, 2 + 1], "Tide and bonus")
	var died: Array = Kit.events(combat, "death", 0).map(
		func(e: Dictionary) -> int: return CoreUtil.to_int(e["uid"])
	)
	assert_eq(died.size(), 3, "the Recruit, then both Hoppers")
	assert_true(died.has(CoreUtil.to_int(hoppers[0]["uid"])))
	assert_true(died.has(CoreUtil.to_int(hoppers[1]["uid"])))
	var gains: Array = Kit.where(combat, "buff", "uid", Kit.uid_of(combat, brock)).map(
		func(e: Dictionary) -> Array: return [e["attack"], e["health"]]
	)
	assert_eq(gains, [[8 + 2, 20 + 2], [8 + 4, 20 + 4], [8 + 6, 20 + 6]], "+2/+2 each death")


## Ruling 43 for Eat: a Gorger eats a Green Recruit sold from a +3/+3 slot under Tide 2. The
## Recruit stands at 7/5; the Gorger keeps its own 2/2.
func test_ruling_43_a_gorger_eats_own_stats_not_the_slots_buff() -> void:
	Kit.ctx(game, p).add_counter(Kit.TIDE, 2, null)
	var gorger: Unit = Kit.put(game, p, "gorger", 0)
	Kit.ctx(game, p).slot_buff(1, 3, 3, null)
	var meal: Unit = Kit.put(game, p, "green-recruit", 1)
	assert_eq([meal.attack(), meal.health()], [2 + 3 + 2, 2 + 3], "slot buff and Tide")
	assert_eq(game.act(p.id, {"type": "sell", "slot": 1}), "")
	assert_eq([gorger.stats.perm_attack, gorger.stats.perm_health], [2, 2])


# --- Types and tribes (44 to 46) ---


## Ruling 44: types are read from the type line. Dame of the Old Sett gives her Knights +2 Fury
## and Overrun: the Hedge Knight shows Fury 3, the Holly Knight (a Briar) nothing.
func test_ruling_44_holly_knight_is_not_a_knight() -> void:
	var knight: Unit = Kit.put(game, p, "hedge-knight", 0)
	var holly: Unit = Kit.put(game, p, "holly-knight", 1)
	Kit.put(game, p, "dame-of-the-old-sett", 2)
	game.recruit.refresh_auras(p)
	assert_eq(Kit.total(knight.view(), "badger_fury", "fury"), 1 + 2)
	assert_true(knight.has_mechanic(&"badger_overrun"))
	assert_eq(Kit.total(holly.view(), "badger_fury", "fury"), 0)
	assert_false(holly.has_mechanic(&"badger_overrun"))


## Ruling 45: a token is its tribe. With a Parish Standard-bearer (+2 Attack to your Mice for each
## Mouse), a Hedgerow Scout's Cousin makes three Mice: the Cousin lands as 2 + 6.
func test_ruling_45_a_cousin_is_a_mouse_for_the_standard_bearer() -> void:
	var scout: Unit = Kit.put(game, p, "hedgerow-scout", 0)
	Kit.put(game, p, "parish-standard-bearer", 4)
	Kit.put(game, p, "husk-sentry", 5)
	assert_eq(scout.attack(), 2 + 2 * 2, "two Mice; the Husk Sentry is a Locust")
	Kit.wall(game, q, 0, 0, 100)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var cousin: Dictionary = Kit.where(combat, "summon", "id", "cousin")[0]
	assert_eq(cousin["attack"], 2 + 2 * 3)


## Ruling 46: another tribe's unit can hold a keyword. A Master-at-Arms gives a Needle Page +1
## Fury; outnumbered by 2, the Page gains 2 Attack when it attacks.
func test_ruling_46_a_mouse_with_fury_from_the_master_at_arms() -> void:
	var page: Unit = Kit.put(game, p, "needle-page", 0)
	Kit.hold(game, p, "master-at-arms")
	p.gold = 10
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 4, "target": page.uid}), "")
	assert_eq(page.view()["totals"]["badger_fury"], {"fury": 1})
	for slot: int in 4:
		Kit.wall(game, q, slot, 0, 100)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	assert_eq(combat.outnumbered_by(0), 2)
	var uid: int = Kit.uid_of(combat, page)
	var raged: int = Kit.index_of(combat, "trigger", {"mechanic": "badger_fury", "uid": uid})
	assert_gt(raged, -1)
	assert_eq(combat.events[Kit.index_of(combat, "buff", {"uid": uid}, raged)]["attack"], 4 + 2)


# --- The strongest combinations (CROSS-TRIBE.md) ---


## Combination 1, Mice behind Knights: when the Gate Warden attacks, the Needle Page next to it
## and the Needle Pikeman behind it both Hit the target before the exchange; the Pikeman gains +3
## Attack for good after its pile-on.
func test_combination_1_needles_pile_on_with_a_knight() -> void:
	var warden: Unit = Kit.put(game, p, "gate-warden", 0)
	var page: Unit = Kit.put(game, p, "needle-page", 1)
	var pikeman: Unit = Kit.put(game, p, "needle-pikeman", 4)
	Kit.wall(game, q, 0, 0, 200)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var attack: Dictionary = Kit.events(combat, "attack")[0]
	assert_eq(attack["uid"], Kit.uid_of(combat, warden), "the Warden attacks first")
	var exchange: int = Kit.index_of(combat, "damage", {"source_uid": Kit.uid_of(combat, warden)})
	var hits: Array = Kit.events(combat, "hit").filter(
		func(e: Dictionary) -> bool: return combat.events.find(e) < exchange
	)
	var hitters: Array = hits.map(func(e: Dictionary) -> int: return e["uid"])
	hitters.sort()
	var expected: Array = [Kit.uid_of(combat, page), Kit.uid_of(combat, pikeman)]
	expected.sort()
	assert_eq(hitters, expected, "both needles Hit before the Warden's damage")
	var to_target: Array = Kit.events(combat, "damage", 1).map(
		func(e: Dictionary) -> int: return e["amount"]
	)
	assert_eq(to_target, [4, 4, 3], "the Page's 4, the Pikeman's 4, then the Warden's 3")
	assert_eq(pikeman.stats.perm_attack, 3)


## Combination 2, Edgewright and Lieutenant on a drilled row: a full front row, each slot +5
## Attack; at Start of fight each unit deals its slot's Attack, doubled by the Edgewright, to the
## enemy across: 10 each.
func test_combination_2_edgewright_doubles_the_lieutenants_volley() -> void:
	for slot: int in 4:
		Kit.ctx(game, p).slot_buff(slot, 5, 0, null)
	Kit.put(game, p, "lieutenant", 0)
	for slot: int in range(1, 4):
		Kit.wall(game, p, slot, 0, 10)
	Kit.put(game, p, "edgewright", 4)
	for slot: int in 4:
		Kit.wall(game, q, slot, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game, p, q)
	var volley: Array[Dictionary] = Kit.events(combat, "damage", 1)
	assert_eq(volley.size(), 4)
	for shot: Dictionary in volley:
		assert_eq(shot["amount"], 2 * 5)
	var across: Array = volley.map(func(e: Dictionary) -> int: return e["slot"])
	across.sort()
	assert_eq(across, [0, 1, 2, 3], "each to the enemy across")
