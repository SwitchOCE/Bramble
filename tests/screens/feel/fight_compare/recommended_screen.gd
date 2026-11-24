extends "res://tests/screens/feel/fight_compare/buff_screen.gd"
## The `recommended` treatment's screen (recommended.gd): buff_screen.gd (the best proposal's
## schedule and CB14's pieces), plus the game clock CB13's deaths are drawn from
## (pilot_motion.gd), as pilot_screen.gd keeps it. Their markers (death_dark, death_gone) go to
## the fixture's log with the buff markers. Exploratory: nothing here reaches the game.

const PilotMotion := preload("res://tests/screens/feel/fight_compare/pilot_motion.gd")

## Game seconds since the fight began.
var clock: float = 0.0


func _ensure_stage() -> void:
	var fresh: bool = _frame == null
	super()
	if fresh and _keeper is PilotMotion:
		_keeper.set("on_marker", _on_death_marker)


func _process(delta: float) -> void:
	clock += delta * maxf(speed, 0.01)
	if _keeper is PilotMotion:
		_keeper.set("clock", clock)
	super(delta)
	if _keeper is PilotMotion:
		_keeper.call("advance")


func _on_death_marker(key: String, marker: String) -> void:
	_markers.append([key, marker, ""])
