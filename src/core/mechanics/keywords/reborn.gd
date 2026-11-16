extends Mechanic
## 11.2.4 Reborn (example keyword): the first time this unit dies in a combat, it returns with
## 1 Health as a fresh copy (9.8.2) and can't return again that combat.


func combat_query(unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	if query == Q_RETURN_HEALTH and unit.returns == 0:
		return maxi(value, 1)
	return value


func on_returned(
	combat: Combat, gone: CombatUnit, back: CombatUnit, _params: MechanicParams
) -> void:
	combat.show_status(back, &"reborn", false, gone)
