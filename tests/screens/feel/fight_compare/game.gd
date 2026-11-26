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


## The game's replay, scheduled before the fixture reads its steps. The loss's parts come from the
## log's counts here, as pilot.gd's (big_loss; the base is the damage less a big loss's extra); the
## game takes them from the session (its fight entry's `loss`).
func make_replay(base: Dictionary, events: Array, catalog: Dictionary, damage: int) -> FightReplay:
	var big: bool = Pilot.big_loss(events)
	var extra: int = GameConfig.new().big_loss_extra if big else 0
	var loss: Dictionary = {"big": big, "base": damage - extra, "extra": extra}
	var replay: FightReplay = FightReplay.build(base, events, catalog, damage, loss)
	FightScreen.schedule(replay)
	return replay


func screen_script() -> Script:
	return GAME_SCREEN
