extends GutTest
## Fixed recruit states exercise the actual Hard factory without creating lobbies.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.player.round_number = 12
	kit.player.tier = 6


func _brain() -> BotBrain:
	var brain: BotBrain = BenchSuites.create_bot("hard@blind") as BotBrain
	assert_false(brain is LineBrain)
	brain._player = kit.player
	brain._rules = kit.rules
	brain._round_now = kit.player.round_number
	brain.value.library = kit.library
	brain.value.recruit_rules = kit.rules
	brain.value.board_owner = kit.player
	return brain


func _body(id: String, slot: int, attack: int, health: int, pinned: bool = false) -> RecruitUnit:
	kit.card(id, [], [], attack, health)
	var unit: RecruitUnit = kit.put(id, slot)
	if pinned:
		unit.timers.append({"turns": 3, "left": 2, "attack": 1, "health": 1})
	return unit


func test_normal_and_golden_shieldbug_cover_two_pinned_back_bodies_from_a_middle_front_slot(
) -> void:
	for golden: bool in [false, true]:
		for backs: Array in [[4, 5], [5, 6]]:
			before_each()
			_body("neutral_shield_left", backs[0], 20, 40, true)
			_body("neutral_shield_right", backs[1], 30, 60, true)
			var bug: RecruitUnit = kit.put("shieldbug", 0, golden)
			var brain: BotBrain = _brain()
			var before: float = brain.value.keep_value(bug)
			brain._arrange()
			var expected: int = 1 if backs[0] == 4 else 2
			assert_same(kit.player.board[expected], bug, "F2/F3 covers both actual recipients")
			assert_eq(
				BotNeutral.text_value(bug, kit.player),
				50.0,
				"golden changes body, not Shield count"
			)
			assert_gt(brain.value.keep_value(bug), before)
			assert_eq(kit.player.board[backs[0]].def_id(), "neutral_shield_left")
			assert_eq(kit.player.board[backs[1]].def_id(), "neutral_shield_right")


func test_normal_and_golden_spider_lend_reach_to_the_two_existing_back_attackers() -> void:
	for golden: bool in [false, true]:
		before_each()
		_body("neutral_swoop_left", 4, 20, 40, true)
		_body("neutral_swoop_right", 5, 30, 60, true)
		var spider: RecruitUnit = kit.put("ballooning_spider", 0, golden)
		var brain: BotBrain = _brain()
		var before: float = brain.value.keep_value(spider)
		brain._arrange()
		assert_same(kit.player.board[1], spider)
		assert_gt(brain.value.keep_value(spider), before)
		kit.player.scout = {
			"specs": [{"attack": 20, "health": 20}, null, null, null, null, null, null]
		}
		assert_eq(BotNeutral.text_value(spider, kit.player), 0.0, "there is no back row to reach")
		kit.player.scout["specs"][6] = {"attack": 100, "health": 200}
		assert_gt(
			BotNeutral.text_value(spider, kit.player),
			0.0,
			"a scouted back carry restores reach value"
		)


func test_click_values_two_real_when_played_opportunities_and_its_golden_extra_repeat() -> void:
	kit.card(
		"neutral_click_stats", [KIT.effect("on_play", {"effect": "buff", "attack": 3, "health": 2})]
	)
	kit.card("neutral_click_gold", [KIT.effect("on_play", {"effect": "gold", "amount": 1})])
	var brain: BotBrain = _brain()
	var normal: RecruitUnit = RecruitUnit.make(
		kit.library.get_unit("click_beetle"), kit.rules.new_iid()
	)
	var golden: RecruitUnit = RecruitUnit.make(
		kit.library.get_unit("click_beetle"), kit.rules.new_iid(), true
	)
	var before: float = brain.value.buy_value(normal, kit.player)
	kit.put("neutral_click_stats")
	kit.put("neutral_click_gold")
	assert_eq(BotNeutral.text_value(normal, kit.player), 7.5)
	assert_eq(BotNeutral.text_value(golden, kit.player), 15.0)
	assert_eq(brain.value.buy_value(normal, kit.player), before + 7.5)
	kit.player.board[0] = normal
	assert_false(brain._can_replace(normal), "the live extra-play engine survives a replacement")
	kit.player.board[1] = golden
	assert_true(brain._can_replace(normal), "a stronger Click replaces the redundant normal")
	assert_false(brain._can_replace(golden))
	kit.player.hand.clear()
	assert_true(brain._can_replace(golden), "no upcoming play means no permanent engine lock")


func test_click_values_a_bird_homecoming_without_counting_an_extra_homecoming_multiply() -> void:
	var brain: BotBrain = _brain()
	var click: RecruitUnit = kit.put("click_beetle", 0)
	var before: float = brain.value.keep_value(click)
	var bird: RecruitUnit = RecruitUnit.make(
		kit.library.get_unit("chiffchaff"), kit.rules.new_iid()
	)
	kit.player.away.append({"unit": bird, "left": 1, "due": 13, "nest": 4})
	assert_gt(brain.value.keep_value(click), before)
	assert_false(brain._can_replace(click))
	assert_eq(BotNeutral.text_value(click, kit.player), 8.0, "landing adds both on-play firings")
	click.golden = true
	assert_eq(
		BotNeutral.text_value(click, kit.player),
		12.0,
		"three landing firings precede one homecoming doubling"
	)


func test_golden_bird_hand_plays_scale_their_effect_once_and_click_adds_only_extra_firings(
) -> void:
	for card_id: String in ["chiffchaff", "one_swallow"]:
		before_each()
		var brain: BotBrain = _brain()
		var click: RecruitUnit = kit.put("click_beetle", 0)
		var before: float = brain.value.keep_value(click)
		var bird: RecruitUnit = kit.put(card_id, -1, true)
		var once: float = 4.0 if card_id == "chiffchaff" else 5.0
		assert_eq(BotNeutral._on_play(bird, false, kit.player), once)
		assert_eq(BotNeutral.text_value(click, kit.player), once)
		assert_eq(brain.value.keep_value(click), before + once)
		click.golden = true
		assert_eq(BotNeutral.text_value(click, kit.player), once * 2.0)
		assert_eq(
			BotNeutral.text_value(bird, kit.player), -1.0, "Bird's own valuation is unchanged"
		)
		assert_eq(kit.rules.play(kit.player, 0, 1), "")
		if card_id == "chiffchaff":
			assert_eq(Vector2i(bird.perm_attack, bird.perm_health), Vector2i(6, 6))
		else:
			assert_eq(kit.player.gold, 6, "three golden Swallow firings grant two gold each")


func test_away_click_payoff_uses_due_round_and_all_landing_firings() -> void:
	var brain: BotBrain = _brain()
	var bird: RecruitUnit = RecruitUnit.make(
		kit.library.get_unit("chiffchaff"), kit.rules.new_iid(), true
	)
	kit.player.away.append({"unit": bird, "left": 7, "due": 14, "nest": 4})
	assert_eq(Pass3Neutrals.homecoming_play_gain(kit.player, bird), Vector2i.ZERO)
	var click: RecruitUnit = kit.put("click_beetle", 0)
	assert_eq(
		BotNeutral.text_value(click, kit.player), 8.0, "two firings, doubled, due in two rounds"
	)
	assert_false(brain._can_replace(click))
	kit.player.away[0]["left"] = 11
	assert_eq(
		BotNeutral.text_value(click, kit.player), 8.0, "departure round is not remaining time"
	)
	kit.player.away[0]["due"] = 13
	assert_eq(BotNeutral.text_value(click, kit.player), 16.0)
	var golden: RecruitUnit = RecruitUnit.make(
		kit.library.get_unit("click_beetle"), kit.rules.new_iid(), true
	)
	kit.player.board[0] = null
	assert_eq(
		BotNeutral.text_value(golden, kit.player), 24.0, "three firings versus no landing play"
	)
	kit.player.board[0] = click
	assert_eq(
		BotNeutral.text_value(golden, kit.player), 8.0, "upgrading two landing firings to three"
	)


func test_click_values_native_nan_rings_and_keeps_the_only_live_engine() -> void:
	for golden_nan: bool in [false, true]:
		before_each()
		var brain: BotBrain = _brain()
		kit.player.ring_size = 1.5
		assert_eq(CoreUtil.to_int(kit.player.pass3_rates["fairies_nan_rings"]), 2)
		var click: RecruitUnit = kit.put("click_beetle", 0)
		assert_true(brain._can_replace(click), "no Nan means no extra-play payoff")
		var nan: RecruitUnit = kit.put("nan_toadstool", -1, golden_nan)
		var once: float = 12.0 if golden_nan else 6.0
		assert_eq(BotNeutral._on_play(nan, false, kit.player), once)
		assert_eq(BotNeutral.text_value(click, kit.player), once)
		assert_false(brain._can_replace(click), "Nan alone supplies a real Ring payoff")
		click.golden = true
		assert_eq(BotNeutral.text_value(click, kit.player), once * 2.0)
		assert_false(brain._can_replace(click))
		assert_eq(BotNeutral.text_value(nan, kit.player), -1.0)
		assert_eq(kit.rules.play(kit.player, 0, 1), "")
		var stats: int = 18 if golden_nan else 9
		assert_eq(BoardUpkeep.ring_value(kit.player.slot_effects[1]), Vector2i(stats, stats))
		assert_true(brain._can_replace(click), "no future Nan removes the engine protection")


func test_native_burner_forecast_matches_real_normal_and_golden_own_body_growth() -> void:
	for golden: bool in [false, true]:
		before_each()
		var left: RecruitUnit = _body("neutral_burn_left", 4, 20, 40)
		var right: RecruitUnit = _body("neutral_burn_right", 5, 10, 30)
		var burner: RecruitUnit = kit.put("charcoal_burner", 1, golden)
		kit.player.gold = 17 if golden else 11
		left.set_aura(100, 100)
		left.tribe_attack = 200
		left.tribe_health = 200
		var expected: float = 60.0 if golden else 30.0
		var before: int = (
			left.perm_attack + left.perm_health + right.perm_attack + right.perm_health
		)
		var board: Array[RecruitUnit] = kit.player.board.duplicate()
		assert_eq(
			BotBurner.forecast(kit.player, kit.player.gold),
			expected,
			"aura and tribe stats are excluded"
		)
		assert_eq(kit.player.board, board, "forecast never mutates the board")
		var brain: BotBrain = _brain()
		assert_false(brain._can_replace(burner), "funded growth keeps the actual engine")
		kit.rules.end_phase(kit.player)
		var after: int = left.perm_attack + left.perm_health + right.perm_attack + right.perm_health
		assert_eq(float(after - before), expected)
		assert_eq(kit.player.gold, 5)
		assert_true(brain._can_replace(burner), "an unfunded Burner is replaceable")


func test_legacy_burner_still_forecasts_its_old_flat_text() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game(), false, LegacyWave1.current_with_neutrals())
	_body("legacy_neutral_burn_left", 4, 20, 40)
	_body("legacy_neutral_burn_right", 5, 10, 30)
	var burner: RecruitUnit = kit.put("charcoal_burner", 1)
	kit.player.gold = 11
	assert_true(BotNeutral.params(burner).is_empty())
	assert_eq(BotBurner.forecast(kit.player, 11), 12.0, "legacy retains +3/+3 for each recipient")
	assert_eq(BotBurner.forecast(kit.player, 5), 0.0)


func test_whirligig_values_moved_back_carry_health_and_conservatively_skips_rings() -> void:
	var brain: BotBrain = _brain()
	kit.player.scout = {
		"specs":
		[
			{"attack": 10, "health": 100},
			null,
			null,
			{"attack": 9000, "health": 9999},
			{"attack": 100, "health": 200},
			null,
			null
		],
		"slots": [[], [], [], [], [], [], []]
	}
	for golden: bool in [false, true]:
		var unit: RecruitUnit = RecruitUnit.make(
			kit.library.get_unit("whirligig_beetle"), kit.rules.new_iid(), golden
		)
		assert_eq(
			BotNeutral.text_value(unit, kit.player), 60.0 if golden else 30.0, "F4 does not move"
		)
		var before: float = brain.value.buy_value(unit, kit.player)
		kit.player.scout["slots"][4] = [
			{"name": BoardUpkeep.RING, "attack": 3, "health": 3, "count": 1}
		]
		assert_eq(BotNeutral.text_value(unit, kit.player), 0.0)
		assert_lt(
			brain.value.buy_value(unit, kit.player),
			before,
			"the conservative Ring guard prices no loss for the skipped pair"
		)
		kit.player.scout["slots"][4] = []
