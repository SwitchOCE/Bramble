extends Mechanic
## After a friendly unit returns, give your units +N/+N permanently (Hazel Coppicer). Any return
## (Root, Molt); not Reserve, a summon or a copy. Permanent, so it also reaches each unit's
## recruit-board self; units that exist only in this fight keep it for the fight.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func after_friendly_return(
	combat: Combat, unit: CombatUnit, back: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or back.side != unit.side or not combat.trigger(unit, &"thorn_coppicer"):
		return
	var amount: int = params.num(&"amount")
	for friend: CombatUnit in combat.units(unit.side).duplicate():
		combat.buff(friend, amount, amount, unit, true)
