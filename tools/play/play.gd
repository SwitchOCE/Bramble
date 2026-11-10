extends SceneTree
## Plays the real game by commands, one call per action. Usage and commands: tools/play/README.md.
## Stateless: the save is a seed and an action list, replayed on every call.
## play.sh resolves the save's path; run through it, not this script directly.


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var as_json: bool = args.has("--json")
	if as_json:
		args.remove_at(args.find("--json"))
	quit(_main(args, as_json))


func _main(args: PackedStringArray, as_json: bool) -> int:
	if args.is_empty():
		print("Usage: play.sh new --seed N [--save path] [--field-library path] [--variant X|Y]")
		print("       play.sh <save> [show|log|buy N|play N [slot]|move A B|sell S|swallow W S|")
		print("                       refresh|freeze|tier|power [slot]|choose N|end] [--json]")
		print("       play.sh <save> reveal          (orchestrator: a blind save's preset)")
		print("       play.sh replay-log <game log> [--save path] [--field-library path]")
		return 2
	if args[0] == "help":
		print(PlayView.how_to_play())
		return 0
	if args[0] == "new":
		return _new(args.slice(1), as_json)
	if args[0] == "replay-log":
		return _replay_log(args.slice(1), as_json)
	return _act(args[0], args.slice(1), as_json)


func _new(args: PackedStringArray, as_json: bool) -> int:
	if not args.has("--seed"):
		args.append_array(["--seed", str(randi_range(1, 99999))])
	if args.has("--difficulty"):
		print("Bot settings were retired. New games use the full-strength lobby.")
		return 2
	var path: String = _option(args, "--save", "")
	if path == "":
		print("play.gd needs --save (play.sh picks one)")
		return 2
	if args.has("--field-library") and _option(args, "--field-library", "") == "":
		print("--field-library needs a path")
		return 2
	var game: PlayGame = _start(args)
	if game.load_error != "":
		print("Cannot start game: %s" % game.load_error)
		return 2
	if not _write(path, game):
		return 1
	_show(game, "Save: %s" % path, as_json)
	return 0


## The new game the options ask for; a refused one carries load_error.
func _start(args: PackedStringArray) -> PlayGame:
	var game_seed: int = _option(args, "--seed", "0").to_int()
	var field_path: String = _option(args, "--field-library", "")
	var strength: String = _option(args, "--field-strength", "top4")
	if not args.has("--variant"):
		return PlayGame.start(game_seed, field_path, strength)
	var variant: String = _option(args, "--variant", "").to_upper()
	var entry: Dictionary = PlayVariant.lookup(variant)
	var refused := PlayGame.new()
	if entry.has("error"):
		refused.load_error = entry["error"]
		return refused
	if str(entry["field_library"]) != "":
		if field_path != "":
			refused.load_error = "the variant map names the field library; drop --field-library"
			return refused
		field_path = entry["field_library"]
		strength = entry["field_strength"]
	return PlayGame.start(game_seed, field_path, strength, entry["preset"], variant)


func _act(path: String, words: PackedStringArray, as_json: bool) -> int:
	var text: String = FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		print("No save at %s" % path)
		return 1
	var saved: Dictionary = data
	var game := PlayGame.from_save(saved)
	if game.load_error != "":
		print("Cannot replay save: %s" % game.load_error)
		return 2
	return _act_loaded(game, path, words, as_json)


func _act_loaded(game: PlayGame, path: String, words: PackedStringArray, as_json: bool) -> int:
	if words.is_empty() or words[0] == "show":
		_show(game, game.replay_note, as_json)
		return 0
	var report: String = _report(game, words[0])
	if report != "":
		print(report)
		return 0
	var problem: String = game.run(words)
	if problem != "":
		_show(game, "REFUSED: %s" % problem, as_json)
		return 3
	if not _write(path, game):
		return 1
	_show(game, game.replay_note, as_json)
	return 0


## What a read-only word prints; "" if it's an action.
static func _report(game: PlayGame, word: String) -> String:
	match word:
		"help":
			return PlayView.how_to_play()
		"log":
			return PlayView.log_text(game)
		"reveal":
			return PlayVariant.reveal(game)
		"hash":
			return game.state_hash()
	return ""


## A game log from the UI (src/ui/game_record_log.gd), replayed and kept as a save.
func _replay_log(args: PackedStringArray, as_json: bool) -> int:
	if args.is_empty() or args[0].begins_with("--"):
		print("replay-log needs a game log file")
		return 2
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if typeof(data) != TYPE_DICTIONARY:
		print("No game log at %s" % args[0])
		return 1
	var game: PlayGame = _from_log(data, _option(args, "--field-library", ""))
	if game.load_error != "":
		print("Cannot replay log: %s" % game.load_error)
		return 2
	var path: String = _option(args, "--save", "")
	var note: String = (
		"Replayed %d actions. State hash %s" % [game.actions.size(), game.state_hash()]
	)
	if path != "":
		if not _write(path, game):
			return 1
		note += "\nSave: %s" % path
	_show(game, note, as_json)
	return 0


static func _from_log(record: Dictionary, field_override: String) -> PlayGame:
	var saved: Dictionary = GameRecordLog.to_save(record, field_override)
	if saved.has("error"):
		var refused := PlayGame.new()
		refused.load_error = saved["error"]
		return refused
	var game := PlayGame.from_save(saved)
	if game.load_error != "":
		return game
	var hero_id: String = GameRecordLog.hero_id(game.session.get_state())
	if str(record.get("hero", "")) != hero_id:
		game.load_error = "it names hero %s, the replay has %s" % [record.get("hero"), hero_id]
	return game


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
