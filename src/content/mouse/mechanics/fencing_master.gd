extends Mechanic
## Grows permanently after its own pile-on. See MouseRules.after_pile_on.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}
