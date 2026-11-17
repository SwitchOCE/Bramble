extends Mechanic
## 11.2.7 Cleave (example keyword): also damages the units adjacent to the target, in its row.


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_CLEAVE else value
