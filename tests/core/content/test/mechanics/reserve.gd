extends Mechanic
## Reserve: in a fight, this steps from the hand into a slot a friendly unit died in.


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_RESERVE else value
