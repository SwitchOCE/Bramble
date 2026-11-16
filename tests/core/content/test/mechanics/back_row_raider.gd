extends Mechanic
## 9.5.7 attacks the enemy back row while it has units.


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return ROW_BACK if query == Q_TARGET_ROW else value
