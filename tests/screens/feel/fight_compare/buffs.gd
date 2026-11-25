extends "res://tests/screens/feel/fight_compare/best.gd"
## `buffs`: CB14, how a stat gain shows (docs/workstreams/fight-animation-24-nov/buff-look/
## DESIGN.md), on top of the best proposal (best.gd, every other branch at its pick unless the
## scenario names it): "options": {"CB14": "a"} (swell and count), "b" (running total), "c"
## (carried total). The schedule is buff_timeline.gd; buff_screen.gd draws the discs, tags,
## flights and flares. Stand-ins: the recruit screen's green gain pill, flight arc and amber ring.
## Exploratory (ideation/fight-animation): nothing here reaches the game.

const BUFF_SCREEN: Script = preload("res://tests/screens/feel/fight_compare/buff_screen.gd")
const BUFF_TIMELINE: GDScript = preload("res://tests/screens/feel/fight_compare/buff_timeline.gd")


func screen_script() -> Script:
	return BUFF_SCREEN


func timeline_script() -> GDScript:
	return BUFF_TIMELINE
