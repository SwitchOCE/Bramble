extends Mechanic
## Pile on N (rulebook 11.7.11): the first N times a neighbour (next to, in front of or behind:
## up to four, 8.2.3; any tribe) attacks each fight, this hits the target first. N counts the
## neighbour attacks this unit hears, not its hits: an attack it hears with 0 Attack still uses
## one. `pile_on` is a NUMBER, so a golden doubles N (7.3.5). Several Pile ons on one unit
## add up and pile on once (MouseRules.pile_on_count). Every pile-on hit lands together once all
## friends have heard the attack (Combat.hit while joining), so a later piler still lands when an
## earlier one's hit was enough; a target they kill ends the attack before the exchange (9.6.1),
## and the kill is the piler's. A unit with 0 Attack doesn't pile on. Dame Bodkin's percent
## applies. The count is a fight count, so a return keeps it (SHARED-RULES 21); a counted
## piler shows its uses left under its own id, and its pill dims at 0.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func param_kinds() -> Dictionary:
	return {"pile_on": MechanicParams.Kind.NUMBER}


func on_friendly_attack(
	combat: Combat,
	unit: CombatUnit,
	attacker: CombatUnit,
	defender: CombatUnit,
	params: MechanicParams
) -> void:
	if unit == null or attacker == null or defender == null:
		return
	if not combat.geometry.neighbours(unit.slot).has(attacker.slot):
		return
	if not MouseRules.resolves_pile_on(unit, params):
		return
	if not MouseRules.use_pile_on(combat, unit):
		return
	if unit.attack() <= 0 or not combat.trigger(unit, MouseRules.PILE_ON):
		return
	var percent: int = 100
	if MouseRules.is_mouse(unit.def):
		percent = combat.side_query(unit.side, MouseRules.Q_PILE_PERCENT, percent)
	combat.hit(unit, defender, percent, MouseRules.after_pile_on.bind(combat, unit))
