extends Mechanic
## Hasty Pudding: Start of Combat, if this has room, it swallows the enemy across (golden: and the
## enemy nearest it). They go back when this dies, after `after` of its side's units have died, or
## when their side has nobody else.


func hears_allies(_params: Dictionary) -> bool:
	return true


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var across: int = BoardGeometry.across(unit.slot)
	var slots: Array[int] = [across]
	slots.append_array(BoardGeometry.adjacent(across))
	var left: int = CoreUtil.to_int(params.get("reach", 1))
	for slot: int in slots:
		var enemy: CombatUnit = combat.unit_at(1 - unit.side, slot)
		if enemy == null or left <= 0 or CombatHeld.room(unit) <= 0:
			continue
		combat.trigger(unit, "hasty")
		CombatHeld.swallow(combat, unit, enemy)
		left -= 1
	CombatHeld.check_sides(combat)


func on_friendly_death(
	combat: Combat, unit: CombatUnit, params: Dictionary, _dead: CombatUnit
) -> void:
	var seen: int = CoreUtil.to_int(unit.counters.get("hasty", 0)) + 1
	unit.counters["hasty"] = seen
	if seen == CoreUtil.to_int(params.get("after", 3)) and not unit.inside.is_empty():
		combat.trigger(unit, "hasty_release")
		CombatHeld.return_inside(combat, unit)
