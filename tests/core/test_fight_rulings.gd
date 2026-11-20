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
	var damage: Array[Dictionary] = CoreKit.events_of(combat, "damage")
	assert_eq(damage.size(), 1, "only the pile-on dealt damage")
	assert_eq(damage[0]["side"], 1, "the defender did not strike back")
	assert_false(damage[0]["from_attack"], "the attacker did not hit either")
	assert_eq(_triggers(combat, "test_after_strike").size(), 1)


func test_a_dead_attacker_skips_its_after_attack_trigger() -> void:
	CoreKit.put(game, p, "b2_crier", 0)
	_wall(p, 4, 0, 100)
	_wall(q, 0, 2, 3)
	var combat: Combat = _fight()
	assert_eq(CoreKit.events_of(combat, "death").size(), 2, "both die in the exchange")
	assert_eq(_triggers(combat, "test_war_cry").size(), 1)
	assert_eq(_triggers(combat, "test_after_strike").size(), 0, "the crier already died")


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


func test_last_fight_changes_reach_the_next_round_event_log() -> void:
	CoreKit.put(game, p, "b2_veteran", 0)
	game.finish_round()
	var first: int = game.events.size()
	game.start_round()
	var marks: Array = game.events.slice(first).filter(
		func(e: Dictionary) -> bool: return e["type"] == "counter" and e["player"] == 0
	)
	assert_eq(marks.size(), 1, "the mark earned for the last fight is in the turn's events")


func test_spent_one_use_keywords_and_kills_name_their_source() -> void:
	var viper: Unit = CoreKit.put(game, p, "t3_viper", 0)
	_wall(p, 4, 0, 100)
	CoreKit.put(game, q, "t4_phoenix", 0)
	var combat: Combat = _fight()
	var start: Dictionary = combat.events[0]
	var viper_view: Dictionary = start["boards"][0][0]
	assert_eq(viper_view["recruit_uid"], viper.uid, "a recruit card matches its fight copy")
	var spent: Array[Dictionary] = CoreKit.events_of(combat, "status").filter(
		func(e: Dictionary) -> bool: return e["status"] == "venomous"
	)
	assert_eq(spent.size(), 1, "Venomous is used up after its kill")
	assert_eq(spent[0]["source_uid"], viper_view["uid"])
	var destroyed: Array[Dictionary] = CoreKit.events_of(combat, "destroy")
	assert_eq(destroyed[0]["source_uid"], viper_view["uid"])
	var phoenix_uid: int = start["boards"][1][0]["uid"]
	var deaths: Array[Dictionary] = CoreKit.events_of(combat, "death").filter(
		func(e: Dictionary) -> bool: return e["uid"] == phoenix_uid
	)
	assert_eq(deaths[0]["killer_uid"], viper_view["uid"])
	var reborn: Array[Dictionary] = CoreKit.events_of(combat, "status").filter(
		func(e: Dictionary) -> bool: return e["status"] == "reborn" and not e["on"]
	)
	assert_eq(reborn.size(), 1, "the returned copy shows Reborn spent")


func test_a_dead_defenders_committed_strike_back_keeps_its_venomous() -> void:
	_wall(p, 0, 4, 40)
	_wall(p, 4, 0, 100)
	CoreKit.put(game, q, "t3_viper", 0)
	var combat: Combat = _fight()
	var damage: Array[Dictionary] = CoreKit.events_of(combat, "damage")
	assert_eq(damage.size(), 2)
	assert_eq(damage[1]["side"], 0, "the defender had committed its direct damage")
	assert_eq(damage[1]["amount"], 2)
	assert_eq(_triggers(combat, "venomous").size(), 1, "one exchange: the strike back keeps Venomous")
	assert_eq(CoreKit.events_of(combat, "destroy").size(), 1)
