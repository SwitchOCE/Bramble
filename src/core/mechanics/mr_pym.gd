extends Mechanic


func recruit_hook(ctx: RecruitContext) -> void:
	if ctx.trigger != "on_item_gained" or str(ctx.card_def.get("id", "")) != "stash":
		return
	ctx.announce("mr_pym")
	var stats: int = CoreUtil.to_int(ctx.params["stats"])
	ctx.queue_pass(stats, stats)
