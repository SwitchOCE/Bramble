extends Mechanic
## Pennywort Snail: sells for `gold` more per turn it ended on your board, up to `turns` turns
## (RecruitRules.sell_value reads the count).


func on_end_of_turn(ctx: RecruitContext) -> void:
	if ctx.source_slot < 0:
		return
	var held: int = CoreUtil.to_int(ctx.source.counters.get("savings", 0))
	var grown: int = mini(held + 1, CoreUtil.to_int(ctx.params.get("turns", 0)))
	if grown > held:
		ctx.source.counters["savings"] = grown
		ctx.buff(ctx.source, 0, CoreUtil.to_int(ctx.params.get("health", 0)), "permanent")
		ctx.announce("savings")
