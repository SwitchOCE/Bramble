extends RefCounted
## An animation treatment for the comparison fight (fight_compare.gd): what the fight screen's
## motion is, and which steps the fight log becomes and how long each is held. This base class is
## `today`: exactly what the game does now (FightMotion, FightReplay.build). A treatment extends
## this file, overrides only what it changes, and is named once in treatments.gd.
## Nothing here is used by the game.

const COMPARE_SCREEN: Script = preload("res://tests/screens/feel/fight_compare/compare_screen.gd")


## The card motion the screen uses: FightMotion or a subclass of it (attack, hit, death, burst).
func make_motion(cards: Control) -> FightMotion:
	return FightMotion.new(cards)


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
