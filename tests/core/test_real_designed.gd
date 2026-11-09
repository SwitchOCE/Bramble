extends GutTest
@warning_ignore_start("unsafe_call_argument")
@warning_ignore_start("unsafe_method_access")

const RECIPES: String = "res://tests/core/data/real_designed_recipes.json"


func _document() -> Dictionary:
	var recipes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RECIPES))
	return RealDesignedBoards.document(recipes, UnitLibrary.load_dir())


func test_all_eight_setups_use_current_cards_complete_fight_inputs_and_pass3_timing() -> void:
	var document: Dictionary = _document()
	var boards: Array = document["boards"]
	assert_eq(boards.size(), 8)
	for board: Dictionary in boards:
		var config: Dictionary = board["config"]
		var rules: Dictionary = board["fight_rules"]
		assert_true(config["pass3_content"])
		assert_true(rules["pass3_content"])
		assert_eq(board["layout"], "blind")
		assert_eq(board["board"].size(), 7)
		assert_eq(board["slots"].size(), 7)
		var library: UnitLibrary = FightCapture.library_for(config, UnitLibrary.load_dir())
		for spec: Dictionary in board["board"]:
			assert_false(library.get_unit(str(spec["def_id"])).is_empty())
		var result: Dictionary = FieldCombat.fight(board, board, 149051, library)
		assert_true(result.has("winner"), str(board["id"]))


func test_nests_belly_reserves_rings_and_tern_swap_are_serialized_from_real_player_state() -> void:
	var boards: Array = _document()["boards"]
	var by_id: Dictionary = {}
	for board: Dictionary in boards:
		by_id[board["id"]] = board
	var bird: Dictionary = by_id["r12:real-birds_homecoming"]
	assert_eq(bird["board"][0]["def_id"], "great_lump")
	assert_eq(bird["fight_rules"]["nests"].size(), 1)
	assert_eq(bird["fight_rules"]["nests"][0]["slot"], 0)
	assert_eq(bird["fight_rules"]["away_birds"].size(), 3)
	var fairy: Dictionary = by_id["r12:real-fairies_ring"]
	assert_eq(fairy["board"][1]["def_id"], "cradle_fetch")
	assert_eq(fairy["board"][1]["attack"], 2, "Fetch copies at combat, not in the input")
	assert_eq(fairy["slots"][4][0]["count"], 33)
	assert_eq(fairy["slots"][4][0]["attack"], 198)
	assert_eq(fairy["fight_rules"]["ring_size"], 6.0)
	var granny: Dictionary = by_id["r12:real-granny-pot-luck"]
	assert_eq(granny["board"][0]["held"].size(), 2)
	assert_eq(granny["board"][5]["held"].size(), 1)
	assert_eq(granny["reserves"].size(), 0, "Belly state lives in the combat specs")
	var tern_swap: Dictionary = by_id["r12:real-seven-whistlers-tern-swap"]
	assert_eq(tern_swap["fight_rules"]["away_birds"], bird["fight_rules"]["away_birds"])
	assert_eq(tern_swap["fight_rules"]["nests"], bird["fight_rules"]["nests"])
	assert_eq(tern_swap["fight_rules"]["nests"][0]["slot"], 0)
	var identities: Dictionary = {}
	for spec: Dictionary in tern_swap["board"]:
		identities[spec["def_id"]] = true
	assert_eq(identities.size(), 6, "Two Jays prevent the seven-different-Birds omen")
	assert_true(identities.has("seven_whistlers"))
	assert_eq(tern_swap["board"][1]["def_id"], "mrs_jay")
	assert_eq(tern_swap["board"][3]["def_id"], "mrs_jay")
	assert_eq(tern_swap["board"].slice(0, 6), bird["board"].slice(0, 6))
	var whistlers: Dictionary = tern_swap["board"][6]
	assert_eq(whistlers["def_id"], "seven_whistlers")
	assert_eq([whistlers["tribe_attack"], whistlers["tribe_health"]], [1, 1])
	assert_eq(
		[whistlers["attack"], whistlers["health"]],
		[10, 12],
		"Pre-start stats include the tribe bonus"
	)
