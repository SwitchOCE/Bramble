extends Mechanic
## Pile on: the first neighbouring attack this unit can join spends its shared Ambush.
## Other Ambush sources can spend it first; golden and extra attacks do not add uses.

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
	var percent: int = combat.side_query(unit.side, MouseRules.Q_PILE_PERCENT, 50)
	if MouseRules.ambush(combat, unit, defender, &"mouse_pile_on", percent):
		MouseRules.after_pile_on(combat, unit)
