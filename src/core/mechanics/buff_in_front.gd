extends Mechanic
## Glow-worm Lantern, Double-agent Bat, Noctule Captain (library entries 68, 43): Start of Combat,
## the units in front of this gain +`attack` Attack this combat. Only back slots have any.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var targets: Array[CombatUnit] = []
	for slot: int in BoardGeometry.in_front_of(unit.slot):
		var other: CombatUnit = combat.unit_at(unit.side, slot)
		if other != null:
			targets.append(other)
	if targets.is_empty():
		return
	combat.trigger(unit, "buff_in_front")
	for other: CombatUnit in targets:
		combat.buff(other, CoreUtil.to_int(params.get("attack", 0)), 0, unit)
