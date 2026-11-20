class_name RecordReplay
extends RefCounted
## Rebuilds a local record through the same rules, without running bots or writing another record.
## Returns the rebuilt session, checkpoint count, completion status, or the FIRST differing turn.


static func read(path: String, store: GhostStore = null) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure(0, "cannot open %s" % path)
	var decoded: Dictionary = decode(file.get_buffer(file.get_length()))
	if not decoded["ok"]:
		return decoded
	var entries: Array[Dictionary] = decoded["entries"]
	return rebuild(entries, store)


## Decode the exact saved bytes. The writer also hashes these bytes for the run source.
static func decode(bytes: PackedByteArray) -> Dictionary:
	var contents: String = bytes.get_string_from_utf8()
	if contents.to_utf8_buffer() != bytes:
		return _failure(0, "record must be UTF-8")
	var lines: PackedStringArray = contents.split("\n")
	if lines[-1].is_empty():
		lines.resize(lines.size() - 1)
	var entries: Array[Dictionary] = []
	for line: String in lines:
		var json := JSON.new()
		if json.parse(line) != OK or not json.data is Dictionary:
			return _failure(0, "invalid JSON at line %d" % (entries.size() + 1))
		entries.append(CoreUtil.to_dict(json.data))
	return {"ok": true, "entries": entries}


## observe, when supplied, sees each verified entry and the game after applying it.
static func rebuild(
	entries: Array[Dictionary], store: GhostStore = null, observe: Callable = Callable()
) -> Dictionary:
	if entries.is_empty():
		return _failure(0, "empty record")
	var header: Dictionary = entries[0]
	if header.get("op") != "header":
		return _failure(0, "missing record header")
	var format: int = CoreUtil.to_int(header.get("format", 0))
	if format != GameRecord.FORMAT:
		return _failure(
			0,
			(
				"unsupported record format %d (expected %d); use the build that wrote the record"
				% [format, GameRecord.FORMAT]
			)
		)
	var build: Dictionary = CoreUtil.to_dict(header.get("build", {}))
	if build.get("rules_hash") != RecordBuild.identity()["rules_hash"]:
		return _failure(0, "build differs; use the build that wrote the record")
	var made: Dictionary = _create(header)
	if not CoreUtil.to_bool(made.get("ok", false)):
		return made
	var game: GameSession = made["session"]
	var loaded: Dictionary = _load_runs(header, game, store)
	if not CoreUtil.to_bool(loaded["ok"]):
		return loaded
	return _replay(entries, game, observe)


static func _replay(entries: Array[Dictionary], game: GameSession, observe: Callable) -> Dictionary:
	if entries[0].get("initial_hash") != RecordState.state_hash(game):
		return _failure(0, "initial state differs")
	var phase: String = "between"
	var checkpoints: int = 0
	for index: int in range(1, entries.size()):
		var entry: Dictionary = entries[index]
		var checked: Dictionary = _step(game, entry, phase)
		if not CoreUtil.to_bool(checked.get("ok", false)):
			return checked
		phase = str(checked["phase"])
		if entry.get("op") in ["start", "fight_boards", "finish"]:
			if str(entry.get("hash", "")) != RecordState.state_hash(game):
				return _failure(game.round_number, "state hash differs at %s" % entry["op"])
		if observe.is_valid():
			observe.call(entry, game)
		if entry.has("hash"):
			checkpoints += 1
	return {
		"ok": true,
		"session": game,
		"turns": game.round_number,
		"checkpoints": checkpoints,
		"complete": game.over and phase == "between"
	}


static func _load_runs(header: Dictionary, game: GameSession, store: GhostStore) -> Dictionary:
	var mode: Variant = header.get("mode")
	if mode not in ["live", "async"] or not header.get("runs") is Array:
		return _failure(0, "invalid mode or runs in header")
	var entries: Array = header["runs"]
	if entries.is_empty() != (mode == "live"):
		return _failure(0, "record mode disagrees with its run seats")
	var runs: Dictionary[int, GhostRun] = {}
	for raw: Variant in entries:
		var entry: Dictionary = CoreUtil.to_dict(raw)
		var seat: int = CoreUtil.to_int(entry.get("seat", -1))
		var id: String = str(entry.get("id", ""))
		if (
			not entry.get("id") is String
			or entry.get("seat") != seat
			or seat <= 0
			or seat >= game.players.size()
			or runs.has(seat)
		):
			return _failure(0, "invalid or repeated seat for run %s" % id)
		if store == null:
			return _failure(0, "no ghost store for run %s" % id)
		var fetched: Dictionary = store.fetch(id, game.library, game.registry)
		if not CoreUtil.to_bool(fetched["ok"]):
			return _failure(0, str(fetched["message"]))
		runs[seat] = fetched["run"]
	if game.set_runs(runs) != OK:
		return _failure(0, "run seats require a standard board")
	return {"ok": true}


static func _create(header: Dictionary) -> Dictionary:
	var recipe: Dictionary = CoreUtil.to_dict(header.get("recipe", {}))
	var paths := PackedStringArray(CoreUtil.to_array(recipe.get("paths", [])))
	for index: int in paths.size():
		paths[index] = content_folder(paths[index])
	var tribes := PackedStringArray(CoreUtil.to_array(recipe.get("tribes", [])))
	var config := GameConfig.new()
	var saved: Dictionary = CoreUtil.to_dict(header.get("config", {}))
	for key: String in RecordState.fields(config):
		if not saved.has(key):
			return _failure(0, "missing config %s" % key)
		var old: Variant = config.get(key)
		if old is Array:
			var target: Array = old
			target.assign(CoreUtil.to_array(saved[key]))
		else:
			config.set(key, CoreUtil.to_int(saved[key]))
	var seed_text: String = str(header.get("seed", ""))
	if not seed_text.is_valid_int():
		return _failure(0, "invalid seed")
	var game: GameSession
	if recipe.get("kind") == "game":
		var content: GameContent = GameContent.load_folders(paths)
		if not content.errors.is_empty():
			return _failure(0, "content failed to load: %s" % content.errors)
		game = GameSession.create(
			seed_text.to_int(), content.library, content.registry, config, tribes
		)
		for standing: StringName in content.standing_for(tribes):
			game.give_standing(standing)
	elif recipe.get("kind") == "core":
		var content: ContentSet = ContentSet.load_folders(paths)
		if not content.errors.is_empty():
			return _failure(0, "content failed to load: %s" % content.errors)
		game = content.session(seed_text.to_int(), config, tribes)
		game.record_recipe = {}
	else:
		return _failure(0, "unknown content recipe")
	game.keep_fight_events = false
	return {"ok": true, "session": game}


## Resolve shipped content in the local build whose fingerprint replay just checked.
static func content_folder(path: String) -> String:
	var normalized: String = path.replace("\\", "/").trim_suffix("/")
	if normalized.get_base_dir().ends_with("/src/content"):
		var local: String = ContentSet.ROOT.path_join(normalized.get_file())
		if FileAccess.file_exists(local.path_join("tribe.json")):
			return local
	return path


static func _step(game: GameSession, entry: Dictionary, phase: String) -> Dictionary:
	var op: String = str(entry.get("op", ""))
	var turn: int = CoreUtil.to_int(entry.get("turn", -1))
	if op not in ["start", "act", "end", "fight_boards", "finish"]:
		return _failure(turn, "unknown operation %s" % op)
	var expected_turn: int = game.round_number + (1 if op == "start" else 0)
	if turn != expected_turn or game.over:
		return _failure(turn, "unexpected turn at %s" % op)
	var next: String = phase
	match op:
		"start":
			if phase != "between":
				return _failure(turn, "start before previous turn finished")
			game.start_round()
			next = "recruit"
		"act", "end":
			if phase != "recruit":
				return _failure(turn, "action outside recruit")
			var player: int = CoreUtil.to_int(entry.get("player", -1))
			if player < 0 or player >= game.players.size() or game.runs.has(player):
				return _failure(turn, "invalid player")
			if op == "end":
				game.end_turn(player)
			else:
				var result: String = game.act(player, CoreUtil.to_dict(entry.get("action", {})))
				if result != str(entry.get("result", "")):
					return _failure(
						turn, "action result differs for player %d: %s" % [player, result]
					)
		"fight_boards":
			if phase != "recruit":
				return _failure(turn, "fight boards outside recruit")
			var run_boards: Array[Dictionary] = game._prepare_fight_boards()
			if (
				JSON.stringify(RecordState.value(entry.get("players")))
				!= JSON.stringify(RecordState.fight_players(game))
			):
				return _failure(turn, "fight boards differ")
			if not game.runs.is_empty() or entry.has("run_boards"):
				if (
					JSON.stringify(RecordState.value(entry.get("run_boards")))
					!= JSON.stringify(run_boards)
				):
					return _failure(turn, "run boards differ")
			next = "fight"
		"finish":
			if phase != "fight":
				return _failure(turn, "finish without fight boards")
			game._resolve_fights()
			if game.over != CoreUtil.to_bool(entry.get("over", false)):
				return _failure(turn, "game completion differs")
			next = "between"
		_:
			return _failure(turn, "unknown operation %s" % op)
	return {"ok": true, "phase": next}


static func _failure(turn: int, message: String) -> Dictionary:
	return {"ok": false, "turn": turn, "message": "first differing turn %d: %s" % [turn, message]}
