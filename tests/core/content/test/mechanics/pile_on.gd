extends Mechanic
## Pile on: whenever a neighbour (next to, in front of or behind: up to four, 8.2.3) attacks,
## this hits the target. Every pile-on hit lands together (Combat.hit while friends hear an
## attack), so a later piler still lands when an earlier one's hit was enough.


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
