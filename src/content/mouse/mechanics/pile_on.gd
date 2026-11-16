extends Mechanic
## Pile on: whenever a neighbour (8.2.3, any tribe) attacks, this hits the target first. The
## core's hit ends the attack before the exchange if the target is dead (9.6.1), and the kill is
## the piler's. A unit with 0 Attack doesn't pile on. Dame Bodkin's percent applies.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func on_friendly_attack(
	combat: Combat,
	unit: CombatUnit,
	attacker: CombatUnit,
	defender: CombatUnit,
	_params: MechanicParams
) -> void:
	if unit == null or unit.gone or attacker == null or defender == null or defender.gone:
		return
	if attacker.gone or unit.attack() <= 0:
		return
	if not combat.geometry.neighbours(unit.slot).has(attacker.slot):
		return
	if not combat.trigger(unit, &"mouse_pile_on"):
		return
	combat.hit(unit, defender, combat.side_query(unit.side, MouseRules.Q_PILE_PERCENT, 100))
	MouseRules.after_pile_on(combat, unit)


## SHARED-RULES 21: a returned unit is the same unit for every "a fight" limit (the Pikeman's 5,
## the Fencing Master's and the Cutpurse's first pile-on), so its counts come back with it.
func on_returned(
	_combat: Combat, gone: CombatUnit, back: CombatUnit, _params: MechanicParams
) -> void:
	for key: StringName in [MouseRules.PILES, MouseRules.PIKE_GAINS]:
		back.set_state(key, gone.state_int(key))
