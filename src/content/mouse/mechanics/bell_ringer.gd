extends Mechanic
## Adds Attack to every gift while alive. See MouseRules.hand_me_down.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}
