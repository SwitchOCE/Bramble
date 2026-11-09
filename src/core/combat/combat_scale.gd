class_name CombatScale
extends RefCounted
## Live proportional slot Hexes use Attack before auras, so recalculation cannot compound itself.


static func add_hex(combat: Combat, source: CombatUnit, side: int, slot: int, percent: int) -> void:
	var key: String = "hex_percent_%d_%d" % [side, slot]
	combat.notes[key] = CoreUtil.to_int(combat.notes.get(key, 0)) + percent
	combat.hex_percents_used = true
	combat._slots_active = true
	combat.emit_event(
		"slot_hex",
		{
			"side": side,
			"slot": slot,
			"amount": 0,
			"total": _flat_hex(combat, side, slot),
			"percent": mini(100, CoreUtil.to_int(combat.notes[key])),
			"percent_amount": percent,
			"source": source.uid
		}
	)
	combat._recalc_auras(true)


static func hex_loss(combat: Combat, unit: CombatUnit, slot_attack: int) -> int:
	# Every aura recalculation asks this of every unit; with no Hex percent yet it is 0, and
	# building the note key each time cost more than the rest of the slot bonus.
	if not combat.hex_percents_used:
		return 0
	var percent: int = CoreUtil.to_int(
		combat.notes.get("hex_percent_%d_%d" % [unit.side, unit.slot], 0)
	)
	return StatFraction.part(
		maxi(0, StatFraction.attack_before_auras(unit) + slot_attack), mini(100, percent)
	)


static func hex_percent(combat: Combat, side: int, slot: int) -> int:
	return mini(100, CoreUtil.to_int(combat.notes.get("hex_percent_%d_%d" % [side, slot], 0)))


static func _flat_hex(combat: Combat, side: int, slot: int) -> int:
	var row: Dictionary = combat.hexes[side]
	return CoreUtil.to_int(row.get(slot, 0))
