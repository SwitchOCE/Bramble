extends Mechanic
## Dame Bodkin: while she is on the board, every pile-on hit by your units deals double damage
## (golden: three times). Other Hits are not doubled. Two don't stack: the bigger applies.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, params: MechanicParams
) -> int:
	if unit != null and query == MouseRules.Q_PILE_PERCENT:
		return maxi(value, 300 if params.golden else 200)
	return value
