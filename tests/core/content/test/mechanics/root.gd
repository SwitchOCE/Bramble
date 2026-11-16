extends Mechanic
## A return that costs: once a fight, if `cost` entries can be spent, it comes back with 1
## Health and spends them.


func param_kinds() -> Dictionary:
	return {"cost": MechanicParams.Kind.THRESHOLD}


func return_health(combat: Combat, unit: CombatUnit, health: int, params: MechanicParams) -> int:
	if unit.returns > 0 or combat.bridge(unit.side).heap(&"test_heap").size() < params.num(&"cost"):
		return health
	return maxi(health, 1)


func on_returned(
	combat: Combat, gone: CombatUnit, _back: CombatUnit, params: MechanicParams
) -> void:
	combat.bridge(gone.side).heap_spend(&"test_heap", params.num(&"cost"), gone)
