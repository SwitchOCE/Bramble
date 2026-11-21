extends Mechanic
## Grudge N: at the start of your turn, gain +N Health and +N/+N per unit outnumbered by last
## fight. Paid by the standing badger_grudge_pay, so a unit has it once whatever gives it.


func param_kinds() -> Dictionary:
	return {"grudge": MechanicParams.Kind.NUMBER}
