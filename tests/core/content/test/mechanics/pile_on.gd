extends Mechanic
## Attack listener: when an adjacent friend attacks, this hits the defender first.


func on_friendly_attack(
	combat: Combat,
	unit: CombatUnit,
	attacker: CombatUnit,
	defender: CombatUnit,
	_params: MechanicParams
) -> void:
	if unit == null or not combat.geometry.adjacent(unit.slot).has(attacker.slot):
		return
	if combat.trigger(unit, &"test_pile_on"):
		combat.hit(unit, defender)
