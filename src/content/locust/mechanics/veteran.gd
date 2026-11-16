extends Mechanic
## Twice-shed Veteran. After another friendly unit returns (Molt or Root; 9.7.2 step 5), it and
## this gain +`amount`/+`amount` this fight.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func after_friendly_return(
	combat: Combat, unit: CombatUnit, back: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or back.gone or not combat.trigger(unit, &"locust_veteran"):
		return
	var amount: int = params.num(&"amount")
	combat.buff(back, amount, amount, unit)
	combat.buff(unit, amount, amount, unit)
