extends Mechanic
## When this is attacked (9.6.1 step 1): gain +health this combat, before damage.


func param_kinds() -> Dictionary:
	return {"health": MechanicParams.Kind.NUMBER}


func on_attacked(
	combat: Combat, unit: CombatUnit, _attacker: CombatUnit, params: MechanicParams
) -> void:
	if combat.trigger(unit, &"attacked_gain"):
		combat.buff(unit, 0, params.num(&"health"), unit)
