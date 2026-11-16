extends Mechanic
## Mother of Thousands. Whenever you summon Hoppers, summon (1 + `extra`) times as many: twice,
## three times on a golden. Two don't add up (the biggest applies). In a fight it must be on
## the board; in the shop, on the recruit board.

const Locust := preload("res://src/content/locust/lib/locust.gd")


func param_kinds() -> Dictionary:
	return {"extra": MechanicParams.Kind.NUMBER}


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, params: MechanicParams
) -> int:
	if unit != null and query == Locust.Q_HOPPER_TIMES:
		return maxi(value, 1 + params.num(&"extra"))
	return value


func modify_int(
	query: StringName, value: int, _player: PlayerState, _unit: Unit, params: MechanicParams
) -> int:
	return maxi(value, 1 + params.num(&"extra")) if query == Locust.Q_HOPPER_TIMES else value
