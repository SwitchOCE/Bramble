extends SceneTree
## Exact RecordState JSON at header (op=0), inclusive JSONL op N, or end of turn T.
## -- record=/absolute/game.jsonl [op=N | turn=T] out=/absolute/state.json
## -- seed=42 out=/absolute/initial.json


func _initialize() -> void:
	var opts: Dictionary = {"seed": "1", "out": "res://.copies/state.json"}
	for arg: String in OS.get_cmdline_user_args():
		var split: int = arg.find("=")
		if split >= 0:
			opts[arg.substr(0, split)] = arg.substr(split + 1)
	var game: GameSession
	if opts.has("record"):
		var file := FileAccess.open(str(opts["record"]), FileAccess.READ)
		if file == null:
			_fail("cannot open record")
			return
		var entries: Array[Dictionary] = []
		while not file.eof_reached():
			var line: String = file.get_line()
			if line == "" and file.eof_reached():
				break
			var parsed: Variant = JSON.parse_string(line)
			if not parsed is Dictionary:
				_fail("invalid JSON at line %d" % (entries.size() + 1))
				return
			entries.append(parsed)
		if entries.is_empty():
			_fail("empty record")
			return
		var initial: Dictionary = RecordReplay.rebuild([entries[0]])
		if not CoreUtil.to_bool(initial.get("ok", false)):
			_fail(str(initial.get("message", "cannot rebuild header")))
			return
		game = initial["session"]
		var last: int = 0
		if opts.has("turn"):
			var wanted: int = str(opts["turn"]).to_int()
			for index: int in range(1, entries.size()):
				if CoreUtil.to_int(entries[index].get("turn", 0)) > wanted:
					break
				last = index
		elif opts.has("op"):
			last = str(opts["op"]).to_int()
		if last < 0 or last >= entries.size():
			_fail("op is outside the record")
			return
		var phase: String = "between"
		for index: int in range(1, last + 1):
			var checked: Dictionary = RecordReplay._step(game, entries[index], phase)
			if not CoreUtil.to_bool(checked.get("ok", false)):
				_fail(str(checked["message"]))
				return
			phase = str(checked["phase"])
	else:
		var content: GameContent = GameContent.load_default()
		if not content.errors.is_empty():
			_fail(str(content.errors))
			return
		game = content.new_session(str(opts["seed"]).to_int())
	var text: String = JSON.stringify(RecordState.session_state(game))
	var target: String = str(opts["out"])
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	var output := FileAccess.open(target, FileAccess.WRITE)
	if output == null:
		_fail("cannot open output %s" % target)
		return
	output.store_string(text)
	output.close()
	print("hash ", text.sha256_text(), " bytes ", text.to_utf8_buffer().size())
	quit(0)


func _fail(message: String) -> void:
	printerr(message)
	quit(1)
