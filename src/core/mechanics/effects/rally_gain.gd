extends Mechanic
## Whenever this attacks (9.6.1 step 2, like HSBG's Rally): gain +attack this combat.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, params: MechanicParams
) -> void:
	if combat.trigger(unit, &"rally_gain"):
		combat.buff(unit, params.num(&"attack"), 0, unit)
