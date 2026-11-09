extends Mechanic
## Recruit swallows from shop, hand and board grow this once a turn.


func on_swallow(ctx: RecruitContext) -> void:
	if ctx.source_slot < 0 or ctx.source.limits.has("stone_soup"):
		return
	ctx.source.limits["stone_soup"] = 1
	ctx.announce("stone_soup")
	var stats: int = CoreUtil.to_int(ctx.params.get("stats", 1))
	ctx.buff(ctx.source, stats, stats, "permanent")
