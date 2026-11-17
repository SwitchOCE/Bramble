extends Mechanic
## A side rule: your death effects resolve twice, in fights and in the Recruit Phase.


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
) -> int:
	if unit != null and query == Q_DEATH_EFFECT_TIMES:
		return maxi(value, 2)
	return value


func modify_int(
	query: StringName, value: int, _player: PlayerState, _unit: Unit, _params: MechanicParams
) -> int:
	return maxi(value, 2) if query == Q_DEATH_EFFECT_TIMES else value
