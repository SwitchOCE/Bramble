extends Mechanic
## Live Pack eligibility is read by CombatHunt. Only the next slot in this row gets the aura.


func has_board_aura(_params: Dictionary) -> bool:
	return true


func board_aura(combat: Combat, unit: CombatUnit, params: Dictionary, out: Dictionary) -> void:
	var row: Array[int] = BoardGeometry.row_of(unit.slot)
	var index: int = row.find(unit.slot) + 1
	if index >= row.size():
		return
	var friend: CombatUnit = combat.unit_at(unit.side, row[index])
	if friend != null:
		var bonus: Vector2i = out.get(friend.uid, Vector2i.ZERO)
		out[friend.uid] = bonus + Vector2i(CoreUtil.to_int(params["attack"]), 0)
