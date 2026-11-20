extends Mechanic
## Dame Bodkin: while she is on the board, every pile-on hit by your Mice deals double damage
## (proposal: golden triples damage). Several Dames use the largest multiplier.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, params: MechanicParams
) -> int:
	if unit != null and query == MouseRules.Q_PILE_PERCENT:
		return maxi(value, 300 if params.golden else 200)
	return value
