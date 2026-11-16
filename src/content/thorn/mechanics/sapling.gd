extends Mechanic
## After this returns, gain +N/+N permanently (Blackthorn Sapling): after any return of this unit,
## Root or a Molt, on the returned unit in the fight and on the recruit board.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_returned(
	combat: Combat, _gone: CombatUnit, back: CombatUnit, params: MechanicParams
) -> void:
	if back == null or back.gone or not combat.trigger(back, &"thorn_sapling"):
		return
	var amount: int = params.num(&"amount")
	combat.buff(back, amount, amount, back, true)
