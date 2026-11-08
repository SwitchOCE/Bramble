extends SceneTree
## taskset -c 2 timeout 3000 godot --headless -s res://tools/sim/placing_bar_run.gd -- out.json

const Probe := preload("res://tools/sim/placing_bar_probe.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var output: String = "build/placing-bar.json" if args.is_empty() else args[0]
	var fights: int = 40 if args.size() < 2 else args[1].to_int()
	var started: int = Time.get_ticks_msec()
	var probe := Probe.new()
	var report: Dictionary = probe.run_probe(
		100, 24, fights, 200, Probe.FIRST_GAME, Probe.SAMPLE_SEED, output
	)
	report.erase("rows")
	report["seconds"] = (Time.get_ticks_msec() - started) / 1000.0
	print("placing_summary: %s" % JSON.stringify(report))
	quit(0 if CoreUtil.to_bool(report["complete"]) else 1)
