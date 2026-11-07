extends Mechanic
## Stone Soup: after you buy a unit into any Belly, the units in your shop gain `stats`. A unit bought
## keeps it; a refresh or the end of the turn washes the rest out (HeldUnits.wash_shop).


func on_swallow(ctx: RecruitContext) -> void:
	if ctx.paid and ctx.source_slot >= 0:
		ctx.announce("stone_soup")
		HeldUnits.soak_shop(ctx.player, CoreUtil.to_int(ctx.params.get("stats", 1)))
