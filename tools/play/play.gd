extends SceneTree
## Plays the real game by commands, one call per action. Usage and commands: tools/play/README.md.
## Stateless: the save is a seed, a difficulty and an action list, replayed on every call.
## play.sh resolves the save's path; run through it, not this script directly.


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var as_json: bool = args.has("--json")
	if as_json:
		args.remove_at(args.find("--json"))
	quit(_main(args, as_json))


func _main(args: PackedStringArray, as_json: bool) -> int:
	if args.is_empty():
		print("Usage: play.sh new --seed N --difficulty naive|easy|normal|hard [--save path]")
		print("       play.sh <save> [show|log|buy N|play N [slot]|move A B|sell S|swallow W S|")
		print("                       refresh|freeze|tier|power [slot]|choose N|end] [--json]")
		return 2
	if args[0] == "new":
		return _new(args.slice(1), as_json)
	return _act(args[0], args.slice(1), as_json)


func _new(args: PackedStringArray, as_json: bool) -> int:
	var game_seed: int = _option(args, "--seed", str(randi_range(1, 99999))).to_int()
	var level: String = _option(args, "--difficulty", "normal")
	if not BotLevel.ALL.has(level):
		print("Difficulty must be naive, easy, normal or hard")
		return 2
	var path: String = _option(args, "--save", "")
	if path == "":
		print("play.gd needs --save (play.sh picks one)")
		return 2
	var game := PlayGame.start(game_seed, level)
	if not _write(path, game):
		return 1
	_show(game, "Save: %s" % path, as_json)
	return 0


func _act(path: String, words: PackedStringArray, as_json: bool) -> int:
	var text: String = FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		print("No save at %s" % path)
		return 1
	var saved: Dictionary = data
	var game := PlayGame.from_save(saved)
	if words.is_empty() or words[0] == "show":
		_show(game, "", as_json)
		return 0
	if words[0] == "log":
		print(PlayView.log_text(game))
		return 0
	var problem: String = game.run(words)
	if problem != "":
		_show(game, "REFUSED: %s" % problem, as_json)
		return 3
	if not _write(path, game):
		return 1
	_show(game, "", as_json)
	return 0


func _show(game: PlayGame, message: String, as_json: bool) -> void:
	print(PlayView.json(game, message) if as_json else PlayView.text(game, message))


func _write(path: String, game: PlayGame) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("Can't write %s" % path)
		return false
	file.store_string(JSON.stringify(game.to_save()))
	return true


static func _option(args: PackedStringArray, name: String, fallback: String) -> String:
	var index: int = args.find(name)
	return args[index + 1] if index >= 0 and index + 1 < args.size() else fallback
