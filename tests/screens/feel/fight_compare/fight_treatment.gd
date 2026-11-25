extends RefCounted
## An animation treatment for the comparison fight (fight_compare.gd): what the fight screen's
## motion is, and which steps the fight log becomes and how long each is held. This base class is
## `today`: the game's motion as it was before the turn came into src/ (today_motion.gd, a kept
## copy of FightMotion) and the game's FightReplay.build. A treatment extends this file, overrides
## only what it changes, and is named once in treatments.gd.
## Nothing here is used by the game.

const COMPARE_SCREEN: Script = preload("res://tests/screens/feel/fight_compare/compare_screen.gd")
const Rotate := preload("res://tests/screens/feel/fight_compare/rotate.gd")
const ROTATE_MOTION: GDScript = preload("res://tests/screens/feel/fight_compare/rotate_motion.gd")
const TODAY_MOTION: GDScript = preload("res://tests/screens/feel/fight_compare/today_motion.gd")

## The rotation switch (rotate.gd): "options": {"ROTATE": "on"} turns every attacker toward its
## target, on top of this treatment's own motion.
var rotate: bool = false
## Its numbers (rotate.gd SET, or SET_LEAN for "ROTATE": "lean").
var rotate_set: Dictionary = Rotate.SET


## The scenario's options (fight_compare.gd calls this before make_replay). A treatment that
## overrides it calls super, for the rotation switch.
func configure(chosen: Dictionary) -> void:
	rotate = Rotate.on(chosen)
	rotate_set = Rotate.set_of(chosen)


## The card motion the screen uses: a FightMotion (attack, hit, death, burst); today's is
## today_motion.gd. With rotation on, today's motion with the turn added (rotate_motion.gd).
func make_motion(cards: Control) -> FightMotion:
	if not rotate:
		return TODAY_MOTION.new(cards)
	var made: FightMotion = ROTATE_MOTION.new(cards)
	return turned(made)


## A rotate_motion.gd (or a subclass, pilot_motion.gd) with the switch set as this treatment's.
func turned(motion: FightMotion) -> FightMotion:
	motion.set("turn_on", rotate)
	motion.set("turn_set", rotate_set)
	return motion


## The replay the screen plays: its steps, their order and holds. A treatment may return a
## FightReplay subclass (replay_with) or change the steps of FightReplay.build's result.
func make_replay(base: Dictionary, events: Array, catalog: Dictionary, damage: int) -> FightReplay:
	return FightReplay.build(base, events, catalog, damage)


## The screen script: compare_screen.gd, or a subclass of it for a treatment that changes how the
## screen plays steps (FightScreen._next_step, _process).
func screen_script() -> Script:
	return COMPARE_SCREEN


## FightReplay.build with a FightReplay subclass in its place, for a treatment that overrides
## FightReplay's methods (such as _push, where every step's hold is set).
static func replay_with(
	script: GDScript, base: Dictionary, events: Array, catalog: Dictionary, damage: int
) -> FightReplay:
	var replay: FightReplay = script.new()
	replay._base = base
	replay._catalog = catalog
	for side: int in 2:
		var row: Array = []
		row.resize(FightReplay.SLOTS)
		replay.boards[side] = row
	for value: Variant in FightReplay.mark_pile_ons(events):
		if value is Dictionary:
			var event: Dictionary = value
			replay.apply(event, damage)
	return replay
