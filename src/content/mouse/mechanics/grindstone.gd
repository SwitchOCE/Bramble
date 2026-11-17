extends Mechanic
## Grindstone Miller: at the end of your turn, give this slot and its neighbours (8.2.3), empty
## or not, +attack Attack (permanent slot buffs).


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit == null or not ctx.trigger(unit, &"mouse_grindstone"):
		return
	var slots: Array[int] = [unit.slot]
	slots.append_array(ctx.geometry().neighbours(unit.slot))
	for slot: int in slots:
		ctx.slot_buff(slot, params.num(&"attack"), 0, unit)
