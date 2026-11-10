extends GutTest
## Fixed recruit construction and one native wake; no lobby or full-game simulation.
@warning_ignore_start("unsafe_call_argument")

const DRIVER := preload("res://tools/sim/supper_constructed.gd")
const ORIGINAL_B := preload("res://tests/core/pass3_original_b.gd")


func _recipes() -> Array:
	var document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(DRIVER.DEFAULT_RECIPES)
	)
	return document["boards"]


func test_native_supper_plants_the_paper_bodies_normal_larder_and_explicit_clocks() -> void:
	for recipe: Dictionary in _recipes():
		var state: Dictionary = DRIVER.make_state(
			recipe, UnitLibrary.load_dir(), GameConfig.full_game()
		)
		var player: PlayerState = state["player"]
		assert_eq(player.gold, 0)
		assert_eq(player.tier, 4)
		assert_eq(player.larder(), CoreUtil.to_int(recipe["expected_larder_gold"]))
		assert_eq(player.occupied().count(true), 6)
		assert_null(player.board[3], "F4 gap keeps Dozey last")
		assert_eq(player.board[4].def_id(), "sleeping_partner")
		assert_eq(player.board[4].turns_in_slot, 8)
		assert_eq(player.board[4].home_slot, 4)
		assert_eq(player.board[6].def_id(), "alderman_dozey")
		assert_eq(player.board[6].turns_in_slot, 2)
		assert_eq(player.board[6].home_slot, 6)
		assert_eq([player.board[6].attack, player.board[6].health], [24, 28])
		assert_eq(player.items[0].def_id(), "great_hoard")
		assert_eq(player.items.size(), 2 if player.larder() == 17 else 1)
		var telemetry: Dictionary = state["telemetry"]
		assert_eq(telemetry["active_stats"], 105)


func test_native_supper_spends_its_real_fuel_then_partner_passes_land_before_the_wake() -> void:
	for recipe: Dictionary in _recipes():
		var state: Dictionary = DRIVER.make_state(
			recipe, UnitLibrary.load_dir(), ORIGINAL_B.apply(GameConfig.full_game())
		)
		var player: PlayerState = state["player"]
		var rules: RecruitRules = state["rules"]
		var fuel: int = player.larder()
		player.round_number = 9
		while not player.items.is_empty():
			assert_eq(rules.play_item(player, 0, 6), "")
		assert_eq([player.board[6].attack, player.board[6].health], [24 + 2 * fuel, 28 + 2 * fuel])
		assert_eq(player.gold, 0, "feeding is not cashing")
		assert_eq(player.larder(), 0)
		rules.end_phase(player)
		# Six touching Hedgerow give 12 real Acorns at original B. Beadle's twelve +2/+2 Passes
		# land before the normal double. Sorrel's next-fight income is deliberately absent.
		assert_eq([player.board[6].attack, player.board[6].health], [96 + 4 * fuel, 104 + 4 * fuel])
		assert_eq(player.board[6].counters["hedgerow_last_wake_round"], 9)
		assert_eq(player.larder(), 21, "twelve Acorns combine into a Hoard and a Stash")
