extends Mechanic
## 4.3.8 card text changing a sell value: this unit sells for `amount` more. Proves the unit
## layer of the rule queries (Rules.ask).


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func modify_int(
	query: StringName, value: int, _player: PlayerState, _unit: Unit, params: MechanicParams
) -> int:
	return value + params.num(&"amount") if query == Rules.SELL_VALUE else value
