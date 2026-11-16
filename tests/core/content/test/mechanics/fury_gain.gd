extends Mechanic
## Bridge, permanent write-back from a fight: whenever this attacks while outnumbered, +1/+1
## for good.


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, _params: MechanicParams
) -> void:
	var outnumbered: bool = combat.units(1 - unit.side).size() > combat.units(unit.side).size()
	if outnumbered and combat.trigger(unit, &"test_fury_gain"):
		combat.buff(unit, 1, 1, unit, true)
