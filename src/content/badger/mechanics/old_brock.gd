extends Mechanic
## Old Brock: after a friendly unit dies (9.7.2 step 3), gain its own Attack and own maximum
## Health this fight (SHARED-RULES 43). Every friendly death pays, summoned units and each death
## of a returning unit included. Golden: double (`times`).


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func after_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or dead == unit or dead.side != unit.side:
		return
	if combat.trigger(unit, &"badger_old_brock"):
		var times: int = params.num(&"times")
		combat.buff(unit, dead.stats.own_attack() * times, dead.stats.own_health() * times, unit)
