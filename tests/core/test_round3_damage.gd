extends GutTest
@warning_ignore_start("unsafe_call_argument")


# These remain regression tests for the selectable legacy mode, not the ideation default.
func _legacy() -> GameConfig:
	var config := GameConfig.full_game()
	config.set_value("damage_mode", "legacy")
	return config


func _fight(config: GameConfig, tier: int, cards: Array) -> Dictionary:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var empty: Array = [null, null, null, null, null, null, null]
	return Combat.create(library, config, rng).run([cards, empty], [tier, tier], [0, 1], 12)


func test_early_loss_costs_four_even_against_one_small_survivor() -> void:
	var row: Array = [{"def_id": "pill_bug", "golden": false}, null, null, null, null, null, null]
	assert_eq(_fight(_legacy(), 1, row)["damage"], 4)
	assert_eq(_fight(GameConfig.defaults(), 1, row)["damage"], 2, "bare rules unchanged")


func test_full_late_board_is_halved_then_capped() -> void:
	var row: Array = []
	for _slot: int in 7:
		row.append({"def_id": "old_mother_mast", "golden": false})
	var result: Dictionary = _fight(_legacy(), 6, row)
	assert_eq(result["damage_uncapped"], 27, "6 + ceil(42 / 2)")
	assert_eq(result["damage"], 12, "cap still protects the final duel")


func test_ties_still_deal_zero() -> void:
	var empty: Array = [null, null, null, null, null, null, null]
	assert_eq(_fight(_legacy(), 1, empty)["damage"], 0)
