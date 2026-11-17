extends Mechanic
## Slot buffs you give are doubled (give-time multiplier; two don't stack).


func modify_int(
	query: StringName, value: int, _player: PlayerState, _unit: Unit, _params: MechanicParams
) -> int:
	return value * 2 if query == Rules.SLOT_BUFF_PERCENT else value
