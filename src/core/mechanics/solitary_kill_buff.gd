extends Mechanic
## Lone Lynx (library entry 41): after this kills an enemy while it has no friendly neighbours,
## gain +`attack`/+`health`. The library says permanently; combat can't write back to the recruit
## board yet, so here it lasts this combat.


func on_damage_dealt(combat: Combat, unit: CombatUnit, params: Dictionary, hit: Hit) -> void:
	if hit.target.health > 0 or not unit.on_board:
		return
	for slot: int in BoardGeometry.neighbours(unit.slot):
		if combat.unit_at(unit.side, slot) != null:
			return
	combat.trigger(unit, "solitary_kill_buff")
	combat.buff(
		unit,
		CoreUtil.to_int(params.get("attack", 0)),
		CoreUtil.to_int(params.get("health", 0)),
		unit
	)
