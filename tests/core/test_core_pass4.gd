extends GutTest
## The core's fourth pass (from the scope review of pass 3): what the five tribes' designs need
## that the core could not express, and where it differed from SHARED-RULES. Each test is named
## for its rule or ruling; the cards are in tests/core/content/test/.

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


## A fight that stops before any attack (Start of fight still runs), so a test can use the fight
## API on standing units.
func _still() -> Combat:
	game.config.attack_limit = 0
	return _fight()


func _put(player: PlayerState, card: String, slot: int, attack: int = -1, health: int = -1) -> Unit:
	var made: Unit = CoreKit.put(game, player, card, slot)
	if attack >= 0:
		made.stats.set_attack = attack
	if health >= 0:
		made.stats.set_health = health
	return made


func _at(combat: Combat, side: int, slot: int) -> CombatUnit:
	return combat.unit_at(side, slot)


func _of(combat: Combat, kind: String, test: Callable) -> Array[Dictionary]:
	return CoreKit.events_of(combat, kind).filter(test)


# --- A1 Lends -------------------------------------------------------------------------------------


func test_lends_an_aura_reads_its_sources_own_total_with_permanent_and_slot_buffs() -> void:
	var lender: Unit = _put(p, "b2_lender", 4)
	lender.stats.perm_attack = 5
	p.slots[4].attack = 2
	var front: Unit = _put(p, "t1_plain", 0)
	game.recruit.refresh_auras(p)
	assert_eq(lender.attack(), 3 + 5 + 2)
	assert_eq(front.attack(), 2 + 10, "lends what it shows: printed 3, +5 permanent, +2 slot")
	assert_eq(front.health(), 4 + 3, "and its Health")
	var combat: Combat = _still()
	assert_eq(_at(combat, 0, 0).attack(), 12, "the same in a fight")


func test_lends_lost_lent_health_never_takes_a_unit_below_1() -> void:
	_put(p, "b2_lender", 4)
	_put(p, "t1_plain", 0)
	var combat: Combat = _still()
	var front: CombatUnit = _at(combat, 0, 0)
	combat.deal_damage(null, front, 6)
	assert_eq(front.health(), 1, "4 + 3 lent, 6 damage")
	combat.destroy(null, _at(combat, 0, 4))
	combat._resolve_deaths(0)
	assert_eq(front.health(), 1, "the lender left; lent Health goes but not below 1")
	assert_false(front.gone)


# --- A2 Edgewright --------------------------------------------------------------------------------


func test_ruling_13_the_slot_doubling_stays_after_the_edgewright_dies_and_is_one_sided() -> void:
	_put(p, "b2_edgewright", 4)
	_put(p, "t1_plain", 0)
	p.slots[0].attack = 3
	_put(q, "t1_plain", 0)
	q.slots[0].attack = 3
	var combat: Combat = _still()
	assert_eq(_at(combat, 0, 0).attack(), 2 + 6, "doubled on the Edgewright's side")
	assert_eq(_at(combat, 1, 0).attack(), 2 + 3, "not on the other")
	assert_eq(_of(combat, "slot_percent", func(_e: Dictionary) -> bool: return true).size(), 1)
	combat.destroy(null, _at(combat, 0, 4))
	combat._resolve_deaths(0)
	assert_eq(_at(combat, 0, 0).attack(), 8, "it keeps working once the Edgewright is dead")
	assert_eq(_at(combat, 1, 0).attack(), 5)
	assert_eq(combat.bridge(0).slot_attack_given(0), 6, "what reads a slot reads it doubled")
	var view: Dictionary = combat.bridge(0).slot_view(0)
	assert_eq([view["attack"], view["given_attack"], view["percent"]], [3, 6, 200])


func test_ruling_13_a_standing_side_query_is_asked_with_its_side_set() -> void:
	_put(p, "b5_edge", 4)
	_put(p, "t1_plain", 0)
	p.slots[0].attack = 1
	_put(q, "t1_plain", 0)
	q.slots[0].attack = 1
	var combat: Combat = _still()
	assert_eq(_at(combat, 0, 0).attack(), 4, "the side with the doubler")
	assert_eq(_at(combat, 1, 0).attack(), 3, "the other side never doubles")


# --- A3 Overrun, A4 dying units ---------------------------------------------------------------


func test_9_5_choose_target_never_returns_a_dying_unit_even_with_guard() -> void:
	_put(p, "t1_plain", 0)
	_put(q, "t1_guard", 0)
	_put(q, "t1_plain", 1)
	var combat: Combat = _still()
	var guard: CombatUnit = _at(combat, 1, 0)
	combat.deal_damage(null, guard, 99)
	for i: int in 3:
		assert_ne(combat.choose_target(_at(combat, 0, 0)), guard, "try %d" % i)
	assert_false(combat.units(1).has(guard), "units() leaves the dying out")
	assert_ne(combat.random_enemy(_at(combat, 0, 0)), guard)
	assert_ne(combat.weakest_enemy(_at(combat, 0, 0)), guard)


func test_overrun_carries_an_attacks_extra_damage_and_tells_it_from_a_hit() -> void:
	_put(p, "b3_overrunner", 0)
	_put(q, "t1_plain", 0, 1, 3)
	_put(q, "t1_plain", 1, 1, 3)
	_put(q, "t1_plain", 4, 1, 30)
	var combat: Combat = _fight()
	var carried: Array[Dictionary] = _of(
		combat, "damage", func(e: Dictionary) -> bool: return e["side"] == 1
	)
	assert_eq(carried[0]["amount"], 10)
	assert_true(carried[0]["from_attack"])
	assert_eq(carried[1]["amount"], 7, "10 less the 3 the target had")
	assert_false(carried[1]["from_attack"], "carried damage is plain damage")
	assert_eq(carried[2]["amount"], 4, "and on again")
	assert_ne(carried[1]["uid"], carried[0]["uid"], "never back to the unit just killed")


# --- A5 one return protocol ---------------------------------------------------------------------


func test_ruling_17_root_first_when_the_heap_can_pay() -> void:
	p.heap(&"test_heap").add(&"t1_plain", 1)
	_put(p, "b3_both", 0)
	_put(q, "t3_hunter", 0, 2, 100)
	var combat: Combat = _fight()
	var back: Array[Dictionary] = CoreKit.events_of(combat, "return")
	assert_eq(back[0]["mechanic"], "test_root", "Root fired")
	assert_eq(p.heap(&"test_heap").size(), 0, "and paid")
	var molts: int = (
		back.filter(func(e: Dictionary) -> bool: return e["mechanic"] == "test_molt").size()
	)
	assert_eq(p.board[0].stats.perm_attack, 2 * molts, "Molt paid only for its own return")
	assert_lt(molts, back.size())


func test_ruling_17_molt_when_the_heap_cannot_pay() -> void:
	var both: Unit = _put(p, "b3_both", 0)
	_put(q, "t3_hunter", 0, 2, 100)
	var combat: Combat = _fight()
	var back: Array[Dictionary] = CoreKit.events_of(combat, "return")
	assert_eq(back[0]["mechanic"], "test_molt")
	assert_eq(both.stats.perm_attack, 2, "Molt's +2/+2 reached the recruit unit")
	assert_eq(_of(combat, "status", func(_e: Dictionary) -> bool: return true).size(), 0)


# --- B12 to B14 returns ---------------------------------------------------------------------------


func test_ruling_22_a_return_is_one_return_event_not_a_summon_and_not_joining() -> void:
	_put(p, "b3_molter", 0)
	_put(p, "b1_greeter", 1, 0)
	_put(q, "t3_hunter", 0, 2, 100)
	var combat: Combat = _fight()
	var back: Array[Dictionary] = CoreKit.events_of(combat, "return")
	assert_eq(back.size(), 1)
	var uid: int = back[0]["uid"]
	assert_eq(_of(combat, "summon", func(e: Dictionary) -> bool: return e["uid"] == uid), [])
	var greets: Array[Dictionary] = _of(
		combat, "trigger", func(e: Dictionary) -> bool: return e["mechanic"] == "test_greet"
	)
	assert_eq(greets.size(), 0, "on_fight_enter does not hear a return")
	var at: int = combat.events.find(back[0])
	for i: int in at:
		assert_ne(combat.events[i].get("uid", -1), uid, "nothing names it before its return")
	assert_eq(back[0]["health"], 1)
	assert_eq(back[0]["slot"], 0, "its own slot")


func test_rulebook_9_8_2_a_plain_copy_keeps_no_counters() -> void:
	var molter: Unit = _put(p, "b3_molter", 0)
	molter.counters[&"test_medal"] = 3
	_put(q, "t3_hunter", 0, 2, 100)
	var combat: Combat = _fight()
	assert_eq(combat.events[0]["boards"][0][0]["counters"], {"test_medal": 3})
	var back: Dictionary = CoreKit.events_of(combat, "return")[0]
	assert_eq(back["counters"], {}, "a plain copy has no Medals")
	assert_eq(molter.counter(&"test_medal"), 3, "the recruit unit keeps them")


func test_rulebook_9_8_2_root_returns_as_the_recruit_unit_with_its_counters() -> void:
	var oak: Unit = _put(p, "b3_oak", 0)
	oak.counters[&"test_medal"] = 2
	_put(q, "t3_hunter", 0, 4, 100)
	var combat: Combat = _fight()
	var back: Dictionary = CoreKit.events_of(combat, "return")[0]
	assert_eq(back["counters"], {"test_medal": 2})


func test_ruling_21_per_fight_limits_carry_across_a_return() -> void:
	_put(p, "b3_molter", 0)
	_put(q, "t3_hunter", 0, 2, 100)
	var combat: Combat = _fight()
	var back: Array[Dictionary] = CoreKit.events_of(combat, "return")
	assert_eq(back.size(), 1, "the returned copy has used the fight's one charge")
	var uses: Array[Dictionary] = CoreKit.events_of(combat, "uses")
	assert_eq(uses[0]["left"], 0, "and the screen is told none is left")
	assert_eq(uses[0]["uid"], back[0]["uid"])


# --- B15 Pile on ----------------------------------------------------------------------------------


func test_pile_on_hits_land_together_so_a_second_piler_still_lands() -> void:
	_put(p, "t1_plain", 0, 1, 50)
	_put(p, "b1_piler", 1)
	_put(p, "b1_piler", 4)
	_put(q, "t1_plain", 0, 0, 2)
	var combat: Combat = _fight()
	var hits: Array[Dictionary] = CoreKit.events_of(combat, "hit")
	assert_eq(hits.size(), 2, "both pilers hit, though the first was enough")
	assert_eq(_of(combat, "damage", func(e: Dictionary) -> bool: return e["side"] == 1).size(), 2)
	assert_eq(
		_of(combat, "damage", func(e: Dictionary) -> bool: return e["side"] == 0).size(),
		0,
		"the target died before the exchange"
	)


func test_pile_on_neighbour_includes_the_slot_behind() -> void:
	_put(p, "t1_plain", 0, 1, 50)
	_put(p, "b1_piler", 4)
	_put(q, "t1_plain", 0, 0, 50)
	game.config.attack_limit = 1
	var combat: Combat = _fight()
	assert_eq(CoreKit.events_of(combat, "hit").size(), 1, "B1 is behind F1: a neighbour")


# --- B16 The Eighth Plague ----------------------------------------------------------------------


func test_eighth_plague_deaths_in_one_batch_count_as_each_resolves() -> void:
	_put(p, "b4_plague", 4, 0, 1000)
	_put(p, "t1_plain", 0, 0, 1)
	_put(p, "t1_plain", 1, 0, 1)
	_put(q, "t4_cleaver", 1, 6, 100)
	game.config.attack_limit = 3
	var combat: Combat = _fight()
	var plague: CombatUnit = _at(combat, 0, 4)
	assert_eq(plague.state.get(&"test_counts", []), [1, 2], "cleave killed both at once")


# --- B17 ------------------------------------------------------------------------------------------


func test_rulings_1_5_the_live_outnumbered_yes_no_is_gone() -> void:
	assert_false(AuraContext.new().has_method("outnumbered"), "outnumbered_by is the rule")
