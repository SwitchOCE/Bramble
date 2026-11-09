extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const FrozenContent := preload("res://tests/core/field_frozen_content.gd")

var _fights: Array = []
var _keys: Array = []
var _frozen: FrozenContent


func before_each() -> void:
	_frozen = FrozenContent.new()
	_frozen.setup("res://tests/fixtures/field/content-0946909.json")


func after_each() -> void:
	_frozen.restore()


func test_normal_lobby_matches_complete_games_captured_at_0946909() -> void:
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/field/normal-0946909.json")
	)
	assert_eq(fixture["source_commit"], "0946909")
	var library: UnitLibrary = _frozen.library
	for recorded: Dictionary in fixture["games"]:
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
			FightCapture.canonical(game).sha256_text(),
			str(recorded["sha256"]),
			"all inputs, all raw results/events, standings and log match seed %s" % recorded["seed"]
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
