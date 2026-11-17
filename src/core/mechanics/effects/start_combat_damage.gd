extends Mechanic
## Start of Combat (9.3): deal `amount` damage to a random enemy (9.5.6: either row).


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var target: CombatUnit = combat.random_enemy(unit)
	if target == null or not combat.trigger(unit, &"start_combat_damage"):
		return
	combat.deal_damage(unit, target, params.num(&"amount"))
