extends Mechanic
## Pile on: whenever a neighbour (next to, in front of or behind: up to four, 8.2.3) attacks,
## this queues a hit on the target (Combat.hit while friends hear an attack).


func on_friendly_attack(
	combat: Combat,
	unit: CombatUnit,
	attacker: CombatUnit,
	defender: CombatUnit,
	_params: MechanicParams
) -> void:
	if unit == null or not combat.geometry.neighbours(unit.slot).has(attacker.slot):
		return
	if combat.trigger(unit, &"test_pile_on"):
		combat.hit(unit, defender)
