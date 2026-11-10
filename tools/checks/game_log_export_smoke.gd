extends SceneTree
## Mount the actual exported Linux pack with the editor (templates ignore --script):
##   godot --headless --main-pack <pack> -s <this script> -- <commit> <log directory>
## Plays a full CorePort game and writes the same record as the UI's GameRecordLog hook.
## Then use tools/play/play.sh replay-log <printed path> from that source commit.

const CorePort := preload("res://src/ui/adapter/core_port.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var baked: String = str(ProjectSettings.get_setting("application/config/build_commit", ""))
	if args.size() != 2 or baked == "":
		printerr("Mount an exported pack with --main-pack and pass -- <commit> <log directory>")
		quit(2)
		return
	if GameRecordLog.build_id() != args[0]:
		printerr("Export build mismatch: expected %s, got %s" % [args[0], GameRecordLog.build_id()])
		quit(1)
		return
	var port := CorePort.new()
	port.setup(GameConfig.full_game())
	var problem: String = port.new_game(29)
	var actions: Array = []
	for step: int in 61:
		if problem != "" or port.is_over():
			break
		var method: String = "choose" if step == 0 else "end_turn"
		var values: Array = [0] if step == 0 else []
		var words: Array = GameRecordLog.words(method, values, port.get_state())
		problem = port.callv(method, values)
		if problem == "":
			actions.append(words)
	if problem != "" or not port.is_over() or port.get_state().get("placement") == null:
		printerr("Export game did not finish: %s" % problem)
		quit(1)
		return
	var path: String = GameRecordLog.write(port, actions, args[1])
	if path == "":
		printerr("Export game log could not be written")
		quit(1)
		return
	print("Export game log: %s" % path)
	print("Build: %s" % GameRecordLog.build_id())
	print("Final state hash: %s" % JSON.stringify(port.get_state(), "", true).sha256_text())
	quit(0)
