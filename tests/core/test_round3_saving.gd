extends GutTest

const Kit := preload("res://tests/core/recruit_kit.gd")


func test_spider_pays_baseline_and_golden_rewards_three_saved() -> void:
	for golden: bool in [false, true]:
		for saved: int in [0, 2, 3, 5, 6, 30]:
			var kit := Kit.new()
			kit.setup(GameConfig.full_game())
			kit.rules.start_phase(kit.player, 1)
			kit.put("money_spider", 0, golden)
			kit.player.gold = saved
			kit.pass_turn()
			var expected: int = 2 if golden and saved >= 3 else 1
			assert_eq(kit.player.gold, saved + 4 + expected)
