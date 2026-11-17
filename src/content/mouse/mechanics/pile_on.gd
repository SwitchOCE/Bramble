extends Mechanic
## Pile on: whenever a neighbour (next to, in front of or behind: up to four, 8.2.3; any tribe)
## attacks, this hits the target first. Every pile-on hit lands together once all friends have
## heard the attack (Combat.hit while joining), so a later piler still lands when an earlier one's
## hit was enough; a target they kill ends the attack before the exchange (9.6.1), and the kill is
## the piler's. A unit with 0 Attack doesn't pile on. Dame Bodkin's percent applies.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func on_friendly_attack(
	combat: Combat,
	unit: CombatUnit,
	attacker: CombatUnit,
	defender: CombatUnit,
	_params: MechanicParams
) -> void:
	if unit == null or attacker == null or defender == null or unit.attack() <= 0:
		return
	if not combat.geometry.neighbours(unit.slot).has(attacker.slot):
		return
	if not combat.trigger(unit, &"mouse_pile_on"):
		return
	combat.hit(unit, defender, combat.side_query(unit.side, MouseRules.Q_PILE_PERCENT, 100))
	MouseRules.after_pile_on(combat, unit)
