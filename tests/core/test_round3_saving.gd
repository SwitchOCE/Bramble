extends GutTest

const Kit := preload("res://tests/core/recruit_kit.gd")


func test_spider_pays_on_one_purchase_of_savings_and_stays_capped() -> void:
	for golden: bool in [false, true]:
		for saved: int in [2, 3, 5, 6, 30]:
			var kit := Kit.new()
			kit.setup(GameConfig.full_game())
			kit.rules.start_phase(kit.player, 1)
			kit.put("money_spider", 0, golden)
			kit.player.gold = saved
			kit.pass_turn()
			var rate: int = 2 if golden else 1
			var expected: int = mini(2, floori(float(saved) / 3.0)) * rate
			assert_eq(kit.player.gold, saved + 4 + expected)
