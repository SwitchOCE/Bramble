extends Mechanic
## "Your Bury effects happen twice" (Old Mother Midden: `times` 2, a golden 3 through card data's
## golden override). One unit is still buried and one entry added. Two Middens don't add up: the
## biggest applies.

const BuryBase := preload("res://src/content/thorn/lib/bury_base.gd")


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func modify_int(
	query: StringName, value: int, _player: PlayerState, _unit: Unit, params: MechanicParams
) -> int:
	if query != BuryBase.Q_BURY_TIMES:
		return value
	return maxi(value, params.num(&"times"))
