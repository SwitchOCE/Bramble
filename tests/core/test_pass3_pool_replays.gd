extends GutTest
@warning_ignore_start("unsafe_call_argument")
## Native untouched tribes, captured from the parent checkpoint with intentional dials held fixed.


func test_native_untouched_tribes_exactly_replay_f574eaf() -> void:
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass3_pool_replay.json")
	)
	assert_eq(fixture["source_commit"], "f574eaf")
	var cases: Array = fixture["cases"]
	assert_eq(cases.size(), 8)
	var config := GameConfig.full_game()
	config.set_value("scale_hero_spell_stats", false)
	config.set_value("fairies_fetch_share", 0.5)
	config.set_value("pass3_preset", "A")
	# Freeze the historical reader comparison basis as well as the fight dials.
	config.set_value("pass3_text_defaults", Pass3Rates.resolved(config))
	var library: UnitLibrary = ScaleOverlay.library_for(TestLibraries.current(), config)
	for entry: Dictionary in cases:
		var rng := RandomNumberGenerator.new()
		rng.seed = CoreUtil.to_int(entry["seed"])
		var combat := Combat.create(library, config, rng)
		combat.side_rules = entry["side_rules"]
		var slots: Array = entry["slot_effects"]
		combat.slot_effects = slots.duplicate(true)
		# JSON parses every number as float; restore the captured Ring integer fields exactly.
		for side: Array in combat.slot_effects:
			for effects: Array in side:
				for ring: Dictionary in effects:
					for field: String in ["attack", "health", "count"]:
						ring[field] = CoreUtil.to_int(ring[field])
		var result: Dictionary = combat.run(entry["boards"], [5, 5], [0, 1], 0)
		assert_true(
			JSON.stringify(result) == str(entry["result"]),
			"byte-identical combat result, events and carry, seed %d" % entry["seed"]
		)
