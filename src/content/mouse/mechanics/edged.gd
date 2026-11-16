extends Mechanic
## Hidden helper: the slot keyword an Edgewright leaves on every slot for one fight. Any unit
## standing on such a slot answers the side's slot Attack percent the Edgewright set, so the
## doubling holds after the Edgewright dies.

const MouseRules := preload("res://src/content/mouse/mouse_rules.gd")


func side_query(
	combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
) -> int:
	if unit != null and query == Q_SLOT_ATTACK_PERCENT:
		return maxi(value, MouseRules.edge_percent(combat, unit.side))
	return value
