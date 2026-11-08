extends Mechanic
## A shortened trip can bring home the rest of the flock, including Cuckoo-delayed Birds.


func on_home(ctx: RecruitContext) -> void:
	if ctx.source != ctx.subject:
		return
	ctx.announce("tern")
	HeldUnits.land_flock(ctx.rules, ctx.player)
