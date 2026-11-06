extends Mechanic
## Pipistrelle's back side (library entry 43): Start of Combat, if this is in the back row, deal
## `damage` to a random enemy.


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	if not BoardGeometry.is_back(unit.slot):
		return
	var enemies: Array[CombatUnit] = combat.units_of(1 - unit.side)
	if enemies.is_empty():
		return
	combat.trigger(unit, "stance_back_ping")
	var target: CombatUnit = enemies[combat.rng.randi_range(0, enemies.size() - 1)]
	combat.deal_effect_damage(unit, target, CoreUtil.to_int(params.get("damage", 0)))
