extends GutTest
## Pass 3's gaps for the tribe designs (SHARED-RULES): Reserve and the slot-fill order, Start of
## Combat passes, aura grants with parameters, slot multipliers, outnumbered at fight start, and
## the smaller context methods. Each through a test card in tests/core/content/test/.

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
	combat.run([p.board, q.board], [0, 1], [p, q], [true, true], [p.hand, q.hand])
	return combat


## A fight that stops before any attack, so a test can call the fight API on standing units.
func _still() -> Combat:
	game.config.attack_limit = 0
	return _fight()


func _put(player: PlayerState, card: String, slot: int, attack: int = -1) -> Unit:
	var made: Unit = CoreKit.put(game, player, card, slot)
	if attack >= 0:
		made.stats.set_attack = attack
	return made


func _index(combat: Combat, test: Callable) -> int:
	for i: int in combat.events.size():
		if test.call(combat.events[i]):
			return i
	return -1


func _ctx() -> RecruitContext:
	return RecruitContext.new(game, game.recruit, p)


func test_reserve_steps_into_emptied_slots_post_first_then_the_round_hook() -> void:
	_put(p, "t1_plain", 0, 0)
	_put(p, "t1_plain", 1, 0)
	_put(p, "b3_post", 4, 0)
	_put(p, "b4_sergeant", 5, 0)
	p.hand.append(CoreKit.unit(game, "b2_reservist"))
	p.hand.append(CoreKit.unit(game, "b2_reservist"))
	_put(q, "t4_cleaver", 0)
	var combat: Combat = _fight()
	assert_eq(combat.events[0]["reserve"][0].size(), 2, "both hand units wait in reserve")
	var steps: Array[Dictionary] = CoreKit.events_of(combat, "reserve")
	assert_eq(steps.size(), 2)
	assert_eq(steps[0]["slot"], 1, "the fill-first slot (a Guard post) first")
	assert_eq(steps[1]["slot"], 0)
	var reserve_at: int = _index(combat, func(e: Dictionary) -> bool: return e["type"] == "reserve")
	var private_at: int = _index(
		combat, func(e: Dictionary) -> bool: return e["type"] == "summon" and e["id"] == "tk_sprout"
	)
	assert_gt(private_at, reserve_at, "after_death_round comes after Reserve")


func test_the_ghost_keeps_its_hand_for_reserve() -> void:
	p.hand.append(CoreKit.unit(game, "b2_reservist"))
	p.health = 0
	game.finish_round()
	assert_eq(game.ghost_of, 0)
	assert_eq(game.ghost_hand.size(), 1)


func test_ghost_reserve_root_keeps_recruit_stats_counters_and_grants() -> void:
	_put(p, "t1_plain", 0)
	var oak: Unit = CoreKit.unit(game, "b3_oak")
	oak.stats.perm_attack = 5
	oak.stats.perm_health = 4
	oak.counters[&"test_medal"] = 2
	assert_true(oak.grant(game.registry, &"test_reserve"))
	p.hand.append(oak)
	p.health = 0
	game.finish_round()
	assert_eq(game.ghost_of, p.id)
	assert_true(p.hand.is_empty(), "the eliminated player's hand was retired")
	assert_eq(game.ghost_hand, [oak] as Array[Unit], "the saved ghost hand is the source")
	var enemy: Unit = _put(q, "t1_plain", 0, 100)
	enemy.stats.set_health = 100
	for repeat: int in 2:
		var combat: Combat = Combat.create(
			game.geometry, game.config, game.registry, game.library, repeat + 1
		)
		combat.run(
			[q.board, game.ghost_board],
			[q.id, Matchmaking.GHOST],
			[q, game.ghost_player],
			[true, false],
			[q.hand, game.ghost_hand]
		)
		var steps: Array[Dictionary] = CoreKit.events_of(combat, "reserve")
		assert_eq(steps.size(), 1, "the saved hand unit entered the ghost fight")
		var returns: Array[Dictionary] = CoreKit.events_of(combat, "return")
		assert_eq(returns.size(), 1, "Root returned it once")
		if returns.size() != 1:
			continue
		var back: Dictionary = returns[0]
		assert_eq(back["attack"], 8, "Root kept its earlier permanent Attack")
		assert_eq(back["health"], 7, "Root kept its earlier permanent Health")
		assert_eq(back["counters"], {"test_medal": 2}, "Root kept its counters")
		assert_true(back["keywords"].has("test_reserve"), "Root kept its granted keyword")
		assert_eq(oak.counters, {&"test_medal": 2}, "the ghost never writes back")
		assert_eq([oak.attack(), oak.health()], [8, 7], "the saved unit stays unchanged")
		assert_true(p.hand.is_empty(), "ghost combat does not restore the retired hand")


func test_9_3_the_set_up_pass_runs_before_the_main_pass() -> void:
	_put(p, "t5_bomber", 0)
	_put(p, "b2_setup", 3)
	_put(q, "t1_plain", 0)
	var combat: Combat = _fight()
	var setup_at: int = _index(
		combat,
		func(e: Dictionary) -> bool:
			return e["type"] == "trigger" and e["mechanic"] == "test_setup_summoner"
	)
	var main_at: int = _index(
		combat,
		func(e: Dictionary) -> bool:
			return e["type"] == "trigger" and e["mechanic"] == "start_combat_damage"
	)
	assert_gt(setup_at, -1)
	assert_gt(main_at, setup_at, "set-up before main, whatever the reading order")
	var sprouts: Array[Dictionary] = CoreKit.events_of(combat, "summon")
	assert_false(sprouts[0]["bought"], "a token is Created")
	assert_true(combat.events[0]["boards"][0][0]["bought"], "a shop unit is Bought")


func test_aura_grants_carry_parameters_and_add_up() -> void:
	_put(p, "b3_thornlender", 1)
	_put(p, "t1_plain", 2)
	_put(p, "b3_thornlender", 3)
	_put(q, "t1_plain", 0)
	var view: Dictionary = _still().events[0]["boards"][0][1]
	assert_eq(view["slot"], 2)
	assert_eq(view["grants"], [{"mechanic": "test_thorns", "amount": 2}])


func test_aura_context_reads_unit_counters() -> void:
	var view := AuraContext.new()
	view.unit_counters = [{&"test_medal": 3}, {}]
	assert_eq(view.unit_counter(0, &"test_medal"), 3)
	assert_eq(view.unit_counter(1, &"test_medal"), 0)
	assert_eq(view.unit_counter(9, &"test_medal"), 0)


func test_slot_multipliers_bigger_applies_and_fight_time_stacks_once() -> void:
	_put(p, "b5_drillmaster", 4)
	_put(p, "b5_drillmaster", 5)
	_ctx().slot_buff(0, 1, 0, null)
	assert_eq(p.slots[0].attack, 2, "two give-time doublers double once")
	_put(p, "t1_plain", 0)
	_put(p, "b5_edge", 1)
	_put(q, "t1_plain", 0)
	var combat: Combat = _still()
	assert_eq(combat.events[0]["boards"][0][0]["attack"], 2 + 2 * 2, "the fight doubles it again")
	combat.bridge(0).slot_set(2, 5, 5, false, null)
	assert_eq(combat.bridge(0).slot(2).attack, 5, "a set is not a buff given: not doubled")


func test_clearing_a_slot_keyword_and_losing_slot_health_never_kills() -> void:
	p.slots[3].keywords.append(&"taunt")
	_ctx().slot_clear_keyword(3, &"taunt", null)
	assert_eq(p.slots[3].keywords.size(), 0)
	assert_eq(CoreKit.log_of(game, "slot")[-1]["total"]["keywords"], [])
	p.slots[0].health = 5
	_put(p, "t1_plain", 0)
	_put(q, "t1_plain", 0)
	var combat: Combat = _still()
	var unit: CombatUnit = combat.unit_at(0, 0)
	combat.deal_damage(null, unit, 7)
	assert_eq(unit.health(), 2)
	combat.bridge(0).slot_set(0, 0, 0, false, null)
	assert_eq(unit.health(), 1, "the lost slot Health leaves it on 1")


func test_hits_take_a_percent_and_heap_entries_can_be_used_for_one_fight() -> void:
	_put(p, "t1_plain", 0)
	_put(q, "t1_plain", 0, 0).stats.set_health = 50
	p.heap(&"test_heap").add(&"t1_plain", 1)
	p.heap(&"test_heap").add(&"t1_plain", 1)
	var combat: Combat = _still()
	combat.hit(combat.unit_at(0, 0), combat.unit_at(1, 0), 200)
	assert_eq(CoreKit.events_of(combat, "damage")[-1]["amount"], 4)
	var side: FightSide = combat.bridge(0)
	assert_true(side.heap_use(&"test_heap", 2, null))
	assert_eq(side.heap_unused(&"test_heap"), 0)
	assert_eq(p.heap(&"test_heap").size(), 2, "using is not spending")
	assert_false(side.heap_use(&"test_heap", 1, null))


func test_a_summon_during_an_attack_piles_on_in_that_attack() -> void:
	_put(p, "b3_captain", 0, 0)
	_put(p, "b2_crier", 1)
	for slot: int in [3, 4, 5, 6]:
		_put(p, "t1_plain", slot, 0)
	_put(q, "t1_plain", 0, 0).stats.set_health = 50
	var combat: Combat = _fight()
	var first_hit: int = _index(combat, func(e: Dictionary) -> bool: return e["type"] == "hit")
	var second_attack: int = -1
	var attacks: int = 0
	for i: int in combat.events.size():
		if combat.events[i]["type"] == "attack":
			attacks += 1
			if attacks == 2:
				second_attack = i
				break
	assert_gt(first_hit, -1, "the summoned Piler hit")
	assert_true(second_attack == -1 or first_hit < second_attack, "in the first attack")


func test_a_permanent_gain_earned_while_dying_is_kept() -> void:
	var ace: Unit = _put(p, "b3_ace", 0)
	var wall: Unit = _put(q, "t1_plain", 0, 2)
	wall.stats.set_health = 3
	var combat: Combat = _fight()
	assert_eq(CoreKit.events_of(combat, "death").size(), 2, "both die in one exchange")
	assert_eq(ace.stats.perm_attack, 1, "Flying Ace keeps its Medal")


func test_outnumbered_is_fixed_at_fight_start_without_back_row_squires() -> void:
	_put(p, "t1_plain", 0)
	_put(q, "t1_plain", 0)
	_put(q, "t1_plain", 1)
	_put(q, "b2_squire", 4)
	_put(q, "t1_plain", 5)
	var combat: Combat = _fight()
	assert_eq(combat.events[0]["outnumbered_by"], [2, 0])
	assert_eq(combat.result["outnumbered_by"], [2, 0])
	assert_eq(combat.outnumbered_by(0), 2, "the same at the end, whatever died")


func test_an_attack_that_takes_no_damage_takes_none_from_thorns() -> void:
	_put(p, "b3_tilter", 0)
	_put(q, "b2_thorny", 0)
	var combat: Combat = _fight()
	var tilter: int = combat.events[0]["boards"][0][0]["uid"]
	var attacks: Array[Dictionary] = CoreKit.events_of(combat, "attack")
	assert_eq(attacks[0]["uid"], tilter, "it attacks at Start of Combat")
	var second: int = combat.events.find(attacks[1]) if attacks.size() > 1 else 9999
	for i: int in mini(second, combat.events.size()):
		var event: Dictionary = combat.events[i]
		if event["type"] == "damage":
			assert_ne(event["uid"], tilter, "no damage while its attack resolves")


func test_root_returns_as_the_recruit_unit_stands_with_real_stats() -> void:
	var oak: Unit = _put(p, "b3_oak", 0)
	oak.stats.perm_attack = 5
	_put(q, "t3_hunter", 0)
	var combat: Combat = _fight()
	var back: Array[Dictionary] = CoreKit.events_of(combat, "return")
	assert_eq(back.size(), 1)
	assert_eq(back[0]["attack"], 8, "its +5 came back with it")
	assert_eq(back[0]["health"], 3, "at full Health")


func test_give_card_sell_slot_death_effects_twice_and_death_effect_query() -> void:
	var given: Unit = _ctx().give_card(&"t1_plain", null)
	assert_true(p.hand.has(given))
	assert_eq(given.pool_copies, 0, "a Created card")
	_put(p, "t1_plain", 2)
	assert_eq(game.act(0, {"type": "sell", "slot": 2}), "")
	assert_eq(CoreKit.log_of(game, "sell")[-1]["slot"], 2)
	_put(p, "b4_dirge", 0)
	var swarm: Unit = _put(p, "b2_swarm", 1)
	_ctx().run_death_effects(swarm)
	var spawns: Array[Dictionary] = CoreKit.log_of(game, "trigger").filter(
		func(e: Dictionary) -> bool: return e["mechanic"] == "test_swarm_spawn"
	)
	assert_eq(spawns.size(), 2, "the Dirge doubles it in the Recruit Phase too")
	assert_true(swarm.has_death_effect())
	assert_false(CoreKit.unit(game, "t1_plain").has_death_effect())
