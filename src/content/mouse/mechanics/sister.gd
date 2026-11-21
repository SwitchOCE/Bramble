extends Mechanic
## Attacks after inheriting, limited by Charge. See MouseRules.after_inheriting.


func param_kinds() -> Dictionary:
	return {"limit": MechanicParams.Kind.NUMBER}
