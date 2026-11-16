extends Mechanic
## Regimental Sergeant Major: at the end of your turn, give every slot +amount/+amount. While
## this is on the recruit board, every slot buff the player's effects give is doubled as it is
## given (Rules.SLOT_BUFF_PERCENT, read from the recruit board in fights too, so it still doubles
## if he died in that fight). Two don't stack: the core takes the bigger. A golden gives +4/+4
## and triples (`extra_percent` 200).


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER, "extra_percent": MechanicParams.Kind.NUMBER}


func modify_int(
	query: StringName, value: int, _player: PlayerState, _unit: Unit, params: MechanicParams
) -> int:
	if query != Rules.SLOT_BUFF_PERCENT:
		return value
	return maxi(value, 100 + params.num(&"extra_percent"))


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit == null or not ctx.trigger(unit, &"pigeon_sergeant_major"):
		return
	for slot: int in ctx.geometry().slot_count:
		ctx.slot_buff(slot, params.num(&"amount"), params.num(&"amount"), unit)
