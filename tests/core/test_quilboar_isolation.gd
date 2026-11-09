extends GutTest
## The reference_library tribe must require an explicit test opt-in and never reach player exports.
@warning_ignore_start("unsafe_call_argument")


func _reference_config() -> GameConfig:
	var config := GameConfig.full_game()
	config.set_value("reference_quilboar", true)
	return config


func test_reference_flag_is_off_in_defaults_and_the_shipped_config() -> void:
	assert_false(GameConfig.defaults().get_bool("reference_quilboar"))
	assert_false(GameConfig.full_game().get_bool("reference_quilboar"))
	assert_false(ReferenceQuilboar.allowed(GameConfig.defaults(), true))
	assert_false(ReferenceQuilboar.allowed(GameConfig.full_game(), true))


func test_reference_opt_in_is_rejected_in_player_builds_even_when_flag_is_true() -> void:
	assert_true(ReferenceQuilboar.allowed(_reference_config(), true))
	assert_false(ReferenceQuilboar.allowed(_reference_config(), false))


func test_default_libraries_and_both_normal_pools_have_no_reference_cards() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	for config: GameConfig in [GameConfig.defaults(), GameConfig.full_game()]:
		var normal: UnitLibrary = ScaleOverlay.library_for(library, config)
		var pool: UnitPool = UnitPool.create(normal, config)
		for unit: Dictionary in normal.all_units():
			assert_false(str(unit["id"]).begins_with("qb_"))
		for card: Dictionary in normal.all_cards():
			assert_false(str(card["id"]).begins_with("qb_"))
		for id: String in pool.ids():
			assert_false(id.begins_with("qb_"))
		for card: Dictionary in normal.pool_spells(config.card_set()):
			assert_false(str(card["id"]).begins_with("qb_"))
	assert_true(library.get_unit("qb_gem_rat").is_empty())
	assert_true(library.get_card("qb_blood_gem").is_empty())


func test_reference_library_is_private_and_switching_flag_off_removes_it() -> void:
	var source: UnitLibrary = UnitLibrary.load_dir()
	var config: GameConfig = _reference_config()
	var reference_library: UnitLibrary = ScaleOverlay.library_for(source, config)
	assert_false(reference_library.get_unit("qb_gem_rat").is_empty())
	assert_false(reference_library.get_card("qb_blood_gem").is_empty())
	assert_true(source.get_unit("qb_gem_rat").is_empty())
	assert_true(source.get_card("qb_blood_gem").is_empty())
	var pool: UnitPool = UnitPool.create(reference_library, config)
	assert_true(pool.has_unit("qb_gem_rat"))
	assert_true(
		reference_library.pool_spells(config.card_set()).any(
			func(card: Dictionary) -> bool: return str(card["id"]) == "qb_gem_confiscation"
		)
	)
	config.set_value("reference_quilboar", false)
	var normal: UnitLibrary = ScaleOverlay.library_for(reference_library, config)
	assert_true(normal.get_unit("qb_gem_rat").is_empty())
	assert_true(normal.get_card("qb_blood_gem").is_empty())
	assert_false(UnitPool.create(normal, config).has_unit("qb_gem_rat"))


func test_every_player_export_explicitly_excludes_reference_content() -> void:
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	var count: int = 0
	for section: String in presets.get_sections():
		if section.ends_with(".options") or not section.begins_with("preset."):
			continue
		count += 1
		var excluded: String = str(presets.get_value(section, "exclude_filter", ""))
		assert_string_contains(excluded, "content/reference/*", section)
		var included: String = str(presets.get_value(section, "include_filter", ""))
		assert_false(included.contains("content/reference"), section)
	assert_gt(count, 0)
