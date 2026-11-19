extends Mechanic
## Grows every friendly piler Mouse after its pile-on.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_CANT_ATTACK else value
