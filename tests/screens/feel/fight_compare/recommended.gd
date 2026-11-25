extends "res://tests/screens/feel/fight_compare/buffs.gd"
## `recommended`: every option the picks page recommends, in one fight: the best proposal (best.gd)
## with the rotation switch on (rotate.gd), CB11 "mild" (its set: stop B, the mild ease-in), CB8
## "c" (several deaths fall one after another), CB14 "c" (each +N flies from its cause into the
## stat; buffs.gd), CB13 "c" (a unit that dies alone: the light goes out and it sinks;
## pilot_motion.gd) and CB12 "b" (damage to the player: the winner's portrait strikes, then the
## loser's Health counts down; pilot_hero_damage.gd). A scenario's own options win over these.
##
## CB13 "c" here is both halves of the pilot's option: the death, drawn by pilot_motion.gd from the
## schedule's clock (recommended_screen.gd: the frame it leaves the board, so FAST speeds it up
## with the fight), and the number that killed it held on through it (pilot_screen.gd's, on the
## best proposal's burst: following its card until the card leaves, then still, full to D+18,
## fading over 8 f). A unit that dies alone is one the schedule drops on its own (best_timeline.gd's
## falls: one unit at that frame, not one of CB8's staggered group).
## CB12 "b" is the pilot's option on this schedule: the result step shows the old Health (pilot.gd
## hold_old_health) and recommended_screen.gd draws the strike by frame after the result. Its
## striker turns with the attackers' set: CB9 "aim_lean" (the game's) with its in-plane lean, else
## the rotation switch's.
## CB8 "c" with CB14 "c": each of Old Brock's gains follows its death, and CB14's gain beats push
## two of the six falls (the 3rd and 5th) 2 and 3 frames later than CB8 schedules them (the
## plan's notes say which); the rest is as each option alone.
## "CB13": "none" in a scenario's options leaves CB13 out (every death falls as best's do), and
## "CB12": "none" leaves CB12 out (the result shows the loss at once, as best's does).
## Exploratory (ideation/fight-animation): nothing here reaches the game.

const PILOT_MOTION: GDScript = preload("res://tests/screens/feel/fight_compare/pilot_motion.gd")
const RECOMMENDED_SCREEN: Script = preload(
	"res://tests/screens/feel/fight_compare/recommended_screen.gd"
)
const Pilot := preload("res://tests/screens/feel/fight_compare/pilot.gd")

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
## Whether CB12 plays (a scenario's "CB12": "none" leaves it out).
var player_damage: bool = true
## CB13: burst index (the timeline's bursts) -> D, for each number that kills a unit dying alone.
var held: Dictionary = {}
## CB12: the striker's turn (rotate.gd's set, {} for none), and whether it has the in-plane lean.
var strike_set: Dictionary = {}
var strike_lean: bool = false


func configure(chosen: Dictionary) -> void:
	var merged: Dictionary = PICKED.duplicate()
	merged.merge(chosen, true)
	single_death = str(merged.get("CB13", DEATH)) != "none"
	player_damage = str(merged.get("CB12", "b")) != "none"
	super(merged)
	strike_set = rotate_set if rotate else {}
	strike_lean = false
	if str(merged.get("CB9", "")) == "aim_lean":
		strike_set = Rotate.SET_LEAN
		strike_lean = true


func make_replay(base: Dictionary, events: Array, catalog: Dictionary, damage: int) -> FightReplay:
	var made: FightReplay = super(base, events, catalog, damage)
	solo.clear()
	solo.merge(solo_falls(timeline))
	held = held_numbers(timeline, solo) if single_death else {}
	if player_damage:
		Pilot.hold_old_health(made.steps, events, damage)
	return made


func make_motion(cards: Control) -> FightMotion:
	if not single_death:
		return super(cards)
	var motion: FightMotion = PILOT_MOTION.new(cards)
	motion.set("option", DEATH)
	motion.set("solo", solo)
	motion.set("whole_frames", false)
	# each single death from its fall's frame on the schedule (none yet: from the clock it shows)
	var starts: Dictionary = {}
	var falls: Array = timeline.get("_falls") if timeline != null else []
	for value: Variant in falls:
		var fall: Dictionary = value
		if solo.has(str(fall["key"])):
			starts[str(fall["key"])] = GlassPieces.as_int(fall["frame"]) / 60.0
	motion.set("starts", starts)
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


## CB13: the burst that kills each unit dying alone (the last on it up to its fall), by its index
## in the timeline's bursts -> the frame it leaves the board.
static func held_numbers(schedule: RefCounted, alone: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var bursts: Array = schedule.get("bursts")
	for value: Variant in schedule.get("_falls"):
		var fall: Dictionary = value
		var key: String = str(fall["key"])
		if not alone.has(key):
			continue
		var frame: int = GlassPieces.as_int(fall["frame"])
		var killing: int = -1
		for k: int in bursts.size():
			var burst: Dictionary = bursts[k]
			if str(burst["key"]) == key and GlassPieces.as_int(burst["frame"]) <= frame:
				killing = k
		if killing >= 0:
			out[killing] = frame
	return out
