extends "res://tests/screens/feel/fight_compare/fight_treatment.gd"
## `best`: the best proposal's attack and ordering (docs/workstreams/fight-animation-24-nov/plans/
## best.md, sections 2 and 3), as far as the fixture's hook allows. The schedule is
## best_timeline.gd; best_screen.gd plays it frame by frame in place of FightScreen's steps.
## A scenario picks each contested branch's option: "options": {"CB2": "c"} (best_timeline.gd
## lists them); a branch not named plays the proposal's pick.
##
## STAND-INS for the new visual elements best.md asks for (each would need an art pass and the
## owner's yes): the cause-to-target line is today's jab; the xN counter is the burst re-popping
## with the running total (CB7 "best_xn" adds a plain-text "xN" marked as a placeholder); C's
## glass crack and shatter are today's fall; C's amber rim glow is today's lunge glow. No sound
## cues are played.
## Exploratory (ideation/fight-animation): nothing here reaches the game.

const BEST_REPLAY: GDScript = preload("res://tests/screens/feel/fight_compare/best_replay.gd")
const BEST_SCREEN: Script = preload("res://tests/screens/feel/fight_compare/best_screen.gd")
const TIMELINE: GDScript = preload("res://tests/screens/feel/fight_compare/best_timeline.gd")

## {CB1: option, ...} from the scenario.
var options: Dictionary = {}
var timeline: RefCounted


## The scenario's options (fight_compare.gd calls this before make_replay).
func configure(chosen: Dictionary) -> void:
	super(chosen)
	options = chosen.duplicate()


func make_replay(base: Dictionary, events: Array, catalog: Dictionary, damage: int) -> FightReplay:
	# CB4 "after" plays a reordered log (best_timeline.gd reorder()); any other option, the log
	var played: Array = timeline_script().call("reorder", events, options)
	var made: FightReplay = replay_with(BEST_REPLAY, base, played, catalog, damage)
	timeline = timeline_script().new(options)
	# where each unit stands: the fight screen's own layout, from a screen never shown
	var probe: FightScreen = FightScreen.new()
	probe.state = {"you_side": GlassPieces.as_int(base.get("you_side", 0))}
	probe._g = GlassPieces.fight_geom()
	timeline.call("build", played, made.get("snaps"), probe.unit_xy)
	probe.free()
	made.set("timeline", timeline)
	var planned: Array = timeline.get("steps")
	made.steps.assign(planned)
	return made


func screen_script() -> Script:
	return BEST_SCREEN


## The schedule's script: best_timeline.gd, or a subclass of it (buffs.gd).
func timeline_script() -> GDScript:
	return TIMELINE


## The plan the report keeps (fight_compare.gd).
func plan() -> Dictionary:
	if timeline == null:
		return {}
	var out: Dictionary = timeline.call("report")
	return out
