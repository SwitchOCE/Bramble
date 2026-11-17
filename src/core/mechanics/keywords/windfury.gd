extends Mechanic
## 11.2.3 Windfury (example keyword): attacks twice in a row each cycle; golden is still two.


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return maxi(value, 2) if query == Q_ATTACKS else value
