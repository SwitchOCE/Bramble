extends Mechanic
## Takes no damage for the duration of its own attack against a back-row defender.


func modify_damage_taken(unit: CombatUnit, _params: Dictionary, hit: Hit) -> int:
	if not unit.counters.has("attacking_back_row"):
		return hit.amount
	hit.modifiers.append("back_row_immunity")
	return 0
