class_name FightReport
extends RefCounted
## What a player's units learn after their fight (Mechanic.after_fight): the outcome and which
## of the player's own units were on the board at the end.

## 1 won, 0 tie, -1 lost.
var outcome: int = 0
## The opponent's player id (Matchmaking.GHOST for the ghost).
var opponent: int = -1
## Recruit uids of this player's units alive (themselves or a return) at the end.
var survivors: Array[int] = []
## Friendly units that died in the fight, tokens included.
var deaths: int = 0
## Outnumbered: how many more counted units the enemy had at fight start (Combat.outnumbered_by).
var outnumbered_by: int = 0


func survived(unit: Unit) -> bool:
	return unit != null and survivors.has(unit.uid)


func won() -> bool:
	return outcome > 0
