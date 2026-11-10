extends SceneTree
## Fixed 1/120 s discovery and replay: eight samples per actual attack interval and phase.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
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
var _selected_attacks: Array[int] = []
var _reduce_all: bool = false
var _tick: int = 0
var _attacks: Array[Dictionary] = []
var _event_ticks: Array[Dictionary] = []
var _result_tick: int = -1
var _finished_tick: int = -1
var _observing_screen: CombatScreen


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_before = args[0]
	_out = args[1]
	if args.size() > 2:
		_scenarios = args[2].split(",", false)
		assert(not _scenarios.is_empty(), "select at least one capture scenario")
		for scenario: String in _scenarios:
			assert(scenario in SCENARIOS, "unknown capture scenario: " + scenario)
	if args.size() > 3:
		for value: String in args[3].split(",", false):
			assert(
				value.is_valid_int() and value.to_int() >= 0, "invalid attack event index: " + value
			)
			var index: int = value.to_int()
			assert(index not in _selected_attacks, "duplicate attack event index: " + value)
			_selected_attacks.append(index)
		assert(not _selected_attacks.is_empty(), "select at least one attack event index")
	if args.size() > 4:
		assert(args[4] == "reduce-all", "expected reduce-all as the fifth argument")
		_reduce_all = true
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
	for scenario: String in _scenarios:
		if _reduce_all or scenario == "combat_mid":
			await _fight(scenario, 1.0, true)
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
	_observing_screen = screen
	screen.attack_started.connect(_attack_started)
	screen.finished.connect(_finished)
	screen.playing = true
	return screen


func _advance(screen: CombatScreen, tick: int) -> void:
	_tick = tick
	var first: int = screen.next_index
	var was_finished: bool = screen.model.finished
	screen.advance_playback(STEP)
	_observe_lunge_peaks(screen, tick)
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
	var selected_mode: bool = not _selected_attacks.is_empty()
	var opening: Dictionary = {}
	var opening_effects: Array[Dictionary] = []
	if not selected_mode:
		var first_attack: Dictionary = starts[0]
		opening = _window("opening", -1, 0, CoreUtil.to_int(first_attack["start_tick"]) - 1)
		windows.append(opening)
		opening_effects = _opening_effects(source_events, discovery, first_attack)
		windows.append_array(opening_effects)
	for index: int in starts.size():
		var attack: Dictionary = starts[index]
		if selected_mode and CoreUtil.to_int(attack["event_index"]) not in _selected_attacks:
			continue
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
		_pin_lunge_peaks(interval, attack)
		attacks.append(interval)
		windows.append(interval)
	if selected_mode:
		assert(
			attacks.size() == _selected_attacks.size(), "every selected index identifies an attack"
		)
	var result: Dictionary = {}
	if not selected_mode:
		result = _window("result", -1, CoreUtil.to_int(discovery["result_tick"]), finish)
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
			await _capture(directory, pending, screen)
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
		"capture_mode": "selected-attacks" if selected_mode else "complete",
		"selected_attack_event_indices": _selected_attacks,
		"seed": fixture.get("seed", -1),
		"speed": speed,
		"reduce_motion": reduced,
		"pixels": [PIXELS.x, PIXELS.y],
		"fixed_step": STEP,
		"ticks": finish + 1,
		"attacks": attacks,
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
	if selected_mode:
		manifest["method"] = (
			"two complete deterministic 1/120 s passes; eight evenly spaced samples per selected "
			+ "actual attack-to-next-attack interval; last attack ends before result; "
			+ "complete replay verifies all event ticks, final Health and automatic return"
		)
	else:
		manifest["opening"] = opening
		manifest["opening_effects"] = opening_effects
		manifest["result"] = result
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


func _capture(directory: String, intervals: Array[Dictionary], screen: CombatScreen) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	assert(image.get_size() == PIXELS)
	var ancillary: int = Capture.budget_nodes(screen).size()
	var raw_labels: int = Capture.text_nodes(screen).size()
	assert(ancillary <= 10, "every captured fight frame stays within the ancillary label budget")
	for interval: Dictionary in intervals:
		var frames: Array = interval["frames"]
		var prefix: String = str(interval["kind"])
		if prefix in ["attack", "opening-event"]:
			prefix += "-%03d" % CoreUtil.to_int(interval["event_index"])
		var image_path: String = "%s-frame-%d.png" % [prefix, frames.size()]
		assert(image.save_png(directory.path_join(image_path)) == OK)
		frames.append(
			{
				"file": image_path,
				"tick": _tick,
				"seconds": _tick * STEP,
				"ancillary_text_nodes": ancillary,
				"raw_text_nodes": raw_labels,
				"attack_actor_positions": _actor_positions(screen, interval)
			}
		)


func _health_text(screen: CombatScreen) -> PackedStringArray:
	var labels: Array = screen.get("_health_labels")
	var values: PackedStringArray = []
	for label: Label in labels:
		values.append(label.text)
	return values


func _attack_started(index: int, duration: float) -> void:
	var event: Dictionary = _observing_screen.events[index]
	var actors: Array[int] = [CoreUtil.to_int(event["attacker"])]
	for uid: Variant in event.get("joiners", []):
		actors.append(CoreUtil.to_int(uid))
	var cards: Dictionary = _observing_screen.get("_cards")
	var peaks: Array[Dictionary] = []
	for uid: int in actors:
		var card: CardView = cards.get(uid)
		assert(card != null, "every attack actor has a visible card")
		var board: BoardView = card.get_parent() as BoardView
		assert(board != null, "attack actor belongs to its board")
		var home: Vector2 = board.card_position(CoreUtil.to_int(card.unit.get("slot", -1)))
		peaks.append(
			{
				"uid": uid,
				"tick": _tick,
				"home": [home.x, home.y],
				"position": [card.position.x, card.position.y],
				"distance_squared": 0.0,
				"flash_strength": 0.0,
				"kind": "flash" if Settings.reduce_motion else "lunge"
			}
		)
	var contact: float = _observing_screen.get("_contact_remaining")
	_attacks.append(
		{
			"event_index": index,
			"start_tick": _tick,
			"predicted_duration": duration,
			"lunge_peaks": peaks,
			"flash_deadline_tick": _tick + ceili((contact + 0.4) / STEP)
		}
	)


func _finished() -> void:
	_finished_tick = _tick


## Measure the actual displayed pose at every fixed tick, separately for every Pack partner.
func _observe_lunge_peaks(screen: CombatScreen, tick: int) -> void:
	if _attacks.is_empty():
		return
	var attack: Dictionary = _attacks.back()
	var peaks: Array = attack["lunge_peaks"]
	var cards: Dictionary = screen.get("_cards")
	var motion: RefCounted = screen.get("_motion")
	var lunges: Dictionary = motion.get("_lunges")
	for peak: Dictionary in peaks:
		var uid: int = CoreUtil.to_int(peak["uid"])
		var card: CardView = cards.get(uid)
		if card == null or not is_instance_valid(card):
			continue
		var lunge: Tween = lunges.get(uid)
		if not Settings.reduce_motion and (lunge == null or not lunge.is_valid()):
			continue
		if Settings.reduce_motion and tick > CoreUtil.to_int(attack["flash_deadline_tick"]):
			continue
		var home_values: Array = peak["home"]
		var home: Vector2 = Vector2(
			CoreUtil.to_float(home_values[0]), CoreUtil.to_float(home_values[1])
		)
		var distance: float = card.position.distance_squared_to(home)
		var flash: float = card.modulate.r + card.modulate.g + card.modulate.b
		var farther: bool = distance > CoreUtil.to_float(peak["distance_squared"]) + 0.000001
		var brighter: bool = (
			Settings.reduce_motion
			and distance <= 0.000001
			and CoreUtil.to_float(peak["distance_squared"]) <= 0.000001
			and flash > CoreUtil.to_float(peak["flash_strength"]) + 0.000001
		)
		if farther or brighter:
			peak["tick"] = tick
			peak["position"] = [card.position.x, card.position.y]
			peak["distance_squared"] = distance
			peak["flash_strength"] = flash
			peak["kind"] = (
				"held-pose"
				if Settings.reduce_motion and distance > 0
				else ("flash" if Settings.reduce_motion else "lunge")
			)


func _pin_lunge_peaks(interval: Dictionary, attack: Dictionary) -> void:
	var uniform: Array = interval["sample_ticks"]
	uniform = uniform.duplicate()
	var samples: Array = uniform.duplicate()
	var peaks: Array = attack["lunge_peaks"]
	var required: Array[int] = []
	var replacements: Array[Dictionary] = []
	for peak: Dictionary in peaks:
		var tick: int = CoreUtil.to_int(peak["tick"])
		assert(tick >= interval["start_tick"] and tick <= interval["end_tick"])
		if not required.has(tick):
			required.append(tick)
	for tick: int in required:
		if samples.has(tick):
			continue
		var victim: int = -1
		var gap: int = 2147483647
		for candidate: Variant in samples:
			var value: int = CoreUtil.to_int(candidate)
			if required.has(value) or value in [interval["start_tick"], interval["end_tick"]]:
				continue
			if absi(value - tick) < gap:
				victim = value
				gap = absi(value - tick)
		if victim < 0:
			# Seven distinct Pack peaks can require an endpoint's slot in an eight-frame sheet.
			for candidate: Variant in samples:
				var value: int = CoreUtil.to_int(candidate)
				if not required.has(value):
					victim = value
					break
		assert(victim >= 0, "all actor peaks fit in eight distinct frames")
		samples.erase(victim)
		samples.append(tick)
		replacements.append({"uniform_tick": victim, "peak_tick": tick})
	samples.sort()
	assert(samples.size() == 8)
	interval["sample_ticks"] = samples
	interval["sampling"] = {
		"mode": "uniform-with-observed-lunge-peaks",
		"uniform_sample_ticks": uniform,
		"replacements": replacements,
		"lunge_peaks": peaks,
		"method":
		(
			"Pin each actor's maximum observed lunge displacement at 120Hz; under reduce "
			+ "motion pin held-pose or strongest source flash. Replace nearest unprotected "
			+ "interior uniform sample; endpoints yield only if peak count requires it."
		)
	}


func _actor_positions(screen: CombatScreen, interval: Dictionary) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var sampling: Dictionary = interval.get("sampling", {})
	var cards: Dictionary = screen.get("_cards")
	for peak: Dictionary in sampling.get("lunge_peaks", []):
		var uid: int = CoreUtil.to_int(peak["uid"])
		var card: CardView = cards.get(uid)
		if card != null and is_instance_valid(card):
			found.append({"uid": uid, "position": [card.position.x, card.position.y]})
	return found
