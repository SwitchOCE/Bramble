class_name Pass3FairyCombat
extends RefCounted
## Rings belong to slots. Fetch copies the displayed stats before its own slot bonus applies.


static func ability(unit: CombatUnit, index: int) -> String:
	if unit.mechanic_ids[index] != "pass3_fairy":
		return ""
	return str(unit.params[index].get("ability", ""))


static func start(combat: Combat, source: CombatUnit, name: String, factor: int = 0) -> void:
	var power: int = source.golden_factor() if factor == 0 else factor
	match name:
		"witch":
			_witch(combat, source, power)
		"hob":
			for fairy: CombatUnit in Pass3Combat.biggest(
				Pass3Combat.tribe(combat, source.side, "Fairies"), power
			):
				combat.trigger(source, "hob")
				combat.set_status(fairy, "shield", true, source)
		"fetch":
			_fetch(combat, source, power)
		"will":
			_wisps(combat, source, power)
		"belladonna":
			_belladonna(combat, source, power)
		"changeling":
			_changeling(combat, source, power)


static func _witch(combat: Combat, source: CombatUnit, power: int) -> void:
	var enemy: CombatUnit = combat.unit_at(1 - source.side, BoardGeometry.across(source.slot))
	if enemy == null:
		return
	var rings: Vector2i = BoardUpkeep.ring_value(combat._slot_effects_at(source.side, source.slot))
	var loss: int = mini(enemy.attack, rings.x * power)
	if loss > 0:
		combat.trigger(source, "hedge_witch")
		combat.buff(enemy, -loss, 0, source)


static func _fetch(combat: Combat, source: CombatUnit, power: int) -> void:
	var candidates: Array[CombatUnit] = []
	var taken: Array = combat.notes.get("pass3_fetch_taken", [])
	var guarded: bool = combat.config.get_bool("pass3_loop_guards")
	for slot: int in BoardGeometry.behind(source.slot):
		var candidate: CombatUnit = combat.unit_at(source.side, slot)
		if (
			candidate != null
			and candidate.has_tribe("Fairies")
			and (not guarded or not _is_fetch(candidate))
			and (not guarded or not taken.has(candidate.uid))
		):
			candidates.append(candidate)
	var biggest: Array[CombatUnit] = Pass3Combat.biggest(candidates)
	if biggest.is_empty():
		return
	var target: CombatUnit = biggest[0]
	taken.append(target.uid)
	combat.notes["pass3_fetch_taken"] = taken
	var share: float = Pass3Rates.number(combat.config, "fairies_fetch_share")
	var spec: Dictionary = {
		"def_id": target.def_id(),
		"golden": target.golden or power > 1,
		"attack": ceili(target.attack * share),
		"health": maxi(1, ceili(target.health * share))
	}
	combat.trigger(source, "cradle_fetch")
	var row: Array = combat.sides[source.side]
	row[source.slot] = null
	source.on_board = false
	combat.emit_event("death", {"uid": source.uid, "side": source.side, "slot": source.slot})
	var copy: CombatUnit = CombatUnit.make(target.def, spec, combat._next_uid, source.side)
	combat._next_uid += 1
	copy.slot = source.slot
	_copy_text(copy, target)
	combat._apply_slot_grants(copy)
	combat.enter_board(copy, source, {"copied": target.uid})
	# A copy's Start of Combat text fires, but the deferred timing steps remain deferred.
	for index: int in copy.scripts.size():
		if not copy.on_board or combat._halted:
			return
		if Pass3BogStart.dependent(copy.mechanic_ids[index], copy.params[index]):
			continue
		elif Pass3Combat.is_late_start(copy.mechanic_ids[index], copy.params[index]):
			var late: Array = combat.notes.get("pass3_copied_late", [])
			late.append([copy, index])
			combat.notes["pass3_copied_late"] = late
		elif ability(copy, index) == "hob":
			var holders: Array = combat.notes.get("pass3_copied_holders", [])
			holders.append([copy, index])
			combat.notes["pass3_copied_holders"] = holders
		else:
			copy.scripts[index].on_start_of_combat(combat, copy, copy.params[index])


static func _copy_text(copy: CombatUnit, target: CombatUnit) -> void:
	copy.scripts = []
	copy.params = []
	copy.mechanic_ids = []
	copy.board_aura_sources = []
	copy.ally_listeners = []
	copy.acts_without_attack = false
	copy.grants = target.grants.duplicate(true)
	for index: int in target.scripts.size():
		var params: Dictionary = target.params[index].duplicate(true)
		if copy.golden and not target.golden:
			params["id"] = target.mechanic_ids[index]
			params = MechanicRegistry.params_for(params, true)
			params.erase("id")
		copy.add_mechanic(target.mechanic_ids[index], target.scripts[index], params)
	copy.statuses = target.statuses.duplicate(true)
	copy.statuses.erase("borrowed")
	copy.counters = target.counters.duplicate(true)
	copy.has_text_override = target.has_text_override
	copy.text_override = target.text_override
	copy.keywords_override = target.keywords_override.duplicate()


static func _is_fetch(unit: CombatUnit) -> bool:
	if unit.has_mechanic("cradle_fetch"):
		return true
	for value: Variant in MechanicRegistry.compiled(unit.def):
		var entry: CompiledMechanic = value
		if entry.id == "pass3_fairy" and str(entry.params.get("ability", "")) == "fetch":
			return true
	return false


static func _wisps(combat: Combat, source: CombatUnit, power: int) -> void:
	for slot: int in CombatMoves.empty_ring_slots(combat, source.side):
		var spec: Dictionary = {
			"def_id": "wisp",
			"golden": false,
			"attack": Pass3Rates.integer(combat.config, "fairies_wisp_attack") * power,
			"health": Pass3Rates.integer(combat.config, "fairies_wisp_health") * power
		}
		combat.trigger(source, "will_o_the_wisp")
		combat.enter_from_spec(spec, source.side, slot, source)


static func _belladonna(combat: Combat, source: CombatUnit, power: int) -> void:
	var across: int = BoardGeometry.across(source.slot)
	var slots: Array[int] = [across]
	if power > 1:
		slots.append_array(BoardGeometry.adjacent(across))
	for slot: int in slots:
		var enemy: CombatUnit = combat.unit_at(1 - source.side, slot)
		if enemy != null:
			combat.trigger(source, "belladonna")
			combat.set_status(enemy, "nightshade", true, source)


static func _changeling(combat: Combat, source: CombatUnit, power: int) -> void:
	var enemy: CombatUnit = combat.unit_at(1 - source.side, BoardGeometry.across(source.slot))
	if enemy == null:
		return
	combat.trigger(source, "changeling")
	CombatMoves.borrow_across(combat, source, enemy, 0)
	combat.set_status(
		enemy, "borrowed", true, source, {"partner": source.uid, "attacks_left": power}
	)


## Move every eligible Ring cohort. A cohort keeps its move count when it meets another cohort.
static func dance(combat: Combat, attacker: CombatUnit) -> bool:
	var mistress: CombatUnit = null
	var power: int = 0
	for unit: CombatUnit in combat.units_of(attacker.side):
		for index: int in unit.scripts.size():
			if ability(unit, index) == "reel":
				var strength: int = CoreUtil.to_int(
					unit.params[index].get("factor", unit.golden_factor())
				)
				if strength > power:
					mistress = unit
					power = strength
	if mistress == null:
		return false
	if not attacker.on_board:
		return true
	var next: int = CombatMoves.next_in_attack_order(combat, attacker)
	if next < 0:
		return true
	var limit: int = Pass3Rates.integer(combat.config, "fairies_reel_moves") * power
	CombatMoves.own_slot_effects(combat, attacker.side)
	var row: Array = combat.slot_effects[attacker.side]
	var from: Array = row[attacker.slot]
	var moved: Array = []
	for effect: Dictionary in from:
		if str(effect.get("name", "")) != BoardUpkeep.RING:
			continue
		if (
			combat.config.get_bool("pass3_loop_guards")
			and CoreUtil.to_int(effect.get("moves", 0)) >= limit
		):
			continue
		var ring: Dictionary = effect.duplicate(true)
		ring["moves"] = CoreUtil.to_int(ring.get("moves", 0)) + 1
		moved.append(ring)
	if moved.is_empty():
		return true
	for effect: Dictionary in moved:
		for index: int in from.size():
			var original: Dictionary = from[index]
			if (
				str(original.get("name", "")) == BoardUpkeep.RING
				and original.get("moves", 0) == CoreUtil.to_int(effect["moves"]) - 1
				and original.get("count", 1) == effect.get("count", 1)
			):
				from.remove_at(index)
				break
	var to: Array = row[next]
	to.append_array(moved)
	_sync_totals(from)
	_sync_totals(to)
	combat.trigger(mistress, "reel_mistress")
	var total: Vector2i = BoardUpkeep.ring_value(moved)
	combat.emit_event(
		"ring_dance",
		{
			"side": attacker.side,
			"from": attacker.slot,
			"to": next,
			"attack": total.x,
			"health": total.y
		}
	)
	combat._recalc_auras(true)
	combat._resolve_deaths(attacker.side)
	return true


## Rounding is once per slot, not once per history cohort; distribute the exact total among them.
static func _sync_totals(effects: Array) -> void:
	var accumulated: float = 0.0
	var previous: int = 0
	for effect: Dictionary in effects:
		if str(effect.get("name", "")) != BoardUpkeep.RING or not effect.has("count"):
			continue
		accumulated += (
			CoreUtil.to_int(effect["count"]) * CoreUtil.to_float(effect.get("ring_size", 1.0))
		)
		var total: int = ceili(accumulated)
		effect["attack"] = total - previous
		effect["health"] = total - previous
		previous = total
