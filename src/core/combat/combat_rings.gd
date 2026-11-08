class_name CombatRings
extends RefCounted
## Horseshoes mark the opposing Ring before the fight. The mark travels with a dancing Ring.


static func prepare(combat: Combat) -> void:
	for side: int in 2:
		var slots: Array = combat.slot_effects[side]
		for slot: int in slots.size():
			var effects: Array = slots[slot]
			var chosen: bool = false
			for effect: Dictionary in effects:
				chosen = chosen or str(effect.get("name", "")) == "Horseshoe"
			if not chosen:
				continue
			var across: int = BoardGeometry.across(slot)
			if not BoardUpkeep.has_ring(combat._slot_effects_at(1 - side, across)):
				continue
			CombatMoves.own_slot_effects(combat, 1 - side)
			for ring: Dictionary in combat._slot_effects_at(1 - side, across):
				if str(ring.get("name", "")) == BoardUpkeep.RING:
					ring["horseshoe"] = true


static func bonus(combat: Combat, unit: CombatUnit) -> Vector2i:
	var effects: Array = combat._slot_effects_at(unit.side, unit.slot)
	var total: Vector2i = BoardUpkeep.ring_stats(effects)
	var weakened := Vector2i.ZERO
	var has_weakened: bool = false
	for ring: Dictionary in effects:
		if str(ring.get("name", "")) == BoardUpkeep.RING and ring.get("horseshoe", false):
			has_weakened = true
			weakened += Vector2i(CoreUtil.to_int(ring["attack"]), CoreUtil.to_int(ring["health"]))
	if not has_weakened:
		return total
	var monarch: int = 0
	if unit.has_tribe("Fairies"):
		for source: CombatUnit in combat.units_of(unit.side):
			for index: int in source.scripts.size():
				if source.mechanic_ids[index] == "fairy_monarch":
					monarch += CoreUtil.to_int(source.params[index]["stats"])
	# Monarch is a single addition per occupied Ring slot, and is included before rounding.
	# Its normal aura arrives separately, so subtract the part Horseshoe removes here.
	weakened += Vector2i(monarch, monarch)
	return total - weakened + Vector2i(floori(weakened.x / 2.0), floori(weakened.y / 2.0))
