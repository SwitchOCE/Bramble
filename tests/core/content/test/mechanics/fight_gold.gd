extends Mechanic
## After this kills a unit, gain 1 gold next turn.


func on_kill(
	combat: Combat, unit: CombatUnit, _victim: CombatUnit, _params: MechanicParams
) -> void:
	if combat.trigger(unit, &"test_fight_gold"):
		combat.bridge(unit.side).add_gold(1, unit)
