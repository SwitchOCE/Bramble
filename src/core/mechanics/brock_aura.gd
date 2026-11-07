extends Mechanic


func has_board_aura(_params: Dictionary) -> bool:
	return true


func board_aura(combat: Combat, unit: CombatUnit, params: Dictionary, out: Dictionary) -> void:
	for slot: int in BoardGeometry.neighbours(unit.slot):
		var friend: CombatUnit = combat.unit_at(unit.side, slot)
		if friend != null:
			var bonus: Vector2i = out.get(friend.uid, Vector2i.ZERO)
			out[friend.uid] = bonus + Vector2i(CoreUtil.to_int(params["attack"]), 0)
