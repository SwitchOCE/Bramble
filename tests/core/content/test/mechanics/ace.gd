extends Mechanic
## After this kills a unit and survives the exchange, gain +1/+1 permanently.


func on_kill(
	combat: Combat, unit: CombatUnit, _victim: CombatUnit, _params: MechanicParams
) -> void:
	if combat.trigger(unit, &"test_ace"):
		combat.buff(unit, 1, 1, unit, true)
