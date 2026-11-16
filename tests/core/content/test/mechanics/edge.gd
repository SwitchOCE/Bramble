extends Mechanic
## In fights, your slots give double Attack (fight-time slot multiplier).


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
) -> int:
	if unit != null and query == Q_SLOT_ATTACK_PERCENT:
		return value * 2
	return value
