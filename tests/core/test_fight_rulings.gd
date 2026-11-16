extends GutTest
## Fight rulings the tribe designs lean on: what counts as an attack, what an attacker killed in
## step 1 still does, hits against Plate, and what the fight log carries for the screens.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = CoreKit.bridge_session()
	game.start_round()
	p = game.player(0)
	q = game.player(1)


func _fight(fight_seed: int = 1) -> Combat:
	var combat: Combat = Combat.create(
		game.geometry, game.config, game.registry, game.library, fight_seed
	)
	combat.run([p.board, q.board], [0, 1], [p, q], [true, true])
	return combat


func _wall(player: PlayerState, slot: int, attack: int, health: int) -> Unit:
	var made: Unit = CoreKit.put(game, player, "t1_plain", slot)
	made.stats.set_attack = attack
	made.stats.set_health = health
	return made


func _triggers(combat: Combat, mechanic: String) -> Array[Dictionary]:
	return CoreKit.events_of(combat, "trigger").filter(
		func(e: Dictionary) -> bool: return e["mechanic"] == mechanic
	)


func test_9_10_1_instead_of_attacking_counts_toward_the_attack_limit() -> void:
	game.config.attack_limit = 5
	CoreKit.put(game, p, "b2_slinger", 0)
	_wall(q, 0, 0, 100)
	var combat: Combat = _fight()
	assert_eq(combat.result["reason"], Combat.REASON_ATTACK_LIMIT)
	assert_eq(combat.result["attacks"], 5)
	assert_eq(CoreKit.events_of(combat, "instead_of_attack").size(), 5)
	assert_eq(CoreKit.events_of(combat, "attack").size(), 0, "it never attacked")
	assert_eq(CoreKit.events_of(combat, "instead_of_attack")[0]["mechanic"], "test_sling")


func test_9_6_1_an_attacker_thorns_kills_in_step_1_does_not_attack() -> void:
	var crier: Unit = CoreKit.put(game, p, "b2_crier", 0)
	CoreKit.put(game, p, "b1_piler", 1)
	CoreKit.put(game, q, "b2_thorny", 0)
	var combat: Combat = _fight()
	var first: Dictionary = CoreKit.events_of(combat, "attack")[0]
	assert_eq(first["side"], 0, "more units attack first (9.2.1)")
	assert_eq(first["slot"], 0, "the crier attacks first")
	assert_eq(_triggers(combat, "test_war_cry").size(), 0, "no 'whenever this attacks'")
	assert_eq(_triggers(combat, "test_after_strike").size(), 0, "no 'after this attacks'")
	assert_eq(CoreKit.events_of(combat, "hit").size(), 0, "no friend joins in")
	var crier_deaths: Array[Dictionary] = CoreKit.events_of(combat, "death").filter(
		func(e: Dictionary) -> bool: return e["side"] == 0 and e["slot"] == crier.slot
	)
	assert_eq(crier_deaths.size(), 1)


func test_9_6_1_after_this_attacks_still_happens_when_a_pile_on_kills_the_target() -> void:
	CoreKit.put(game, p, "b2_crier", 0)
	CoreKit.put(game, p, "b1_piler", 1)
	_wall(q, 0, 1, 2)
	var combat: Combat = _fight()
	assert_eq(CoreKit.events_of(combat, "hit").size(), 1, "the piler joins in")
	var exchange: Array[Dictionary] = CoreKit.events_of(combat, "damage").filter(
		func(e: Dictionary) -> bool: return e["side"] == 0
	)
	assert_eq(exchange.size(), 0, "the target died before the exchange")
	assert_eq(_triggers(combat, "test_after_strike").size(), 1)


func test_a_hit_is_not_attack_damage_so_plate_does_not_reduce_it() -> void:
	var crier: Unit = CoreKit.put(game, p, "b2_crier", 0)
	var piler: Unit = CoreKit.put(game, p, "b1_piler", 1)
	CoreKit.put(game, q, "b2_plated", 0)
	var combat: Combat = _fight()
	var hurt: Array[Dictionary] = CoreKit.events_of(combat, "damage").filter(
		func(e: Dictionary) -> bool: return e["side"] == 1
	)
	var uids: Dictionary = {}
	for event: Dictionary in CoreKit.events_of(combat, "combat_start")[0]["boards"][0]:
		uids[event["slot"]] = event["uid"]
	assert_eq(hurt[0]["source_uid"], uids[piler.slot], "the hit lands first")
	assert_eq(hurt[0]["amount"], 2, "Plate doesn't reduce a hit")
	assert_eq(hurt[1]["source_uid"], uids[crier.slot])
	assert_eq(hurt[1]["amount"], 3 - 1, "Plate 1 takes 1 off the attack (war cry made it 3)")


func test_combat_start_carries_player_counters_and_heap_sizes() -> void:
	p.counters[&"test_tide"] = 2
	q.heap(&"test_heap").add(&"t1_plain", 1)
	CoreKit.put(game, p, "t1_plain", 0)
	CoreKit.put(game, q, "t1_plain", 0)
	var start: Dictionary = _fight().events[0]
	assert_eq(start["counters"][0][&"test_tide"], 2)
	assert_eq(start["heaps"][1]["test_heap"], 1)


func test_keyword_and_status_events_name_their_source() -> void:
	CoreKit.put(game, p, "t4_wall", 0)
	CoreKit.put(game, q, "t2_shield", 0)
	var combat: Combat = _fight()
	var pops: Array[Dictionary] = CoreKit.events_of(combat, "status")
	assert_gt(pops.size(), 0, "the shield popped")
	var damager: int = -1
	for event: Dictionary in CoreKit.events_of(combat, "attack"):
		if event["target_side"] == pops[0]["side"]:
			damager = event["uid"]
			break
	assert_eq(pops[0]["source_uid"], damager, "the unit whose damage it stopped")
	assert_eq(combat.units(0).size(), 1, "the wall outlasts the shield")
	var holder: CombatUnit = combat.units(0)[0]
	assert_true(combat.bridge(0).give_keyword(holder, &"windfury", false, holder))
	var given: Dictionary = CoreKit.events_of(combat, "keyword")[-1]
	assert_eq(given["source_uid"], holder.uid)


func test_after_fight_changes_reach_the_fight_record() -> void:
	CoreKit.put(game, p, "b2_veteran", 0)
	game.finish_round()
	var mine: Array = game.fights.filter(func(f: Dictionary) -> bool: return f["players"].has(0))
	assert_eq(mine.size(), 1)
	var after: Array = mine[0]["after"]
	var medals: Array = after.filter(
		func(e: Dictionary) -> bool: return e["type"] == "counter" and e["player"] == 0
	)
	assert_gt(medals.size(), 0, "the medal it earned after the fight is in the record")
