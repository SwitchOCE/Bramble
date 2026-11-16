extends Mechanic
## Thimble Captain: whenever a neighbour attacks, summon a Cousin (golden: 2) nearest the
## Captain. Not on its own attacks. A Cousin that lands next to the attacker piles on in this
## same attack (the core lets a unit that arrives while friends hear an attack hear it too).

const MouseRules := preload("res://src/content/mouse/mouse_rules.gd")


func param_kinds() -> Dictionary:
	return {"count": MechanicParams.Kind.NUMBER}


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
	if combat.trigger(unit, &"mouse_captain"):
		MouseRules.summon_cousins(combat, unit, params.num(&"count"))
