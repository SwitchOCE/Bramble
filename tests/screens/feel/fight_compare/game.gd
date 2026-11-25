extends "res://tests/screens/feel/fight_compare/fight_treatment.gd"
## `game`: the game's own card motion now (src/screens/fight/fight_motion.gd, with the turn toward
## the target since 25 Nov) on the game's own fight screen and replay, to film the real game on the
## comparison fight. `today` is the motion from before the turn (today_motion.gd). "ROTATE" does
## nothing here: the game always turns.


func make_motion(cards: Control) -> FightMotion:
	return FightMotion.new(cards)
