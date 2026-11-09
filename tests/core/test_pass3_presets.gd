extends GutTest
@warning_ignore_start("unsafe_call_argument")

const CK := preload("res://tests/core/combat_kit.gd")


func test_b_is_default_a_is_fallback_and_c_has_data_authored_engine_overrides() -> void:
	var config := GameConfig.full_game()
	assert_eq(config.get_string("pass3_preset"), "B")
	assert_eq(Pass3Rates.number(config, "fairies_fetch_share"), 1.0)
	assert_eq(config.get_int("scale_hero_spell_percent"), 10)
	config.set_value("pass3_preset", "A")
	assert_eq(Pass3Rates.number(config, "fairies_fetch_share"), 0.5)
	config.set_value("pass3_preset", "C")
	assert_eq(Pass3Rates.number(config, "fairies_fetch_share"), 2.0)
	assert_eq(config.get_int("scale_hero_spell_percent"), 20)
	assert_eq(Pass3Rates.number(config, "birds_homecoming_multiplier"), 4.0)
	assert_eq(Pass3Rates.integer(config, "birds_trip_turns"), 2, "C leaves clocks intact")
	assert_eq(Pass3Rates.integer(config, "fairies_reel_moves"), 2, "C leaves loop guards intact")
	config.set_value("fairies_fetch_share", 0.75)
	assert_eq(Pass3Rates.number(config, "fairies_fetch_share"), 0.75, "explicit sweep beats preset")


func test_preset_resolution_contains_rates_without_metadata_and_does_not_mutate_defaults() -> void:
	var before: Dictionary = Pass3Rates.defaults()
	var config := GameConfig.full_game()
	config.set_value("pass3_preset", "C")
	var c: Dictionary = Pass3Rates.resolved(config)
	assert_false(c.has("notes"))
	assert_false(c.has("presets"))
	assert_eq(c["fairies_ring_growth"], before["fairies_ring_growth"] * 2)
	c["fairies_ring_growth"] = 99
	assert_eq(Pass3Rates.defaults(), before)
	assert_true(Pass3Rates.overridden(config))
	assert_eq(Pass3Rates.resolved(config)["fairies_ring_growth"], 2.0)


func test_fetch_real_combat_and_generated_words_follow_each_preset() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	for preset_id: String in ["A", "B", "C"]:
		var config := GameConfig.full_game()
		config.set_value("pass3_preset", preset_id)
		var configured: UnitLibrary = ScaleOverlay.library_for(library, config)
		var rng := RandomNumberGenerator.new()
		rng.seed = 19
		var combat := Combat.create(configured, config, rng)
		combat._setup(
			[
				CK.board({0: CK.u("cradle_fetch"), 4: CK.u("hedge_witch", 100, 120)}),
				CK.board({0: CK.plain(1, 1000)})
			]
		)
		combat._start_of_combat()
		var share: float = Pass3Rates.number(config, "fairies_fetch_share")
		assert_eq(combat.unit_at(0, 0).attack, ceili(100 * share), preset_id)
		assert_eq(combat.unit_at(0, 0).health, ceili(120 * share), preset_id)
		var words: String = "half" if preset_id == "A" else "full" if preset_id == "B" else "double"
		assert_string_contains(configured.get_unit("cradle_fetch")["text"], words + " stats")
		if preset_id == "C":
			assert_string_contains(
				configured.get_unit("cradle_fetch")["golden_details"], "twice the current stats"
			)


func test_authored_default_fetch_golden_reader_matches_b_rates() -> void:
	var authored: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/units/cradle_fetch.json")
	)
	var library: UnitLibrary = UnitLibrary.load_dir()
	assert_eq(authored["golden_details"], library.get_unit("cradle_fetch")["golden_details"])
	assert_string_contains(authored["golden_details"], "Copies all the current stats")
