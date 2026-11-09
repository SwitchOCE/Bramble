extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access", "unsafe_property_access")

const FieldTestData := preload("res://tests/core/field_test_data.gd")
const FrozenContent := preload("res://tests/core/field_frozen_content.gd")


func test_merged_frozen_content_isolates_and_restores_pass3_rates() -> void:
	var previous: Dictionary = Pass3Rates._defaults
	var sentinel: Dictionary = {"live_content_sentinel": 123}
	Pass3Rates._defaults = sentinel
	var frozen := FrozenContent.new()
	frozen.setup("res://tests/fixtures/field/content-0946909.json")
	assert_false(Pass3Rates.defaults().has("live_content_sentinel"))
	assert_gt(Pass3Rates.defaults().size(), 0)
	frozen.restore()
	assert_same(Pass3Rates._defaults, sentinel)
	Pass3Rates._defaults = previous


func test_gzip_library_round_trip_and_invalid_header_are_loud() -> void:
	var path: String = "user://field-compressed.json.gz"
	var json: PackedByteArray = FileAccess.get_file_as_bytes(FieldTestData.path())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(json.compress(FileAccess.COMPRESSION_GZIP))
	file.close()
	var field := FieldLibrary.read(path, UnitLibrary.load_dir())
	assert_eq(field.error, "")
	var lines: Dictionary = field.data.get("lines", {})
	assert_gt(lines.size(), 0)
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("not a gzip field")
	file.close()
	field = FieldLibrary.read(path, UnitLibrary.load_dir())
	assert_string_contains(field.error, "gzip header")
	assert_eq(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)), OK)


func test_prepared_snapshot_starts_a_game_without_reading_or_validating_again() -> void:
	var path: String = "user://field-once.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(FieldTestData.path()))
	file.close()
	var units := UnitLibrary.load_dir()
	var config := GameConfig.full_game()
	var field := FieldLibrary.prepare(config, units, path)
	assert_eq(field.error, "")
	assert_eq(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)), OK)
	var session := GameSession.create(71, units, config, Bot.create, field)
	assert_not_null(session, "uses the prepared snapshot even after its source file is gone")
	if session != null:
		assert_same(session._field.library, field, "session retains the validated object")
		config.set_value("starting_health", config.get_int("starting_health") + 1)
		assert_null(
			GameSession.create(71, units, config, Bot.create, field), "config still checked"
		)


func test_gameplay_hash_matches_python_and_ignores_presentation() -> void:
	var card: Dictionary = {
		"id": "probe",
		"name": "Old",
		"attack": 4,
		"mechanics":
		[{"id": "effect", "name": "counter", "limit": 2, "do": {"effect": "buff", "attack": 1}}],
		"text": "Words",
		"portrait_path": "somewhere.png"
	}
	var expected: String = "c717cf22bb7a5c0468778fab417826a6d0f05bb20229e7dc7e389ed93df99aaa"
	assert_eq(FieldLibrary.gameplay_hash(card), expected, "canonical hash agrees with Python")
	card["name"] = "New card name"
	card["text"] = "New description"
	card["details"] = "New details"
	card["overlay_text"] = {"any": "New overlay wording"}
	card["portrait_path"] = "new.png"
	card["source"] = {"doc": "new-reference.md"}
	assert_eq(FieldLibrary.gameplay_hash(card), expected)
	card["mechanics"][0]["name"] = "different_counter"
	assert_ne(FieldLibrary.gameplay_hash(card), expected, "counter names are gameplay IDs")
	card["mechanics"][0]["name"] = "counter"
	card["attack"] = 5
	assert_ne(FieldLibrary.gameplay_hash(card), expected)


func test_schema_keyword_and_overlay_wording_are_not_gameplay() -> void:
	var schema: Dictionary = {
		"keywords": {"Ring": "Old words"},
		"size_cap_overlay":
		{"text_rules": [{"pattern": "old", "replacement": "new"}], "unbounded": ["cap"]}
	}
	var expected: String = FieldLibrary.gameplay_hash(schema, true)
	schema["keywords"]["Ring"] = "New words"
	schema["size_cap_overlay"]["text_rules"] = []
	assert_eq(FieldLibrary.gameplay_hash(schema, true), expected)
	schema["size_cap_overlay"]["unbounded"] = ["different_cap"]
	assert_ne(FieldLibrary.gameplay_hash(schema, true), expected)


func test_missing_export_content_directory_sets_explicit_validation_error() -> void:
	var root_path: String = "user://field-missing-content-test"
	for folder: String in ["units", "heroes", "spells", "schema"]:
		var directory: String = ProjectSettings.globalize_path(root_path.path_join(folder))
		assert_eq(DirAccess.make_dir_recursive_absolute(directory), OK)
		var file := FileAccess.open(directory.path_join("probe.json"), FileAccess.WRITE)
		file.store_string("{}")
		file.close()
	var field := FieldLibrary.new()
	assert_eq(field._content_manifest(root_path), {})
	assert_string_contains(field.error, "Cannot validate field content")
	assert_string_contains(field.error, "content/levers")
	for folder: String in ["units", "heroes", "spells", "schema"]:
		var directory: String = ProjectSettings.globalize_path(root_path.path_join(folder))
		DirAccess.remove_absolute(directory.path_join("probe.json"))
		DirAccess.remove_absolute(directory)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(root_path))


func test_eligibility_filters_whole_source_lobby_and_top_four() -> void:
	var field := FieldLibrary.new()
	field.data = {
		"lines":
		{
			"line_a":
			{
				"tribe": "A",
				"trajectories":
				[
					{"id": "winner-ab", "finish_place": 2, "lobby_tribes": ["A", "B"]},
					{"id": "loser-ab", "finish_place": 7, "lobby_tribes": ["A", "B"]},
					{"id": "winner-ac", "finish_place": 1, "lobby_tribes": ["A", "C"]}
				]
			}
		}
	}
	var allowed: PackedStringArray = ["A", "B"]
	var winners: Array[Dictionary] = field.eligible(allowed)
	assert_eq(winners.size(), 1)
	assert_eq(winners[0]["trajectory"]["id"], "winner-ab")
	assert_eq(field.eligible(allowed, "all").size(), 2)
	assert_eq(field.eligible(PackedStringArray(), "top4").size(), 2)
	assert_string_contains(field.can_deal(allowed, "top4", 2), "only 1 eligible")
	assert_eq(field.can_deal(allowed, "all", 2), "")
	assert_string_contains(field.can_deal(allowed, "unknown"), "Unknown field strength")


func test_metadata_rejects_invalid_places_or_tribe_lists() -> void:
	var metadata: Dictionary = {"finish_place": 4, "lobby_tribes": ["A", "B"]}
	assert_true(FieldLibrary._valid_metadata(metadata))
	for place: Variant in [0, 9, 1.5, "1", null]:
		metadata["finish_place"] = place
		assert_false(FieldLibrary._valid_metadata(metadata), str(place))
	metadata["finish_place"] = 1
	for tribes: Variant in [["A", "A"], [""], [1], null]:
		metadata["lobby_tribes"] = tribes
		assert_false(FieldLibrary._valid_metadata(metadata), str(tribes))


func test_current_content_fixture_has_eight_distinct_winners_for_each_rotation() -> void:
	var field := FieldLibrary.read(FieldTestData.path(), UnitLibrary.load_dir())
	assert_eq(field.error, "")
	if field.error != "":
		return
	var hashes: Dictionary = field.data["content_hashes"]
	assert_true(hashes.has("content/pass3/rates.json"), "pass 3 rates are gameplay content")
	var rotations: Dictionary = {}
	var lines: Dictionary = field.data["lines"]
	for line: Dictionary in lines.values():
		for trajectory: Dictionary in line["trajectories"]:
			var tribes := PackedStringArray(trajectory["lobby_tribes"])
			rotations["+".join(tribes)] = tribes
	assert_gt(rotations.size(), 0)
	for tribes: PackedStringArray in rotations.values():
		assert_eq(field.can_deal(tribes, "top4", 8), "")
