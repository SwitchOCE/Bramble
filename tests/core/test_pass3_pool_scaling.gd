extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")


func test_scaling_follows_content_without_overriding_explicit_comparisons() -> void:
	var config := GameConfig.defaults()
	assert_true(config._values.has("scale_hero_spell_percent"), "bench overrides require this key")
	assert_null(config.get_value("scale_hero_spell_percent"), "null resolves the JSON preset rate")
	assert_false(config.get_bool("scale_hero_spell_stats"))
	config.set_value("pass3_content", true)
	assert_true(config.get_bool("scale_hero_spell_stats"))
	assert_eq(config.get_int("scale_hero_spell_percent"), 10)
	config.set_value("scale_hero_spell_stats", false)
	assert_false(config.get_bool("scale_hero_spell_stats"))
	config.set_value("pass3_content", false)
	config.set_value("scale_hero_spell_stats", true)
	assert_true(config.get_bool("scale_hero_spell_stats"))
	assert_true(GameConfig.full_game().get_bool("scale_hero_spell_stats"))


func test_default_spell_scaling_and_explicit_off_use_existing_recipient_math() -> void:
	var kit := KIT.new()
	kit.setup(GameConfig.full_game())
	kit.library = kit.rules.library
	var unit: RecruitUnit = kit.put("field_vole", 0)
	unit.attack = 100
	unit.health = 200
	kit.spell(
		"scaled",
		{"effect": "buff", "attack": 2, "health": 1, "target": {"select": "chosen"}},
		"unit"
	)
	assert_eq(kit.cast("scaled", 0), "")
	assert_eq([unit.attack, unit.health], [120, 220])
	kit.config.set_value("scale_hero_spell_stats", false)
	assert_eq(kit.cast("scaled", 0), "")
	assert_eq([unit.attack, unit.health], [122, 221])


func test_supper_lifts_ceiling_keeps_once_guard_and_inherits_to_future_units() -> void:
	var config := GameConfig.full_game()
	config.set_value("card_rate_limits", false)
	config.set_value("card_size_caps", false)
	var kit := KIT.new()
	kit.setup(config)
	var unit: RecruitUnit = kit.put("field_vole", 0)
	unit.attack = 100
	unit.health = 100
	assert_eq(kit.cast("harvest_supper", 0), "")
	assert_eq(kit.player.tribe_bonuses["Hedgerow folk"], 10)
	assert_ne(kit.cast("harvest_supper", 0), "")
	assert_eq(kit.player.items.size(), 1, "failed cast is retained")
	assert_false(BotCommitment.can_cast(kit.rules.library.get_card("harvest_supper"), kit.player))
	kit.rules.start_phase(kit.player, 2)
	assert_gt(
		BotCommitment.spell_value(kit.rules.library.get_card("harvest_supper"), kit.player), 0.0
	)
	assert_eq(kit.cast("harvest_supper", 0), "")
	assert_gt(kit.player.tribe_bonuses["Hedgerow folk"], 10)
	kit.rules.give_card(kit.player, "field_vole")
	assert_eq(kit.player.hand.back().tribe_attack, kit.player.tribe_bonuses["Hedgerow folk"])


func test_legacy_supper_ceiling_and_optional_rate_limit_stay_compatible() -> void:
	var kit := KIT.new()
	kit.setup(GameConfig.full_game(), true)
	kit.put("field_vole", 0)
	for turn: int in [1, 2, 3]:
		kit.rules.start_phase(kit.player, turn)
		assert_eq(kit.cast("harvest_supper", 0), "")
	kit.rules.start_phase(kit.player, 4)
	assert_ne(kit.cast("harvest_supper", 0), "")
	assert_eq(kit.player.tribe_bonuses["Hedgerow folk"], 3)
	assert_eq(
		BotCommitment.spell_value(kit.rules.library.get_card("harvest_supper"), kit.player), 0.0
	)
	kit.player.card_size_caps = false
	kit.player.card_rate_limits = false
	assert_eq(kit.cast("harvest_supper", 0), "")
	assert_eq(kit.cast("harvest_supper", 0), "")
	assert_eq(kit.player.tribe_bonuses["Hedgerow folk"], 5)


func test_default_pass3_supper_exceeds_the_old_ceiling_with_size_caps_enabled() -> void:
	var kit := KIT.new()
	kit.setup(GameConfig.full_game())
	assert_true(kit.player.card_size_caps, "this is the real default, not the caps-off overlay")
	var unit: RecruitUnit = kit.put("field_vole", 0)
	unit.attack = 100
	unit.health = 100
	assert_eq(kit.cast("harvest_supper", 0), "")
	assert_eq(kit.player.tribe_bonuses["Hedgerow folk"], 10, "legacy ceiling would stop at three")
	kit.rules.start_phase(kit.player, 2)
	assert_eq(kit.cast("harvest_supper", 0), "")
	assert_gt(kit.player.tribe_bonuses["Hedgerow folk"], 10)


func test_generated_reader_words_follow_json_defaults_and_cache_comparisons() -> void:
	var library := UnitLibrary.load_dir()
	var config := GameConfig.full_game()
	config.set_value("card_rate_limits", false)
	var original: Dictionary = Pass3Rates.defaults()
	Pass3Rates._defaults["scale_hero_spell_percent"] = 25
	var scaled: UnitLibrary = ScaleOverlay.library_for(library, config)
	assert_eq(config.get_int("scale_hero_spell_percent"), 25)
	assert_string_contains(scaled.get_card("harvest_supper")["details"], "25%")
	assert_eq(
		scaled.get_card("harvest_supper")["text"],
		"Choose a unit. Increase its tribe bonus. Once a turn."
	)
	assert_string_contains(scaled.get_card("pinch_of_dust")["text"], "+25%/+25%")
	assert_false(str(scaled.get_card("harvest_supper")["text"]).contains("+3/+3"))
	assert_string_contains(scaled.get_card("harvest_supper")["text"], "Once a turn")
	config.set_value("scale_hero_spell_percent", 40)
	var swept: UnitLibrary = ScaleOverlay.library_for(scaled, config)
	assert_string_contains(swept.get_card("harvest_supper")["details"], "40%")
	assert_false(str(swept.get_card("harvest_supper")["details"]).contains("25%"))
	config.set_value("pass3_content", false)
	config.set_value("scale_hero_spell_stats", false)
	var legacy: UnitLibrary = ScaleOverlay.library_for(swept, config)
	assert_string_contains(legacy.get_card("harvest_supper")["text"], "+3/+3")
	assert_false(str(legacy.get_card("harvest_supper")["details"]).contains("40%"))
	Pass3Rates._defaults = original


func test_scripted_engine_guards_doublings_but_repeats_fractional_and_flat_growth() -> void:
	for sample: Array in [
		[100, false, true, 0, 20, true],
		[100, false, true, 0, 40, false],
		[100, false, false, 0, 40, true],
		[50, true, true, 0, 20, true],
		[50, true, false, 0, 40, true],
		[50, false, true, 0, 22, true],
		[100, false, true, 10, 30, true],
	]:
		var config := GameConfig.defaults()
		config.set_value("pass3_content", true)
		config.set_value("scale_levers", ["scale_engine", "scale_doubler"])
		config.set_value("scale_engine_self", true)
		config.set_value("scale_engine_percent", sample[0])
		config.set_value("pass3_loop_guards", sample[2])
		config.set_value("scale_engine_flat", sample[3])
		var kit := KIT.new()
		kit.setup(config, not sample[5])
		kit.library = kit.rules.library
		var unit: RecruitUnit = kit.put("scale_engine", 0, sample[1])
		unit.attack = 10
		unit.health = 10
		kit.put("scale_doubler", 4)
		kit.rules.end_phase(kit.player)
		assert_eq(unit.attack, sample[4], str(sample))


func test_percentage_faces_match_high_board_grants_at_default_and_override_rates() -> void:
	for rate: int in [10, 25]:
		var config := GameConfig.full_game()
		if rate != 10:
			config.set_value("scale_hero_spell_percent", rate)
		var kit := KIT.new()
		kit.setup(config)
		var unit: RecruitUnit = kit.put("field_vole", 0)
		unit.attack = 100
		unit.health = 200
		var words: String = kit.library.get_card("pinch_of_dust")["text"]
		assert_string_contains(words, "+%d%%/+%d%%" % [rate, rate])
		assert_eq(kit.cast("pinch_of_dust", 0), "")
		assert_eq([unit.attack, unit.health], [100 + rate, 200 + 2 * rate])
		words = kit.library.get_card("harvest_supper")["details"]
		assert_string_contains(words, "%d%% of the lower of your board's average" % rate)
		assert_string_contains(words, "+1/+1 as a minimum")
		var baseline: int = unit.attack
		assert_eq(kit.cast("harvest_supper", 0), "")
		assert_eq(kit.player.tribe_bonuses["Hedgerow folk"], StatFraction.part(baseline, rate))
		assert_string_contains(
			kit.library.get_hero("sample_painter")["text"], "+%d%%/+%d%%" % [rate, rate]
		)


func test_pass3_counted_rings_keep_their_count_on_a_large_board() -> void:
	var kit := KIT.new()
	kit.setup(GameConfig.full_game())
	var unit: RecruitUnit = kit.put("field_vole", 0)
	unit.attack = 100
	unit.health = 200
	assert_eq(kit.cast("spore_cloud", 0), "")
	assert_eq(Pass3Fairies.ring_count(kit.player.slot_effects[0][0]), 2)
	assert_eq(kit.library.get_card("spore_cloud")["text"], "Ring a slot 2 times.")
	assert_eq(kit.cast("boundary_stone", 0), "")
	assert_eq(Pass3Fairies.ring_count(kit.player.slot_effects[0][0]), 5)
	assert_eq(kit.library.get_card("boundary_stone")["text"], "Ring a slot 3 times.")
	kit.spell(
		"paint",
		{"effect": "slot_effect", "name": "Paint", "attack": 1, "health": 1, "at": "chosen"},
		"any_slot"
	)
	assert_eq(kit.cast("paint", 0), "")
	var paint: Dictionary = kit.player.slot_effects[0][1]
	assert_gt(CoreUtil.to_int(paint["attack"]), 1, "ordinary slot buffs retain scaling")
