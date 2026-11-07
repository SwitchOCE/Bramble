extends Mechanic


func after_combat(ctx: RecruitContext) -> void:
	var takes: int = mini(ctx.player.takes_last_fight, CoreUtil.to_int(ctx.params["takes_max"]))
	if takes <= 0:
		return
	ctx.announce("ermeline")
	if ctx.player.tier >= UnitLibrary.TIERS:
		var cap: int = CoreUtil.to_int(ctx.params["gold_max"]) + (1 if ctx.source.golden else 0)
		ctx.player.gold_next_turn += mini(cap, takes * CoreUtil.to_int(ctx.params["discount"]))
	else:
		ctx.player.hunt_discount_next += takes * CoreUtil.to_int(ctx.params["discount"])
