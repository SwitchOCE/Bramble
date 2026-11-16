extends Mechanic
## Once a fight, returns as its recruit unit stands, at full Health (Root).


func combat_query(unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	if query == Q_RETURN_AS_RECRUIT:
		return 1
	if query == Q_RETURN_HEALTH and unit.returns == 0:
		return maxi(value, 999)
	return value
