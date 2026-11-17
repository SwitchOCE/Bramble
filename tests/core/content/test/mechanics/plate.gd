extends Mechanic
## Damage from attacks is reduced by `amount`, to no less than 1.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func absorb_damage(
	_combat: Combat, _unit: CombatUnit, amount: int, from_attack: bool, params: MechanicParams
) -> int:
	if not from_attack or amount <= 0:
		return amount
	return maxi(1, amount - params.num(&"amount"))
