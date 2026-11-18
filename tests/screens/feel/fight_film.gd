extends "res://tests/screens/fight_stand_in.gd"
## The same deterministic core fight before/after animation changes, with frame-clock timings.

var elapsed: float = 0.0
var result_at: float = -1.0
var finished_at: float = -1.0
var transitions: Array[Dictionary] = []
var _last_step: int = -1


func _ready() -> void:
	super()
	screen.result_shown.connect(func() -> void: result_at = elapsed)
	screen.playback_finished.connect(func() -> void: finished_at = elapsed)


func _process(delta: float) -> void:
	elapsed += delta
	if screen._step != _last_step and screen.is_playing():
		_last_step = screen._step
		var step: Dictionary = replay.steps[_last_step]
		transitions.append({"step": _last_step, "at": elapsed, "kind": step["kind"]})


func feel_setup(scenario: Dictionary) -> void:
	if scenario.has("long_windup") and scenario["long_windup"] == true:
		(screen._keeper as FightMotion).windup_time = FightMotion.WINDUP_LONG


func feel_report() -> Dictionary:
	var planned: float = 0.0
	var attacks: int = 0
	for step: Dictionary in replay.steps:
		planned += GlassPieces.as_float(step["hold"])
	for event: Dictionary in combat.events:
		if event.get("type") == "attack":
			attacks += 1
	return {
		"fight": fight,
		"attacks": attacks,
		"steps": replay.steps.size(),
		"planned_seconds": planned,
		"result_at": result_at,
		"finished_at": finished_at,
		"core_matches":
		screen_summary(0) == core_summary(0) and screen_summary(1) == core_summary(1),
		"transitions": transitions,
	}
