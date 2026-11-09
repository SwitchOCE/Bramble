extends Mechanic

const HexValue := preload("res://src/core/hex_value.gd")
## Hex: Start of Combat, the enemy slot across from this has less Attack. Each spell you cast adds
## `n`, kept in the unit's "hex" counter (the card's own number on top), up to `most` in all.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	if params.has("percent"):
		combat.trigger(unit, "hex")
		CombatScale.add_hex(
			combat,
			unit,
			1 - unit.side,
			BoardGeometry.across(unit.slot),
			(
				CoreUtil.to_int(params["percent"])
				+ CoreUtil.to_int(unit.counters.get("hex_percent", 0))
			)
		)
		return
	var amount: int = HexValue.amount(
		CoreUtil.to_int(params.get("n", 0)),
		CoreUtil.to_int(unit.counters.get("hex", 0)),
		HexValue.ceiling(params, combat.tier_of(unit.side))
	)
	combat.trigger(unit, "hex")
	combat.add_hex(unit, 1 - unit.side, BoardGeometry.across(unit.slot), amount)


func on_spell_cast(ctx: RecruitContext) -> void:
	if ctx.params.has("percent"):
		ctx.source.counters["hex_percent"] = (
			CoreUtil.to_int(ctx.source.counters.get("hex_percent", 0))
			+ CoreUtil.to_int(ctx.params["percent"])
		)
		return
	var grown: int = CoreUtil.to_int(ctx.source.counters.get("hex", 0))
	ctx.source.counters["hex"] = grown + CoreUtil.to_int(ctx.params.get("n", 0))
