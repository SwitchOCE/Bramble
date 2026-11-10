extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const DRIVER := preload("res://tools/sim/neutral_roles.gd")
const FIGHTS := preload("res://tools/sim/potluck_constructed.gd")


func _document() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DRIVER.DEFAULT_RECIPES))


func test_roles_have_32_paired_seeds_and_controls_preserve_every_body_and_other_card() -> void:
	var document: Dictionary = _document()
	var library: UnitLibrary = UnitLibrary.load_dir()
	assert_eq(DRIVER.recipe_errors(document, library), PackedStringArray())
	for role: Dictionary in document["roles"]:
		var card_id: String = str(role["card"])
		var off: UnitLibrary = DRIVER.without_text(library, card_id)
		for original: Dictionary in library.all_units():
			var id: String = str(original["id"])
			var changed: Dictionary = off.get_unit(id)
			if id != card_id:
				assert_eq(changed, original, "other cards remain byte-equivalent in memory")
			else:
				var expected: Dictionary = original.duplicate(true)
				expected["mechanics"] = []
				expected.erase(MechanicRegistry.COMPILED_KEY)
				assert_eq(changed, expected, "only the targeted native mechanic is removed")


func test_fixed_roles_record_shield_target_and_exposure_answers_normal_and_golden() -> void:
	var document: Dictionary = _document()
	var library: UnitLibrary = UnitLibrary.load_dir()
	var config: GameConfig = GameConfig.full_game()
	for role: Dictionary in document["roles"]:
		var card: String = str(role["card"])
		var off: UnitLibrary = DRIVER.without_text(library, card)
		for golden: bool in [false, true]:
			var ours: Dictionary = RealDesignedBoards.make_board(
				DRIVER.own_recipe(role, golden), library, config
			)
			var opponent: Dictionary = role["theirs"]
			var theirs: Dictionary = RealDesignedBoards.make_board(opponent, library, config)
			var input: Dictionary = FieldCombat.pair_input(ours, theirs, 283101)
			var on_record: Dictionary = FIGHTS._run(input, library)
			var off_record: Dictionary = FIGHTS._run(input, off)
			assert_eq(
				on_record["input"], off_record["input"], "paired controls use identical inputs"
			)
			var on: Dictionary = DRIVER.role_metrics(on_record, role, 0)
			var control: Dictionary = DRIVER.role_metrics(off_record, role, 0)
			match card:
				"shieldbug":
					assert_true(on["carry_start_shield"])
					assert_false(control["carry_start_shield"])
					assert_eq(on["carry_shield_blocks"], 1)
					assert_eq(control["carry_shield_blocks"], 0)
				"ballooning_spider":
					assert_true(on["first_carry_targets_enemy_carry"])
					assert_false(control["first_carry_targets_enemy_carry"])
				"whirligig_beetle":
					assert_eq(on["enemy_carry_after_start_slot"], 0)
					assert_eq(control["enemy_carry_after_start_slot"], 4)
					assert_eq(on["enemy_carry_after_start_health"], 48 if golden else 54)
					assert_eq(control["enemy_carry_after_start_health"], 60)
					assert_true(on["first_carry_targets_enemy_carry"])
					assert_false(control["first_carry_targets_enemy_carry"])


func test_recruit_roles_have_known_answers_for_both_bodies_and_scaled_echo() -> void:
	var rows: Array = DRIVER.RECRUIT.run(UnitLibrary.load_dir(), GameConfig.full_game())
	assert_eq(rows.size(), 8)
	for row: Dictionary in rows:
		var golden: bool = row["golden"]
		match str(row["role"]):
			"charcoal_fractional_growth":
				assert_eq(row["per_recipient_first_gain"], 60 if golden else 30)
				assert_eq(row["second_turn_body"], 256 if golden else 169)
			"click_two_when_played_units":
				assert_eq(row["carry_gain"], 3 if golden else 2)
				assert_eq(row["tier_discount_gain"], 3 if golden else 2)
			"echo_scaled_spell":
				assert_eq(row["recipient_gain"], 20 if row["preset"] == "C" else 10)
				assert_eq(row["total_stat_gain"], 120 if row["preset"] == "C" else 60)
