extends Mechanic
## Squire: in the back row, this isn't counted for Outnumbered (on either side).


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_UNCOUNTED else value
