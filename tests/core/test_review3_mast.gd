extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")


func test_buying_mast_does_not_pay_but_playing_it_then_buying_does() -> void:
	for hoard: bool in [false, true]:
		var kit := Kit.new()
		kit.setup(GameConfig.full_game(), false, LegacyWave1.with_hedgerow(UnitLibrary.load_dir()))
		kit.player.gold = 30
		if hoard:
			kit.rules.give_card(kit.player, "great_hoard")
		var mast: RecruitUnit = kit.shop("old_mother_mast")
		assert_eq(kit.rules.buy(kit.player, 0), "")
		assert_false(kit.item_ids().has("acorn"), "Mast in hand cannot hear its own purchase")
		assert_false(mast.limits.has("interest"), "buying it does not spend its board payment")
		assert_eq(kit.rules.play(kit.player, 0, 0), "")
		kit.shop("field_vole")
		assert_eq(kit.rules.buy(kit.player, 0), "")
		var expected: int = 2 if hoard else 1
		assert_eq(kit.item_ids().count("acorn"), expected)
		kit.shop("field_vole")
		assert_eq(kit.rules.buy(kit.player, 0), "")
		assert_eq(kit.item_ids().count("acorn"), expected, "still once per turn")


func test_an_existing_mast_can_pay_when_another_mast_is_bought() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game(), false, LegacyWave1.with_hedgerow(UnitLibrary.load_dir()))
	kit.put("old_mother_mast", 0)
	kit.player.gold = 10
	var bought: RecruitUnit = kit.shop("old_mother_mast")
	assert_eq(kit.rules.buy(kit.player, 0), "")
	assert_eq(kit.item_ids(), ["acorn"], "only the existing board Mast pays")
	assert_false(bought.limits.has("interest"))
