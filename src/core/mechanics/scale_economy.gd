extends Mechanic
## Income reaches the next recruit turn and can pay for ordinary stat-buying lines.


func on_end_of_turn(ctx: RecruitContext) -> void:
	if not ctx.rules.config.lever_enabled("scale_economy") or ctx.source_slot < 0:
		return
	var income: int = CoreUtil.to_int(ctx.source.counters.get("scale_income", 0)) + 1
	income = clampi(income, 0, maxi(0, ctx.rules.config.get_int("scale_economy_cap")))
	ctx.source.counters["scale_income"] = income
	ctx.announce("scale_economy")
	ctx.gain_gold(income * ctx.source.golden_factor(), "next_turn")
