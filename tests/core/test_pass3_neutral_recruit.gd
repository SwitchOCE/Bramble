extends GutTest

const ORIGINAL_B := preload("res://tests/core/pass3_original_b.gd")
## Fixed boards: neutral recruit growth, When played repetitions and per-landing Bird payoffs.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")
const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(ORIGINAL_B.apply(GameConfig.full_game()))
	kit.player.round_number = 3
	kit.player.gold = 100


func test_burner_normal_and_golden_round_once_on_own_body_excluding_other_layers() -> void:
	for golden: bool in [false, true]:
		before_each()
		kit.put("charcoal_burner", 1, golden)
		var target: RecruitUnit = kit.put("field_vole", 4)
		target.add_permanent(17 - target.attack, 23 - target.health)
		var permanent: Vector2i = Vector2i(target.perm_attack, target.perm_health)
		target.tribe_attack = 100
		target.tribe_health = 100
		target.set_aura(200, 200)
		target.add_combat(300, 300)
		kit.player.gold = 30
		kit.rules.events.fire(kit.player, "end_of_turn")
		var gain: Vector2i = Vector2i(10, 13) if golden else Vector2i(5, 6)
		assert_eq(Vector2i(target.perm_attack, target.perm_health), permanent + gain)
		assert_eq(kit.player.gold, 18 if golden else 24)


func test_burner_leaves_five_gold_and_only_buffs_directly_behind() -> void:
	kit.put("charcoal_burner", 0)
	var target: RecruitUnit = kit.put("field_vole", 4)
	target.add_permanent(18, 17)
	var outside: RecruitUnit = kit.put("field_vole", 5)
	kit.player.gold = 7
	kit.rules.events.fire(kit.player, "end_of_turn")
	assert_eq(kit.player.gold, 5)
	assert_eq(target.perm_attack, 20)
	assert_eq(target.perm_health, 19)
	assert_eq(Vector2i(outside.perm_attack, outside.perm_health), Vector2i.ZERO)


func test_click_normal_and_golden_repeat_when_played_and_copies_use_strongest() -> void:
	for golden: bool in [false, true]:
		before_each()
		kit.put("click_beetle", 6, golden)
		kit.put("click_beetle", 5)
		var bird: RecruitUnit = kit.put("one_swallow")
		kit.player.gold = 0
		assert_eq(kit.rules.play(kit.player, kit.player.hand.find(bird), 0), "")
		assert_eq(kit.player.gold, 3 if golden else 2)


func test_click_each_landing_and_returned_play_repeat_without_repeating_home_growth() -> void:
	for golden: bool in [false, true]:
		before_each()
		kit.config.set_value("birds_homecoming_multiplier", 2.0)
		kit.put("click_beetle", 6, golden)
		var bird: RecruitUnit = kit.put("chiffchaff")
		kit.player.hand.erase(bird)
		kit.player.away.append({"unit": bird, "left": 1, "due": 3, "nest": 0, "missed_fight": true})
		HeldUnits.land_due(kit.rules, kit.player)
		assert_eq(Vector2i(bird.attack, bird.health), Vector2i(8, 10) if golden else Vector2i(6, 8))
		assert_eq(kit.rules.play(kit.player, kit.player.hand.find(bird), 0), "")
		assert_eq(
			Vector2i(bird.attack, bird.health), Vector2i(11, 13) if golden else Vector2i(8, 10)
		)
		kit.player.round_number += 1
		assert_eq(kit.rules.sell(kit.player, 0), "")
		kit.player.round_number += 3
		HeldUnits.land_due(kit.rules, kit.player)
		assert_eq(
			Vector2i(bird.attack, bird.health), Vector2i(28, 32) if golden else Vector2i(20, 24)
		)


func test_without_click_bird_homecoming_keeps_existing_behavior() -> void:
	for nested: bool in [false, true]:
		before_each()
		kit.config.set_value("birds_homecoming_multiplier", 2.0)
		var bird: RecruitUnit = _away_bird("chiffchaff")
		if nested:
			var tern: RecruitUnit = kit.put("old_tern")
			kit.rules.events.fire(kit.player, "on_home", {"subject": tern})
		else:
			HeldUnits.land_due(kit.rules, kit.player)
		assert_eq(Vector2i(bird.attack, bird.health), Vector2i(2, 4))
		assert_eq(kit.player.homecomings_this_turn, 1)


func test_click_extra_triggers_do_not_repeat_multiplication_or_advance_every_counter() -> void:
	kit.put("click_beetle", 6, true)
	kit.card(
		"onplay_double",
		[KIT.effect("on_play", {"effect": "multiply", "factor": 2, "target": {"select": "self"}})],
		[],
		3,
		5
	)
	var body: RecruitUnit = kit.put("onplay_double")
	assert_eq(kit.rules.play(kit.player, kit.player.hand.find(body), 0), "")
	assert_eq(Vector2i(body.attack, body.health), Vector2i(6, 10))
	kit.card(
		"onplay_every",
		[KIT.effect("on_play", {"effect": "gold", "amount": 7}, {"name": "every_play", "every": 2})]
	)
	var counter: RecruitUnit = kit.put("onplay_every")
	kit.player.gold = 0
	assert_eq(kit.rules.play(kit.player, kit.player.hand.find(counter), 1), "")
	assert_eq(kit.player.gold, 0, "extra triggers never tick an every countdown")


func test_click_nested_old_tern_recall_finishes_when_played_before_homecoming_growth() -> void:
	kit.config.set_value("birds_homecoming_multiplier", 2.0)
	kit.put("click_beetle", 6)
	var tern: RecruitUnit = kit.put("old_tern")
	var bird: RecruitUnit = kit.put("chiffchaff")
	kit.player.hand.erase(bird)
	kit.player.away.append({"unit": bird, "left": 1, "due": 20, "nest": 0, "missed_fight": true})
	kit.rules.events.fire(kit.player, "on_home", {"subject": tern})
	assert_true(kit.player.hand.has(bird), "Old Tern recalled the Bird during an event drain")
	assert_eq(
		Vector2i(bird.attack, bird.health),
		Vector2i(6, 8),
		"two When played gains must land before one homecoming doubling"
	)


func test_click_three_returning_copies_all_finish_before_their_triple() -> void:
	for nested: bool in [false, true]:
		before_each()
		kit.config.set_value("birds_homecoming_multiplier", 2.0)
		kit.put("click_beetle", 6)
		for _index: int in 3:
			_away_bird("chiffchaff")
		if nested:
			var tern: RecruitUnit = kit.put("old_tern")
			kit.rules.events.fire(kit.player, "on_home", {"subject": tern})
			kit.player.hand.erase(tern)
		else:
			HeldUnits.land_due(kit.rules, kit.player)
		assert_eq(kit.player.hand.size(), 1)
		var golden: RecruitUnit = kit.player.hand[0]
		assert_true(golden.golden)
		assert_eq(Vector2i(golden.attack, golden.health), Vector2i(17, 22))
		assert_eq(kit.player.homecomings_this_turn, 3)


func test_click_replay_recall_keeps_nested_copy_out_of_triples_until_finished() -> void:
	kit.config.set_value("birds_homecoming_multiplier", 2.0)
	kit.put("click_beetle", 6)
	kit.put("chiffchaff", 0)
	kit.put("chiffchaff", 1)
	kit.card(
		"recall_bird",
		[
			{"id": "pass3_bird", "ability": "test_recall"},
			KIT.effect("on_play", {"effect": "bring_home", "count": 1}),
			KIT.effect(
				"on_play",
				{"effect": "buff", "attack": 1, "health": 1, "target": {"select": "self"}}
			)
		],
		["Birds"],
		1,
		2
	)
	var caller: RecruitUnit = _away_bird("recall_bird")
	_away_bird("chiffchaff", 20)
	HeldUnits.land_due(kit.rules, kit.player)
	assert_eq(Vector2i(caller.attack, caller.health), Vector2i(6, 8))
	assert_eq(kit.player.homecomings_this_turn, 2)
	assert_eq(kit.player.hand.size(), 2)
	for unit: RecruitUnit in kit.player.hand:
		if unit.def_id() == "chiffchaff":
			assert_true(unit.golden)
			assert_eq(Vector2i(unit.attack, unit.health), Vector2i(7, 10))


func test_click_recall_preserves_queued_work_and_duplicate_recalls_finish_once() -> void:
	kit.config.set_value("birds_homecoming_multiplier", 2.0)
	kit.put("click_beetle", 6, true)
	var tern: RecruitUnit = kit.put("old_tern")
	var bird: RecruitUnit = _away_bird("chiffchaff", 20)
	var seen: Array[Vector2i] = []
	kit.rules.events.continue_with(
		func() -> void:
			kit.rules.events.fire(kit.player, "on_home", {"subject": tern})
			kit.rules.events.fire(kit.player, "on_home", {"subject": tern})
			kit.rules.events.continue_with(
				func() -> void: seen.append(Vector2i(bird.attack, bird.health))
			)
	)
	assert_eq(seen, [Vector2i(1, 2)], "work already queued runs before the recalled Bird")
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(8, 10))
	assert_eq(kit.player.hand.count(bird), 1)
	assert_eq(kit.player.homecomings_this_turn, 1)


func test_click_landing_completes_even_when_trigger_budget_drops_replay() -> void:
	kit.config.set_value("trigger_limit_action", 0)
	kit.config.set_value("birds_homecoming_multiplier", 2.0)
	kit.put("click_beetle", 6)
	var bird: RecruitUnit = _away_bird("chiffchaff")
	HeldUnits.land_due(kit.rules, kit.player)
	assert_true(kit.player.hand.has(bird), "budget exhaustion cannot strand a returning Bird")
	assert_true(kit.player.away.is_empty())
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(2, 4))
	assert_eq(kit.player.homecomings_this_turn, 1)


func test_click_landing_replay_uses_shared_multiplier_and_countdown_guards() -> void:
	kit.config.set_value("birds_homecoming_multiplier", 2.0)
	kit.put("click_beetle", 6, true)
	kit.card(
		"guard_bird",
		[
			{"id": "pass3_bird", "ability": "test_guards"},
			KIT.effect("on_play", {"effect": "multiply", "factor": 2}),
			KIT.effect("on_play", {"effect": "gold", "amount": 7}, {"every": 2, "counter": "clock"})
		],
		["Birds"],
		3,
		5
	)
	var bird: RecruitUnit = _away_bird("guard_bird")
	kit.player.gold = 0
	HeldUnits.land_due(kit.rules, kit.player)
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(12, 20))
	assert_eq(bird.counters.get("clock"), 1)
	assert_eq(kit.player.gold, 0)
	assert_eq(kit.player.homecomings_this_turn, 1)


func _away_bird(id: String, due: int = 3) -> RecruitUnit:
	var bird: RecruitUnit = kit.put(id)
	kit.player.hand.erase(bird)
	kit.player.away.append({"unit": bird, "left": 1, "due": due, "nest": 0, "missed_fight": true})
	return bird
