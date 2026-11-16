extends Mechanic
## When this dies, summon a Pip (Crab-apple): a 3/3 Briar with Seed, into this unit's slot, else
## the nearest empty one; with no room it is lost (Pips don't wait). A golden Crab-apple summons
## a golden Pip (6/6, and its Seed adds 2). Eaten in the shop, the Pip goes on the recruit board
## like any summon.

const PIP: StringName = &"pip"


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if combat.trigger(unit, &"thorn_pip"):
		combat.summon(unit.side, PIP, unit.slot, true, unit, false, {}, params.golden)


func on_recruit_death(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if ctx.trigger(unit, &"thorn_pip"):
		ctx.summon(PIP, unit.slot, false, params.golden)
