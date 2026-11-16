extends Mechanic
## Start of fight (set-up pass): your slots give double Attack this fight (golden: triple). The
## side keeps the percent if this dies (FightSide.set_slot_attack_percent); two don't stack.


func start_of_combat_priority(_params: MechanicParams) -> int:
	return SOC_SETUP


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if combat.trigger(unit, &"test_edgewright"):
		combat.bridge(unit.side).set_slot_attack_percent(300 if params.golden else 200, unit)
