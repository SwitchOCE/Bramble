extends Mechanic
## Hex: Start of Combat, the enemy slot across from this has less Attack. Each spell you cast adds
## `n`, kept in the unit's "hex" counter (the card's own number is added on top).


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var amount: int = CoreUtil.to_int(params.get("n", 0))
	amount += CoreUtil.to_int(unit.counters.get("hex", 0))
	combat.trigger(unit, "hex")
	combat.add_hex(unit, 1 - unit.side, BoardGeometry.across(unit.slot), amount)


func on_spell_cast(ctx: RecruitContext) -> void:
	var grown: int = CoreUtil.to_int(ctx.source.counters.get("hex", 0))
	ctx.source.counters["hex"] = grown + CoreUtil.to_int(ctx.params.get("n", 0))
