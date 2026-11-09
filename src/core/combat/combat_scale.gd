class_name CombatScale
extends RefCounted
## Live proportional slot Hexes use Attack before auras, so recalculation cannot compound itself.


static func add_hex(combat: Combat, source: CombatUnit, side: int, slot: int, percent: int) -> void:
	var key: String = "hex_percent_%d_%d" % [side, slot]
	combat.notes[key] = CoreUtil.to_int(combat.notes.get(key, 0)) + percent
	combat._slots_active = true
	combat.emit_event(
		"slot_hex",
		{
			"side": side,
			"slot": slot,
			"amount": 0,
			"total": 0,
			"percent": combat.notes[key],
			"source": source.uid
		}
	)
	combat._recalc_auras(true)


static func hex_loss(combat: Combat, unit: CombatUnit, slot_attack: int) -> int:
	var percent: int = CoreUtil.to_int(
		combat.notes.get("hex_percent_%d_%d" % [unit.side, unit.slot], 0)
	)
	return StatFraction.part(
		maxi(0, StatFraction.attack_before_auras(unit) + slot_attack), mini(100, percent)
	)
