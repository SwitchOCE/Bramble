extends Mechanic
## In the back row, this isn't counted for Outnumbered.


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_UNCOUNTED else value
