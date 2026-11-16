extends Mechanic
## Bugler: after a friendly Pigeon joins the fight (summoned, or stepping in from Reserve; a
## return is not joining, SHARED-RULES 22), give every friendly Pigeon on the board
## +amount/+amount for this fight, the new one included.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_fight_enter(
	combat: Combat, unit: CombatUnit, entered: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or entered == null or entered.side != unit.side or entered.returns > 0:
		return
	if not entered.def.has_tribe("Pigeon") or not combat.trigger(unit, &"pigeon_bugler"):
		return
	var amount: int = params.num(&"amount")
	for friend: CombatUnit in combat.units(unit.side).duplicate():
		if not friend.gone and friend.def.has_tribe("Pigeon"):
			combat.buff(friend, amount, amount, unit)
