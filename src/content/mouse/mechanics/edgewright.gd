extends Mechanic
## Edgewright: start of fight (set-up pass), your slots give double Attack this fight (golden:
## triple). The stored buffs don't change; the fight reads them at that percent (the core's
## Q_SLOT_ATTACK_PERCENT, which stacks once with the give-time doubling). Two don't stack: the
## bigger applies. It keeps working if the Edgewright dies: the percent goes on the side and every
## slot gets the hidden mouse_edged keyword, whose holder answers the same query.

const MouseRules := preload("res://src/content/mouse/mouse_rules.gd")


func start_of_combat_priority(_params: MechanicParams) -> int:
	return SOC_SETUP


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if not combat.trigger(unit, &"mouse_edgewright"):
		return
	var side: FightSide = combat.bridge(unit.side)
	var percent: int = 300 if params.golden else 200
	side.set_state(MouseRules.EDGE_PERCENT, maxi(side.state_int(MouseRules.EDGE_PERCENT), percent))
	for slot: int in combat.geometry.slot_count:
		if not side.slot(slot).keywords.has(MouseRules.EDGED):
			side.slot_buff(slot, 0, 0, false, unit, MouseRules.EDGED)


func side_query(
	combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
) -> int:
	if unit != null and query == Q_SLOT_ATTACK_PERCENT:
		return maxi(value, MouseRules.edge_percent(combat, unit.side))
	return value
