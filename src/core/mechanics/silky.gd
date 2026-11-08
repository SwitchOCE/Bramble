extends Mechanic
## The departing Silky receives the event too, so she can Ring her own vacated slot.


func recruit_hook(ctx: RecruitContext) -> void:
	if ctx.trigger != "on_shy_left" or not BoardGeometry.is_valid(ctx.amount):
		return
	ctx.announce("silky")
	var stats: int = CoreUtil.to_int(ctx.params.get("stats", 2))
	ctx.add_slot_effect(ctx.amount, {"name": BoardUpkeep.RING, "attack": stats, "health": stats})
