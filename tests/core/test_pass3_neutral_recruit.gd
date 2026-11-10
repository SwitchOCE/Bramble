extends GutTest
## Fixed boards: neutral recruit growth, When played repetitions and per-landing Bird payoffs.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")
const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())
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


func test_click_each_homecoming_replays_before_single_growth_and_playing_returned_hand_repeats_again(
) -> void:
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
	kit.config.set_value("birds_homecoming_multiplier", 2.0)
	var bird: RecruitUnit = kit.put("chiffchaff")
	kit.player.hand.erase(bird)
	kit.player.away.append({"unit": bird, "left": 1, "due": 3, "nest": 0, "missed_fight": true})
	HeldUnits.land_due(kit.rules, kit.player)
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(2, 4))


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
