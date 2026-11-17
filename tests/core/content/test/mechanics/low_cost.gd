extends Mechanic
## A numbered keyword whose aura grants take the lowest number (Root's cost: "pays the lowest
## cost"), through grant_combine.


func param_kinds() -> Dictionary:
	return {"cost": MechanicParams.Kind.THRESHOLD}


func grant_combine(_param: StringName) -> Combine:
	return Combine.MIN
