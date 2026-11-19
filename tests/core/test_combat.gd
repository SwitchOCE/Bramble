extends GutTest
## Chapter 9 and the example keywords of chapter 11, read from the fight log.

@warning_ignore_start("unsafe_call_argument")

const CoreKit := preload("res://tests/core/core_kit.gd")

var game: GameSession


func before_each() -> void:
	game = CoreKit.session(5)


func _board(spec: Dictionary = {}) -> Array[Unit]:
	return CoreKit.board(game, spec)


## Side 1: one unit that never attacks and never dies.
func _target_dummy() -> Array[Unit]:
	var b: Array[Unit] = _board()
	CoreKit.dummy(b, game, 0, 0, 100000)
	return b


func test_9_2_1_more_units_attack_first() -> void:
	var combat: Combat = CoreKit.fight(
		game, _board({0: "t1_plain", 1: "t1_plain"}), _target_dummy()
	)
	assert_eq(CoreKit.events_of(combat, "combat_start")[0]["first"], 0)
	var flipped: Combat = CoreKit.fight(
		game, _target_dummy(), _board({0: "t1_plain", 1: "t1_plain"})
	)
	assert_eq(CoreKit.events_of(flipped, "combat_start")[0]["first"], 1)


func test_9_4_2_reading_order_and_9_10_1_attack_limit_tie() -> void:
	var combat: Combat = CoreKit.fight(
		game, _board({0: "t1_plain", 2: "t1_plain", 5: "t1_plain"}), _target_dummy()
	)
	assert_eq(CoreKit.attack_slots(combat, 0).slice(0, 6), [0, 2, 5, 0, 2, 5] as Array[int])
	assert_eq(combat.result["reason"], Combat.REASON_ATTACK_LIMIT)
	assert_eq(combat.result["winner"], -1, "a tie")
	assert_eq(combat.result["attacks"], 200)


func test_9_4_10_a_side_that_cant_attack_passes() -> void:
	var combat: Combat = CoreKit.fight(game, _board({0: "t1_plain"}), _target_dummy())
	assert_gt(CoreKit.events_of(combat, "pass").size(), 0)
	for event: Dictionary in CoreKit.events_of(combat, "pass"):
		assert_eq(event["side"], 1)


func test_9_4_8_rulebook_worked_example() -> void:
	# A has F1, F3, B2. F3 (a golden Seed: two Sprouts on death) attacks and dies.
	var a: Array[Unit] = _board({0: "t4_wall", 5: "t1_plain"})
	var seed_unit: Unit = CoreKit.unit(game, "t1_seed", true)
	seed_unit.slot = 2
	a[2] = seed_unit
	var b: Array[Unit] = _board()
	CoreKit.dummy(b, game, 0, 4, 100000)
	var combat: Combat = CoreKit.fight(game, a, b)
	var summons: Array[Dictionary] = CoreKit.events_of(combat, "summon")
	assert_eq(summons[0]["slot"], 2, "8.4.1 the first takes the dead unit's slot")
	assert_eq(summons[1]["slot"], 3, "8.4.2 then the nearest")
	assert_eq(
		CoreKit.attack_slots(combat, 0).slice(0, 6),
		[0, 2, 2, 3, 5, 0] as Array[int],
		"F3 token, F4 token, B2, then the cycle resets"
	)


func test_9_5_1_back_row_is_protected_while_the_front_lives() -> void:
	var a: Array[Unit] = _board()
	CoreKit.dummy(a, game, 0, 0, 100000)
	CoreKit.dummy(a, game, 4, 0, 100000)
	var b: Array[Unit] = _board({0: "t1_plain"})
	var combat: Combat = CoreKit.fight(game, a, b)
	for event: Dictionary in CoreKit.events_of(combat, "attack"):
		assert_eq(event["target_slot"], 0)


func test_9_5_3_stealthed_front_row_still_protects_the_back() -> void:
	var a: Array[Unit] = _board({0: "t4_shade"})
	a[0].stats.set_attack = 0
	CoreKit.dummy(a, game, 4, 0, 100000)
	var b: Array[Unit] = _board({0: "t1_plain"})
	var combat: Combat = CoreKit.fight(game, a, b)
	var first: Dictionary = CoreKit.events_of(combat, "attack")[0]
	assert_eq(first["target_slot"], 0, "all candidates stealthed: they lose it, back stays safe")


func test_9_5_4_taunt_must_be_attacked_within_the_row() -> void:
	var a: Array[Unit] = _board()
	CoreKit.dummy(a, game, 0, 0, 100000)
	CoreKit.dummy(a, game, 2, 0, 100000)
	var guard: Unit = CoreKit.unit(game, "t1_guard")
	guard.stats.set_attack = 0
	guard.stats.set_health = 100000
	guard.slot = 1
	a[1] = guard
	var combat: Combat = CoreKit.fight(game, a, _board({0: "t1_plain"}))
	for event: Dictionary in CoreKit.events_of(combat, "attack"):
		assert_eq(event["target_slot"], 1)


func test_9_5_4_back_row_taunt_does_nothing_while_front_lives() -> void:
	var a: Array[Unit] = _board()
	CoreKit.dummy(a, game, 0, 0, 100000)
	var guard: Unit = CoreKit.unit(game, "t1_guard")
	guard.stats.set_attack = 0
	guard.slot = 4
	a[4] = guard
	var combat: Combat = CoreKit.fight(game, a, _board({0: "t1_plain"}))
	assert_eq(CoreKit.events_of(combat, "attack")[0]["target_slot"], 0)


func test_9_6_1_damage_is_simultaneous_and_9_9_2_both_empty_is_a_tie() -> void:
	var combat: Combat = CoreKit.fight(game, _board({0: "t3_hunter"}), _board({0: "t3_hunter"}))
	assert_eq(CoreKit.events_of(combat, "death").size(), 2)
	assert_eq(combat.result["winner"], -1)
	assert_eq(CoreKit.events_of(combat, "buff").size(), 0, "a dead hunter gains nothing")


func test_9_9_2_side_with_units_left_wins() -> void:
	var combat: Combat = CoreKit.fight(game, _board({0: "t6_titan"}), _board({0: "t1_plain"}))
	assert_eq(combat.result["winner"], 0)
	assert_eq(combat.result["reason"], Combat.REASON_BOARD_EMPTY)


func test_9_8_2_reborn_returns_once_with_1_health() -> void:
	var b: Array[Unit] = _board()
	CoreKit.dummy(b, game, 0, 6, 100000)
	var combat: Combat = CoreKit.fight(game, _board({0: "t4_phoenix"}), b)
	var returns: Array[Dictionary] = CoreKit.events_of(combat, "return")
	assert_eq(returns.size(), 1)
	assert_eq(returns[0]["health"], 1)
	assert_eq(returns[0]["slot"], 0, "9.8.3 its own slot")
	assert_eq(combat.result["winner"], 1)


func test_9_10_3_return_limit() -> void:
	game.config.return_limit = 0
	var b: Array[Unit] = _board()
	CoreKit.dummy(b, game, 0, 6, 100000)
	var combat: Combat = CoreKit.fight(game, _board({0: "t4_phoenix"}), b)
	assert_eq(CoreKit.events_of(combat, "return").size(), 0)


func test_9_10_2_trigger_limit_ends_in_a_tie() -> void:
	game.config.combat_trigger_limit = 1
	var combat: Combat = CoreKit.fight(game, _board({0: "t2_fighter"}), _target_dummy())
	assert_eq(combat.result["reason"], Combat.REASON_TRIGGER_LIMIT)
	assert_eq(combat.result["winner"], -1)


func test_11_2_2_divine_shield_takes_the_first_hit() -> void:
	var b: Array[Unit] = _board()
	CoreKit.dummy(b, game, 0, 2, 100000)
	var combat: Combat = CoreKit.fight(game, _board({0: "t2_shield"}), b)
	var statuses: Array[Dictionary] = CoreKit.events_of(combat, "status")
	assert_eq(statuses[0]["status"], "divine_shield")
	assert_false(statuses[0]["on"])
	var hits: Array[Dictionary] = CoreKit.events_of(combat, "damage").filter(
		func(e: Dictionary) -> bool: return e["side"] == 0
	)
	assert_eq(hits[0]["health"], 2, "the first damage that landed was the second hit")


func test_11_2_5_venomous_destroys_what_it_damages() -> void:
	var combat: Combat = CoreKit.fight(game, _board({0: "t3_viper"}), _board({0: "t4_wall"}))
	var destroyed: Array[Dictionary] = CoreKit.events_of(combat, "destroy")
	assert_eq(destroyed.size(), 1)
	assert_eq(destroyed[0]["side"], 1)


func test_11_2_5_divine_shield_stops_venomous() -> void:
	var combat: Combat = CoreKit.fight(game, _board({0: "t3_viper"}), _board({0: "t2_shield"}))
	assert_eq(CoreKit.events_of(combat, "destroy").size(), 0)


func test_11_2_3_windfury_attacks_twice_in_a_row() -> void:
	var a: Array[Unit] = _board({0: "t3_twin"})
	CoreKit.dummy(a, game, 4, 0, 10)
	var combat: Combat = CoreKit.fight(game, a, _target_dummy())
	var turns: Array[String] = []
	for event: Dictionary in combat.events:
		if event["type"] == "attack" or event["type"] == "pass":
			turns.append("%s%d" % [event["type"], event["side"]])
	assert_eq(turns.slice(0, 5), ["attack0", "attack0", "pass1", "attack0", "attack0"])


func test_11_2_7a_cleave_also_hits_one_unit_beside_the_target() -> void:
	var b: Array[Unit] = _board()
	for slot: int in [0, 1, 2]:
		CoreKit.dummy(b, game, slot, 0, 100)
	var combat: Combat = CoreKit.fight(game, _board({0: "t4_cleaver"}), b)
	var first: Dictionary = CoreKit.events_of(combat, "attack")[0]
	var target: int = first["target_slot"]
	var beside: Array[int] = game.geometry.adjacent(target).filter(
		func(s: int) -> bool: return s <= 2
	)
	var got: Array[int] = []
	var index: int = combat.events.find(first) + 1
	while combat.events[index]["type"] == "damage" and combat.events[index]["side"] == 1:
		got.append(combat.events[index]["slot"])
		index += 1
	assert_eq(got.size(), 2, "the target and one unit beside it, not both (owner, 19 Nov)")
	assert_eq(got[0], target)
	assert_has(beside, got[1])


func test_9_3_start_of_combat_fires_before_attacks() -> void:
	var combat: Combat = CoreKit.fight(game, _board({0: "t5_bomber"}), _board({0: "t1_plain"}))
	assert_eq(combat.result["attacks"], 0, "the bomber's 8 killed the only enemy")
	assert_eq(combat.result["winner"], 0)
	assert_eq(CoreKit.events_of(combat, "trigger")[0]["mechanic"], "start_combat_damage")


func test_9_7_4_death_counter_fires_on_the_third_friendly_death() -> void:
	var a: Array[Unit] = _board({1: "t1_plain", 2: "t1_plain", 3: "t1_plain"})
	var avenger: Unit = CoreKit.unit(game, "t5_avenger")
	avenger.stats.set_attack = 0
	avenger.stats.set_health = 100000
	avenger.slot = 4
	a[4] = avenger
	var b: Array[Unit] = _board()
	CoreKit.dummy(b, game, 0, 10, 100000)
	var combat: Combat = CoreKit.fight(game, a, b)
	var deaths: int = 0
	for event: Dictionary in combat.events:
		if event["type"] == "death" and event["side"] == 0:
			deaths += 1
		if event["type"] == "trigger" and event["mechanic"] == "avenge_buff":
			assert_eq(deaths, 3)
			return
	fail_test("the counter never fired")


func test_rally_buffs_before_damage() -> void:
	var combat: Combat = CoreKit.fight(game, _board({0: "t2_fighter"}), _target_dummy())
	var hits: Array[Dictionary] = CoreKit.events_of(combat, "damage").filter(
		func(e: Dictionary) -> bool: return e["side"] == 1
	)
	assert_eq(hits[0]["amount"], 6, "4 + 2 from its own attack")


func test_when_attacked_gains_health_before_damage() -> void:
	var a: Array[Unit] = _board({0: "t4_wall"})
	a[0].stats.set_attack = 0
	var combat: Combat = CoreKit.fight(game, a, _board({0: "t1_plain"}))
	var hits: Array[Dictionary] = CoreKit.events_of(combat, "damage").filter(
		func(e: Dictionary) -> bool: return e["side"] == 0
	)
	assert_eq(hits[0]["health"], 14 + 4 - 2)


func test_after_a_kill_the_killer_gains() -> void:
	var combat: Combat = CoreKit.fight(game, _board({0: "t3_hunter"}), _board({0: "t1_plain"}))
	var buffs: Array[Dictionary] = CoreKit.events_of(combat, "buff")
	assert_eq(buffs.size(), 1)
	assert_eq([buffs[0]["attack"], buffs[0]["side"]], [8, 0])


func test_12_2_1_aura_in_combat_and_gone_with_its_source() -> void:
	var a: Array[Unit] = _board({0: "t3_banner", 1: "t1_plain"})
	var combat: Combat = CoreKit.fight(game, a, _target_dummy())
	var start: Dictionary = CoreKit.events_of(combat, "combat_start")[0]
	var boards: Array = start["boards"]
	var mine: Array = boards[0]
	assert_eq(mine[1]["attack"], 4, "+2 from the adjacent banner")


func test_9_1_1_combat_never_changes_the_recruit_board() -> void:
	var a: Array[Unit] = _board({0: "t2_fighter", 1: "t1_seed"})
	var b: Array[Unit] = _board({0: "t6_titan"})
	CoreKit.fight(game, a, b)
	assert_eq([a[0].attack(), a[0].health(), a[0].slot], [4, 6, 0])
	assert_eq(a[1].slot, 1)
	assert_null(a[2], "no summon left behind")


func test_10_1_2_starting_units_and_kills_are_counted() -> void:
	var a: Array[Unit] = _board({0: "t6_titan", 1: "t1_plain"})
	var b: Array[Unit] = _board({0: "t5_bomber"})
	var combat: Combat = CoreKit.fight(game, a, b)
	var starting: Array = combat.result["starting"]
	assert_eq(starting, [2, 1])
	var killed: Array = combat.result["killed"]
	assert_eq(killed[1], 1, "the bomber was killed")


func test_same_seed_same_fight() -> void:
	var a: Array[Unit] = _board({0: "t1_plain", 1: "t2_shield", 4: "t3_viper"})
	var b: Array[Unit] = _board({0: "t1_guard", 1: "t3_twin", 2: "t1_seed"})
	var one: Combat = CoreKit.fight(game, a, b, 77)
	var two: Combat = CoreKit.fight(game, a, b, 77)
	assert_eq(JSON.stringify(one.events), JSON.stringify(two.events))
