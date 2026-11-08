extends Mechanic
## Away strikes are read by HeldUnits and CombatHeld; coming home grows every owned Bird.


func on_home(ctx: RecruitContext) -> void:
	if ctx.source != ctx.subject:
		return
	ctx.announce("mother_goose")
	for bird: RecruitUnit in ctx.player.all_units():
		if bird.has_tribe(HeldUnits.BIRDS):
			ctx.buff(
				bird,
				CoreUtil.to_int(ctx.params.get("attack", 1)),
				CoreUtil.to_int(ctx.params.get("health", 1)),
				"permanent"
			)
