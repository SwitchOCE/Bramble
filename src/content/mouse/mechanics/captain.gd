extends Mechanic
## One Cousin for each qualifying attack until Charge runs out.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func param_kinds() -> Dictionary:
	return {"limit": MechanicParams.Kind.THRESHOLD}


func on_friendly_attack(
	combat: Combat,
	unit: CombatUnit,
	attacker: CombatUnit,
	_defender: CombatUnit,
	params: MechanicParams
) -> void:
	if unit == null or unit.gone or attacker == null or attacker == unit:
		return
	if not combat.geometry.neighbours(unit.slot).has(attacker.slot):
		return
	if MouseRules.charge(combat, unit, &"mouse_captain", MouseRules.charge_without_number(params)):
		MouseRules.summon_cousins(combat, unit, 1)
