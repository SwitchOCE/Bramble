extends "res://tests/ui/shots/declutter_frames.gd"
## Reuse batch1's deterministic full discovery/replay and eight native attack samples.


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() == 2, "usage: -- <fixture directory> <frames output>")
	_before = args[0]
	_out = args[1]
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(_before.path_join("bog_1688x780.json"))
	)
	for value: Variant in fixture["selected_attack_event_indices"]:
		_selected_attacks.append(CoreUtil.to_int(value))
	DisplayServer.window_set_size(PIXELS)
	root.size = PIXELS
	Settings.path = "user://declutter_bog_frames.cfg"
	Settings.reset()
	_run.call_deferred()


func _run() -> void:
	await process_frame
	for speed: float in [1.0, 4.0]:
		await _fight("bog", speed, false)
	await _fight("bog", 1.0, true)
	print("declutter Bog: native before/after moment strips complete")
	quit()
