extends "res://tests/screens/feel/fight_compare/fight_treatment.gd"
## `game`: the game's own fight now, to film the real game on the comparison fight: the game's
## FightReplay scheduled by its FightTimeline (the best proposal with the owner's picks, plan step
## 1b), played by the game's own FightScreen and FightMotion, with its sound cues. `today` is the
## game from before the turn (today_motion.gd and compare_screen.gd's step playback). "ROTATE"
## does nothing here: the game always turns.

const GAME_SCREEN: Script = preload("res://src/screens/fight/fight_screen.gd")
const Pilot := preload("res://tests/screens/feel/fight_compare/pilot.gd")


func make_motion(cards: Control) -> FightMotion:
	return FightMotion.new(cards)


## The game's replay, scheduled before the fixture reads its steps. Whether the loss was big comes
## from the log's counts here (pilot.gd big_loss); the game takes it from the session.
func make_replay(base: Dictionary, events: Array, catalog: Dictionary, damage: int) -> FightReplay:
	var big: bool = Pilot.big_loss(events)
	var replay: FightReplay = FightReplay.build(base, events, catalog, damage, big)
	FightScreen.schedule(replay)
	return replay


func screen_script() -> Script:
	return GAME_SCREEN
