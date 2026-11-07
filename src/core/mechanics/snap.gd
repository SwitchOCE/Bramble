extends Mechanic
## A tongue reaches any enemy still standing in this side's mud.


func attack_target(combat: Combat, unit: CombatUnit, _params: Dictionary) -> CombatUnit:
	var world := CombatWorld.make(combat, unit, unit.side, {}, "attack")
	var targets: Array[BoardUnit] = TargetSelect.pick(
		{"select": "mired", "pick": "highest_attack", "count": 1}, world
	)
	if targets.is_empty():
		return null
	combat.trigger(unit, "snap")
	return targets[0] as CombatUnit
