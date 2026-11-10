extends SceneTree
## Repairs missing capture metadata only after proving the full event stream is identical.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const Replay := preload("res://tools/sim/fight_capture.gd")


func _initialize() -> void:
	var directory: String = OS.get_cmdline_user_args()[0]
	var first_path: String = directory.path_join("combat_mid_1688x780.json")
	var first: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(first_path))
	var config := GameConfig.full_game()
	config.set_value("human_bot", "tribe")
	var port := CorePort.new()
	port.setup(config)
	assert(port.new_game(CoreUtil.to_int(first["seed"])) == "")
	for round_number: int in 6:
		assert(port.end_turn() == "")
	var combat: Dictionary = port.get_last_combat()
	var input: Dictionary = port.get("_declutter_input")
	var previous: Dictionary = first["combat"]
	assert(Replay.canonical(previous["events"]) == Replay.canonical(combat["events"]))
	combat["floor_marks"] = Capture.floor_marks(input)
	combat["hero_health_before"] = input.get("hero_health_before", [])
	var old_health: Array = previous.get("hero_health_after", [])
	combat["hero_health_after"] = old_health
	for scenario: String in ["combat_mid", "combat_reminder"]:
		var path: String = directory.path_join(scenario + "_1688x780.json")
		if not FileAccess.file_exists(path):
			continue
		var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var saved: Dictionary = report["combat"]
		assert(Replay.canonical(saved["events"]) == Replay.canonical(combat["events"]))
		report["combat"] = combat
		report["fight_input"] = input
		report["state"] = port.get_state()
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t", true, true))
		file.close()
	print("declutter: exact event identity proved; raw fight input and floor metadata saved")
	quit(0)
