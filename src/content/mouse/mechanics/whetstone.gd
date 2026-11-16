extends Mechanic
## Whetstone Vole: at the end of your turn, give this slot +attack Attack (a permanent slot buff).


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit != null and ctx.trigger(unit, &"mouse_whetstone"):
		ctx.slot_buff(unit.slot, params.num(&"attack"), 0, unit)
