extends Mechanic


func on_take(
	combat: Combat, unit: CombatUnit, params: Dictionary, hunter: CombatUnit, dead: CombatUnit
) -> void:
	if unit != hunter or dead.tier() > combat.tier_of(unit.side) or not dead.def.get("pool", false):
		return
	combat.trigger(unit, "poach")
	combat.carry_back(
		unit.side, {"op": "poach", "card": dead.def_id(), "discount": params["discount"]}
	)
	combat.emit_event("poach", {"hunter": unit.uid, "quarry": dead.uid, "card": dead.def_id()})
