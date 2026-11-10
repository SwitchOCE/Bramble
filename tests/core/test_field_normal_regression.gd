extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const FrozenContent := preload("res://tests/core/field_frozen_content.gd")
const ReplayContract := preload("res://tests/core/replay_contract.gd")

var _fights: Array = []
var _keys: Array = []
var _frozen: FrozenContent


func before_each() -> void:
	_frozen = FrozenContent.new()
	_frozen.setup("res://tests/fixtures/field/content-0946909.json")


func after_each() -> void:
	_frozen.restore()


func test_normal_lobby_matches_complete_games_after_b9_sally_targeting() -> void:
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/field/normal-b9-content.json")
	)
	var baseline: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/field/normal-067429a3.json")
	)
	assert_eq(fixture["baseline_source_commit"], "067429a3")
	assert_eq(fixture["content_source_commit"], "0946909")
	assert_eq(fixture["source_parent_commit"], "9affb598")
	assert_eq(fixture["previous_fixture"], "res://tests/fixtures/field/normal-a35-dial-bots.json")
	assert_eq(
		fixture["source_patch"],
		(
			"Build 9 Sally targets the nearest unringed slot, occupied or empty; frozen content "
			+ "and original baseline configs retained."
		)
	)
	assert_eq(fixture["games"].size(), 4)
	var previous: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(str(fixture["previous_fixture"]))
	)
	var library: UnitLibrary = _frozen.library
	for index: int in 4:
		var recorded: Dictionary = fixture["games"][index]
		assert_eq(recorded["seed"], baseline["games"][index]["seed"])
		assert_eq(recorded["config"], baseline["games"][index]["config"])
		# Only seed 20261109 changes: R3 seat 4 Sally Rings occupied B1 instead of empty B2.
		# Reverting Sally targeting + its face restores the prior 59-fight hash exactly.
		# Evidence: docs/ideation/evidence/b9-content/field-repin.md.
		if CoreUtil.to_int(recorded["seed"]) != 20261109:
			assert_eq(recorded, previous["games"][index], "unaffected complete-game pin")
		var source: Dictionary = recorded["config"]
		var config := FightCapture.config_for(source)
		_keys = source.keys()
		var session := GameSession.create(CoreUtil.to_int(recorded["seed"]), library, config)
		_fights.clear()
		session.fight_capture_observer = _remember
		while not session.is_over():
			session.end_turn()
		var game: Dictionary = {
			"fights": _fights.duplicate(true),
			"standings": session.get_standings(),
			"game_log": session.get_game_log()
		}
		assert_eq(_fights.size(), CoreUtil.to_int(recorded["fight_count"]))
		assert_eq(
			FightCapture.canonical(ReplayContract.gameplay(game)).sha256_text(),
			str(recorded["sha256"]),
			"all gameplay inputs/results/events, standings and log match seed %s" % recorded["seed"]
		)


func _remember(input: Dictionary, result: Dictionary, _combat: Combat) -> void:
	var normalized: Dictionary = input.duplicate(true)
	# Compare the pinned complete config; newly introduced current config keys may use defaults.
	var config: Dictionary = normalized["config"]
	for key: String in config.keys():
		if key not in _keys:
			assert_true(
				GameConfig.defaults()._values.has(key) or Pass3Rates.defaults().has(key),
				"unknown config key: %s" % key
			)
			config.erase(key)
	_fights.append({"input": normalized, "result": result.duplicate(true)})
