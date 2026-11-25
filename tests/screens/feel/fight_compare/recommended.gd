extends "res://tests/screens/feel/fight_compare/buffs.gd"
## `recommended`: every option the picks page recommends, in one fight: the best proposal (best.gd)
## with the rotation switch on (rotate.gd), CB11 "mild" (its set: stop B, the mild ease-in), CB8
## "c" (several deaths fall one after another), CB14 "c" (each +N flies from its cause into the
## stat; buffs.gd) and CB13 "c" (a unit that dies alone: the light goes out and it sinks;
## pilot_motion.gd). A scenario's own options win over these.
##
## What CB13 "c" brings here is the death itself, drawn by pilot_motion.gd from this screen's game
## clock (recommended_screen.gd). The pilot's other half, the killing number held on through the
## death, belongs to today's step-by-step screen (pilot_screen.gd); here the number is the best
## proposal's burst (readable to C+30). A unit that dies alone is one the schedule drops on its own
## (best_timeline.gd's falls: one unit at that frame, not one of CB8's staggered group).
## CB8 "c" with CB14 "c": each of Old Brock's gains follows its death, and CB14's gain beats push
## two of the six falls (the 3rd and 5th) 2 and 3 frames later than CB8 schedules them (the
## plan's notes say which); the rest is as each option alone.
## "CB13": "none" in a scenario's options leaves CB13 out (every death falls as best's do), for
## comparing with the game before its single death is built.
## Exploratory (ideation/fight-animation): nothing here reaches the game.

const PILOT_MOTION: GDScript = preload("res://tests/screens/feel/fight_compare/pilot_motion.gd")
const RECOMMENDED_SCREEN: Script = preload(
	"res://tests/screens/feel/fight_compare/recommended_screen.gd"
)

## The picks, as options (CB11 "mild" is CB2 "b" with CB3 "mild", as clips.py FILM_OPTIONS).
const PICKED: Dictionary = {
	"ROTATE": "on",
	"CB2": "b",
	"CB3": "mild",
	"CB8": "c",
	"CB14": "c",
}
## CB13's pick (pilot_motion.gd's option).
const DEATH: String = "c"

## Keys ("u8") of units that die alone, filled by make_replay (pilot_motion.gd reads it).
var solo: Dictionary = {}
## Whether CB13 plays (a scenario's "CB13": "none" leaves it out).
var single_death: bool = true


func configure(chosen: Dictionary) -> void:
	var merged: Dictionary = PICKED.duplicate()
	merged.merge(chosen, true)
	single_death = str(merged.get("CB13", DEATH)) != "none"
	super(merged)


func make_replay(base: Dictionary, events: Array, catalog: Dictionary, damage: int) -> FightReplay:
	var made: FightReplay = super(base, events, catalog, damage)
	solo.clear()
	solo.merge(solo_falls(timeline))
	return made


func make_motion(cards: Control) -> FightMotion:
	if not single_death:
		return super(cards)
	var motion: FightMotion = PILOT_MOTION.new(cards)
	motion.set("option", DEATH)
	motion.set("solo", solo)
	return motion


func screen_script() -> Script:
	return RECOMMENDED_SCREEN


## The keys the schedule drops alone: a fall no other unit starts on the same frame, outside any
## staggered group (CB8).
static func solo_falls(schedule: RefCounted) -> Dictionary:
	var grouped: Dictionary = {}
	for value: Variant in schedule.get("_staggers"):
		var group: Dictionary = value
		for fall: Variant in group["falls"]:
			var one: Dictionary = fall
			grouped[str(one["key"])] = true
	var at_frame: Dictionary = {}
	for value: Variant in schedule.get("_falls"):
		var fall: Dictionary = value
		var frame: int = GlassPieces.as_int(fall["frame"])
		at_frame[frame] = GlassPieces.as_int(at_frame.get(frame, 0)) + 1
	var out: Dictionary = {}
	for value: Variant in schedule.get("_falls"):
		var fall: Dictionary = value
		var key: String = str(fall["key"])
		if (
			not grouped.has(key)
			and GlassPieces.as_int(at_frame[GlassPieces.as_int(fall["frame"])]) == 1
		):
			out[key] = true
	return out
