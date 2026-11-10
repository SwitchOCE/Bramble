extends SceneTree
## Compare complete eager/indexed field games on the unchanged real bundle.

var _fights: Array[String] = []


func _observe(input: Dictionary, _result: Dictionary, _combat: Combat) -> void:
	_fights.append(FieldLibrary.canonical(input).sha256_text())


func _play(field: FieldLibrary, units: UnitLibrary, game_seed: int) -> Dictionary:
	var config := GameConfig.full_game()
	var header: Dictionary = field.data["config"]
	var restored: Dictionary = Pass3Rates.restore_values(header)
	for key: String in restored:
		if key not in FieldLibrary.RUNTIME_KEYS:
			config.set_value(key, restored[key])
	config.set_value("human_bot", "hard")
	config.set_value("opponents", "field")
	config.set_value("field_library", "same-source-bundle")
	var session := GameSession.create(game_seed, units, config, Bot.create, field)
	assert(session != null)
	_fights.clear()
	session.fight_capture_observer = _observe
	var boards: Array[String] = []
	while not session.is_over():
		var round_frames: Array = []
		for id: int in session._field.frames:
			round_frames.append({"seat": id, "frame": session._field.frames[id]})
		boards.append(FieldLibrary.canonical(round_frames).sha256_text())
		assert(session.end_turn() == "")
	return {
		"boards": boards,
		"fights": _fights.duplicate(),
		"switches": session._field.switches.duplicate(true),
		"history": session._field.history.duplicate(true),
		"standings": session.get_standings()
	}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() == 1, "expected unchanged gzip library path")
	var units := UnitLibrary.load_dir()
	var packed: PackedByteArray = FileAccess.get_file_as_bytes(args[0])
	var eager := FieldLibrary.new()
	eager.data = JSON.parse_string(
		packed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8()
	)
	assert(eager._validate(units) == "")
	var indexed := FieldLibrary.read(args[0], units)
	if indexed.error != "":
		printerr(indexed.error)
		quit(1)
		return
	for game_seed: int in [71, 191, 280001]:
		var before: Dictionary = _play(eager, units, game_seed)
		var after: Dictionary = _play(indexed, units, game_seed)
		if FieldLibrary.canonical(before) != FieldLibrary.canonical(after):
			printerr("replay mismatch for seed %d" % game_seed)
			quit(1)
			return
		var boards: Array = before["boards"]
		var fights: Array = before["fights"]
		var switches: Array = before["switches"]
		print(
			(
				"lazy-equivalence: "
				+ JSON.stringify(
					{
						"seed": game_seed,
						"rounds": boards.size(),
						"fights": fights.size(),
						"switches": switches.size(),
						"trace_sha256": FieldLibrary.canonical(before).sha256_text()
					}
				)
			)
		)
	print("lazy-equivalence: bundle_sha256=" + FileAccess.get_sha256(args[0]))
	quit(0)
