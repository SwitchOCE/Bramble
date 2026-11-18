extends SceneTree
## Dumps the JSON a state hash is computed from: -- seed=<n> [rounds=<n>] out=<file>


func _initialize() -> void:
	var opts: Dictionary = {"seed": "1", "rounds": "0", "out": "res://build/league/state.json"}
	for arg: String in OS.get_cmdline_user_args():
		opts[arg.get_slice("=", 0)] = arg.substr(arg.get_slice("=", 0).length() + 1)
	var content: GameContent = GameContent.load_default()
	var game: GameSession = content.new_session(str(opts["seed"]).to_int())
	var text: String = JSON.stringify(RecordState.session_state(game))
	var file := FileAccess.open(str(opts["out"]), FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("hash ", text.sha256_text(), " bytes ", text.length())
	quit(0)
