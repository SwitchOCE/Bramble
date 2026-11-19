extends Mechanic
## Pays gold after each pile-on. See MouseRules.after_pile_on.


func param_kinds() -> Dictionary:
	return {"gold": MechanicParams.Kind.NUMBER}
