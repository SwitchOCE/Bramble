extends "res://tests/ui/shots/declutter_frames.gd"
## Timing-only old-barrier baseline; selected after frames reuse the same complete event streams.

const FIXTURES: Dictionary = {
	"bog":
	"res://docs/ideation/evidence/declutter/batch1/strips/bog-followup/fixture/bog_1688x780.json",
	"combat_mid": "res://docs/ideation/evidence/declutter/batch1/before/combat_mid_1688x780.json",
}
const STATE_FIELDS: PackedStringArray = [
	"units",
	"boards",
	"player_ids",
	"first_side",
	"phase",
	"finished",
	"winner",
	"damage",
	"round_toll",
	"round_toll_added",
	"damage_uncapped",
	"end_reason",
	"result_rules",
	"early_spoils",
	"slot_marks",
	"bog_toll",
	"bog_patches",
	"slot_hexes",
]
var _timing_name: String = ""
var _capture_after: bool = false
var _phase: String
var _packet: String
var _revision: String


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() == 3, "usage: -- <before|timing-after|after> <packet> <revision>")
	assert(args[0] in ["before", "timing-after", "after"])
	_capture_after = args[0] == "after"
	_phase = "before" if args[0] == "before" else "after"
	_timing_name = (
		"before" if _phase == "before" else ("after-final" if _capture_after else "after-cleanup")
	)
	_packet = args[1]
	_revision = args[2]
	DirAccess.make_dir_recursive_absolute(_packet)
	root.size = PIXELS
	if _capture_after:
		DisplayServer.window_set_size(PIXELS)
	Settings.path = "user://declutter_retire_frames.cfg"
	Settings.reset()
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var runs: Array[Dictionary] = []
	for scenario: String in ["bog", "combat_mid"]:
		var fixture: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(str(FIXTURES[scenario]))
		)
		Settings.reduce_motion = false
		Settings.field_mode_enabled = false
		Settings.opponents = "bots"
		for speed: float in [1.0, 4.0]:
			Settings.fight_speed = speed
			var first: Dictionary = await _timed(fixture, speed)
			var second: Dictionary = await _timed(fixture, speed)
			assert(first == second, "two full fixed-step timing passes agree")
			first["scenario"] = scenario
			first["speed"] = speed
			first["fixture"] = FIXTURES[scenario]
			first["source_revision"] = _revision
			runs.append(first)
			print(
				"cue retirement timing: ",
				_phase,
				" ",
				scenario,
				" x",
				speed,
				" duration=",
				first.duration_seconds,
				" ticks=",
				first.ticks
			)
	_write(
		_packet.path_join(_timing_name + "-timings.json"),
		{
			"phase": _phase,
			"production_revision": _revision,
			"fixed_step": STEP,
			"method":
			(
				"Two complete manual 1/120-second passes per whole fight, from first playback "
				+ "advance through automatic return. No before images are rendered or saved."
			),
			"runs": runs,
		}
	)
	if _capture_after:
		for scenario: String in ["bog", "combat_mid"]:
			_before = str(FIXTURES[scenario]).get_base_dir()
			_out = "res://build/declutter-retire/after-frames"
			_selected_attacks.clear()
			if scenario == "bog":
				_selected_attacks.append(17)
				_selected_attacks.append(25)
			else:
				_selected_attacks.append(45)
			for speed: float in [1.0, 4.0]:
				Settings.fight_speed = speed
				await _fight(scenario, speed, false)
			await _fight(scenario, 1.0, true)
	print("cue retirement ", _phase, ": complete")
	quit()


func _timed(fixture: Dictionary, speed: float) -> Dictionary:
	var screen: CombatScreen = _screen(fixture, speed)
	for tick: int in LIMIT:
		_advance(screen, tick)
		if _finished_tick >= 0:
			break
	assert(_finished_tick >= 0 and _result_tick >= 0, "whole fight reaches automatic return")
	assert(screen.next_index == screen.events.size(), "every source event was applied")
	var state: Dictionary = {}
	for field: String in STATE_FIELDS:
		state[field] = screen.model.get(field)
	var state_json: String = JSON.stringify(state, "", true, true)
	var result: Dictionary = {
		"ticks": _finished_tick + 1,
		"duration_seconds": (_finished_tick + 1) * STEP,
		"result_tick": _result_tick,
		"automatic_return_tick": _finished_tick,
		"event_ticks": _event_ticks.duplicate(true),
		"events": screen.events.duplicate(true),
		"events_sha256": JSON.stringify(screen.events, "", true, true).sha256_text(),
		"final_state": JSON.parse_string(state_json),
		"final_state_sha256": state_json.sha256_text(),
		"final_health_text": Array(_health_text(screen)),
	}
	root.remove_child(screen)
	screen.queue_free()
	await process_frame
	return result


func _write(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "open timing output")
	file.store_string(JSON.stringify(value, "\t", true, true) + "\n")
