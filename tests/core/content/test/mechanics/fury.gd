extends Mechanic
## A numbered keyword with no behaviour of its own ("Fury N"), for giving one with a number.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}
