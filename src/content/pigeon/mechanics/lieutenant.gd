extends Mechanic


func param_kinds() -> Dictionary:
	return {"percent": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var row: Array[int] = combat.geometry.row_of(unit.slot)
	var dealers: Array[CombatUnit] = []
	for slot: int in row:
		var here: CombatUnit = combat.unit_at(unit.side, slot)
		if here == null or here.gone:
			return
		dealers.append(here)
	if not combat.trigger(unit, &"pigeon_lieutenant"):
		return
	for dealer: CombatUnit in dealers:
		var amount: int = int(
			combat.bridge(unit.side).slot(dealer.slot).renown * params.num(&"percent") / 100.0
		)
		if amount <= 0 or combat.halted():
			continue
		var target: CombatUnit = combat.unit_at(
			1 - dealer.side, combat.geometry.across(dealer.slot)
		)
		if target != null and not target.should_die():
			combat.deal_damage(dealer, target, amount)
