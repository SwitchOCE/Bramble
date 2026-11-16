extends Mechanic
## Sortie: attacks the enemy back row while it has units. A front-row Guard is ignored; a
## back-row Guard applies (the core picks Guard among the chosen row's units).


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return ROW_BACK if query == Q_TARGET_ROW else value
