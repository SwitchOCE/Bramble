extends Mechanic


func param_kinds() -> Dictionary:
	return {"damage": MechanicParams.Kind.NUMBER}


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var killer: CombatUnit = combat.killer_of(unit)
	if killer != null and not killer.gone and not killer.should_die():
		if combat.trigger(unit, &"sting_killer"):
			combat.deal_damage(unit, killer, params.num(&"damage"))
