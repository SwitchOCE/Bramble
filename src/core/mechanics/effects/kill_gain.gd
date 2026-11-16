extends Mechanic
## After this kills a unit (9.7.2 step 1): gain +attack/+health this combat, if it is alive.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER, "health": MechanicParams.Kind.NUMBER}


func on_kill(combat: Combat, unit: CombatUnit, _victim: CombatUnit, params: MechanicParams) -> void:
	if unit.gone or not combat.trigger(unit, &"kill_gain"):
		return
	combat.buff(unit, params.num(&"attack"), params.num(&"health"), unit)
