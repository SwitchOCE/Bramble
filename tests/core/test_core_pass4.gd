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


# --- A1 Lends ---


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


# --- A2 Edgewright ---


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


# --- A3 Overrun, A4 dying units ---


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
	for slot: int in [4, 5, 6]:
		_put(p, "t1_plain", slot, 0, 1)
	_put(q, "t1_plain", 0, 1, 3)
	_put(q, "t1_plain", 1, 1, 3)
	_put(q, "t1_plain", 4, 1, 30)
	var combat: Combat = _fight()
	assert_eq(CoreKit.events_of(combat, "attack")[0]["side"], 0, "the wider side attacks first")
	var carried: Array[Dictionary] = _of(
		combat, "damage", func(e: Dictionary) -> bool: return e["side"] == 1
	)
	assert_eq(carried[0]["amount"], 10)
	assert_true(carried[0]["from_attack"])
	assert_eq(carried[1]["amount"], 7, "10 less the 3 the target had")
	assert_false(carried[1]["from_attack"], "carried damage is plain damage")
	assert_eq(carried[2]["amount"], 4, "and on again")
	assert_ne(carried[1]["uid"], carried[0]["uid"], "never back to the unit just killed")


## Only the overrunner's own attack carries: its strike back when it is attacked does not, though
## damage_from_attack() is true then too.
func test_overrun_does_not_carry_its_strike_back() -> void:
	_put(p, "t1_plain", 0, 1, 3)
	_put(p, "t1_plain", 1, 0, 3)
	_put(p, "t1_plain", 2, 0, 3)
	_put(q, "b3_overrunner", 0)
	var combat: Combat = _fight()
	var first: Dictionary = CoreKit.events_of(combat, "attack")[0]
	assert_eq(first["side"], 0, "the wider side attacks first")
	var second: int = combat.events.find(CoreKit.events_of(combat, "attack")[1])
	var hurt: Array[int] = []
	for i: int in range(combat.events.find(first), second):
		var event: Dictionary = combat.events[i]
		if event["type"] == "damage" and event["side"] == 0:
			hurt.append(event["uid"])
	assert_eq(hurt, [first["uid"]], "the strike back hit the attacker only: nothing carried")


# --- A5 one return protocol ---


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


# --- B12 to B14 returns ---


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
	assert_eq(back[0]["health"], 1 + 2, "1 Health, then its +2/+2, shown as it stands")
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


# --- B15 Pile on ---


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


# --- B16 The Eighth Plague ---


func test_eighth_plague_deaths_in_one_batch_count_as_each_resolves() -> void:
	_put(p, "b4_plague", 4, 0, 1000)
	_put(p, "t1_plain", 0, 0, 1)
	_put(p, "t1_plain", 1, 0, 1)
	_put(q, "t4_cleaver", 1, 6, 100)
	game.config.attack_limit = 3
	var combat: Combat = _fight()
	var plague: CombatUnit = _at(combat, 0, 4)
	assert_eq(plague.state.get(&"test_counts", []), [1, 2], "cleave killed both at once")


# --- B17 ---


func test_rulings_1_5_the_live_outnumbered_yes_no_is_gone() -> void:
	assert_false(AuraContext.new().has_method("outnumbered"), "outnumbered_by is the rule")


# --- A6, A7 giving a numbered mechanic ---


func test_a6_a_fight_gives_a_numbered_mechanic_to_a_unit_without_one() -> void:
	var plain: Unit = _put(p, "t1_plain", 0)
	plain.golden = true
	var combat: Combat = _still()
	var unit: CombatUnit = _at(combat, 0, 0)
	assert_true(combat.bridge(0).give_effect(unit, &"test_fury", {"amount": 2}, true, null))
	assert_true(unit.has_mechanic(&"test_fury"))
	var given: Dictionary = CoreKit.events_of(combat, "effect")[0]
	assert_eq(given["mechanic"], "test_fury")
	assert_eq(given["params"], {"amount": 2})
	assert_true(given["permanent"])
	var effects: Array = unit.view(game.geometry)["effects"]
	assert_eq(effects, [{"mechanic": "test_fury", "amount": 2}], "not doubled on a golden")
	assert_true(plain.has_mechanic(&"test_fury"), "permanent reaches the recruit unit")
	assert_false(combat.bridge(0).give_effect(unit, &"test_fury", {"wrong": 1}, false, null))


func test_a7_master_at_arms_gives_plus_1_fury_not_doubled_on_a_golden_target() -> void:
	var furious: Unit = game.new_unit(game.library.get_card(&"b3_furious"), true)
	p.place(furious, 0)
	p.gold = 10
	p.hand.append(CoreKit.unit(game, "b2_arms"))
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": 1, "target": furious.uid}), "")
	var given: Array = furious.view()["effects"].filter(
		func(e: Dictionary) -> bool: return e["mechanic"] == "test_fury"
	)
	assert_eq(given.map(func(e: Dictionary) -> int: return e["amount"]), [6, 1], "Fury 6 and +1")
	assert_eq(CoreKit.log_of(game, "effect").size(), 1)
	assert_eq(furious.view()["totals"]["test_fury"], {"amount": 7}, "one number to show: Fury 7")
	assert_eq(furious.view()["text"], "Fury 6.", "the card text stays the printed number")


func test_the_view_sums_printed_given_and_granted_numbers_as_the_mechanic_combines() -> void:
	var plain: Unit = _put(p, "t1_plain", 0)
	_put(p, "b3_thornlender", 1)
	game.recruit.refresh_auras(p)
	assert_true(plain.grant_effect(game.registry, &"test_thorns", {"amount": 2}))
	var thorns: int = plain.view()["totals"]["test_thorns"]["amount"]
	assert_eq(thorns, 2 + 1, "given 2, granted 1")
	assert_true(plain.grant_effect(game.registry, &"test_low_cost", {"cost": 3}))
	assert_true(plain.grant_effect(game.registry, &"test_low_cost", {"cost": 1}))
	assert_eq(plain.view()["totals"]["test_low_cost"], {"cost": 1}, "the lowest, as grants take")
	var combat: Combat = _still()
	var shown: Dictionary = combat.events[0]["boards"][0][0]
	assert_eq(shown["totals"]["test_thorns"]["amount"], 3, "the fight view has it too")
	assert_false(_put(p, "t1_plain", 3).view()["totals"].has("test_thorns"), "none shows none")


func test_rulebook_7_2_3_a_played_unit_may_aim_at_itself() -> void:
	p.gold = 10
	p.hand.append(CoreKit.unit(game, "b2_arms"))
	var arms: Unit = p.hand[0]
	var plays: Array = game.legal_actions(0).filter(
		func(a: Dictionary) -> bool: return a["type"] == "play" and a["target"] == arms.uid
	)
	assert_gt(plays.size(), 0, "on an empty board it can aim at itself")
	assert_eq(game.act(0, plays[0]), "")
	assert_true(arms.has_mechanic(&"test_fury"))


# --- A8 golden summons, A9 heap marks, A10 combining grants ---


func test_a8_a_fight_summon_can_be_golden() -> void:
	_put(p, "t1_plain", 0)
	var combat: Combat = _still()
	var token: CombatUnit = combat.summon(0, &"tk_sprout", 0, false, null, false, {}, true)
	assert_true(token.golden)
	assert_eq([token.attack(), token.health()], [4, 4])
	assert_true(CoreKit.events_of(combat, "summon")[-1]["golden"])


func test_a9_heap_marks_name_entries_and_stay_right_when_the_heap_changes() -> void:
	var heap: CardHeap = p.heap(&"test_heap")
	heap.add(&"t1_plain", 1)
	heap.add(&"t3_viper", 3)
	heap.add(&"t3_twin", 3)
	heap.add(&"t2_shield", 2)
	_put(p, "t1_plain", 0)
	var combat: Combat = _still()
	var side: FightSide = combat.bridge(0)
	var first: Dictionary = side.heap_use_highest(&"test_heap", null)
	assert_eq(first["id"], &"t3_twin", "highest tier, newest first on a tie")
	side.heap_spend(&"test_heap", 1, null)
	side.heap_add(&"test_heap", &"t4_wall", 4, null)
	assert_eq(side.heap_use_highest(&"test_heap", null)["id"], &"t4_wall")
	assert_eq(side.heap_use_highest(&"test_heap", null)["id"], &"t3_viper", "the twin stays used")
	assert_eq(side.heap_use_highest(&"test_heap", null)["id"], &"t2_shield")
	assert_eq(side.heap_use_highest(&"test_heap", null), {}, "nothing left to copy")
	var uses: Array[Dictionary] = CoreKit.events_of(combat, "heap_use")
	assert_eq(uses[0]["ids"], ["t3_twin"], "the event names the entry")
	assert_eq(heap.size(), 4, "entries stay in the heap")


func test_a10_grants_add_up_by_default_and_a_mechanic_may_take_the_lowest() -> void:
	var summed: Array[BoundMechanic] = game.registry.bind_grants(
		[{"mechanic": "test_thorns", "amount": 1}, {"mechanic": "test_thorns", "amount": 1}]
	)
	assert_eq(summed[0].params.num(&"amount"), 2, "Fury and Thorns add up")
	var lowest: Array[BoundMechanic] = game.registry.bind_grants(
		[{"mechanic": "test_low_cost", "cost": 3}, {"mechanic": "test_low_cost", "cost": 1}]
	)
	assert_eq(lowest[0].params.num(&"cost"), 1, "Root 1 + Root 1 costs 1")


# --- A11 untested hooks ---


func test_a11_hand_reserve_puts_every_hand_unit_in_reserve() -> void:
	_put(p, "b4_colonel", 4, 0)
	_put(p, "t1_plain", 0, 0, 1)
	p.hand.append(CoreKit.unit(game, "t1_plain"))
	p.hand.append(CoreKit.unit(game, "t2_shield"))
	_put(q, "t1_plain", 0, 5, 50)
	var combat: Combat = _fight()
	assert_eq(combat.events[0]["reserve"][0].size(), 2, "both hand units, no Reserve of their own")
	var step: Dictionary = CoreKit.events_of(combat, "reserve")[0]
	for key: String in ["uid", "id", "slot", "attack", "health", "keywords", "effects", "text"]:
		assert_true(step.has(key), "D28: the reserve event is a full unit view (%s)" % key)


func test_a11_an_entry_added_in_a_fight_is_heard() -> void:
	var briar: Unit = _put(p, "b3_briar", 4, 0)
	_put(p, "b2_seeder", 0)
	_put(q, "t1_plain", 0, 5, 50)
	game.config.attack_limit = 2
	_fight()
	assert_eq(briar.stats.perm_attack, 1, "the seeder's entry went in during the fight")


# --- 30 to 36 ---


func _orders() -> Array:
	return game.legal_actions(0).filter(func(a: Dictionary) -> bool: return a["type"] == "ability")


func test_item_30_an_ability_unusable_from_where_the_unit_stands_is_not_legal() -> void:
	p.gold = 3
	var corporal: Unit = _put(p, "b2_corporal", 0)
	assert_eq(_orders(), [], "nothing in front of the front row")
	var use: Dictionary = {"type": "ability", "uid": corporal.uid, "mechanic": "test_corporal"}
	assert_ne(game.act(0, use), "")
	var bound: BoundMechanic = corporal.mechanics[0]
	assert_ne(game.recruit.ability_error(p, corporal, bound), "", "so a screen can dim it")
	assert_eq(game.act(0, {"type": "move", "from": 0, "to": 5}), "")
	assert_eq(_orders().size(), 1, "from the back row it is legal")
	assert_eq(game.recruit.ability_error(p, corporal, bound), "")


func test_item_31_golden_text_and_a_golden_number_that_is_not_double() -> void:
	var plain: Unit = CoreKit.unit(game, "b2_herald")
	var gold: Unit = game.new_unit(game.library.get_card(&"b2_herald"), true)
	assert_eq(plain.view()["text"], "Thorns 2.")
	assert_eq(gold.view()["text"], "Thorns 3, golden.", "golden text, golden number 3 not 4")
	assert_eq(gold.mechanics[0].params.num(&"amount"), 3)
	assert_eq(plain.view()["reminders"], ["Only one pays each fight."], "item 36")


func test_item_32_a_turn_counter_is_logged() -> void:
	var unit: Unit = _put(p, "t1_plain", 0)
	RecruitContext.new(game, game.recruit, p).add_turn_counter(unit, &"test_ate", 1, unit)
	assert_eq(unit.turn_counter(&"test_ate"), 1)
	assert_eq(CoreKit.log_of(game, "turn_counter")[0]["value"], 1)


func test_item_33_a_recruit_summon_may_take_its_own_slot_first() -> void:
	_put(p, "t1_plain", 1)
	var ctx := RecruitContext.new(game, game.recruit, p)
	var made: Unit = ctx.summon(&"tk_sprout", 2, true)
	assert_eq(made.slot, 2, "the slot its source left")
	assert_ne(ctx.summon(&"tk_sprout", 2, false).slot, 2, "otherwise the nearest empty one")


# --- D23 to D27 what the fight log tells a screen ---


func test_d23_a_fight_unit_view_shows_its_own_numbered_keywords() -> void:
	_put(p, "t1_plain", 0)
	_put(q, "b3_furious", 0)
	var start: Dictionary = _still().events[0]
	assert_eq(start["boards"][1][0]["effects"], [{"mechanic": "test_fury", "amount": 3}])


func test_d24_damage_a_no_damage_attack_ignored_is_logged_as_prevented() -> void:
	_put(p, "b3_tilter", 0)
	_put(q, "b2_thorny", 0)
	var combat: Combat = _fight()
	var stopped: Array[Dictionary] = CoreKit.events_of(combat, "prevented")
	assert_gt(stopped.size(), 0)
	assert_eq(stopped[0]["reason"], "takes_no_damage")
	var first: Dictionary = CoreKit.events_of(combat, "attack")[0]
	assert_true(first["out_of_turn"])
	assert_true(first["takes_no_damage"])


func test_d27_a_stats_event_says_what_changed_and_after_which_event() -> void:
	_put(p, "b2_edgewright", 4)
	_put(p, "t1_plain", 0)
	p.slots[0].attack = 3
	var combat: Combat = _still()
	var shown: Array[Dictionary] = _of(
		combat, "stats", func(e: Dictionary) -> bool: return e["slot"] == 0 and e["side"] == 0
	)
	assert_eq(shown[-1]["slot_attack"], 6)
	assert_eq(combat.events[shown[-1]["after"]]["type"], "slot_percent", "the cause")
