extends Mechanic
## Start of Combat, set-up pass: summon a Sprout.


func start_of_combat_priority(_params: MechanicParams) -> int:
	return SOC_SETUP


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	if combat.trigger(unit, &"test_setup_summoner"):
		combat.summon(unit.side, &"tk_sprout", unit.slot, false, unit)
