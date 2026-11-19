extends Mechanic
## 11.2.7 Cleave: also damages one random unit next to the target, in its row (owner, 19 Nov).


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_CLEAVE else value
