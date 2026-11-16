extends Mechanic
## Any sale: this gains the sold unit's stats for good, and the sold unit's death effects
## resolve in the Recruit Phase.


func on_any_sold(ctx: RecruitContext, unit: Unit, sold: Unit, _params: MechanicParams) -> void:
	if unit == null or sold.is_spell() or not ctx.trigger(unit, &"test_eat"):
		return
	ctx.buff(unit, sold.attack(), sold.health(), true, unit)
	ctx.run_death_effects(sold)
