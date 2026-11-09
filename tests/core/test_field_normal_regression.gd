extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const FrozenContent := preload("res://tests/core/field_frozen_content.gd")

var _fights: Array = []
var _keys: Array = []
var _frozen: FrozenContent


func before_each() -> void:
	_frozen = FrozenContent.new()
	_frozen.setup()


func after_each() -> void:
	_frozen.restore()


func test_normal_lobby_matches_complete_games_captured_at_9af89c2() -> void:
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/field/normal-9af89c2.json")
	)
	assert_eq(fixture["source_commit"], "9af89c2")
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
	# Compare the original complete config; the only excluded keys are the new mode controls.
	var config: Dictionary = normalized["config"]
	for key: String in config.keys():
		if key not in _keys:
			assert_true(key in ["opponents", "field_library", "field_strength"])
			config.erase(key)
	_fights.append({"input": normalized, "result": result.duplicate(true)})
