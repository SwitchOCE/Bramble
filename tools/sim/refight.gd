extends SceneTree
## Verify streamed bench captures, including every combat event, through a JSON round trip.
## --headless -s res://tools/sim/refight.gd -- <prefix>.fights.jsonl


func _initialize() -> void:
	var paths: PackedStringArray = OS.get_cmdline_user_args()
	if paths.is_empty():
		printerr("refight: expected a .fights.jsonl path")
		quit(2)
		return
	var library := UnitLibrary.load_dir()
	var count: int = 0
	var started: int = Time.get_ticks_msec()
	for path: String in paths:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			printerr("refight: cannot read %s" % path)
			quit(2)
			return
		while not file.eof_reached():
			var line: String = file.get_line()
			if line.is_empty():
				continue
			var recorded: Dictionary = JSON.parse_string(line)
			for card: Dictionary in recorded.get("test_cards", []):
				if library.get_unit(str(card["id"])).is_empty():
					assert(library.register_unit(card) == "")
			var input: Dictionary = recorded["input"]
			var result: Dictionary = FightCapture.replay(input, library)
			if not FightCapture.matches(recorded, result):
				printerr("refight: mismatch at record %d in %s" % [count + 1, path])
				quit(1)
				return
			count += 1
	if count == 0:
		printerr("refight: no captures")
		quit(1)
		return
	print(
		"refight: %d exact fights in %.3f s" % [count, (Time.get_ticks_msec() - started) / 1000.0]
	)
	quit(0)
