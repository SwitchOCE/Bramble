extends Mechanic
## An ability on a shop card: once a turn, a shop unit goes into the heap.


func has_ability() -> bool:
	return true


func ability_target(_params: MechanicParams) -> Target:
	return Target.SHOP_UNIT


func on_ability(ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams) -> void:
	if not ctx.trigger(unit, &"test_bury"):
		return
	var card_id: StringName = ctx.take_from_shop(ctx.target_index, unit)
	if card_id != &"":
		ctx.heap_add(&"test_heap", card_id, unit)
