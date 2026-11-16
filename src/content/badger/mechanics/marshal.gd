extends Mechanic
## Marshal of the Red Mist: while this is on the board, every friendly unit's Fury counts double
## (golden: triple), applied after everything that adds Fury. Two Marshals don't stack: the
## biggest applies. `extra` is what it adds to the multiplier (1, or 2 on a golden).

const BadgerRules := preload("res://src/content/badger/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"extra": MechanicParams.Kind.NUMBER}


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, params: MechanicParams
) -> int:
	if unit == null or query != BadgerRules.Q_FURY_TIMES:
		return value
	return maxi(value, 1 + params.num(&"extra"))
