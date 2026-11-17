extends Mechanic
## An ability with a slot target and a gold cost: pay 1, a slot gets +2/+2 and is a guard
## post (gives Taunt).


func has_ability() -> bool:
	return true


func ability_cost(_params: MechanicParams) -> int:
	return 1


func ability_target(_params: MechanicParams) -> Target:
	return Target.SLOT


func on_ability(ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams) -> void:
	if ctx.trigger(unit, &"test_order_slot"):
		ctx.slot_buff(ctx.target_index, 2, 2, unit, &"taunt")
