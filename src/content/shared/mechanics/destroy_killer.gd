extends Mechanic


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	var killer: CombatUnit = combat.killer_of(unit)
	if killer != null and not killer.gone and not killer.should_die():
		if combat.trigger(unit, &"destroy_killer"):
			combat.destroy(unit, killer)
