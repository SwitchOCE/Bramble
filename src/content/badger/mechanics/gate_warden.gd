extends Mechanic
## Gate Warden: whenever this is attacked (9.6.1 step 1, before damage), gain +N/+N permanently.
## A Hit, Overrun's carried damage and other plain damage are not attacks.


func param_kinds() -> Dictionary:
	return {"gain": MechanicParams.Kind.NUMBER}


func on_attacked(
	combat: Combat, unit: CombatUnit, _attacker: CombatUnit, params: MechanicParams
) -> void:
	if combat.trigger(unit, &"badger_gate_warden"):
		var gain: int = params.num(&"gain")
		combat.buff(unit, gain, gain, unit, true)
