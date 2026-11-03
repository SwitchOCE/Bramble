extends Mechanic
## Hunker (library entry 1): when an enemy attacks this, the attack damage this takes is halved,
## rounded up. Only attack damage while defending; halves once (SPEC 4.2).


func modify_damage_taken(_unit: CombatUnit, _params: Dictionary, hit: Hit) -> int:
	if hit.kind != Hit.ATTACK or not hit.on_defender or hit.modifiers.has("hunker"):
		return hit.amount
	hit.modifiers.append("hunker")
	return ceili(hit.amount / 2.0)
