extends Mechanic
## Mag Pye: first of all, takes the text of the enemy across for the fight. It has none, and this has
## it. Golden: also the enemy across from the next slot along. A Belly isn't text.


func first_of_all(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var slots: Array[int] = [BoardGeometry.across(unit.slot)]
	var along: Array[int] = BoardGeometry.adjacent(unit.slot)
	if CoreUtil.to_int(params.get("reach", 1)) > 1 and not along.is_empty():
		slots.append(BoardGeometry.across(along[along.size() - 1]))
	for slot: int in slots:
		var enemy: CombatUnit = combat.unit_at(1 - unit.side, slot)
		if enemy != null and not _textless(enemy):
			combat.trigger(unit, "mag_pye")
			CombatHeld.steal_text(combat, unit, enemy)


static func _textless(enemy: CombatUnit) -> bool:
	for id: String in enemy.mechanic_ids:
		if id != HeldUnits.BELLY:
			return false
	return true
