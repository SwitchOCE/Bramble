extends Mechanic
## A stand-in Tavern spell's effect (6.2): Discover a unit of the player's tier or lower.


func on_played(ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams) -> void:
	if ctx.trigger(unit, &"discover"):
		ctx.discover(1, ctx.player.tier)
