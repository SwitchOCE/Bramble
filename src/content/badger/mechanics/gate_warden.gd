extends Mechanic
## Gate Warden: whenever this is attacked (9.6.1 step 1, before damage), gain +attack/+health
## permanently.
## A Hit, Overrun's carried damage and other plain damage are not attacks.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER, "health": MechanicParams.Kind.NUMBER}


func on_attacked(
	combat: Combat, unit: CombatUnit, _attacker: CombatUnit, params: MechanicParams
) -> void:
	if combat.trigger(unit, &"badger_gate_warden"):
		combat.buff(unit, params.num(&"attack"), params.num(&"health"), unit, true)
