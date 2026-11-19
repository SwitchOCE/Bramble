extends Mechanic


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, params: MechanicParams
) -> int:
	if unit != null and query == Q_HAND_RENOWN_TIMES:
		return maxi(value, 3 if params.golden else 2)
	return value
