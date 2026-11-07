extends GutTest
@warning_ignore_start("unsafe_method_access", "unsafe_call_argument")

const Kit := preload("res://tests/core/recruit_kit.gd")


func test_current_tier_is_a_majority_in_tier_3_and_4_shops() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	for tier: int in [3, 4]:
		kit.player.tier = tier
		var current: int = 0
		var total: int = 0
		var empty: int = 0
		for _roll: int in 500:
			kit.player.gold = 10000
			assert_eq(kit.rules.refresh(kit.player), "")
			var found: bool = false
			for unit: RecruitUnit in kit.player.shop:
				total += 1
				current += 1 if unit.tier() == tier else 0
				found = found or unit.tier() == tier
			empty += 0 if found else 1
		assert_between(float(current) / total, 0.44, 0.56)
		assert_lt(empty, 60, "fewer than 12% shops miss the bought tier")


func test_hiring_fair_advances_its_offers_and_costs_six() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	assert_eq(kit.library.get_card("hiring_fair")["cost"], 6)
	var offers: Dictionary = {}
	var designs: Dictionary = {}
	for _cast: int in 8:
		kit.rules.discover(kit.player, {"tier": 6, "count": 3})
		var options: PackedStringArray = kit.player.pending[0]["options"]
		assert_eq(options.size(), 3)
		for id: String in options:
			assert_eq(kit.rules.pool.tier_of(id), 6)
			designs[id] = true
		options.sort()
		offers[",".join(options)] = true
		assert_eq(kit.rules.choose(kit.player, 0), "")
	assert_gt(offers.size(), 1, "not a fixed trio")
	assert_gte(designs.size(), 5, "draws from the full tier-6 set")
