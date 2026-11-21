extends Mechanic


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_ONLY_ATTACK_DAMAGE else value
