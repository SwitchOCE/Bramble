extends GutTest
## The bridge capabilities, each through a neutral test card (tests/core/content/test/:
## a script per mechanic, cards in units.json): fight-to-player write-back, lasting state, slots,
## heaps, listeners, abilities and targets, auras that see the fight, and the screens' views.

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


## A fight between two players' real boards; `live_b` false makes side 1 a ghost-like copy.
func _fight(live_b: bool = true, fight_seed: int = 1) -> Combat:
	var combat: Combat = Combat.create(
		game.geometry, game.config, game.registry, game.library, fight_seed
	)
	combat.run([p.board, q.board], [0, 1], [p, q], [true, live_b])
	return combat


func _ctx(player: PlayerState) -> RecruitContext:
	return RecruitContext.new(game, game.recruit, player)


func test_12_1_1_a_permanent_buff_in_a_fight_reaches_the_recruit_unit() -> void:
	var berserk: Unit = CoreKit.put(game, p, "b2_berserk", 0)
	for slot: int in 3:
		CoreKit.put(game, q, "t1_plain", slot)
	var combat: Combat = _fight()
	var lasting: Array[Dictionary] = CoreKit.events_of(combat, "buff").filter(
		func(e: Dictionary) -> bool: return e["permanent"]
	)
	assert_gt(lasting.size(), 0, "it attacked while outnumbered")
	assert_eq(berserk.stats.perm_attack, lasting.size(), "each fury +1/+1 is on the real unit")


func test_9_1_1_a_ghost_side_never_writes_back() -> void:
	var berserk: Unit = CoreKit.put(game, q, "b2_berserk", 0)
	for slot: int in 3:
		CoreKit.put(game, p, "t1_plain", slot)
	_fight(false)
	assert_eq(berserk.stats.perm_attack, 0)


func test_rulings_1_2_an_aura_reads_the_fixed_outnumbered_count() -> void:
	CoreKit.put(game, p, "b2_berserk", 0)
	CoreKit.put(game, q, "t1_plain", 0)
	CoreKit.put(game, q, "t1_plain", 1)
	var combat: Combat = _fight()
	var start: Dictionary = combat.events[0]
	var shown: Dictionary = start["boards"][0][0]
	assert_eq(shown["attack"], 3 + 2, "outnumbered at the start: +2 Attack")
	assert_gt(CoreKit.events_of(combat, "death").size(), 0, "enemies died, evening the count")
	var stats: Array[Dictionary] = CoreKit.events_of(combat, "stats").filter(
		func(e: Dictionary) -> bool: return e["uid"] == shown["uid"] and e["attack"] < 5
	)
	assert_eq(stats.size(), 0, "the count is fixed at the start, so the aura stays")


func test_last_fight_earns_lasting_counters_at_the_start_of_turn() -> void:
	var veteran: Unit = CoreKit.put(game, p, "b2_veteran", 0)
	game.finish_round()
	assert_eq(veteran.counter(&"test_mark"), 0)
	game.start_round()
	assert_true(veteran.counter(&"test_mark") >= 1)
	assert_eq(veteran.stats.perm_attack, veteran.counter(&"test_mark"), "+1/+1 for each mark")
	var view: Dictionary = p.view()
	assert_eq(view["board"][0]["counters"]["test_mark"], veteran.counter(&"test_mark"))


func test_3_3_1_an_ability_with_a_slot_target_is_a_legal_action() -> void:
	var officer: Unit = CoreKit.put(game, p, "b3_officer", 0)
	p.gold = 3
	var mine: Array[Dictionary] = game.legal_actions(0).filter(
		func(a: Dictionary) -> bool: return a["type"] == "ability"
	)
	assert_eq(mine.size(), game.geometry.slot_count, "one per slot")
	var use: Dictionary = {
		"type": "ability", "uid": officer.uid, "mechanic": "test_order_slot", "target": 4
	}
	assert_eq(game.act(0, use), "")
	assert_eq(p.gold, 2, "costs 1")
	assert_true(p.slots[4].keywords.has(&"taunt"), "a slot can give a keyword")
	assert_eq(game.act(0, use), "already used this turn")
	game.end_turn(0)
	game.finish_round()
	game.start_round()
	assert_eq(game.act(0, use), "", "once a turn, again next turn")


func test_heap_fills_on_sale_and_from_the_shop_and_is_spent_in_fights() -> void:
	var burier: Unit = CoreKit.put(game, p, "b1_burier", 0)
	var shop_card: StringName = p.shop_units[0]
	var bury: Dictionary = {
		"type": "ability", "uid": burier.uid, "mechanic": "test_bury", "target": 0
	}
	assert_eq(game.act(0, bury), "")
	assert_eq(p.heap(&"test_heap").size(), 1)
	assert_eq(StringName(p.heap(&"test_heap").entries[0]["id"]), shop_card)
	p.gold = 10
	assert_eq(game.act(0, {"type": "buy", "spell": false, "index": 1}), "")
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": 1, "target": -1}), "")
	assert_eq(game.act(0, {"type": "sell", "slot": 1}), "")
	assert_eq(p.heap(&"test_heap").size(), 2, "a Bought unit sold goes in (standing mechanic)")
	assert_eq(p.view()["heaps"]["test_heap"].size(), 2)


func test_9_8_2_a_return_that_spends_the_real_heap() -> void:
	p.heap(&"test_heap").add(&"t1_plain", 1)
	p.heap(&"test_heap").add(&"t2_shield", 2)
	p.heap(&"test_heap").add(&"t1_seed", 1)
	CoreKit.put(game, p, "b3_rooter", 0)
	for slot: int in 4:
		CoreKit.put(game, q, "t1_guard", slot)
	var combat: Combat = _fight()
	assert_eq(CoreKit.events_of(combat, "return").size(), 1, "once a fight")
	assert_eq(p.heap(&"test_heap").size(), 1, "spent 2 for good")
	assert_eq(StringName(p.heap(&"test_heap").entries[0]["id"]), &"t2_shield", "lowest tiers first")


func test_a_death_in_a_fight_adds_to_the_real_heap_but_not_a_ghosts() -> void:
	CoreKit.put(game, p, "b2_seeder", 0)
	CoreKit.put(game, q, "b2_seeder", 0)
	var killers: Array[Unit] = [CoreKit.put(game, p, "t3_hunter", 1)]
	killers.append(CoreKit.put(game, q, "t3_hunter", 1))
	for killer: Unit in killers:
		killer.stats.set_health = 100
	var combat: Combat = _fight(false)
	var adds: Array = [0, 0]
	for event: Dictionary in CoreKit.events_of(combat, "heap_add"):
		adds[event["side"]] += 1
	assert_eq(adds, [1, 1], "both seeders died and seeded")
	assert_eq(p.heap(&"test_heap").size(), 1, "the live side's real heap")
	assert_eq(q.heap(&"test_heap").size(), 0, "the ghost's heap is a copy")


func test_9_6_1_a_neighbour_piles_on_with_a_hit() -> void:
	CoreKit.put(game, p, "t1_plain", 0)
	CoreKit.put(game, p, "b1_piler", 1)
	CoreKit.put(game, q, "t2_mentor", 0)
	var combat: Combat = _fight()
	var joins: Array[Dictionary] = CoreKit.events_of(combat, "hit")
	assert_gt(joins.size(), 0)
	assert_eq(joins[0]["uid"], combat.events[0]["boards"][0][1]["uid"])


func test_9_4_12_attacks_immediately_keeps_the_pointer() -> void:
	CoreKit.put(game, p, "b3_charger", 3)
	CoreKit.put(game, q, "t1_guard", 0)
	CoreKit.put(game, q, "t1_guard", 1)
	var combat: Combat = _fight()
	var attacks: Array[Dictionary] = CoreKit.events_of(combat, "attack")
	assert_eq(attacks[0]["side"], 0, "the charge comes before the first normal attack")
	assert_eq(attacks[1]["side"], 1, "and side 1, which has more units, still goes first")


func test_9_5_7_a_unit_that_attacks_the_back_row() -> void:
	p.place(CoreKit.unit(game, "b3_raider", true), 0)
	CoreKit.put(game, q, "t1_guard", 0)
	CoreKit.put(game, q, "t1_plain", 4)
	var combat: Combat = _fight()
	var mine: Array[Dictionary] = CoreKit.events_of(combat, "attack").filter(
		func(e: Dictionary) -> bool: return e["side"] == 0
	)
	assert_eq(mine[0]["target_slot"], 4, "past the front-row Taunt into the back row")


func test_9_7_2_death_effects_twice_and_full_board_summons_fail() -> void:
	for slot: int in 7:
		CoreKit.put(game, p, "t1_guard", slot)
	p.board[0] = null
	CoreKit.put(game, p, "b2_swarm", 0)
	p.board[6] = null
	CoreKit.put(game, p, "b4_dirge", 6)
	CoreKit.put(game, q, "t2_mentor", 0)
	var combat: Combat = _fight()
	var spawns: Array[Dictionary] = CoreKit.events_of(combat, "trigger").filter(
		func(e: Dictionary) -> bool: return e["mechanic"] == "test_swarm_spawn"
	)
	assert_eq(spawns.size(), 2, "the death effect resolved twice")
	assert_eq(CoreKit.events_of(combat, "summon_failed").size(), 3, "only one slot was open")
	var summons: Array[Dictionary] = CoreKit.events_of(combat, "summon")
	assert_eq(summons.size(), 1, "later deaths free slots but summon nothing")
	assert_eq(summons[0]["id"], "tk_sprout")
	assert_eq(summons[0]["slot"], 0)


func test_12_2_1_an_aura_gives_a_keyword() -> void:
	CoreKit.put(game, p, "b4_lender", 1)
	var plain: Unit = CoreKit.put(game, p, "t1_plain", 0)
	game.recruit.refresh_auras(p)
	assert_true(plain.has_mechanic(&"taunt"))
	assert_true(plain.view()["keywords"].has("taunt"))
	assert_false(plain.mechanics.any(func(b: BoundMechanic) -> bool: return b.id == &"taunt"))


func test_11_1_1_keywords_gained_and_lost_in_a_fight() -> void:
	var plain: Unit = CoreKit.put(game, p, "t1_plain", 0)
	var combat: Combat = Combat.create(game.geometry, game.config, game.registry, game.library, 1)
	combat.run([p.board, q.board], [0, 1], [p, q], [true, true])
	var copy := CombatUnit.from_unit(plain, 99, 0)
	assert_true(combat.bridge(0).give_keyword(copy, &"windfury", true))
	assert_true(plain.has_mechanic(&"windfury"), "permanently: the recruit unit has it")


func test_eat_takes_stats_for_good_and_runs_death_effects_in_the_recruit_phase() -> void:
	var eater: Unit = CoreKit.put(game, p, "b3_eater", 0)
	CoreKit.put(game, p, "b2_swarm", 1)
	assert_eq(game.act(0, {"type": "sell", "slot": 1}), "")
	assert_eq(eater.stats.perm_attack, 1)
	assert_eq(eater.stats.perm_health, 2)
	assert_eq(
		p.board_units().filter(func(u: Unit) -> bool: return u.def.id == &"tk_sprout").size(), 1
	)


func test_joining_the_fight_is_heard() -> void:
	CoreKit.put(game, p, "b1_greeter", 4)
	CoreKit.put(game, p, "t1_seed", 1)
	CoreKit.put(game, q, "t3_hunter", 0)
	var combat: Combat = _fight()
	var sprouts: Array[Dictionary] = CoreKit.events_of(combat, "summon")
	assert_gt(sprouts.size(), 0, "the seed died and summoned")
	var greeted: Array[Dictionary] = CoreKit.events_of(combat, "buff").filter(
		func(e: Dictionary) -> bool: return e["uid"] == sprouts[0]["uid"]
	)
	assert_eq(greeted.size(), 1, "fight: on_fight_enter")


func test_6_1_5_a_spell_aimed_at_a_slot() -> void:
	p.hand.append(CoreKit.unit(game, "sp_gift"))
	var plays: Array[Dictionary] = game.legal_actions(0).filter(
		func(a: Dictionary) -> bool: return a["type"] == "play"
	)
	assert_eq(plays.size(), game.geometry.slot_count)
	assert_eq(
		game.act(0, {"type": "play", "hand": 0, "slot": -1, "target": 9}), "not a valid target"
	)
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": -1, "target": 5}), "")
	assert_eq(p.slots[5].renown, 2)


func test_9_6_1_plate() -> void:
	CoreKit.put(game, p, "t1_plain", 0).stats.set_attack = 3
	CoreKit.put(game, q, "b2_plated", 0)
	var combat: Combat = _fight()
	var hits: Array[Dictionary] = CoreKit.events_of(combat, "damage").filter(
		func(e: Dictionary) -> bool: return e["side"] == 1
	)
	assert_eq(hits[0]["amount"], 3 - 1, "Plate 1 takes 1 off an attack")


func test_7_3_5_golden_text_reads_doubled_numbers() -> void:
	var normal: Unit = CoreKit.unit(game, "b3_grower")
	var golden: Unit = CoreKit.unit(game, "b3_grower", true)
	assert_eq(normal.view()["text"], "Start of Combat: +1/+1 for each heap entry.")
	assert_eq(golden.view()["text"], "Start of Combat: +2/+2 for each heap entry.")
	var rooter: Unit = CoreKit.unit(game, "b3_rooter", true)
	assert_true(rooter.view()["text"].contains("spend 2 heap"), "a THRESHOLD isn't doubled")


func test_view_for_has_costs_opponent_and_legal_actions() -> void:
	var view: Dictionary = game.view_for(0)
	assert_eq(view["costs"]["refresh"], 1)
	assert_eq(view["costs"]["shop_units"].size(), p.shop_units.size())
	assert_eq(view["opponent"], game.opponent_of(0))
	assert_eq(view["legal_actions"], game.legal_actions(0))


func test_summon_events_carry_the_unit_view() -> void:
	CoreKit.put(game, p, "t1_seed", 0)
	CoreKit.put(game, q, "t2_mentor", 0)
	var combat: Combat = _fight()
	var summons: Array[Dictionary] = CoreKit.events_of(combat, "summon")
	assert_gt(summons.size(), 0)
	for key: String in ["uid", "id", "slot", "label", "attack", "health", "keywords", "text"]:
		assert_true(summons[0].has(key), key)
