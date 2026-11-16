extends Mechanic
## "Your Bury effects happen twice" (Old Mother Midden; a golden: three times). One unit is still
## buried and one entry added. Two Middens don't add up: the biggest applies.

const BuryBase := preload("res://src/content/thorn/lib/bury_base.gd")


func modify_int(
	query: StringName, value: int, _player: PlayerState, _unit: Unit, params: MechanicParams
) -> int:
	if query != BuryBase.Q_BURY_TIMES:
		return value
	return maxi(value, 3 if params.golden else 2)
