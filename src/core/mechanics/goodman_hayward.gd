extends Mechanic


func recruit_hook(ctx: RecruitContext) -> void:
	if ctx.trigger != "on_item_played":
		return
	var item: String = str(ctx.card_def.get("id", ""))
	if item != "stash" and item != "great_hoard":
		return
	ctx.announce("goodman_hayward")
	var stats: int = CoreUtil.to_int(ctx.params["stats"])
	var touched: Array[int] = BoardGeometry.touching(ctx.player.occupied(), ctx.source_slot)
	for slot: int in touched:
		var unit: RecruitUnit = ctx.player.board[slot]
		if unit.has_tribe("Hedgerow folk"):
			ctx.buff(unit, stats, stats, "permanent")
