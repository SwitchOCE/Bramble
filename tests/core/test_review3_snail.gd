extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")


func test_bought_snail_grows_its_real_sale_price_and_reports_each_gain_only() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)
	kit.player.shop.clear()
	kit.player.gold = 10
	var seen := SoakCoverage.new()
	kit.player.log_observer = func(type: String, fields: Dictionary) -> void:
		seen.note_recruit("", type, fields)
	var snail: RecruitUnit = kit.shop("pennywort_snail")
	assert_eq(kit.rules.buy(kit.player, 0), "")
	assert_eq(kit.rules.play(kit.player, 0, 0), "")
	assert_eq(seen.purchase_counts()["pennywort_snail"], 1)
	for turn: int in range(1, 6):
		kit.pass_turn()
		assert_eq(kit.rules.sell_value(snail, kit.player), 1 + mini(turn, 3))
		assert_eq(snail.health, 3 + mini(turn, 3), "Health stops with the savings")
	assert_eq(seen.card_counts()["pennywort_snail"], 3, "one event per real increase, none at cap")
	assert_eq(seen.snail_gains(), 3)
	var before: int = kit.player.gold
	assert_eq(kit.rules.sell(kit.player, 0), "")
	assert_eq(kit.player.gold, before + 4, "actual sale pays the savings")


func test_snail_does_not_accrue_savings_in_hand() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)
	var snail: RecruitUnit = kit.put("pennywort_snail")
	kit.pass_turn()
	assert_eq(kit.rules.sell_value(snail), 0, "Created, with no board wait")
	assert_false(snail.counters.has("savings"))
