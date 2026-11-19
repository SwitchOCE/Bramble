extends GutTest
## Hooks and rules that had no test: can't attack, fight gold, combines false, counters on a
## triple, heap and death listeners, returns heard by friends, standing triggers, nested
## attacks. Each through a test card in tests/core/content/test/.

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


func _fight(live_b: bool = true) -> Combat:
	var combat: Combat = Combat.create(game.geometry, game.config, game.registry, game.library, 1)
	combat.run([p.board, q.board], [0, 1], [p, q], [true, live_b])
	return combat


func _wall(player: PlayerState, slot: int, attack: int, health: int) -> Unit:
	var made: Unit = CoreKit.put(game, player, "t1_plain", slot)
	made.stats.set_attack = attack
	made.stats.set_health = health
	return made


func _triggers(combat: Combat, mechanic: String) -> int:
	return (
		CoreKit
		. events_of(combat, "trigger")
		. filter(func(e: Dictionary) -> bool: return e["mechanic"] == mechanic)
		. size()
	)


func test_9_4_5_a_unit_that_cant_attack_is_skipped() -> void:
	CoreKit.put(game, p, "b2_pacifist", 0)
	CoreKit.put(game, q, "t1_plain", 0)
	var combat: Combat = _fight()
	var mine: Array[Dictionary] = CoreKit.events_of(combat, "attack").filter(
		func(e: Dictionary) -> bool: return e["side"] == 0
	)
	assert_eq(mine.size(), 0)
	assert_gt(CoreKit.events_of(combat, "attack").size(), 0, "the other side still attacks")


func test_gold_earned_in_a_fight_is_paid_next_turn_and_never_to_a_ghost() -> void:
	CoreKit.put(game, p, "b3_cutpurse", 0)
	_wall(q, 0, 1, 1)
	_fight()
	assert_eq(p.gold_next_turn, 1)
	var income: int = game.rules.income(p, game.round_number + 1)
	game.finish_round()
	var before: int = p.gold
	game.start_round()
	assert_eq(p.gold, before + income + 1, "paid at the start of the next turn")
	assert_eq(p.gold_next_turn, 0)
	var ghost_side: PlayerState = game.player(2)
	CoreKit.put(game, ghost_side, "b3_cutpurse", 0)
	var combat: Combat = Combat.create(game.geometry, game.config, game.registry, game.library, 2)
	_wall(game.player(3), 0, 1, 1)
	combat.run([game.player(3).board, ghost_side.board], [3, 2], [game.player(3), ghost_side])
	assert_eq(ghost_side.gold_next_turn, 0, "a side that doesn't write back earns nothing")


func test_7_3_1_a_card_with_combines_false_never_triples() -> void:
	p.gold = 100
	for _i: int in 3:
		CoreKit.set_shop(game, p, ["b1_loner"] as Array[String])
		assert_eq(game.act(0, {"type": "buy", "spell": false, "index": 0}), "")
	assert_eq(p.hand.size(), 3)
	assert_false(p.hand.any(func(u: Unit) -> bool: return u.golden))


func test_7_3_a_triple_adds_up_its_copies_counters() -> void:
	p.gold = 100
	var amounts: Array[int] = [1, 2, 0]
	for amount: int in amounts:
		CoreKit.set_shop(game, p, ["b2_veteran"] as Array[String])
		assert_eq(game.act(0, {"type": "buy", "spell": false, "index": 0}), "")
		for unit: Unit in p.hand:
			if not unit.golden and unit.counter(&"test_mark") == 0:
				unit.counters[&"test_mark"] = amount
				break
	var golden: Array[Unit] = p.hand.filter(func(u: Unit) -> bool: return u.golden)
	assert_eq(golden.size(), 1)
	assert_eq(golden[0].counter(&"test_mark"), 3, "1 + 2 + the third copy's 0")


func test_on_heap_added_hears_every_entry() -> void:
	var watcher: Unit = CoreKit.put(game, p, "b2_watcher", 0)
	var ctx := RecruitContext.new(game, game.recruit, p)
	ctx.heap_add(&"test_heap", &"t1_plain", null)
	ctx.heap_add(&"test_heap", &"t1_plain", null)
	assert_eq(watcher.stats.perm_attack, 2)


func test_9_7_2_on_any_death_hears_both_sides() -> void:
	CoreKit.put(game, p, "b3_mourner", 0)
	CoreKit.put(game, p, "t1_seed", 1)
	_wall(q, 0, 3, 1)
	_wall(q, 1, 3, 1)
	var combat: Combat = _fight()
	var deaths: int = CoreKit.events_of(combat, "death").size()
	var mourner_alive: bool = combat.units(0).any(
		func(u: CombatUnit) -> bool: return u.def.id == &"b3_mourner"
	)
	assert_gt(deaths, 1)
	if mourner_alive:
		assert_eq(_triggers(combat, "test_mourner"), deaths, "every death, either side")
	else:
		assert_gt(_triggers(combat, "test_mourner"), 0)


func test_9_7_2_step_5_after_a_friendly_unit_returns() -> void:
	CoreKit.put(game, p, "t4_phoenix", 0)
	CoreKit.put(game, p, "b3_welcomer", 4)
	_wall(q, 0, 50, 50)
	var combat: Combat = _fight()
	var back: Array[Dictionary] = CoreKit.events_of(combat, "return")
	assert_eq(back.size(), 1)
	assert_eq(_triggers(combat, "test_welcome_back"), 1)
	var buffs: Array[Dictionary] = CoreKit.events_of(combat, "buff").filter(
		func(e: Dictionary) -> bool: return e["uid"] == back[0]["uid"]
	)
	assert_eq(buffs.size(), 1)


func test_9_4_12_nested_attacks_stop_at_max_attack_depth() -> void:
	CoreKit.put(game, p, "b4_frenzy", 0)
	CoreKit.put(game, p, "t1_plain", 1).stats.set_attack = 0
	_wall(q, 0, 0, 1000)
	var combat: Combat = _fight()
	var run: int = 0
	for event: Dictionary in combat.events:
		if event["type"] == "attack":
			if event["side"] != 0:
				break
			run += 1
		elif event["type"] == "pass":
			break
	assert_eq(run, Combat.MAX_ATTACK_DEPTH + 1, "its turn's attack and four nested ones")


func test_9_10_2_a_standing_listener_triggers_for_its_side() -> void:
	var ctx := RecruitContext.new(game, game.recruit, p)
	assert_true(ctx.add_standing(&"test_mourner"))
	CoreKit.put(game, p, "t3_hunter", 0)
	_wall(q, 0, 1, 1)
	var combat: Combat = _fight()
	var side_triggers: Array[Dictionary] = CoreKit.events_of(combat, "trigger").filter(
		func(e: Dictionary) -> bool: return e["mechanic"] == "test_mourner"
	)
	assert_eq(side_triggers.size(), 1, "one death, heard by p's standing mechanic")
	assert_eq(side_triggers[0]["side"], 0)
	assert_eq(side_triggers[0]["uid"], -1, "no unit")
	assert_eq(combat.result["triggers"], CoreKit.events_of(combat, "trigger").size())
