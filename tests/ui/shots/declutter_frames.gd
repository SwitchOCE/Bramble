extends SceneTree
## Deterministic combat evidence: fixed 1/120 s steps, eight native viewport frames per attack.

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const Settings := preload("res://src/ui/settings.gd")
const STEP: float = 1.0 / 120.0
const PIXELS := Vector2i(1688, 780)

var _before: String
var _out: String
var _tick: int = 0
var _attacks: Array[Dictionary] = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_before = args[0]
	_out = args[1]
	DisplayServer.window_set_size(PIXELS)
	root.size = PIXELS
	Settings.path = "user://declutter_frame_settings.cfg"
	Settings.reset()
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	await process_frame
	for scenario: String in ["combat_mid", "homecoming-following-combat", "rival-fight"]:
		for speed: float in [1.0, 4.0]:
			await _fight(scenario, speed, false)
	await _fight("combat_mid", 1.0, true)
	print("declutter: all deterministic frame captures complete")
	quit(0)


func _fight(scenario: String, speed: float, reduced: bool) -> void:
	Settings.reduce_motion = reduced
	Settings.fight_speed = speed
	Settings.field_mode_enabled = scenario == "rival-fight"
	Settings.opponents = "field" if Settings.field_mode_enabled else "bots"
	var suffix: String = "-reduce" if reduced else ""
	var directory: String = _out.path_join("%s-x%d%s" % [scenario, int(speed), suffix])
	DirAccess.make_dir_recursive_absolute(directory)
	var fixture: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(_before.path_join(scenario + "_1688x780.json"))
	)
	var screen := CombatScreen.new()
	screen.manual_playback = true
	root.add_child(screen)
	Capture.presentation(screen, fixture)
	var names: Array = fixture["names"]
	var combat: Dictionary = fixture["combat"]
	screen.setup(
		combat,
		PackedStringArray(names),
		CoreUtil.to_int(fixture["bottom_side"]),
		"Last fight",
		CoreUtil.to_int(fixture["opponent_health"])
	)
	screen.set_speed(speed)
	_tick = 0
	_attacks = []
	screen.attack_started.connect(_attack_started)
	screen.playing = true
	var complete: bool = false
	for tick: int in 120 * 300:
		_tick = tick
		screen.advance_playback(STEP)
		var pending: Array[Dictionary] = []
		for attack: Dictionary in _attacks:
			var samples: Array = attack["sample_ticks"]
			var captured: Array = attack["frames"]
			if captured.size() < 8 and tick >= CoreUtil.to_int(samples[captured.size()]):
				pending.append(attack)
		if not pending.is_empty():
			await process_frame
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			assert(image.get_size() == PIXELS)
			for attack: Dictionary in pending:
				var frames: Array = attack["frames"]
				var image_path: String = (
					"attack-%03d-frame-%d.png"
					% [CoreUtil.to_int(attack["event_index"]), frames.size()]
				)
				assert(image.save_png(directory.path_join(image_path)) == OK)
				frames.append({"file": image_path, "tick": tick, "seconds": tick * STEP})
		if screen.next_index >= screen.events.size():
			var all_captured: bool = true
			for attack: Dictionary in _attacks:
				var frames: Array = attack["frames"]
				all_captured = all_captured and frames.size() == 8
			if all_captured:
				complete = true
				break
	assert(complete, "fight completed within deterministic five-minute limit")
	assert(not _attacks.is_empty(), "scripted fight contains attacks")
	var manifest: Dictionary = {
		"scenario": scenario,
		"speed": speed,
		"reduce_motion": reduced,
		"pixels": [PIXELS.x, PIXELS.y],
		"fixed_step": STEP,
		"ticks": _tick + 1,
		"attacks": _attacks,
		"events": screen.events,
		"method": "manual_playback; advance_playback(1/120); nearest tick to j*duration/7",
	}
	var file := FileAccess.open(directory.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t", true, true))
	file.close()
	print("declutter frames: %s attacks=%d ticks=%d" % [directory, _attacks.size(), _tick])
	root.remove_child(screen)
	screen.queue_free()
	await process_frame


func _attack_started(index: int, duration: float) -> void:
	var samples: Array[int] = []
	for sample: int in 8:
		samples.append(_tick + roundi(sample * duration / (7.0 * STEP)))
	(
		_attacks
		. append(
			{
				"event_index": index,
				"start_tick": _tick,
				"duration": duration,
				"sample_ticks": samples,
				"frames": [],
			}
		)
	)
