extends Mechanic
## Master-at-Arms: Recruit: give a friendly unit (itself included, 7.2.3) +{amount} Fury
## for good, through RecruitContext.give_effect. The number is this card's; a golden target
## doesn't double it.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func recruit_target(_params: MechanicParams) -> Target:
	return Target.FRIENDLY_UNIT


func on_recruited(ctx: RecruitContext, unit: Unit, target: Unit, params: MechanicParams) -> void:
	if target != null and ctx.trigger(unit, &"test_arms"):
		ctx.give_effect(target, &"test_fury", {"amount": params.num(&"amount")}, unit)
