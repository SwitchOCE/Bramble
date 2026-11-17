extends Mechanic
## Can't attack.


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_CANT_ATTACK else value
