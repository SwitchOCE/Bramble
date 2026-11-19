extends Mechanic
## 11.2.7 Cleave: also damages one unit next to the target, in its row, picked at random (owner, 19 Nov 2026).


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_CLEAVE else value
