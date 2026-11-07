extends Mechanic
## Flat additions to Rings under Fairies, rebuilt whenever the board or text changes.


func has_board_aura(_params: Dictionary) -> bool:
	return true


func board_aura(combat: Combat, unit: CombatUnit, params: Dictionary, out: Dictionary) -> void:
	var stats: int = CoreUtil.to_int(params["stats"])
	for fairy: CombatUnit in combat.units_of(unit.side):
		if not fairy.has_tribe("Fairies"):
			continue
		if not BoardUpkeep.has_ring(combat._slot_effects_at(fairy.side, fairy.slot)):
			continue
		var now: Vector2i = out.get(fairy.uid, Vector2i.ZERO)
		out[fairy.uid] = now + Vector2i(stats, stats)
