extends Mechanic
## Recruit swallows from shop, hand and board grow this once a turn.


func on_swallow(ctx: RecruitContext) -> void:
	if (
		ctx.source_slot < 0
		or (
			CoreUtil.to_int(ctx.source.limits.get("stone_soup", 0))
			>= CoreUtil.to_int(ctx.params.get("limit", 1))
		)
	):
		return
	ctx.source.limits["stone_soup"] = CoreUtil.to_int(ctx.source.limits.get("stone_soup", 0)) + 1
	ctx.announce("stone_soup")
	var stats: int = CoreUtil.to_int(ctx.params.get("stats", 1))
	ctx.buff(ctx.source, stats, stats, "permanent")
