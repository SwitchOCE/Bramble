extends SceneTree
## Used by frozen_replay_proof.py on both archived and current runtimes.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const FrozenContent := preload("res://tests/core/field_frozen_content.gd")
var _fights: Array = []
var _keys: Array = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() == 1, "expected output path")
	var output: Dictionary = {"field": [], "pool": [], "legacy": []}
	_capture_field(output["field"])
	_capture_pool(output["pool"])
	_capture_legacy(output["legacy"])
	var file: FileAccess = FileAccess.open(args[0], FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(output, "", true, true))
	file.close()
	quit()


func _capture_field(rows: Array) -> void:
	var frozen: FrozenContent = FrozenContent.new()
	frozen.setup("res://tests/fixtures/field/content-0946909.json")
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/field/normal-067429a3.json")
	)
	for recorded: Dictionary in fixture["games"]:
		var source: Dictionary = recorded["config"]
		_keys = source.keys()
		var session: GameSession = GameSession.create(
			CoreUtil.to_int(recorded["seed"]), frozen.library, FightCapture.config_for(source)
		)
		_fights.clear()
		session.fight_capture_observer = _remember
		while not session.is_over():
			assert(session.end_turn() == "")
		var game: Dictionary = {
			"fights": _fights.duplicate(true),
			"standings": session.get_standings(),
			"game_log": session.get_game_log(),
		}
		rows.append(
			{"seed": recorded["seed"], "actual": game, "canonical": FightCapture.canonical(game)}
		)
	frozen.restore()


func _remember(input: Dictionary, result: Dictionary, _combat: Combat) -> void:
	var normalized: Dictionary = input.duplicate(true)
	var config: Dictionary = normalized["config"]
	for key: String in config.keys():
		if key not in _keys:
			assert(GameConfig.defaults()._values.has(key) or Pass3Rates.defaults().has(key))
			config.erase(key)
	_fights.append({"input": normalized, "result": result.duplicate(true)})


func _capture_pool(rows: Array) -> void:
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass3_pool_replay.json")
	)
	var config: GameConfig = GameConfig.full_game()
	config.set_value("scale_hero_spell_stats", false)
	config.set_value("fairies_fetch_share", 0.5)
	config.set_value("pass3_preset", "A")
	config.set_value("pass3_text_defaults", Pass3Rates.resolved(config))
	var library: UnitLibrary = ScaleOverlay.library_for(
		LegacyWave1.with_hedgerow(LegacyWave1.current_with_oozes()), config
	)
	for entry: Dictionary in fixture["cases"]:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = CoreUtil.to_int(entry["seed"])
		var combat: Combat = Combat.create(library, config, rng)
		combat.side_rules = entry["side_rules"]
		var slots: Array = entry["slot_effects"]
		combat.slot_effects = slots.duplicate(true)
		for side: Array in combat.slot_effects:
			for effects: Array in side:
				for ring: Dictionary in effects:
					for field: String in ["attack", "health", "count"]:
						ring[field] = CoreUtil.to_int(ring[field])
		var result: Dictionary = combat.run(entry["boards"], [5, 5], [0, 1], 0)
		rows.append({"seed": entry["seed"], "actual": result, "serialized": JSON.stringify(result)})


func _capture_legacy(rows: Array) -> void:
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass3_legacy_replay.json")
	)
	var library: UnitLibrary = LegacyBog.library()
	for entry: Dictionary in fixture["cases"]:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = CoreUtil.to_int(entry["seed"])
		var combat: Combat = Combat.create(library, GameConfig.defaults(), rng)
		combat.notes["test_pass3_start_order"] = false
		combat.side_rules = entry["side_rules"]
		var result: Dictionary = combat.run(entry["boards"], [5, 5], [0, 1], 0)
		rows.append({"seed": entry["seed"], "actual": result, "serialized": JSON.stringify(result)})
