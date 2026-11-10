extends GutTest
@warning_ignore_start("unsafe_call_argument")

const DRIVER := preload("res://tools/sim/potluck_constructed.gd")


func test_declared_native_recipes_match_their_phase_budgets_and_real_belly_capacities() -> void:
	var document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(DRIVER.DEFAULT_RECIPES)
	)
	var library: UnitLibrary = UnitLibrary.load_dir()
	var paper: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://docs/ideation/content/pass3/presets-model/six.json")
	)
	var recipes: Array = document["boards"]
	assert_eq(recipes.size(), 2)
	for recipe: Dictionary in recipes:
		assert_eq(
			CoreUtil.to_int(recipe["expected_active_stats"]),
			roundi(
				CoreUtil.to_float(
					paper["B"]["lines"]["Oozes"][1][str(CoreUtil.to_int(recipe["round"]))]
				)
			)
		)
		assert_eq(DRIVER.recipe_errors(recipe, library), PackedStringArray())
		var board: Dictionary = RealDesignedBoards.make_board(
			recipe, library, GameConfig.full_game()
		)
		assert_eq(board["design"]["raw_body_stats"], recipe["expected_active_stats"])
		assert_eq(board["hero_effects"], [])
		var specs: Array = board["board"]
		assert_eq(specs[5]["def_id"], "bubble_and_squeak")
		assert_eq(specs[6]["def_id"], "dishwater_nell")
		assert_false(specs[5]["golden"])
		var invalid: Dictionary = recipe.duplicate(true)
		invalid["expected_active_stats"] = 1
		assert_has(DRIVER.recipe_errors(invalid, library), "active stat budget mismatch")
