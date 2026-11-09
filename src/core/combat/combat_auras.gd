class_name CombatAuras
extends RefCounted
## Rebuild the aura layer without changing permanent or combat buffs.


static func recalc(combat: Combat, log_changes: bool) -> void:
	var everyone: Array[CombatUnit] = combat.units_of(0)
	everyone.append_array(combat.units_of(1))
	var from_others: Dictionary = {}
	var contributions: Dictionary = {}
	for unit: CombatUnit in everyone:
		for index: int in unit.board_aura_sources:
			var before: Dictionary = from_others.duplicate() if combat.log_events else {}
			unit.scripts[index].board_aura(combat, unit, unit.params[index], from_others)
			if combat.log_events:
				for target: int in from_others:
					var delta: Vector2i = from_others[target] - before.get(target, Vector2i.ZERO)
					if delta != Vector2i.ZERO:
						var sources: Dictionary = contributions.get(target, {})
						_record(sources, "%d:%d" % [unit.uid, index], unit, "aura", delta)
						contributions[target] = sources
	for unit: CombatUnit in everyone:
		var sources: Dictionary = contributions.get(unit.uid, {})
		var bonus: Vector2i = from_others.get(unit.uid, Vector2i.ZERO)
		if unit.def_id() == HeldUnits.EGG:
			bonus += Pass3BirdCombat.egg_bonus(combat, unit)
			var egg: Vector2i = RedwingAura.egg_aura(combat, unit)
			bonus += egg
			if combat.log_events:
				_record(sources, "Redwing", null, "Redwing aura", egg)
			var tit: Vector2i = TomTitAura.egg_aura(combat, unit)
			bonus += tit
			if combat.log_events:
				_record(sources, "Tom Tit", null, "Tom Tit aura", tit)
		if combat._slots_active:
			var slot: Vector2i = combat._slot_bonus(unit)
			bonus += slot
			if combat.log_events:
				_record(sources, "Ring", null, "Ring", slot + Vector2i(unit.hex_amount, 0))
				_record(sources, "Hex", null, "Hex", Vector2i(-unit.hex_amount, 0))
		for index: int in unit.scripts.size():
			var own: Vector2i = unit.scripts[index].aura(combat, unit, unit.params[index])
			bonus += own
			if combat.log_events:
				var name: String = "Rainbow" if unit.mechanic_ids[index] == "rainbow" else "aura"
				_record(sources, "self:%d" % index, unit, name, own)
		var changes: Array = _changes(unit.aura_sources, sources) if combat.log_events else []
		unit.aura_sources = sources
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
			CombatMoves.emit_stats(
				combat,
				unit,
				unit.attack - old_attack,
				unit.health - old_health,
				null,
				false,
				"",
				changes
			)
	Pass3BirdCombat.sync_protection(combat)


static func _record(
	sources: Dictionary, key: String, source: CombatUnit, name: String, amount: Vector2i
) -> void:
	if amount != Vector2i.ZERO:
		sources[key] = {"source": CombatMoves.uid_or_null(source), "name": name, "amount": amount}


static func _changes(before: Dictionary, after: Dictionary) -> Array:
	var out: Array = []
	var keys: Array = before.keys()
	for key: Variant in after:
		if not keys.has(key):
			keys.append(key)
	for key: Variant in keys:
		var old: Dictionary = before.get(key, {})
		var now: Dictionary = after.get(key, {})
		if old.get("amount", Vector2i.ZERO) == now.get("amount", Vector2i.ZERO):
			continue
		var chosen: Dictionary = old if now.is_empty() else now
		var change: Dictionary = chosen.duplicate()
		change.erase("amount")
		change["change"] = "lost" if now.is_empty() else ("gained" if old.is_empty() else "changed")
		out.append(change)
	return out
