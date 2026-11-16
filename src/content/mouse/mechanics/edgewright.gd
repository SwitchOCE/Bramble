extends Mechanic
## Edgewright: start of fight (set-up pass), your slots give double Attack this fight (golden:
## triple). The stored buffs don't change; the side reads them at that percent for the rest of the
## fight, even if the Edgewright dies (FightSide.set_slot_attack_percent). Two don't stack: the
## bigger applies. It stacks once with the give-time doubling (SHARED-RULES 13).


func start_of_combat_priority(_params: MechanicParams) -> int:
	return SOC_SETUP


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if combat.trigger(unit, &"mouse_edgewright"):
		combat.bridge(unit.side).set_slot_attack_percent(300 if params.golden else 200, unit)
