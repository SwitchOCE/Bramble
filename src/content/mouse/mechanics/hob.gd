extends Mechanic
## Gives each heir permanent Attack, limited by Charge. See MouseRules.after_inheriting.


func param_kinds() -> Dictionary:
	return {"limit": MechanicParams.Kind.THRESHOLD, "attack": MechanicParams.Kind.NUMBER}
