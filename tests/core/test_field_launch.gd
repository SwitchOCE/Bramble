extends GutTest
## Field replay references must remain pinned before any saved actions run.
@warning_ignore_start("unsafe_call_argument")

const FieldTestData := preload("res://tests/core/field_test_data.gd")


func test_field_save_rejects_missing_library_before_replay() -> void:
	var game := (
		PlayGame
		. from_save(
			{
				"seed": 5,
				"actions": [["end"]],
				"field_library": "res://tests/fixtures/no-such-field-library.json",
				"field_library_sha256": "1234",
			}
		)
	)
	assert_string_contains(game.load_error, "missing")
	assert_null(game.session)
	assert_eq(game.actions, [])


func test_field_save_rejects_changed_library_before_replay() -> void:
	var game := (
		PlayGame
		. from_save(
			{
				"seed": 5,
				"actions": [["end"]],
				"field_library": "res://project.godot",
				"field_library_sha256": "00000000000000000000000000000000",
			}
		)
	)
	assert_string_contains(game.load_error, "changed")
	assert_null(game.session)
	assert_eq(game.actions, [])


func test_field_save_requires_both_reference_fields() -> void:
	for reference: Dictionary in [
		{"field_library": "res://project.godot"},
		{"field_library_sha256": "1234"},
		{"field_library": 42, "field_library_sha256": "1234"},
	]:
		var saved: Dictionary = {"seed": 5, "actions": []}
		saved.merge(reference)
		var game := PlayGame.from_save(saved)
		assert_ne(game.load_error, "")
		assert_null(game.session)


func test_field_save_keeps_mode_and_replays_actions() -> void:
	var game := PlayGame.start(5, FieldTestData.path())
	assert_eq(game.load_error, "")
	assert_not_null(game.session)
	if game.session == null:
		return
	var state: Dictionary = game.session.get_state()
	if str(state["phase"]) == "hero_choice":
		assert_eq(game.run(PackedStringArray(["choose", "0"])), "")
	assert_eq(game.run(PackedStringArray(["end"])), "")
	var saved: Dictionary = game.to_save()
	assert_eq(saved["field_library"], FieldTestData.path())
	assert_eq(saved["field_library_sha256"], FileAccess.get_sha256(FieldTestData.path()))
	var replayed := PlayGame.from_save(saved)
	assert_eq(replayed.load_error, "")
	assert_not_null(replayed.session)
	if replayed.session != null:
		assert_eq(replayed.session.get_state(), game.session.get_state())
		assert_eq(replayed.session._config.get_string("opponents"), "field")


func test_field_strength_dial_survives_save_and_replay() -> void:
	var game := PlayGame.start(5, FieldTestData.path(), "all")
	assert_eq(game.load_error, "")
	assert_eq(game.session._config.get_string("field_strength"), "all")
	var saved: Dictionary = game.to_save()
	assert_eq(saved["field_strength"], "all")
	var loaded := PlayGame.from_save(saved)
	assert_eq(loaded.load_error, "")
	assert_eq(loaded.session._config.get_string("field_strength"), "all")
	assert_eq(loaded.session.get_state(), game.session.get_state())
