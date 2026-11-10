extends "res://tests/ui/shots/declutter_frames.gd"
## The two requested repair moments, at x1 and reduced motion only.


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() == 4, "usage: -- <before fixtures> <frames output> <scenario> <attack>")
	_before = args[0]
	_out = args[1]
	assert(args[2] in ["rival-fight", "combat_mid"])
	_scenarios = PackedStringArray([args[2]])
	for value: String in args[3].split(",", false):
		_selected_attacks.append(value.to_int())
	DisplayServer.window_set_size(PIXELS)
	root.size = PIXELS
	Settings.path = "user://declutter_narrow_frames.cfg"
	Settings.reset()
	_run.call_deferred()


func _run() -> void:
	await process_frame
	for scenario: String in _scenarios:
		await _fight(scenario, 1.0, false)
		await _fight(scenario, 1.0, true)
	print("declutter narrow: requested x1/reduce moment strips complete")
	quit()
