extends Mechanic
## Dirge-singer. Your death effects trigger (1 + `extra`) times: twice, three times on a golden,
## however they were set off (a death, a drumbeat, being eaten). Two don't add up. Not "after a
## friendly unit dies" effects or returns (ruling 33).


func param_kinds() -> Dictionary:
	return {"extra": MechanicParams.Kind.NUMBER}


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, params: MechanicParams
) -> int:
	if unit != null and query == Q_DEATH_EFFECT_TIMES:
		return maxi(value, 1 + params.num(&"extra"))
	return value


func modify_int(
	query: StringName, value: int, _player: PlayerState, _unit: Unit, params: MechanicParams
) -> int:
	return maxi(value, 1 + params.num(&"extra")) if query == Q_DEATH_EFFECT_TIMES else value
