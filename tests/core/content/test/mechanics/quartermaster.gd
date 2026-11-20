extends Mechanic
## A Quartermaster stand-in: one more reservist from the hand steps in each fight
## (Q_RESERVE_LIMIT), while this is on the board.


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
) -> int:
	if unit != null and query == Q_RESERVE_LIMIT:
		return value + 1
	return value
