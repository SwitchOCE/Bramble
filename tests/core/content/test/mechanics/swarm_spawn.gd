extends Mechanic
## Waiting summons: when this dies, `count` Sprouts that wait for empty slots. In the Recruit
## Phase (eaten), one Sprout on the recruit board.


func param_kinds() -> Dictionary:
	return {"count": MechanicParams.Kind.NUMBER}


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if not combat.trigger(unit, &"test_swarm_spawn"):
		return
	for _i: int in params.num(&"count"):
		combat.summon(unit.side, &"tk_sprout", unit.slot, true, unit, true)


func on_recruit_death(ctx: RecruitContext, unit: Unit, _params: MechanicParams) -> void:
	if ctx.trigger(unit, &"test_swarm_spawn"):
		ctx.summon(&"tk_sprout", -1)
