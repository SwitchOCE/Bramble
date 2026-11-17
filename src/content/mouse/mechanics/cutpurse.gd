extends Mechanic
## Shrew Cutpurse: the first time this piles on each fight, gain `gold` gold, paid at the start of
## your next turn. The pile-on itself is mouse_pile_on; MouseRules.after_pile_on pays the gold.


func param_kinds() -> Dictionary:
	return {"gold": MechanicParams.Kind.NUMBER}
