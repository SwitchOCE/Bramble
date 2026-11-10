extends GutTest
@warning_ignore_start("unsafe_call_argument")

const CK := preload("res://tests/core/combat_kit.gd")
const KIT := preload("res://tests/core/recruit_kit.gd")


func test_b_is_default_a_is_fallback_and_c_has_data_authored_engine_overrides() -> void:
	var config := GameConfig.full_game()
	assert_eq(config.get_string("pass3_preset"), "B")
	assert_eq(Pass3Rates.number(config, "fairies_fetch_share"), 1.0)
	assert_eq(config.get_int("scale_hero_spell_percent"), 10)
	config.set_value("pass3_preset", "A")
	assert_eq(Pass3Rates.number(config, "fairies_fetch_share"), 0.5)
	config.set_value("pass3_preset", "C")
	assert_eq(Pass3Rates.number(config, "fairies_fetch_share"), 1.0)
	assert_eq(config.get_int("scale_hero_spell_percent"), 20)
	assert_eq(Pass3Rates.number(config, "birds_homecoming_multiplier"), 3.0)
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
	assert_eq(c["fairies_ring_growth"], 12.0)
	c["fairies_ring_growth"] = 99
	assert_eq(Pass3Rates.defaults(), before)
	assert_true(Pass3Rates.overridden(config))
	assert_eq(Pass3Rates.resolved(config)["fairies_ring_growth"], 12.0)


func test_fetch_real_combat_and_generated_words_follow_each_preset() -> void:
	var library: UnitLibrary = TestLibraries.current()
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
		var words: String = "half" if preset_id == "A" else "full"
		assert_string_contains(configured.get_unit("cradle_fetch")["text"], words + " stats")
		if preset_id == "C":
			assert_string_contains(
				configured.get_unit("cradle_fetch")["golden_details"], "all the current stats"
			)


func test_authored_default_fetch_golden_reader_matches_b_rates() -> void:
	var authored: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/units/cradle_fetch.json")
	)
	var library: UnitLibrary = TestLibraries.current()
	assert_eq(authored["golden_details"], library.get_unit("cradle_fetch")["golden_details"])
	assert_string_contains(authored["golden_details"], "Copies all the current stats")


func test_fairy_rebase_uses_paper_rates_with_authorized_initial_ring_sizes() -> void:
	var config := GameConfig.full_game()
	for preset_id: String in ["B", "C"]:
		config.set_value("pass3_preset", preset_id)
		assert_eq(
			Pass3Rates.number(config, "fairies_initial_ring_size"), 4.0 if preset_id == "B" else 6.0
		)
		assert_eq(
			Pass3Rates.number(config, "fairies_ring_growth"), 6.0 if preset_id == "B" else 12.0
		)
		assert_eq(Pass3Rates.integer(config, "fairies_lob_turns"), 2)
		assert_eq(Pass3Rates.integer(config, "fairies_monarch_period"), 2)
		assert_eq(Pass3Rates.integer(config, "fairies_nan_rings"), 2)
		assert_eq(Pass3Rates.integer(config, "fairies_annis_rings"), 1)
		assert_eq(Pass3Rates.integer(config, "fairies_sally_rings"), 1)
		assert_eq(Pass3Rates.integer(config, "bog_soak_keep"), 3 if preset_id == "B" else 4)
	config.set_value("pass3_preset", "A")
	assert_eq(Pass3Rates.number(config, "fairies_initial_ring_size"), 1.0)
	assert_eq(Pass3Rates.number(config, "fairies_ring_growth"), 1.0)
	assert_eq(Pass3Rates.integer(config, "fairies_lob_turns"), 3)
	assert_eq(Pass3Rates.integer(config, "fairies_monarch_period"), 3)


func test_queen_period_keeps_start_of_turn_and_cluricaun_uses_end_of_turn() -> void:
	var config := GameConfig.full_game()
	config.set_value("fairies_queen_period", 2)
	var library: UnitLibrary = ScaleOverlay.library_for(TestLibraries.current(), config)
	assert_string_contains(library.get_unit("queen_of_elfland")["text"], "Every 2nd Start of Turn:")
	assert_string_contains(library.get_unit("cluricaun")["text"], "End of Turn:")
	assert_false(str(library.get_unit("cluricaun")["details"]).contains("tier-up"))


func test_overridden_compares_with_effective_default_b_instead_of_historical_base() -> void:
	var config := GameConfig.defaults()
	assert_false(Pass3Rates.overridden(config), "B is the default, including its override map")
	config.set_value("fairies_ring_growth", 6.0)
	assert_false(Pass3Rates.overridden(config), "an explicit default value is not a sweep")
	config.set_value("fairies_ring_growth", 3.0)
	assert_true(Pass3Rates.overridden(config))
	config.set_value("fairies_ring_growth", null)
	for preset_id: String in ["A", "C"]:
		config.set_value("pass3_preset", preset_id)
		assert_true(Pass3Rates.overridden(config), preset_id)


func test_bird_b_changes_only_measured_path_dials_from_9f03fe0() -> void:
	var frozen: Dictionary = (
		JSON
		. parse_string(
			(
				'{"base":{"birds_homecoming_multiplier":2.0,"birds_golden_homecoming_multiplier":2.0,"'
				+ 'birds_trip_turns":2,"birds_swallow_trip_turns":1,"birds_golden_tern_trip_turns":1,"bi'
				+ 'rds_redbreast_share":0.125,"birds_cuckoo_share":0.1,"birds_jack_daw_share":0.25,"bird'
				+ 's_jack_daw_permanent":true,"birds_stork_gold_step":6,"birds_stork_recalls":1,"birds_g'
				+ 'olden_egg_enabled":true,"birds_golden_egg_multiplier":2.0,"birds_whistlers_loss_share'
				+ '":0.5,"birds_whistlers_flock_count":7,"birds_lump_multiplier":1.0,"birds_ratchet_mult'
				+ 'iplier":1.0,"birds_redwing_share":0.5,"birds_redwing_targets":2,"birds_tom_tit_reduct'
				+ 'ion":50,"birds_tom_tit_targets":1,"birds_dunnock_turns":1,"birds_dunnock_targets":1}}'
			)
		)
	)
	var config := GameConfig.full_game()
	config.set_value("pass3_preset", "B")
	var expected: Dictionary = frozen["base"]
	var actual: Dictionary = {}
	var resolved: Dictionary = Pass3Rates.resolved(config)
	for key: String in resolved:
		if key.begins_with("birds_"):
			actual[key] = resolved[key]
	# Build 8 measurement: held dials stay at their historical values.
	expected.merge(
		{
			"birds_chiffchaff_gain": 3.0,
			"birds_homecoming_multiplier": 2.5,
			"birds_golden_homecoming_multiplier": 3.0,
			"birds_redbreast_share": 1.0 / 6.0,
			"birds_cuckoo_share": 1.0 / 7.0,
			"birds_golden_egg_multiplier": 3.0
		},
		true
	)
	assert_eq(actual, expected, "B changes only the measured Bird path values")


func test_bird_c_raises_only_fitted_dials_from_the_paper_endpoint() -> void:
	# Snapshot of ideation/main 4eacc662 presets.json: C's Birds subset only.
	var expected: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/paper_c_birds.json")
	)
	var config := GameConfig.full_game()
	config.set_value("pass3_preset", "C")
	var actual: Dictionary = {}
	var resolved: Dictionary = Pass3Rates.resolved(config)
	for key: String in resolved:
		if key.begins_with("birds_"):
			actual[key] = resolved[key]
	expected.merge(
		{
			"birds_chiffchaff_gain": 6.0,
			"birds_cuckoo_share": 0.16666666666666666,
			"birds_golden_egg_multiplier": 3.5,
			"birds_golden_homecoming_multiplier": 3.5,
			"birds_homecoming_multiplier": 3.0,
			"birds_redbreast_share": 0.1875,
			"birds_stork_gold_step": 5.0
		},
		true
	)
	assert_eq(actual, expected, "C keeps held Bird dials and applies the provisional measured path")


func test_optional_bird_dials_drive_real_recruits_without_changing_b() -> void:
	for preset_id: String in ["B", "C"]:
		for golden: bool in [false, true]:
			var config := GameConfig.full_game()
			config.set_value("pass3_preset", preset_id)
			var kit: KIT = KIT.new()
			kit.setup(config)
			kit.rules.start_phase(kit.player, 1)
			var factor: int = 2 if golden else 1
			var gain: int = (6 if preset_id == "C" else 3) * factor
			var chiff: RecruitUnit = kit.play("chiffchaff", 0, golden)
			assert_eq(chiff.attack, factor + gain, preset_id + " Chiffchaff Attack")
			assert_eq(chiff.health, 2 * factor + gain, preset_id + " Chiffchaff Health")
			assert_string_contains(chiff.view()["text"], "+%d/+%d" % [gain, gain])
			var gold: int = kit.player.gold
			kit.play("one_swallow", 1, golden)
			assert_eq(kit.player.gold, gold + factor, "Swallow's existing reward is preserved")
			kit.play("mother_goose", 2, golden)
			assert_eq(kit.player.items.size(), factor, "Goose gives the configured Golden Eggs")
			var jay: RecruitUnit = kit.play("mrs_jay", 3, golden)
			jay.played_round = 0
			assert_eq(kit.rules.sell(kit.player, 3), "")
			assert_eq(kit.player.items.size(), 2 * factor, "Jay gives the configured Acorns")


func test_optional_bird_dials_can_be_swept_and_captured_from_b() -> void:
	var config := GameConfig.full_game()
	config.set_value("birds_chiffchaff_gain", 5)
	config.set_value("birds_goose_eggs", 3)
	config.set_value("birds_swallow_gold", 2)
	config.set_value("birds_jay_acorns", 4)
	var kit: KIT = KIT.new()
	kit.setup(config)
	kit.rules.start_phase(kit.player, 1)
	var chiff: RecruitUnit = kit.play("chiffchaff", 0)
	assert_eq(chiff.attack, 6)
	var gold: int = kit.player.gold
	kit.play("one_swallow", 1)
	assert_eq(kit.player.gold, gold + 2)
	kit.play("mother_goose", 2, true)
	assert_eq(kit.player.items.size(), 6)
	kit.player.items.clear()
	var jay: RecruitUnit = kit.play("mrs_jay", 3)
	jay.played_round = 0
	assert_eq(kit.rules.sell(kit.player, 3), "")
	assert_eq(kit.player.items.size(), 2, "four Acorns combine into a Stash and an Acorn")
	assert_eq(RecruitExtras.item_count(kit.player, "stash"), 1)
	assert_eq(RecruitExtras.item_count(kit.player, "acorn"), 1)
	var values: Dictionary = JSON.parse_string(JSON.stringify(config.resolved_values()))
	var restored: GameConfig = FightCapture.config_for(values)
	assert_eq(Pass3Rates.integer(restored, "birds_chiffchaff_gain"), 5)
	assert_eq(Pass3Rates.integer(restored, "birds_goose_eggs"), 3)
	assert_eq(Pass3Rates.integer(restored, "birds_swallow_gold"), 2)
	assert_eq(Pass3Rates.integer(restored, "birds_jay_acorns"), 4)
