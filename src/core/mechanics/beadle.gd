extends Mechanic
## Actual Acorn gains count, including Acorns brought back from the previous fight.


func recruit_hook(ctx: RecruitContext) -> void:
	if ctx.trigger != "on_item_gained" or str(ctx.card_def.get("id", "")) != "acorn":
		return
	var used: int = CoreUtil.to_int(ctx.source.limits.get("beadle", 0))
	if used >= CoreUtil.to_int(ctx.params.get("limit", 1)):
		return
	ctx.source.limits["beadle"] = used + 1
	ctx.announce("beadle")
	var stats: int = CoreUtil.to_int(ctx.params["stats"])
	ctx.queue_pass(stats, stats)
