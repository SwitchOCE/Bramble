extends GutTest
## CLI games always use the current lobby; old saves fail cleanly rather than changing levels.


func test_new_save_has_only_seed_and_actions_and_replays() -> void:
	var game: PlayGame = PlayGame.start(42)
	var saved: Dictionary = game.to_save()
	assert_eq(saved.keys(), ["seed", "actions"])
	var loaded: PlayGame = PlayGame.from_save(saved)
	assert_eq(loaded.load_error, "")
	assert_eq(loaded.to_save(), saved)
	for player: Dictionary in game.session.get_game_log()["players"]:
		if player["player_id"] != 0:
			assert_true(str(player["personality"]).begins_with("hard"))


func test_retired_save_settings_are_refused_without_starting_a_session() -> void:
	var game: PlayGame = PlayGame.from_save({"seed": 42, "difficulty": "easy", "actions": []})
	assert_string_contains(game.load_error, "retired bot rules")
	assert_null(game.session)


func test_legacy_full_strength_metadata_is_ignored_and_not_saved_again() -> void:
	var game: PlayGame = PlayGame.from_save({"seed": 42, "difficulty": "hard", "actions": []})
	assert_eq(game.load_error, "")
	assert_string_contains(game.replay_note, "ignored")
	assert_false(game.to_save().has("difficulty"))


func test_malformed_and_obsolete_actions_are_refused_without_engine_errors() -> void:
	for data: Dictionary in [{}, {"seed": 1, "actions": [3]}, {"seed": 1, "actions": [[5]]}]:
		assert_ne(PlayGame.from_save(data).load_error, "")
	var game: PlayGame = PlayGame.from_save({"seed": 1, "actions": [["retired_command"]]})
	assert_string_contains(game.load_error, "Saved action 1")
	assert_eq(game.actions, [])
