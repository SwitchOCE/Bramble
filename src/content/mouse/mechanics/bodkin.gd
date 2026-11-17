extends Mechanic
## Dame Bodkin: while she is on the board, pile-on Ambushes deal full Attack, normal or golden.
## Opening and Catapult Ambushes stay at 50%; no extra uses. Two do not stack.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
) -> int:
	if unit != null and query == MouseRules.Q_PILE_PERCENT:
		return maxi(value, 100)
	return value
