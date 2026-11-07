extends Mechanic
## Mrs Dunnock: End of Turn, standing on a Nest, that bird comes home `turns` sooner (next turn at
## the soonest).


func on_end_of_turn(ctx: RecruitContext) -> void:
	if ctx.source_slot < 0 or ctx.player.nest_at(ctx.source_slot).is_empty():
		return
	ctx.announce("dunnock")
	HeldUnits.shorten_trip(ctx.player, ctx.source_slot, CoreUtil.to_int(ctx.params.get("turns", 1)))
