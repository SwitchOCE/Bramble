extends Mechanic
## Applies to every positive damage source, before Shield and Shell.


func modify_damage_taken(_unit: CombatUnit, params: Dictionary, hit: Hit) -> int:
	if hit.modifiers.has("damage_reduction"):
		return hit.amount
	hit.modifiers.append("damage_reduction")
	return maxi(0, hit.amount - StatFraction.loss(hit.amount, params, "n"))
