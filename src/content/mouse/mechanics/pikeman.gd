extends Mechanic
## Needle Pikeman: can't attack (skipped in the attack order, and "attacks immediately" does
## nothing). After each pile-on it gains +attack Attack permanently, `limit` times a fight; the
## gain is made in MouseRules.after_pile_on, after the hit that earned it.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER, "limit": MechanicParams.Kind.THRESHOLD}


func combat_query(_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	return 1 if query == Q_CANT_ATTACK else value
