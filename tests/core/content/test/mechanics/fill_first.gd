extends Mechanic
## A Guard post stand-in: Reserve units fill slot `slot` first.


func param_kinds() -> Dictionary:
	return {"slot": MechanicParams.Kind.THRESHOLD}


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, params: MechanicParams
) -> int:
	if unit != null and query == Q_FILL_FIRST:
		return params.num(&"slot")
	return value
