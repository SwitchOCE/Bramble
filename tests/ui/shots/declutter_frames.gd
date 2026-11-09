extends SceneTree
## Fixed 1/120 s discovery and replay: eight samples per actual attack interval and phase.

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const Settings := preload("res://src/ui/settings.gd")
const STEP: float = 1.0 / 120.0
const PIXELS := Vector2i(1688, 780)
const LIMIT: int = 120 * 300
const SCENARIOS := ["combat_mid", "homecoming-following-combat", "rival-fight"]

var _before: String
var _out: String
var _scenarios := PackedStringArray(SCENARIOS)
var _tick: int = 0
var _attacks: Array[Dictionary] = []
var _event_ticks: Array[Dictionary] = []
var _result_tick: int = -1
var _finished_tick: int = -1


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_before = args[0]
	_out = args[1]
	if args.size() > 2:
		_scenarios = args[2].split(",", false)
		assert(not _scenarios.is_empty(), "select at least one capture scenario")
		for scenario: String in _scenarios:
			assert(scenario in SCENARIOS, "unknown capture scenario: " + scenario)
	DisplayServer.window_set_size(PIXELS)
	root.size = PIXELS
	Settings.path = "user://declutter_frame_settings.cfg"
	Settings.reset()
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	await process_frame
	for scenario: String in _scenarios:
		for speed: float in [1.0, 4.0]:
			await _fight(scenario, speed, false)
	if "combat_mid" in _scenarios:
		await _fight("combat_mid", 1.0, true)
	print("declutter: all deterministic frame captures complete")
	quit(0)


func _screen(fixture: Dictionary, speed: float) -> CombatScreen:
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
	_event_ticks = []
	_result_tick = -1
	_finished_tick = -1
	screen.attack_started.connect(_attack_started)
	screen.finished.connect(_finished)
	screen.playing = true
	return screen


func _advance(screen: CombatScreen, tick: int) -> void:
	_tick = tick
	var first: int = screen.next_index
	var was_finished: bool = screen.model.finished
	screen.advance_playback(STEP)
	for index: int in range(first, screen.next_index):
		var event: Dictionary = screen.events[index]
		_event_ticks.append({"event_index": index, "type": str(event["type"]), "tick": tick})
	if not was_finished and screen.model.finished:
		_result_tick = tick


func _discover(fixture: Dictionary, speed: float) -> Dictionary:
	var screen: CombatScreen = _screen(fixture, speed)
	for tick: int in LIMIT:
		_advance(screen, tick)
		if _finished_tick >= 0:
			break
	assert(_finished_tick >= 0, "fight returns within deterministic five-minute limit")
	assert(_result_tick >= 0 and not _attacks.is_empty(), "fight has attacks and a result")
	var discovery: Dictionary = {
		"attacks": _attacks.duplicate(true),
		"event_ticks": _event_ticks.duplicate(true),
		"result_tick": _result_tick,
		"finished_tick": _finished_tick,
		"final_health_text": _health_text(screen),
	}
	root.remove_child(screen)
	screen.queue_free()
	await process_frame
	return discovery


func _window(kind: String, index: int, start: int, end: int) -> Dictionary:
	assert(end - start >= 7, "each eight-frame interval contains eight distinct fixed ticks")
	var samples: Array[int] = []
	for sample: int in 8:
		samples.append(start + roundi(sample * float(end - start) / 7.0))
	return {
		"kind": kind,
		"event_index": index,
		"start_tick": start,
		"end_tick": end,
		"duration": (end - start) * STEP,
		"sample_ticks": samples,
		"frames": [],
	}


func _opening_source(event: Dictionary) -> String:
	var kind: String = str(event["type"])
	if kind == "side_trigger":
		return "side:%d" % CoreUtil.to_int(event["side"])
	var source: Variant = event.get("source")
	if source == null:
		source = event.get("maker")
	if source == null and kind == "trigger":
		source = event.get("uid")
	if source == null and kind == "quarry_marked":
		source = event.get("hunter")
	return "" if source == null else "unit:%d" % CoreUtil.to_int(source)


## Preserve every opening cause, grouping recipients of one caster rather than splitting them.
## Same-tick causes share a sheet: real playback gives them no separate interval to sample.
func _opening_effects(
	events: Array, discovery: Dictionary, first_attack: Dictionary
) -> Array[Dictionary]:
	var groups: Array[Dictionary] = [
		{"event_index": 0, "start_tick": 0, "event_indices": [], "causes": []}
	]
	var active_source: String = ""
	var timeline: Array = discovery["event_ticks"]
	var attack_index: int = CoreUtil.to_int(first_attack["event_index"])
	for record: Dictionary in timeline:
		var index: int = CoreUtil.to_int(record["event_index"])
		if index >= attack_index:
			break
		var event: Dictionary = events[index]
		var kind: String = str(event["type"])
		var source: String = _opening_source(event)
		var boundary: bool = kind in ["trigger", "side_trigger", "quarry_marked"]
		boundary = boundary or (not source.is_empty() and source != active_source)
		var group: Dictionary = groups.back()
		var tick: int = CoreUtil.to_int(record["tick"])
		if boundary and tick - CoreUtil.to_int(group["start_tick"]) >= 8:
			group = {"event_index": index, "start_tick": tick, "event_indices": [], "causes": []}
			groups.append(group)
		var indices: Array = group["event_indices"]
		indices.append(index)
		if not source.is_empty():
			active_source = source
			var causes: Array = group["causes"]
			causes.append({"event_index": index, "type": kind, "source": source, "tick": tick})
	var intervals: Array[Dictionary] = []
	for index: int in groups.size():
		var group: Dictionary = groups[index]
		var end: int = CoreUtil.to_int(first_attack["start_tick"]) - 1
		if index + 1 < groups.size():
			var following: Dictionary = groups[index + 1]
			end = CoreUtil.to_int(following["start_tick"]) - 1
		var interval: Dictionary = _window(
			"opening-event",
			CoreUtil.to_int(group["event_index"]),
			CoreUtil.to_int(group["start_tick"]),
			end
		)
		interval["event_indices"] = group["event_indices"]
		interval["causes"] = group["causes"]
		intervals.append(interval)
	return intervals


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
	var combat: Dictionary = fixture["combat"]
	var source_events: Array = combat["events"]
	var event_hash: String = JSON.stringify(source_events, "", true, true).sha256_text()
	var discovery: Dictionary = await _discover(fixture, speed)
	var starts: Array = discovery["attacks"]
	var finish: int = CoreUtil.to_int(discovery["finished_tick"])
	var windows: Array[Dictionary] = []
	var attacks: Array[Dictionary] = []
	var first_attack: Dictionary = starts[0]
	var opening: Dictionary = _window(
		"opening", -1, 0, CoreUtil.to_int(first_attack["start_tick"]) - 1
	)
	windows.append(opening)
	var opening_effects: Array[Dictionary] = _opening_effects(
		source_events, discovery, first_attack
	)
	windows.append_array(opening_effects)
	for index: int in starts.size():
		var attack: Dictionary = starts[index]
		var end: int = CoreUtil.to_int(discovery["result_tick"]) - 1
		if index + 1 < starts.size():
			var following: Dictionary = starts[index + 1]
			end = CoreUtil.to_int(following["start_tick"]) - 1
		var interval: Dictionary = _window(
			"attack",
			CoreUtil.to_int(attack["event_index"]),
			CoreUtil.to_int(attack["start_tick"]),
			end
		)
		interval["predicted_duration"] = attack["predicted_duration"]
		attacks.append(interval)
		windows.append(interval)
	var result: Dictionary = _window(
		"result", -1, CoreUtil.to_int(discovery["result_tick"]), finish
	)
	windows.append(result)
	var screen: CombatScreen = _screen(fixture, speed)
	for tick: int in finish + 1:
		_advance(screen, tick)
		var pending: Array[Dictionary] = []
		for interval: Dictionary in windows:
			var samples: Array = interval["sample_ticks"]
			var frames: Array = interval["frames"]
			if frames.size() < 8 and tick == CoreUtil.to_int(samples[frames.size()]):
				pending.append(interval)
		if not pending.is_empty():
			await _capture(directory, pending)
	assert(_attacks == starts, "render replay starts every attack on its discovered fixed tick")
	assert(_event_ticks == discovery["event_ticks"], "render replay preserves every event tick")
	assert(_finished_tick == finish, "result and automatic return preserve their discovered timing")
	assert(_health_text(screen) == discovery["final_health_text"], "result Health is deterministic")
	assert(event_hash == JSON.stringify(source_events, "", true, true).sha256_text())
	for interval: Dictionary in windows:
		var frames: Array = interval["frames"]
		assert(frames.size() == 8, "each interval contains all eight native samples")
	var expected_health: Array = combat.get("hero_health_after", [])
	var displayed: PackedStringArray = _health_text(screen)
	for side: int in expected_health.size():
		if CoreUtil.to_int(expected_health[side]) >= 0:
			assert(
				displayed[side] == str(CoreUtil.to_int(expected_health[side])), "final Health lands"
			)
	var manifest: Dictionary = {
		"scenario": scenario,
		"seed": fixture.get("seed", -1),
		"speed": speed,
		"reduce_motion": reduced,
		"pixels": [PIXELS.x, PIXELS.y],
		"fixed_step": STEP,
		"ticks": finish + 1,
		"attacks": attacks,
		"opening": opening,
		"opening_effects": opening_effects,
		"result": result,
		"event_ticks": _event_ticks,
		"events": screen.events,
		"source_events_sha256": event_hash,
		"hero_health_before": combat.get("hero_health_before", []),
		"hero_health_after": expected_health,
		"final_health_text": Array(displayed),
		"automatic_return_tick": finish,
		"timing_passes_equal": true,
		"method":
		(
			"two deterministic 1/120 s passes; eight evenly spaced actual attack-to-next-attack "
			+ "samples; opening source-group focus sheets; last attack ends before result; "
			+ "separate result continues through settled Health and automatic return"
		),
	}
	var file := FileAccess.open(directory.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t", true, true))
	file.close()
	print(
		(
			"declutter frames: %s attacks=%d opening_effects=%d result=%d..%d Health=%s"
			% [
				directory,
				attacks.size(),
				opening_effects.size(),
				_result_tick,
				finish,
				str(displayed)
			]
		)
	)
	root.remove_child(screen)
	screen.queue_free()
	await process_frame


func _capture(directory: String, intervals: Array[Dictionary]) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	assert(image.get_size() == PIXELS)
	for interval: Dictionary in intervals:
		var frames: Array = interval["frames"]
		var prefix: String = str(interval["kind"])
		if prefix in ["attack", "opening-event"]:
			prefix += "-%03d" % CoreUtil.to_int(interval["event_index"])
		var image_path: String = "%s-frame-%d.png" % [prefix, frames.size()]
		assert(image.save_png(directory.path_join(image_path)) == OK)
		frames.append({"file": image_path, "tick": _tick, "seconds": _tick * STEP})


func _health_text(screen: CombatScreen) -> PackedStringArray:
	var labels: Array = screen.get("_health_labels")
	var values: PackedStringArray = []
	for label: Label in labels:
		values.append(label.text)
	return values


func _attack_started(index: int, duration: float) -> void:
	_attacks.append({"event_index": index, "start_tick": _tick, "predicted_duration": duration})


func _finished() -> void:
	_finished_tick = _tick
