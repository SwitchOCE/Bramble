extends GutTest
@warning_ignore_start("unsafe_method_access", "unsafe_call_argument")

const Kit := preload("res://tests/core/recruit_kit.gd")


func test_treasurer_has_a_reversible_ceiling_and_copies_share_it() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game(), false, LegacyWave1.with_hedgerow(UnitLibrary.load_dir()))
	var plain: RecruitUnit = kit.put("honorary_treasurer", 0)
	var golden: RecruitUnit = kit.put("honorary_treasurer", 1, true)
	HeldUnits.give_plain_copy(kit.rules, kit.player, "honorary_treasurer")
	assert_eq(kit.rules.play(kit.player, 0, 2), "")
	var copy: RecruitUnit = kit.player.board[2]
	for _item: int in 2:
		kit.rules.give_card(kit.player, "great_hoard")
	kit.rules.board_changed(kit.player)
	assert_eq(plain.attack, 3 + 8)
	assert_eq(golden.attack, 6 + 16)
	assert_eq(copy.attack, 3 + 8)
	assert_true(copy.plain_copy)
	for _item: int in 2:
		kit.rules.give_card(kit.player, "great_hoard")
	kit.rules.board_changed(kit.player)
	assert_eq(golden.attack, 22, "further hoarding adds nothing")
	while not kit.player.items.is_empty():
		assert_eq(kit.rules.play_item(kit.player, 0), "")
	assert_eq(plain.attack, 3, "cashing removes the aura")
	assert_eq(golden.attack, 6)


func test_hoard_still_pays_more_than_its_three_stashes() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	for _item: int in 3:
		kit.rules.give_card(kit.player, "stash")
	assert_eq(kit.item_ids(), ["great_hoard"])
	assert_eq(kit.player.larder(), 16)
	var gold: int = kit.player.gold
	assert_eq(kit.rules.play_item(kit.player, 0), "")
	assert_eq(kit.player.gold, gold + 16)


func test_dozey_keeps_small_acorns_and_limits_large_conversion() -> void:
	for golden: bool in [false, true]:
		var kit := Kit.new()
		kit.setup(GameConfig.full_game(), false, LegacyWave1.with_hedgerow(UnitLibrary.load_dir()))
		var unit: RecruitUnit = kit.put("alderman_dozey", 0, golden)
		var rate: int = 2 if golden else 1
		var base: int = unit.attack
		kit.rules.give_card(kit.player, "acorn")
		kit.rules.play_item(kit.player, 0, 0)
		assert_eq(unit.attack, base + rate)
		kit.rules.give_card(kit.player, "great_hoard")
		kit.rules.play_item(kit.player, 0, 0)
		assert_eq(unit.attack, base + 9 * rate)


func test_mast_cannot_take_both_interest_branches_in_one_turn() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game(), false, LegacyWave1.with_hedgerow(UnitLibrary.load_dir()))
	kit.put("old_mother_mast", 0)
	kit.player.gold = 20
	kit.shop("pill_bug")
	assert_eq(kit.rules.buy(kit.player, 0), "")
	assert_eq(kit.item_ids(), ["acorn"])
	kit.rules.give_card(kit.player, "great_hoard")
	kit.shop("pill_bug")
	assert_eq(kit.rules.buy(kit.player, 0), "")
	assert_eq(kit.item_ids(), ["acorn", "great_hoard"], "first buy already paid")
