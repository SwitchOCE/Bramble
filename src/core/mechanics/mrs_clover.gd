extends Mechanic
## Recruiting summons grow permanently. Combat summons grow twice per fight.


func on_summon(ctx: RecruitContext) -> void:
	if ctx.subject == null:
		return
	ctx.announce("mrs_clover")
	var stats: int = CoreUtil.to_int(ctx.params["stats"])
	ctx.buff(ctx.subject, stats, stats, "permanent")


func hears_allies(_params: Dictionary) -> bool:
	return true


func on_ally_summon(
	combat: Combat, unit: CombatUnit, params: Dictionary, summoned: CombatUnit
) -> void:
	var used: int = CoreUtil.to_int(unit.limits.get("mrs_clover", 0))
	if used >= CoreUtil.to_int(params["limit"]):
		return
	unit.limits["mrs_clover"] = used + 1
	var stats: int = CoreUtil.to_int(params["stats"])
	combat.trigger(unit, "mrs_clover")
	combat.buff(summoned, stats, stats, unit)
