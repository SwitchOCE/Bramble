extends GutTest
## Renown and the Reserve limit (pitch-pigeon 1 variant A and 1b; build plan S3): +1/+1 for each
## Renown to the unit that starts a fight in the slot and to reservists who step in there, and to
## nothing else; Renown gained in a fight counts from the next fight; at most 2 reservists from
## the hand a fight, raised by Q_RESERVE_LIMIT; the Guard post first, then the most Renown, then
## reading order. Through the test cards in tests/core/content/test/.

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


func _fight(fight_seed: int = 1, live: Array = [true, true]) -> Combat:
	var combat: Combat = Combat.create(
		game.geometry, game.config, game.registry, game.library, fight_seed
	)
	combat.run([p.board, q.board], [0, 1], [p, q], live, [p.hand, q.hand])
	return combat


## A fight that stops before any attack and is then opened again, so a test can kill units by
## hand and resolve the deaths (Combat._resolve_deaths does nothing once a fight has halted).
func _still() -> Combat:
	game.config.attack_limit = 0
	var combat: Combat = _fight()
	combat._halt_reason = ""
	return combat


func _put(player: PlayerState, card: String, slot: int, attack: int = -1) -> Unit:
	var made: Unit = CoreKit.put(game, player, card, slot)
	if attack >= 0:
		made.stats.set_attack = attack
	return made


func _hand(card: String, count: int = 1, golden: bool = false) -> void:
	for _i: int in count:
		p.hand.append(CoreKit.unit(game, card, golden))


## A wall that kills one unit an attack and never dies.
func _wall() -> Unit:
	var wall: Unit = _put(q, "t1_plain", 0, 100)
	wall.stats.set_health = 10000
	return wall


func _kill(combat: Combat, slots: Array[int]) -> void:
	for slot: int in slots:
		combat.deal_damage(null, combat.unit_at(0, slot), 1000)
	combat._resolve_deaths(0)


func _stats(event: Dictionary) -> Array[int]:
	return [CoreUtil.to_int(event["attack"]), CoreUtil.to_int(event["health"])]


func test_renown_reaches_a_starting_unit_and_a_reservist() -> void:
	p.slots[0].renown = 3
	_put(p, "t1_plain", 0, 0)
	_hand("b2_reservist")
	_wall()
	var combat: Combat = _fight()
	var start: Dictionary = combat.events[0]["boards"][0][0]
	assert_eq(_stats(start), [3, 7] as Array[int], "a 0/4 starter in a Renown 3 slot")
	assert_eq(CoreUtil.to_int(combat.events[0]["slots"][0][0]["renown"]), 3, "the fight's slot")
	var steps: Array[Dictionary] = CoreKit.events_of(combat, "reserve")
	assert_eq(steps.size(), 1)
	assert_eq(steps[0]["slot"], 0)
	assert_eq(_stats(steps[0]), [5, 5] as Array[int], "a 2/2 reservist steps in at 5/5")
	assert_true(steps[0]["from_hand"])


func test_renown_skips_a_summon_and_a_return() -> void:
	p.slots[0].renown = 3
	p.slots[1].renown = 3
	_put(p, "t1_seed", 0)
	_put(p, "t4_phoenix", 1)
	_wall()
	var combat: Combat = _fight()
	var start: Array = combat.events[0]["boards"][0]
	assert_eq(_stats(start[0]), [5, 5] as Array[int], "starters get it")
	assert_eq(_stats(start[1]), [11, 9] as Array[int])
	var sprouts: Array[Dictionary] = CoreKit.events_of(combat, "summon")
	assert_eq(sprouts.size(), 1)
	assert_eq(sprouts[0]["slot"], 0, "the Sprout lands in the seed's own slot")
	assert_eq(_stats(sprouts[0]), [2, 2] as Array[int], "a summon doesn't get Renown")
	var back: Array[Dictionary] = CoreKit.events_of(combat, "return")
	assert_eq(back.size(), 1)
	assert_eq(back[0]["slot"], 1, "Reborn comes back to its own slot")
	assert_eq(CoreUtil.to_int(back[0]["attack"]), 8, "a return doesn't get Renown")


func test_a_unit_moved_into_a_renown_slot_mid_fight_does_not_get_it() -> void:
	p.slots[0].renown = 4
	_put(p, "t1_plain", 0)
	_put(p, "t1_plain", 1)
	_put(q, "t1_plain", 0)
	var combat: Combat = _still()
	var mover: CombatUnit = combat.unit_at(0, 1)
	_kill(combat, [0])
	# No card moves a unit in a fight yet; move it as the board would.
	var row: Array = combat.sides[0]
	row[1] = null
	row[0] = mover
	mover.slot = 0
	combat._units_cache[0] = null
	combat._refresh_auras()
	assert_eq([mover.attack(), mover.health()], [2, 4], "it keeps only its own stats")


func test_renown_gained_in_a_fight_counts_from_the_next_fight() -> void:
	_put(p, "t1_plain", 0, 0)
	_put(p, "b3_padre", 4, 0)
	_hand("b2_reservist")
	_wall()
	var combat: Combat = _fight()
	var gains: Array[Dictionary] = CoreKit.events_of(combat, "renown")
	assert_gt(gains.size(), 0, "the Padre gave a slot Renown")
	assert_eq(gains[0]["slot"], 0)
	assert_eq(gains[0]["next_fight"], 1)
	assert_true(gains[0]["permanent"])
	var steps: Array[Dictionary] = CoreKit.events_of(combat, "reserve")
	assert_eq(_stats(steps[0]), [2, 2] as Array[int], "not in the fight it was earned in")
	assert_eq(combat.bridge(0).slot(0).renown, 0, "the fight's copy doesn't change")
	assert_gt(p.slots[0].renown, 0, "the real slot has it")
	var earned: int = p.slots[0].renown
	game.recruit.refresh_auras(p)
	var next: Combat = _fight(2)
	var start: Dictionary = next.events[0]["boards"][0][0]
	assert_eq(_stats(start), [earned, 4 + earned] as Array[int], "it counts from the next fight")


func test_a_ghost_keeps_no_renown_it_earns() -> void:
	_put(p, "t1_plain", 0, 0)
	_put(p, "b3_padre", 4, 0)
	_wall()
	var combat: Combat = _fight(1, [false, true])
	var gains: Array[Dictionary] = CoreKit.events_of(combat, "renown")
	assert_gt(gains.size(), 0)
	assert_false(gains[0]["permanent"])
	assert_eq(p.slots[0].renown, 0)


func test_the_reserve_limit_is_2_a_fight() -> void:
	for slot: int in 4:
		_put(p, "t1_plain", slot, 0)
	_hand("b2_reservist", 4)
	_wall()
	var combat: Combat = _fight()
	assert_eq(combat.events[0]["reserve"][0].size(), 4, "all four wait in reserve")
	assert_eq(CoreKit.events_of(combat, "reserve").size(), 2, "only 2 step in")
	assert_eq(combat.arrivals.called[0], 2)


func test_a_raised_limit_lets_3_step_in() -> void:
	for slot: int in 4:
		_put(p, "t1_plain", slot, 0)
	_put(p, "b4_quartermaster", 6, 0)
	_hand("b2_reservist", 4)
	_wall()
	var combat: Combat = _fight()
	assert_eq(CoreKit.events_of(combat, "reserve").size(), 3, "the Quartermaster raised it to 3")


func test_fill_order_post_then_most_renown_then_reading_order() -> void:
	game.config.reserve_limit = 4
	for slot: int in 4:
		_put(p, "t1_plain", slot)
	_put(p, "b3_post", 4)
	p.slots[3].renown = 5
	p.slots[2].renown = 2
	p.slots[0].renown = 2
	_hand("b2_reservist", 4)
	_put(q, "t1_plain", 0)
	var combat: Combat = _still()
	_kill(combat, [0, 1, 2, 3])
	var order: Array = CoreKit.events_of(combat, "reserve").map(
		func(e: Dictionary) -> int: return CoreUtil.to_int(e["slot"])
	)
	assert_eq(order, [1, 3, 0, 2], "the post, Renown 5, then the Renown 2 slots in reading order")


func test_from_hand_flag_and_the_colonel_hook_double_only_hand_reservists() -> void:
	p.slots[0].renown = 3
	p.slots[1].renown = 3
	_put(p, "t1_plain", 0)
	_put(p, "t1_plain", 1)
	_put(p, "b6_honours", 4)
	_put(p, "b4_bugle", 5)
	_hand("b2_reservist")
	_put(q, "t1_plain", 0)
	var combat: Combat = _still()
	assert_eq(_stats(combat.events[0]["boards"][0][0]), [5, 7] as Array[int], "a starter: single")
	_kill(combat, [0, 1])
	var steps: Array[Dictionary] = CoreKit.events_of(combat, "reserve")
	assert_eq(steps.size(), 2, "the hand reservist, then the Bugle's Sprout")
	assert_true(steps[0]["from_hand"])
	assert_eq(steps[0]["slot"], 0)
	assert_eq(_stats(steps[0]), [8, 8] as Array[int], "from the hand: double Renown")
	assert_false(steps[1]["from_hand"])
	assert_eq(steps[1]["slot"], 1)
	assert_eq(_stats(steps[1]), [5, 5] as Array[int], "a Private: single Renown")
	var reservist: CombatUnit = combat.unit_at(0, 0)
	var private: CombatUnit = combat.unit_at(0, 1)
	assert_true(reservist.reservist and reservist.from_hand)
	assert_true(private.reservist and not private.from_hand)
	assert_false(private.bought, "a Private is Created")
	_kill(combat, [4])
	assert_eq([reservist.attack(), reservist.health()], [5, 5], "the double ends with its source")


func test_a_golden_colonel_hook_triples() -> void:
	p.slots[0].renown = 2
	_put(p, "t1_plain", 0)
	p.place(CoreKit.unit(game, "b6_honours", true), 4)
	_hand("b2_reservist")
	_put(q, "t1_plain", 0)
	var combat: Combat = _still()
	_kill(combat, [0])
	assert_eq(_stats(CoreKit.events_of(combat, "reserve")[0]), [8, 8] as Array[int])


func test_privates_do_not_count_against_the_limit() -> void:
	game.config.reserve_limit = 1
	_put(p, "t1_plain", 0)
	_put(p, "t1_plain", 1)
	_put(p, "b4_bugle", 5)
	_hand("b2_reservist", 2)
	_put(q, "t1_plain", 0)
	var combat: Combat = _still()
	_kill(combat, [0])
	_kill(combat, [1])
	var steps: Array[Dictionary] = CoreKit.events_of(combat, "reserve")
	assert_eq(steps.size(), 2, "one from the hand, then the Sprout")
	assert_true(steps[0]["from_hand"])
	assert_false(steps[1]["from_hand"])
	assert_eq(combat.arrivals.called[0], 1, "the Sprout wasn't counted")


func test_step_in_needs_an_empty_slot() -> void:
	_put(p, "t1_plain", 0)
	_put(q, "t1_plain", 0)
	var combat: Combat = _still()
	assert_null(combat.step_in(0, &"tk_sprout", 0, null), "slot 0 is taken")
	var private: CombatUnit = combat.step_in(0, &"tk_sprout", 2, null)
	assert_not_null(private)
	assert_eq(private.renown_slot, 2)


func test_the_recruit_board_shows_renown_in_a_units_stats() -> void:
	var unit: Unit = _put(p, "t1_plain", 2)
	var held: Unit = CoreKit.unit(game, "t1_plain")
	p.hand.append(held)
	p.slots[2].renown = 4
	p.slots[0].attack = 1
	game.recruit.refresh_auras(p)
	assert_eq([unit.attack(), unit.health()], [6, 8], "2/4 plus Renown 4")
	assert_eq([unit.stats.own_attack(), unit.stats.own_health()], [2, 4], "not its own stats")
	assert_eq([held.attack(), held.health()], [2, 4], "a hand unit stands in no slot")
	var ctx := RecruitContext.new(game, game.recruit, p)
	ctx.add_renown(2, 1, null)
	assert_eq(p.slots[2].renown, 5)
	assert_eq(unit.attack(), 7, "a Recruit Phase gain shows at once")
	assert_eq(CoreKit.log_of(game, "renown")[-1]["total"], 5)
	p.slots[0].renown = 2
	p.board[2] = null
	p.place(unit, 0)
	game.recruit.refresh_auras(p)
	assert_eq([unit.attack(), unit.health()], [5, 6], "moved: slot 0's buff and Renown")


func test_renown_and_slot_buffs_stack() -> void:
	p.slots[0].renown = 2
	p.slots[0].attack = 3
	p.slots[0].health = 1
	_put(p, "t1_plain", 0)
	_put(q, "t1_plain", 0)
	var combat: Combat = _still()
	assert_eq(_stats(combat.events[0]["boards"][0][0]), [7, 7] as Array[int])
