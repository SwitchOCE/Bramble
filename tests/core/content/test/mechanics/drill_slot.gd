extends Mechanic
## Slot effects: at the end of your turn, this slot gets +1/+1 for good.


func on_end_of_turn(ctx: RecruitContext, unit: Unit, _params: MechanicParams) -> void:
	if unit != null and ctx.trigger(unit, &"test_drill_slot"):
		ctx.slot_buff(unit.slot, 1, 1, unit)
