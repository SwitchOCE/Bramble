extends GutTest
## The Briars in fights through the core, asserted on the fight log and the real players: Seed,
## Thorns, Root, Grow, the auras, copies from the Compost and the return payoffs.

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


func _fight(fight_seed: int = 1, live_b: bool = true) -> Combat:
	return ThornKit.fight(game, p, q, fight_seed, live_b)


func _killer(player: PlayerState, slot: int = 0) -> Unit:
	return ThornKit.wall(game, player, slot, 200, 5000)


## Damage events dealt to `uid` by `source` (fight uids).
func _damage(combat: Combat, uid: int, source: int) -> Array[Dictionary]:
	return ThornKit.about(combat, "damage", uid).filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["source_uid"]) == source
	)


func test_bramble_runner_seed_adds_to_the_real_compost_when_it_dies() -> void:
	var runner: Unit = CoreKit.put(game, p, "bramble-runner", 0)
	_killer(q)
	var combat: Combat = _fight()
	assert_eq(ThornKit.triggers(combat, "thorn_seed").size(), 1)
	assert_eq(
		ThornKit.compost_ids(p), ["bramble-runner"] as Array[String], "fights use the real one"
	)
	assert_eq(p.board[0], runner, "the board was copied: the Runner is back next turn")
	var adds: Array[Dictionary] = ThornKit.events(combat, "heap_add", 0)
	assert_eq(CoreUtil.to_int(adds[0]["size"]), 1)


func test_bramble_runner_golden_adds_two_and_a_ghost_side_changes_nothing() -> void:
	var golden: Unit = CoreKit.unit(game, "bramble-runner", true)
	p.place(golden, 0)
	q.place(CoreKit.unit(game, "bramble-runner"), 0)
	_killer(p, 1)
	_killer(q, 1)
	_fight(1, false)
	assert_eq(p.heap(HEAP).size(), 2, "a golden adds 2 entries")
	assert_eq(q.heap(HEAP).size(), 0, "a saved copy of a board changes nothing on the player")


func test_nettle_sprout_thorns_kill_the_attacker_before_it_strikes() -> void:
	var sprout: Unit = CoreKit.put(game, p, "nettle-sprout", 0)
	ThornKit.wall(game, q, 0, 1, 2)
	ThornKit.wall(game, q, 1, 1, 2)
	var combat: Combat = _fight()
	var sprout_uid: int = ThornKit.uid_of(combat, sprout)
	var first: Dictionary = ThornKit.events(combat, "attack")[0]
	assert_eq(CoreUtil.to_int(first["side"]), 1, "the bigger board attacks first")
	var attacker: int = CoreUtil.to_int(first["uid"])
	var thorned: Array[Dictionary] = _damage(combat, attacker, sprout_uid)
	assert_eq(thorned.size(), 1)
	assert_eq(CoreUtil.to_int(thorned[0]["amount"]), 2, "Thorns 2")
	assert_eq(_damage(combat, sprout_uid, attacker).size(), 0, "a dead attacker doesn't strike")
	assert_eq(ThornKit.about(combat, "death", attacker).size(), 1)


func test_sweetbriar_grows_for_good_when_a_seed_lands_in_the_fight() -> void:
	var sweet: Unit = CoreKit.put(game, p, "sweetbriar", 4)
	CoreKit.put(game, p, "bramble-runner", 0)
	_killer(q)
	var combat: Combat = _fight()
	var seeds: int = ThornKit.triggers(combat, "thorn_seed").size()
	assert_gt(seeds, 0)
	assert_gt(ThornKit.triggers(combat, "thorn_sweetbriar").size(), 0)
	assert_eq(sweet.stats.perm_attack, p.heap(HEAP).size(), "+1/+1 for good for each entry")


func test_blackthorn_sapling_roots_back_as_it_stands_and_grows_for_good() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t1_plain"])
	var sapling: Unit = CoreKit.put(game, p, "blackthorn-sapling", 0)
	sapling.stats.perm_attack = 3
	sapling.stats.perm_health = 3
	_killer(q)
	var combat: Combat = _fight()
	var returns: Array[Dictionary] = ThornKit.events(combat, "return", 0)
	assert_eq(returns.size(), 1, "Root once a fight")
	assert_eq(
		[CoreUtil.to_int(returns[0]["attack"]), CoreUtil.to_int(returns[0]["health"])],
		[9, 10],
		"back as it stands (5/6 +3/+3), full Health, then +1/+1"
	)
	assert_eq(p.heap(HEAP).size(), 1, "Root 1 spent 1 for good")
	assert_eq(sapling.stats.perm_attack, 4, "+1/+1 on the recruit board")
	assert_eq(ThornKit.events(combat, "status", 0).size(), 1, "the Root pill drops")


func test_golden_blackthorn_sapling_grows_two_two_and_spends_one_compost() -> void:
	ThornKit.fill(game, p, ["t1_plain"])
	var sapling: Unit = CoreKit.unit(game, "blackthorn-sapling", true)
	p.place(sapling, 0)
	_killer(q)
	var combat: Combat = _fight()
	var returns: Array[Dictionary] = ThornKit.events(combat, "return", 0)
	assert_eq(returns.size(), 1)
	assert_eq([returns[0]["attack"], returns[0]["health"]], [12, 14])
	assert_eq([sapling.stats.perm_attack, sapling.stats.perm_health], [2, 2])
	assert_eq(p.heap(HEAP).size(), 0, "still Root 1")


func test_blackthorn_sapling_with_an_empty_compost_stays_dead() -> void:
	CoreKit.put(game, p, "blackthorn-sapling", 0)
	_killer(q)
	var combat: Combat = _fight()
	assert_eq(ThornKit.events(combat, "return").size(), 0)
	assert_eq(ThornKit.events(combat, "heap_remove").size(), 0)


func test_blackberry_sprawl_grows_two_for_every_two_in_the_compost() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t1_plain", "t1_plain", "t1_plain", "t1_plain"])
	var sprawl: Unit = CoreKit.put(game, p, "blackberry-sprawl", 0)
	var golden: Unit = CoreKit.unit(game, "blackberry-sprawl", true)
	p.place(golden, 1)
	ThornKit.wall(game, q, 0, 1, 500)
	var combat: Combat = _fight()
	var grown: Array[Dictionary] = ThornKit.about(combat, "buff", ThornKit.uid_of(combat, sprawl))
	assert_eq([grown[0]["attack"], grown[0]["health"]], [8, 12], "heap 5: 2 pairs, +4/+4")
	var gold_grown: Array[Dictionary] = ThornKit.about(
		combat, "buff", ThornKit.uid_of(combat, golden)
	)
	assert_eq([gold_grown[0]["attack"], gold_grown[0]["health"]], [16, 24], "Grow 4: +8/+8")
	assert_false(bool(grown[0]["permanent"]), "this fight only")
	assert_eq(sprawl.attack(), 4)


func test_nettle_skirmisher_thorns_four_and_roots_with_its_thorns() -> void:
	ThornKit.fill(game, p, ["t1_plain"])
	var skirmisher: Unit = CoreKit.put(game, p, "nettle-skirmisher", 0)
	ThornKit.wall(game, q, 0, 30, 200)
	ThornKit.wall(game, q, 1, 30, 200)
	var combat: Combat = _fight()
	var uid: int = ThornKit.uid_of(combat, skirmisher)
	var thorned: Array[Dictionary] = ThornKit.events(combat, "damage", 1).filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["source_uid"]) == uid
	)
	assert_eq(CoreUtil.to_int(thorned[0]["amount"]), 4, "Thorns 4")
	var returns: Array[Dictionary] = ThornKit.events(combat, "return", 0)
	assert_eq(returns.size(), 1)
	var back: int = CoreUtil.to_int(returns[0]["uid"])
	var thorned_again: Array[Dictionary] = ThornKit.events(combat, "damage", 1).filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["source_uid"]) == back
	)
	assert_gt(thorned_again.size(), 0, "the returned unit keeps its printed Thorns 4")
	assert_eq(p.heap(HEAP).size(), 0)


func test_crab_apple_seeds_and_summons_a_pip_into_its_slot() -> void:
	CoreKit.put(game, p, "crab-apple", 0)
	_killer(q)
	var combat: Combat = _fight()
	var summons: Array[Dictionary] = ThornKit.events(combat, "summon", 0)
	assert_eq(summons.size(), 1)
	assert_eq([str(summons[0]["id"]), CoreUtil.to_int(summons[0]["slot"])], ["pip", 0])
	assert_false(bool(summons[0]["bought"]), "the Pip is Created")
	assert_eq(
		ThornKit.compost_ids(p), ["crab-apple", "pip"] as Array[String], "two entries a fight"
	)
	assert_eq(p.heap(HEAP).entries[0]["tier"], 3)


func test_crab_apple_golden_summons_a_golden_pip_that_adds_two() -> void:
	p.place(CoreKit.unit(game, "crab-apple", true), 0)
	_killer(q)
	var combat: Combat = _fight()
	var pip: Dictionary = ThornKit.events(combat, "summon", 0)[0]
	assert_true(bool(pip["golden"]), "a golden Pip, not a buffed plain one")
	assert_eq([CoreUtil.to_int(pip["attack"]), CoreUtil.to_int(pip["health"])], [6, 6])
	assert_eq(ThornKit.compost_ids(p).count("crab-apple"), 2, "the golden Crab-apple adds 2")
	assert_eq(ThornKit.compost_ids(p).count("pip"), 2, "the golden Pip's Seed adds 2")


func test_old_stump_summons_a_copy_of_the_highest_tier_unit_and_the_entry_stays() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t3_hunter", "t2_shield"])
	CoreKit.put(game, p, "old-stump", 0)
	_killer(q)
	var combat: Combat = _fight()
	var summons: Array[Dictionary] = ThornKit.events(combat, "summon", 0)
	assert_eq(summons.size(), 1)
	assert_eq([str(summons[0]["id"]), CoreUtil.to_int(summons[0]["slot"])], ["t3_hunter", 0])
	assert_false(bool(summons[0]["golden"]))
	assert_false(bool(summons[0]["bought"]), "a copy is Created")
	assert_eq(ThornKit.events(combat, "heap_use", 0).size(), 1)
	assert_eq(p.heap(HEAP).size(), 3, "the entry stays in the Compost")


func test_old_stump_each_entry_comes_out_once_a_fight_and_golden_takes_two() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t3_hunter", "t2_shield"])
	CoreKit.put(game, p, "old-stump", 0)
	p.place(CoreKit.unit(game, "old-stump", true), 1)
	_killer(q)
	var combat: Combat = _fight()
	var ids: Array[String] = []
	for event: Dictionary in ThornKit.events(combat, "summon", 0):
		ids.append(str(event["id"]))
	ids.sort()
	assert_eq(ids, ["t1_plain", "t2_shield", "t3_hunter"] as Array[String], "no entry twice")


func test_old_stump_with_an_empty_compost_does_nothing() -> void:
	CoreKit.put(game, p, "old-stump", 0)
	_killer(q)
	var combat: Combat = _fight()
	assert_eq(ThornKit.events(combat, "summon").size(), 0)
	assert_eq(ThornKit.triggers(combat, "thorn_old_stump").size(), 0)


func test_ivy_climber_gives_the_units_in_front_of_it_grow_one() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t1_plain", "t1_plain", "t1_plain"])
	CoreKit.put(game, p, "ivy-climber", 4)
	var units: Array[Unit] = []
	for slot: int in 3:
		units.append(CoreKit.put(game, p, "t1_plain", slot))
	ThornKit.wall(game, q, 0, 1, 500)
	var combat: Combat = _fight()
	var grew: Array[int] = []
	for event: Dictionary in ThornKit.triggers(combat, "thorn_grow"):
		grew.append(CoreUtil.to_int(event["slot"]))
	assert_eq(grew, [0, 1] as Array[int], "B1 is behind F1 and F2; any tribe")
	var buffed: Dictionary = ThornKit.about(combat, "buff", ThornKit.uid_of(combat, units[0]))[0]
	assert_eq([buffed["attack"], buffed["health"]], [4, 6], "heap 4: +2/+2")


func test_ivy_climber_in_the_front_row_does_nothing() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t1_plain"])
	CoreKit.put(game, p, "ivy-climber", 0)
	CoreKit.put(game, p, "t1_plain", 1)
	ThornKit.wall(game, q, 0, 1, 500)
	var combat: Combat = _fight()
	assert_eq(ThornKit.triggers(combat, "thorn_grow").size(), 0)


func test_hawthorn_warden_is_attacked_first_and_roots_spending_the_two_lowest() -> void:
	ThornKit.fill(game, p, ["t3_hunter", "t1_plain", "t2_shield", "t1_seed"])
	var warden: Unit = CoreKit.put(game, p, "hawthorn-warden", 1)
	CoreKit.put(game, p, "t1_plain", 0)
	CoreKit.put(game, p, "t1_plain", 2)
	_killer(q)
	var combat: Combat = _fight()
	var first_on_q: Dictionary = ThornKit.events(combat, "attack", 1)[0]
	assert_eq(CoreUtil.to_int(first_on_q["target_uid"]), ThornKit.uid_of(combat, warden), "Guard")
	assert_eq(ThornKit.events(combat, "return", 0).size(), 1)
	assert_eq(
		ThornKit.compost_ids(p),
		["t3_hunter", "t2_shield"] as Array[String],
		"the two lowest tiers, oldest first"
	)


func test_holly_knight_gives_front_row_briars_thorns_for_every_three() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t1_plain", "t1_plain", "t1_plain", "t1_plain", "t1_plain"])
	var sprout: Unit = CoreKit.put(game, p, "nettle-sprout", 0)
	var plain: Unit = CoreKit.put(game, p, "t1_plain", 1)
	CoreKit.put(game, p, "holly-knight", 4)
	ThornKit.wall(game, q, 0, 1, 30)
	ThornKit.wall(game, q, 1, 1, 30)
	ThornKit.wall(game, q, 2, 1, 30)
	var combat: Combat = _fight()
	assert_eq(ThornKit.granted(ThornKit.start_view(combat, sprout), "thorn_thorns", "amount"), 2)
	assert_eq(ThornKit.granted(ThornKit.start_view(combat, plain), "thorn_thorns", "amount"), 0)
	var sprout_uid: int = ThornKit.uid_of(combat, sprout)
	var attacks_on: int = 0
	var thorned: Array[int] = []
	for i: int in combat.events.size():
		var event: Dictionary = combat.events[i]
		if event["type"] != "attack" or CoreUtil.to_int(event["target_uid"]) != sprout_uid:
			continue
		attacks_on += 1
		# Step 1: the Thorns trigger, then its damage to the attacker, before anything else.
		assert_eq(str(combat.events[i + 1]["mechanic"]), "thorn_thorns")
		thorned.append(CoreUtil.to_int(combat.events[i + 2]["amount"]))
	assert_gt(attacks_on, 0)
	assert_eq(thorned[0], 4, "printed 2 and 2 more, one trigger")
	assert_eq(ThornKit.triggers(combat, "thorn_thorns").size(), attacks_on)


func test_lone_hawthorn_thorns_kills_go_into_the_compost_if_bought() -> void:
	CoreKit.put(game, p, "lone-hawthorn", 0)
	var sweet: Unit = CoreKit.put(game, p, "sweetbriar", 4)
	ThornKit.wall(game, q, 0, 1, 8)
	ThornKit.wall(game, q, 1, 1, 8)
	var combat: Combat = _fight()
	assert_eq(ThornKit.triggers(combat, "thorn_lone_hawthorn").size(), 2)
	assert_eq(ThornKit.compost_ids(p), ["t1_plain", "t1_plain"] as Array[String])
	assert_eq(sweet.stats.perm_attack, 2, "Sweetbriar hears each entry")


func test_lone_hawthorn_created_enemies_add_nothing() -> void:
	CoreKit.put(game, p, "lone-hawthorn", 0)
	for slot: int in 2:
		var token: Unit = ThornKit.wall(game, q, slot, 1, 8)
		token.bought_copies = 0
	var combat: Combat = _fight()
	assert_eq(ThornKit.events(combat, "death", 1).size(), 2, "the thorns kill them")
	assert_eq(p.heap(HEAP).size(), 0, "tokens kill but don't feed")


func test_hazel_coppicer_gives_the_board_one_one_for_good_after_a_return() -> void:
	ThornKit.fill(game, p, ["t1_plain"])
	CoreKit.put(game, p, "blackthorn-sapling", 0)
	var plain: Unit = CoreKit.put(game, p, "t1_plain", 1)
	var coppicer: Unit = CoreKit.put(game, p, "hazel-coppicer", 4)
	_killer(q)
	var combat: Combat = _fight()
	assert_eq(ThornKit.events(combat, "return", 0).size(), 1)
	assert_eq(ThornKit.triggers(combat, "thorn_coppicer").size(), 1)
	assert_eq(plain.stats.perm_attack, 1, "every friendly unit, for good")
	assert_eq(coppicer.stats.perm_attack, 1, "itself included")


func test_elder_mother_summons_the_best_copy_with_a_bonus_for_each_entry() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t4_wall", "t3_hunter", "t2_shield"])
	CoreKit.put(game, p, "elder-mother", 4)
	ThornKit.wall(game, q, 0, 1, 500)
	var combat: Combat = _fight()
	var summons: Array[Dictionary] = ThornKit.events(combat, "summon", 0)
	assert_eq(summons.size(), 1)
	assert_eq(summons[0]["id"], "t4_wall", "highest tier first")
	var grown: Dictionary = ThornKit.about(combat, "buff", CoreUtil.to_int(summons[0]["uid"]))[0]
	assert_eq([grown["attack"], grown["health"]], [8, 18], "+1/+1 per entry")
	assert_eq(p.heap(HEAP).size(), 4, "the entries stay")
	assert_eq(ThornKit.events(combat, "heap_use", 0).size(), 1)


func test_golden_elder_mother_summons_the_two_best_with_the_same_bonus() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t4_wall", "t3_hunter", "t2_shield"])
	p.place(CoreKit.unit(game, "elder-mother", true), 4)
	ThornKit.wall(game, q, 0, 1, 500)
	var combat: Combat = _fight()
	var summons: Array[Dictionary] = ThornKit.events(combat, "summon", 0)
	assert_eq(summons.map(func(e: Dictionary) -> String: return e["id"]), ["t4_wall", "t3_hunter"])
	for summoned: Dictionary in summons:
		var grown: Dictionary = ThornKit.about(combat, "buff", CoreUtil.to_int(summoned["uid"]))[0]
		assert_eq(grown["attack"] - summoned["attack"], 4, "+1 per entry")
		assert_eq(grown["health"] - summoned["health"], 4, "+1 per entry")
	assert_eq(p.heap(HEAP).size(), 4)
	assert_eq(ThornKit.events(combat, "heap_use", 0).size(), 2)


func test_elder_mother_loses_the_copy_on_a_full_board() -> void:
	ThornKit.fill(game, p, ["t3_hunter", "t2_shield"])
	CoreKit.put(game, p, "elder-mother", 4)
	for slot: int in [0, 1, 2, 3, 5, 6]:
		ThornKit.wall(game, p, slot, 1, 1)
	ThornKit.wall(game, q, 0, 30, 5000)
	var combat: Combat = _fight()
	assert_gt(ThornKit.events(combat, "death", 0).size(), 0, "slots opened later")
	assert_eq(ThornKit.events(combat, "summon", 0).size(), 0, "no late arrivals")
	assert_eq(ThornKit.events(combat, "heap_use", 0).size(), 0, "no entry was copied")
	assert_eq(p.heap(HEAP).size(), 2)


func test_golden_elder_mother_loses_only_the_extra_copy_on_a_nearly_full_board() -> void:
	ThornKit.fill(game, p, ["t3_hunter", "t2_shield"])
	p.place(CoreKit.unit(game, "elder-mother", true), 4)
	for slot: int in [0, 1, 3, 5, 6]:
		ThornKit.wall(game, p, slot, 1, 1)
	ThornKit.wall(game, q, 0, 30, 5000)
	var combat: Combat = _fight()
	var summons: Array[Dictionary] = ThornKit.events(combat, "summon", 0)
	assert_eq(summons.size(), 1)
	assert_eq([summons[0]["id"], summons[0]["slot"]], ["t3_hunter", 2])
	assert_eq(ThornKit.events(combat, "heap_use", 0).size(), 1)


func test_briar_king_gives_other_front_row_briars_grow_two() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t1_plain", "t1_plain", "t1_plain"])
	var sprout: Unit = CoreKit.put(game, p, "nettle-sprout", 0)
	CoreKit.put(game, p, "t1_plain", 1)
	CoreKit.put(game, p, "briar-king", 2)
	ThornKit.wall(game, q, 0, 1, 500)
	var combat: Combat = _fight()
	var grew: Array[Dictionary] = ThornKit.triggers(combat, "thorn_grow")
	assert_eq(grew.size(), 1, "only the Sprout: not the plain unit, not the King")
	assert_eq(CoreUtil.to_int(grew[0]["uid"]), ThornKit.uid_of(combat, sprout))
	var buffed: Dictionary = ThornKit.about(combat, "buff", ThornKit.uid_of(combat, sprout))[0]
	assert_eq([buffed["attack"], buffed["health"]], [6, 11], "heap 4: +4/+4")


func test_the_old_hedge_gives_other_briars_root_one() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t1_plain", "t1_plain"])
	var runner: Unit = CoreKit.put(game, p, "nettle-sprout", 0)
	var plain: Unit = CoreKit.put(game, p, "t1_plain", 1)
	CoreKit.put(game, p, "the-old-hedge", 4)
	CoreKit.put(game, p, "the-old-hedge", 5)
	_killer(q)
	var combat: Combat = _fight()
	var from: Array[int] = []
	for event: Dictionary in ThornKit.events(combat, "return", 0):
		from.append(CoreUtil.to_int(event["from_uid"]))
	assert_has(from, ThornKit.uid_of(combat, runner), "a Briar returns")
	assert_does_not_have(from, ThornKit.uid_of(combat, plain), "not a Briar")
	for event: Dictionary in ThornKit.events(combat, "heap_remove", 0):
		assert_eq(event["ids"].size(), 1, "two Hedges still give Root 1")


func test_the_old_hedge_root_from_two_sources_returns_once_and_pays_the_lower_cost() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t1_plain", "t1_plain"])
	var warden: Unit = CoreKit.put(game, p, "hawthorn-warden", 0)
	CoreKit.put(game, p, "the-old-hedge", 4)
	_killer(q)
	var combat: Combat = _fight()
	var warden_uid: int = ThornKit.uid_of(combat, warden)
	var returns: Array[Dictionary] = ThornKit.events(combat, "return", 0).filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["from_uid"]) == warden_uid
	)
	assert_eq(returns.size(), 1, "once a fight")
	var spent: Array[Dictionary] = ThornKit.events(combat, "heap_remove", 0).filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["source_uid"]) == warden_uid
	)
	assert_eq(spent[0]["ids"].size(), 1, "Root 2 and Root 1: it pays 1")


func test_root_is_once_a_fight_even_with_compost_left() -> void:
	ThornKit.fill(game, p, ["t1_plain", "t1_plain", "t1_plain"])
	CoreKit.put(game, p, "blackthorn-sapling", 0)
	_killer(q)
	var combat: Combat = _fight()
	var returns: Array[Dictionary] = ThornKit.events(combat, "return", 0)
	assert_eq(returns.size(), 1, "the returned Sapling dies again and stays dead")
	assert_eq(str(returns[0]["mechanic"]), "thorn_root", "through the return protocol")
	assert_eq(p.heap(HEAP).size(), 2, "one Root, one entry spent")


## Root against the locusts' Molt (SHARED-RULES 17), with the real cards of every tribe: a
## Skin-shedder gives the Sapling beside it Molt. Root first when the Compost can pay, Molt on the
## later death; with an empty Compost, Molt at once.
func test_root_comes_before_a_skin_shedders_molt_when_the_compost_can_pay() -> void:
	for heap_size: int in [1, 0]:
		var all: GameSession = CoreKit.all_tribes().session(3)
		all.start_round()
		var me: PlayerState = all.player(0)
		var them: PlayerState = all.player(1)
		for _i: int in heap_size:
			me.heap(HEAP).add(&"bramble-runner", 1)
		CoreKit.put(all, me, "blackthorn-sapling", 0)
		CoreKit.put(all, me, "skin-shedder", 1)
		var killer: Unit = CoreKit.put(all, them, "bramble-runner", 0)
		killer.stats.set_attack = 200
		killer.stats.set_health = 5000
		var combat: Combat = ThornKit.fight(all, me, them)
		var how: Array[String] = []
		for event: Dictionary in ThornKit.events(combat, "return", 0):
			if str(event["id"]) == "blackthorn-sapling":
				how.append(str(event["mechanic"]))
		assert_gt(how.size(), 0, "heap %d: the Sapling returns" % heap_size)
		if heap_size == 1:
			assert_eq(how[0], "thorn_root", "the Compost can pay: Root first")
			# The later death's Molt needs the locusts to carry a Molt given this fight across a
			# Root return (their molt.gd on_returned); Root itself never fires twice.
			assert_eq(how.count("thorn_root"), 1, "Root once a fight")
		else:
			assert_ne(how[0], "thorn_root", "nothing to pay with: Molt")
		assert_eq(me.heap(HEAP).size(), 0, "heap %d: Root spent what it could" % heap_size)


## The fight result's Compost count (a play-tester saw it stale): every Seed that resolves logs a
## heap_add with the new size, and the real player's view carries it once the fight is over.
func test_seeds_log_each_new_compost_size_and_the_player_view_carries_it() -> void:
	CoreKit.put(game, p, "bramble-runner", 0)
	CoreKit.put(game, p, "bramble-runner", 1)
	ThornKit.fill(game, p, ["t1_plain", "t1_plain"])
	_killer(q)
	var combat: Combat = _fight()
	var sizes: Array[int] = []
	for event: Dictionary in ThornKit.events(combat, "heap_add", 0):
		assert_eq(str(event["heap"]), "thorn_compost")
		sizes.append(CoreUtil.to_int(event["size"]))
	assert_eq(sizes, [3, 4] as Array[int], "one heap_add per Seed, each with the new size")
	assert_eq(p.view()["heaps"]["thorn_compost"].size(), 4, "the after-fight view is current")
	assert_eq(game.view_for(0)["heaps"]["thorn_compost"].size(), 4)
