extends Mechanic
## When this dies, summon `count` Sprouts if there is room. In the Recruit
## Phase (eaten), one Sprout on the recruit board.


func param_kinds() -> Dictionary:
	return {"count": MechanicParams.Kind.NUMBER}


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if not combat.trigger(unit, &"test_swarm_spawn"):
		return
	for _i: int in params.num(&"count"):
		combat.summon(unit.side, &"tk_sprout", unit.slot, true, unit)


func on_recruit_death(ctx: RecruitContext, unit: Unit, _params: MechanicParams) -> void:
	if ctx.trigger(unit, &"test_swarm_spawn"):
		ctx.summon(&"tk_sprout", -1)


func has_death_effect() -> bool:
	return true
