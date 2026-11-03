extends Mechanic
## Peck (X) (library entry 5): the attack strikes the target X times, Attack split as evenly as
## possible, larger parts first. Combat runs the strikes (SPEC 4.2).


func strikes(params: Dictionary) -> int:
	return CoreUtil.to_int(params.get("strikes", 1))
