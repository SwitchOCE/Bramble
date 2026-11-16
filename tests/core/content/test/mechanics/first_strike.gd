extends Mechanic
## Strikes first: a defender this kills doesn't strike back.


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_STRIKES_FIRST else value
