extends Mechanic
## The Colonel: while this is on the board when a fight starts, every unit in your hand has
## Reserve for that fight (Q_HAND_RESERVE).


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
) -> int:
	if unit != null and query == Q_HAND_RESERVE:
		return 1
	return value
