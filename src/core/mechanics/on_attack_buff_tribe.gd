extends Mechanic
## Drumming Woodpecker (library entry 5): whenever this attacks (each strike), your other `tribe`
## units gain +`attack` Attack this combat.


func on_before_attack(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var tribe: String = str(params.get("tribe", ""))
	var targets: Array[CombatUnit] = []
	for other: CombatUnit in combat.units_of(unit.side):
		var tribes: Array = other.def["tribes"]
		if other != unit and tribes.has(tribe):
			targets.append(other)
	if targets.is_empty():
		return
	combat.trigger(unit, "on_attack_buff_tribe")
	for other: CombatUnit in targets:
		combat.buff(other, CoreUtil.to_int(params.get("attack", 0)), 0, unit)
