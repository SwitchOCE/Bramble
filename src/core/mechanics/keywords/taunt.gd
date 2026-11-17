extends Mechanic
## 11.2.1 Taunt (example keyword): must be attacked, within the row that can be attacked (9.5.4).


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_TAUNT else value
