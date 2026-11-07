class_name CombatAuras
extends RefCounted
## Rebuild the aura layer without changing permanent or combat buffs.


static func recalc(combat: Combat, log_changes: bool) -> void:
	var everyone: Array[CombatUnit] = combat.units_of(0)
	everyone.append_array(combat.units_of(1))
	var from_others: Dictionary = {}
	for unit: CombatUnit in everyone:
		for index: int in unit.board_aura_sources:
			unit.scripts[index].board_aura(combat, unit, unit.params[index], from_others)
	for unit: CombatUnit in everyone:
		var bonus: Vector2i = Vector2i.ZERO
		if not from_others.is_empty():
			bonus = from_others.get(unit.uid, Vector2i.ZERO)
		if combat._slots_active:
			bonus += combat._slot_bonus(unit)
		for index: int in unit.scripts.size():
			bonus += unit.scripts[index].aura(combat, unit, unit.params[index])
		if bonus.x == unit.aura_attack and bonus.y == unit.aura_health:
			continue
		var old_attack: int = unit.attack
		var old_health: int = unit.health
		unit.set_aura(bonus.x, bonus.y)
		if (
			log_changes
			and old_health > 0
			and (unit.attack != old_attack or unit.health != old_health)
		):
			combat._emit_stats(unit, unit.attack - old_attack, unit.health - old_health, unit)
