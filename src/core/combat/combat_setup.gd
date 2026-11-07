class_name CombatSetup
extends RefCounted


static func apply(combat: Combat, boards: Array) -> void:
	for side: int in 2:
		var row: Array = []
		row.resize(BoardGeometry.SLOTS)
		combat.sides[side] = row
		var board: Array = boards[side]
		for slot: int in BoardGeometry.SLOTS:
			if slot >= board.size() or board[slot] == null:
				continue
			var spec: Dictionary = board[slot]
			var unit_def: Dictionary = combat.library.get_unit(str(spec["def_id"]))
			if unit_def.is_empty():
				continue
			var unit := CombatUnit.make(unit_def, spec, combat._next_uid, side)
			combat._next_uid += 1
			unit.slot = slot
			row[slot] = unit
			combat._apply_slot_grants(unit)
