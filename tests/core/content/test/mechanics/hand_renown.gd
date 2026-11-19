extends Mechanic
## The Colonel's Renown hook, as a stand-in: reservists from your hand have double Renown (golden:
## triple) while this is on the board (Q_HAND_RENOWN_TIMES).


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, params: MechanicParams
) -> int:
	if unit != null and query == Q_HAND_RENOWN_TIMES:
		return maxi(value, 3 if params.golden else 2)
	return value
