extends Mechanic
## An ability with a slot target and a gold cost: pay 1 to give a slot Taunt.


func has_ability() -> bool:
	return true


func ability_cost(_params: MechanicParams) -> int:
	return 1


func ability_target(_params: MechanicParams) -> Target:
	return Target.SLOT


func on_ability(ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams) -> void:
	if ctx.trigger(unit, &"test_order_slot"):
		ctx.slot_keyword(ctx.target_index, &"taunt", unit)
