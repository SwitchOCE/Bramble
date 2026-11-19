extends Mechanic
## Makes a gift permanent, limited by Charge. See MouseRules.hand_me_down.


func param_kinds() -> Dictionary:
	return {"limit": MechanicParams.Kind.THRESHOLD}
