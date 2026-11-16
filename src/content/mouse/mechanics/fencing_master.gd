extends Mechanic
## Fencing Master: the first time each of your Mice piles on in a fight (the Master included),
## it gains +attack Attack permanently; a Cousin keeps it for the fight. Each Master gives its
## own. Made in MouseRules.after_pile_on while the Master is on the board.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}
