extends SceneTree
## Engine half of ghost_core.sh.

const GAMES: int = 24
const FIRST_SEED: int = 3100
const MADE: String = "2026-11-20T12:00:00Z"
const PLAYER: String = "local-player"
const LABEL: String = "local-proof"

var _out: String
var _field: GhostStore
var _ids: Array[String] = []
var _opponents: Array[GhostRun] = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("ghost_core: expected an output directory")
		quit(2)
		return
	_out = args[0]
	_field = GhostStore.new(_out.path_join("rust-field"))
	quit(0 if _check_store() and _play_games() else 1)


func _check_store() -> bool:
	var infos: Array[Dictionary] = _field.find()
	if infos.size() != 8 or _field.error != "":
		return _fail("expected eight Rust-indexed runs: %s" % _field.error)
	var copy := GhostStore.new(_out.path_join("gd-field"))
	var content: GameContent = GameContent.load_default()
	# Write in the opposite order to exercise sorting independently of index order.
	for index: int in range(infos.size() - 1, -1, -1):
		var info: Dictionary = infos[index]
		var id: String = info["id"]
		var fetched: Dictionary = _field.fetch(id, content.library, content.registry)
		if not fetched["ok"] or fetched["info"] != info:
			return _fail("Rust run and index differ for %s" % id)
		var path: String = _field.directory.path_join("runs").path_join(id.left(2))
		if copy.add(FileAccess.get_file_as_bytes(path.path_join(id + ".json"))) != id:
			return _fail(copy.error)
		_ids.append(id)
		_opponents.append(fetched["run"])
	var cases: Array[Dictionary] = [
		{"seed": 47, "labels": [], "placement": null, "exclude": []},
		{"seed": -8172, "labels": ["flow", "random"], "placement": [1, 7], "exclude": []},
		{"seed": 20261120, "labels": [], "placement": null, "exclude": [_ids[2]]},
		{"seed": 5, "labels": ["flow"], "placement": null, "exclude": []},
	]
	var results: Array[Dictionary] = []
	for entry: Dictionary in cases:
		var rules: String = infos[0]["rules_hash"]
		var seed_value: int = entry["seed"]
		var excluded: Dictionary = {}
		for id: String in entry["exclude"]:
			excluded[id] = true
		entry["rules_hash"] = rules
		var expected: Dictionary = LocalMatchmaker.pick(
			_field, rules, entry, excluded, Rng.new(seed_value)
		)
		var actual: Dictionary = LocalMatchmaker.pick(
			copy, rules, entry, excluded, Rng.new(seed_value)
		)
		if expected != actual:
			return _fail("matchmaker differs with reversed index order")
		results.append(actual)
	if copy.rebuild_index() != infos.size():
		return _fail(copy.error)
	return (
		_write("cases.json", JSON.stringify(cases))
		and _write("gd-picks.json", JSON.stringify(results, "", false))
	)


func _play_games() -> bool:
	var content: GameContent = GameContent.load_default()
	GameRecord.directory = _out.path_join("raw")
	var store := GhostStore.new(_out.path_join("gd-players"))
	var manifest: PackedStringArray = []
	var ended: Dictionary = {}
	for index: int in GAMES:
		var seed_value: int = FIRST_SEED + index
		var lobby: Dictionary[int, GhostRun] = {}
		for seat: int in range(1, 8):
			lobby[seat] = _opponents[(index + seat - 1) % _opponents.size()]
		var game: GameSession = content.new_async_session(seed_value, lobby)
		game.keep_fight_events = false
		if index % 6 == 0:
			game.config.round_limit = 1
		var stream: Rng = Rng.derive(seed_value, "bot:0")
		var bot: Bot = FlowBot.new(stream)
		if index % 2 != 0:
			bot = RandomBot.new(stream)
		while not game.over:
			game.start_round()
			if game.player(0).alive:
				bot.take_turn(game, 0)
			game.finish_round()
			game.events.clear()
			game.fights.clear()
		if bot.refused != 0:
			return _fail("seed %d: bot refused %s" % [seed_value, bot.last_refusal])
		var cut: Dictionary = GhostRunWriter.cut(game.record, MADE, PLAYER, LABEL, _field)
		if not cut["ok"]:
			return _fail("seed %d: %s" % [seed_value, cut["message"]])
		var bytes: PackedByteArray = cut["bytes"]
		var id: String = store.add(bytes)
		if id != cut["id"]:
			return _fail(store.error)
		var fetched: Dictionary = store.fetch(id)
		var info: Dictionary = fetched.get("info", {})
		var reason: String = str(info.get("ended", ""))
		ended[reason] = CoreUtil.to_int(ended.get(reason, 0)) + 1
		# Copy the source bytes into the Rust cutter's match layout.
		var path: String = "records/game-%05d.jsonl" % index
		var record_bytes: PackedByteArray = FileAccess.get_file_as_bytes(game.record.path)
		if not _write_bytes(path, record_bytes):
			return false
		manifest.append(
			JSON.stringify(
				{
					"game": index,
					"seed": str(seed_value),
					"seats": [{"seat": 0, "player": PLAYER, "label": LABEL}]
				}
			)
		)

	print("ghost_core: wrote %d finished async player runs %s" % [GAMES, ended])
	return _write("games.jsonl", "\n".join(manifest) + "\n")


func _write(path: String, content: String) -> bool:
	return _write_bytes(path, content.to_utf8_buffer())


func _write_bytes(path: String, bytes: PackedByteArray) -> bool:
	var file: FileAccess = FileAccess.open(_out.path_join(path), FileAccess.WRITE)
	if file == null:
		return _fail("cannot open %s" % path)
	file.store_buffer(bytes)
	file.flush()
	return file.get_error() == OK or _fail("cannot write %s" % path)


func _fail(message: String) -> bool:
	printerr("ghost_core: %s" % message)
	return false
