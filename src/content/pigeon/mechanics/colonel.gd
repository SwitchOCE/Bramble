extends Mechanic
## The Colonel: while this is on the board when a fight starts, every unit in the player's hand
## is in Reserve for that fight, left to right, tokens included (the core reads Q_HAND_RESERVE
## once, as the fight starts, so they keep it if the Colonel dies).


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
) -> int:
	if unit != null and query == Q_HAND_RESERVE:
		return 1
	return value
