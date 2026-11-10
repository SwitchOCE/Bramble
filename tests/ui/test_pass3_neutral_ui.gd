extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")


func test_away_forecast_matches_click_landing_without_changing_current_stats() -> void:
	var cases: Array = [
		[1, 0, false, Vector2i(2, 4)],
		[1, 2, false, Vector2i(6, 8)],
		[1, 3, false, Vector2i(8, 10)],
		[1, 2, true, Vector2i(12, 16)],
		[4, 2, false, Vector2i(18, 20)],
		[4, 3, true, Vector2i(52, 56)],
	]
	for row: Array in cases:
		var kit := KIT.new()
		var config: GameConfig = GameConfig.full_game()
		config.set_value("birds_chiffchaff_gain", row[0])
		config.set_value("birds_homecoming_multiplier", 2.0)
		config.set_value("birds_golden_homecoming_multiplier", 2.0)
		kit.setup(config)
		kit.player.round_number = 3
		if row[1] > 0:
			kit.put("click_beetle", 6, row[1] == 3)
			kit.put("click_beetle", 5)
		var bird: RecruitUnit = kit.put("chiffchaff", -1, row[2])
		kit.player.hand.erase(bird)
		kit.player.away.append({"unit": bird, "left": 1, "due": 3, "nest": 0, "missed_fight": true})
		var before: Dictionary = bird.view().duplicate(true)
		var log_size: int = kit.player.recruit_log.size()
		var forecast: Dictionary = HeldUnits.away_views(kit.player)[0]
		var expected: Vector2i = row[3]
		assert_eq(Vector2i(forecast["home_attack"], forecast["home_health"]), expected)
		assert_eq(bird.view(), before, "forecast leaves the current Bird unchanged")
		assert_eq(kit.player.recruit_log.size(), log_size, "forecast never resolves events")
		HeldUnits.land_due(kit.rules, kit.player)
		assert_eq(Vector2i(bird.attack, bird.health), expected, "forecast agrees with real landing")
