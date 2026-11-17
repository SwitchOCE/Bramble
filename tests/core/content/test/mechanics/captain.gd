extends Mechanic
## Whenever a neighbour attacks, summon a Piler (which piles on in the same attack).


func on_friendly_attack(
	combat: Combat,
	unit: CombatUnit,
	attacker: CombatUnit,
	_defender: CombatUnit,
	_params: MechanicParams
) -> void:
	if unit == null or not combat.geometry.adjacent(unit.slot).has(attacker.slot):
		return
	if combat.trigger(unit, &"test_captain"):
		combat.summon(unit.side, &"b1_piler", unit.slot, false, unit)
