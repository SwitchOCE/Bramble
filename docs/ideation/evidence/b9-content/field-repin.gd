extends SceneTree
## Reproduce the complete-game regression, preserving its config and gameplay projection.

const FrozenContent := preload("res://tests/core/field_frozen_content.gd")
const ReplayContract := preload("res://tests/core/replay_contract.gd")
var _fights: Array = []
var _keys: Array = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() in [1, 2], "provide an output directory and optional seed")
	var output: String = args[0]
	DirAccess.make_dir_recursive_absolute(output)
	var frozen := FrozenContent.new()
	frozen.setup("res://tests/fixtures/field/content-0946909.json")
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/field/normal-a35-dial-bots.json")
	)
	var manifest: Array[Dictionary] = []
	for recorded: Dictionary in fixture["games"]:
		if args.size() == 2 and CoreUtil.to_int(recorded["seed"]) != args[1].to_int():
			continue
		var source: Dictionary = recorded["config"]
		_keys = source.keys()
		var seed_number: int = CoreUtil.to_int(recorded["seed"])
		var session := GameSession.create(
			seed_number, frozen.library, FightCapture.config_for(source)
		)
		_fights.clear()
		session.fight_capture_observer = _remember
		while not session.is_over():
			assert(session.end_turn() == "")
		var game: Dictionary = {
			"fights": _fights.duplicate(true),
			"standings": session.get_standings(),
			"game_log": session.get_game_log()
		}
		var bytes: String = FightCapture.canonical(ReplayContract.gameplay(game))
		var file := FileAccess.open(output.path_join("%d.json" % seed_number), FileAccess.WRITE)
		file.store_string(bytes)
		(
			manifest
			. append(
				{
					"seed": seed_number,
					"fight_count": _fights.size(),
					"sha256": bytes.sha256_text(),
					"previous_fight_count": recorded["fight_count"],
					"previous_sha256": recorded["sha256"],
				}
			)
		)
		session.fight_capture_observer = Callable()
	frozen.restore()
	var manifest_file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, "\t", true, true) + "\n")
	print(JSON.stringify(manifest))
	quit()


func _remember(input: Dictionary, result: Dictionary, _combat: Combat) -> void:
	var normalized: Dictionary = input.duplicate(true)
	var config: Dictionary = normalized["config"]
	for key: String in config.keys():
		if key not in _keys:
			assert(GameConfig.defaults()._values.has(key) or Pass3Rates.defaults().has(key))
			config.erase(key)
	_fights.append({"input": normalized, "result": result.duplicate(true)})
