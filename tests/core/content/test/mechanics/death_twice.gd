extends Mechanic
## A side rule: your death effects resolve twice.


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
) -> int:
	if unit != null and query == Q_DEATH_EFFECT_TIMES:
		return maxi(value, 2)
	return value
