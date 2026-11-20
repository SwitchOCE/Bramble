extends Mechanic
## The Colonel: while this is alive on the board in a fight, reservists from your hand get double
## their slot's Renown, triple for a golden (Q_HAND_RENOWN_TIMES, asked when auras are worked out,
## so it ends when the Colonel dies). Privates and starting units get the slot's Renown as usual.


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, params: MechanicParams
) -> int:
	if unit != null and query == Q_HAND_RENOWN_TIMES:
		return maxi(value, 3 if params.golden else 2)
	return value
