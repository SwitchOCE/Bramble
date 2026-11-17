extends Mechanic
## Grudge N: after each fight, gain +N/+N for each unit you were outnumbered by. Paid by the
## standing badger_grudge_pay, so a unit has it once whatever gives it.


func param_kinds() -> Dictionary:
	return {"grudge": MechanicParams.Kind.NUMBER}
