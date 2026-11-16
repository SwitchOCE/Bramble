extends Mechanic
## Thorns: whenever this is attacked, it deals `amount` damage to the attacker first (step 1).


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_attacked(
	combat: Combat, unit: CombatUnit, attacker: CombatUnit, params: MechanicParams
) -> void:
	if combat.trigger(unit, &"test_thorns"):
		combat.deal_damage(unit, attacker, params.num(&"amount"))
