extends Mechanic


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	for i: int in params.num(&"times"):
		var target: CombatUnit = combat.weakest_enemy(unit)
		if target == null or unit.attack() <= 0 or combat.halted():
			return
		if i == 0 and not combat.trigger(unit, &"ballista"):
			return
		combat.hit(unit, target)
