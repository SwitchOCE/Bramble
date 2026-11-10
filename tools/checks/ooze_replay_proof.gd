extends SceneTree
## Export the existing frozen replay bytes without rerecording or repinning any fixture.
## Run under godot_slot.sh with -- <output-directory>; compare before/after files byte for byte.

const FrozenContent := preload("res://tests/core/field_frozen_content.gd")
var _output: String
var _rows: Array[Dictionary] = []
var _fights: Array = []
var _keys: Array = []
var _library: UnitLibrary
var _has_oozes: bool = false


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(2)
		return
	_output = args[0]
	DirAccess.make_dir_recursive_absolute(_output)
	_normal_games()
	_pool_fights()
	_legacy_fights()
	var file := FileAccess.open(_output.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(_rows, "\t", true, true) + "\n")
	print("Frozen replay proof: ", _rows.size(), " unchanged fixture hashes")
	quit()


func _normal_games() -> void:
	var frozen := FrozenContent.new()
	frozen.setup("res://tests/fixtures/field/content-0946909.json")
	_library = frozen.library
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/field/normal-a35-dial-bots.json")
	)
	for recorded: Dictionary in fixture["games"]:
		var source: Dictionary = recorded["config"]
		_keys = source.keys()
		var session := GameSession.create(
			CoreUtil.to_int(recorded["seed"]), _library, FightCapture.config_for(source)
		)
		_fights.clear()
		_has_oozes = false
		session.fight_capture_observer = _remember
		session._rules.shop_observer = _shop
		for player: PlayerState in session._players:
			_shop(player)
		while not session.is_over():
			assert(session.end_turn() == "")
		var game: Dictionary = {
			"fights": _fights.duplicate(true),
			"standings": session.get_standings(),
			"game_log": session.get_game_log(),
		}
		_save(
			"normal-%s" % recorded["seed"],
			FightCapture.canonical(game),
			str(recorded["sha256"]),
			_has_oozes
		)
		session._rules.shop_observer = Callable()
		session.fight_capture_observer = Callable()
	frozen.restore()


func _remember(input: Dictionary, result: Dictionary, _combat: Combat) -> void:
	var normalized: Dictionary = input.duplicate(true)
	var config: Dictionary = normalized["config"]
	for key: String in config.keys():
		if key not in _keys:
			assert(GameConfig.defaults()._values.has(key) or Pass3Rates.defaults().has(key))
			config.erase(key)
	for board: Array in input["boards"]:
		_has_oozes = _has_oozes or _board_has_oozes(board)
	_fights.append({"input": normalized, "result": result.duplicate(true)})


func _shop(player: PlayerState) -> void:
	for unit: RecruitUnit in player.shop:
		_has_oozes = _has_oozes or unit.has_tribe("Oozes")


func _pool_fights() -> void:
	var config := GameConfig.full_game()
	config.set_value("scale_hero_spell_stats", false)
	config.set_value("fairies_fetch_share", 0.5)
	config.set_value("pass3_preset", "A")
	config.set_value("pass3_text_defaults", Pass3Rates.resolved(config))
	_library = ScaleOverlay.library_for(
		LegacyWave1.with_hedgerow(LegacyWave1.current_with_oozes()), config
	)
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass3_pool_replay.json")
	)
	for entry: Dictionary in fixture["cases"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = CoreUtil.to_int(entry["seed"])
		var combat := Combat.create(_library, config, rng)
		combat.side_rules = entry["side_rules"]
		var slots: Array = entry["slot_effects"]
		combat.slot_effects = slots.duplicate(true)
		for side: Array in combat.slot_effects:
			for effects: Array in side:
				for ring: Dictionary in effects:
					for field: String in ["attack", "health", "count"]:
						ring[field] = CoreUtil.to_int(ring[field])
		var boards: Array = entry["boards"]
		var result: Dictionary = combat.run(boards, [5, 5], [0, 1], 0)
		_save_combat("pool-%s" % entry["seed"], entry, result)


func _legacy_fights() -> void:
	_library = LegacyBog.library()
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass3_legacy_replay.json")
	)
	var index: int = 0
	for entry: Dictionary in fixture["cases"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = CoreUtil.to_int(entry["seed"])
		var combat := Combat.create(_library, GameConfig.defaults(), rng)
		combat.notes["test_pass3_start_order"] = false
		combat.side_rules = entry["side_rules"]
		var boards: Array = entry["boards"]
		var result: Dictionary = combat.run(boards, [5, 5], [0, 1], 0)
		_save_combat("legacy-%02d-%s" % [index, entry["seed"]], entry, result)
		index += 1


func _save_combat(name: String, entry: Dictionary, result: Dictionary) -> void:
	var boards: Array = entry["boards"]
	var first: Array = boards[0]
	var second: Array = boards[1]
	_save(
		name,
		JSON.stringify(result),
		str(entry["result"]).sha256_text(),
		_board_has_oozes(first) or _board_has_oozes(second)
	)


func _board_has_oozes(board: Array) -> bool:
	for spec: Variant in board:
		if spec == null:
			continue
		var unit: Dictionary = spec
		var card: Dictionary = _library.get_unit(str(unit["def_id"]))
		if "Oozes" in card.get("tribes", []):
			return true
		var held: Array = unit.get("held", [])
		if _board_has_oozes(held):
			return true
	return false


func _save(name: String, bytes: String, expected: String, has_oozes: bool) -> void:
	var digest: String = bytes.sha256_text()
	assert(digest == expected, "frozen replay changed: %s (%s != %s)" % [name, digest, expected])
	var file := FileAccess.open(_output.path_join(name + ".json"), FileAccess.WRITE)
	file.store_string(bytes)
	_rows.append({"name": name, "has_oozes": has_oozes, "sha256": digest})
