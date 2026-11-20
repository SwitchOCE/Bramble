class_name FightDeaths
extends RefCounted
## Death resolution (rulebook 9.7), the one return protocol (9.8, SHARED-RULES 15-22) and the
## end of a fight (9.9, 10.1.2), for Combat. Mechanics never call this; they act through Combat.

var _combat_ref: WeakRef


static func create(combat: Combat) -> FightDeaths:
	var made := FightDeaths.new()
	made._combat_ref = weakref(combat)
	return made


func _combat() -> Combat:
	var found: Combat = _combat_ref.get_ref()
	return found


## 9.7: every unit at 0 Health or destroyed dies. Dying units leave their slots first (9.7.1);
## then, in order active side first then reading order (9.7.3): step 1 kills and "whenever a
## unit dies"; step 2 own death effects and friendly death counters; step 3 "after a friendly
## unit dies"; step 4 returns; step 5 "after a friendly unit returns"; then the slot-fill order
## (FightArrivals: Reserve, waiting summons, after_death_round); new deaths start another pass
## (step 6).
func resolve(active_side: int) -> void:
	var c: Combat = _combat()
	while c._halt_reason == "":
		var dying: Array[CombatUnit] = []
		for side_index: int in [active_side, 1 - active_side]:
			for unit: CombatUnit in c._board(side_index):
				if unit.should_die():
					dying.append(unit)
		if dying.is_empty():
			return
		var emptied: Array = [[], []]
		for unit: CombatUnit in dying:
			var died_in: Array = emptied[unit.side]
			died_in.append(unit.slot)
			unit.gone = true
			var row: Array = c.sides[unit.side]
			row[unit.slot] = null
			c._units_cache[unit.side] = null
			var killer: CombatUnit = c.killer_of(unit)
			(
				c
				. _log(
					{
						"type": "death",
						"side": unit.side,
						"slot": unit.slot,
						"uid": unit.uid,
						"killer_uid": killer.uid if killer != null else -1,
					}
				)
			)
		c._refresh_auras()
		var outer_witnessed: Dictionary = c.arrivals.witnessed
		c.arrivals.witnessed = {}
		_death_steps(dying, active_side)
		var back: Array[CombatUnit] = []
		for unit: CombatUnit in dying:
			var returned: CombatUnit = _try_return(unit)
			if returned != null:
				back.append(returned)
		for unit: CombatUnit in back:
			c._notify_friends(unit, &"after_friendly_return", [unit])
		c.arrivals.after_deaths(emptied, active_side)
		c.arrivals.witnessed = outer_witnessed


func _death_steps(dying: Array[CombatUnit], active_side: int) -> void:
	var c: Combat = _combat()
	for unit: CombatUnit in dying:
		var killer: CombatUnit = c.killer_of(unit)
		if killer != null and killer.side != unit.side:
			for bound: BoundMechanic in killer.hooks():
				bound.mechanic.on_kill(c, killer, unit, bound.params)
	for unit: CombatUnit in dying:
		for side_index: int in [active_side, 1 - active_side]:
			c._notify(side_index, &"on_any_death", [unit])
	for unit: CombatUnit in dying:
		c.run_death_effects(unit)
		c._notify(unit.side, &"on_friendly_death", [unit])
	# SHARED-RULES (The Eighth Plague): a side's deaths are counted as each one resolves, so the
	# first of two deaths in one batch reads 1 and the second 2 in "after a friendly unit dies".
	for unit: CombatUnit in dying:
		c.bridge(unit.side).deaths += 1
		c._notify(unit.side, &"after_friendly_death", [unit])


## 9.8.2-9.8.3, 9.10.3, SHARED-RULES 15-22: the one return protocol. Every mechanic on the dying
## unit may offer a return (Mechanic.return_offer); the highest return_priority wins (Root's
## RETURN_FIRST before Molt's RETURN_PLAIN, ruling 17), ties in hook order; with no offer the
## unit stays dead (the one way to return: Molt, Root and the core's Reborn all offer here). One
## return for each death,
## at most config.return_limit a fight for one unit. The unit comes back to its own slot, else
## the nearest empty one:
##   - as a plain copy (a fresh card, golden kept, no counters, buffs or given keywords; 9.8.2,
##     glossary "Plain copy"), or as its recruit unit stands when the chosen offer says so
##     (return_as_recruit: Root, ruling 16);
##   - carrying its per-fight limits (CombatUnit.fight_counts, ruling 21) and its uses shown.
## The chosen mechanic's pay_return runs, then on_returned for every mechanic the dead unit had;
## then it is logged as one `return` event (the new unit's view as it now stands, `from_uid`,
## `mechanic`), followed by what those hooks logged. Not a summon, and on_fight_enter does not
## hear it (ruling 22: a return is not joining the fight). "After a friendly unit returns"
## follows in death step 5.
func _try_return(unit: CombatUnit) -> CombatUnit:
	var c: Combat = _combat()
	if unit.returns >= c.config.return_limit or c._halt_reason != "":
		return null
	var chosen: BoundMechanic = null
	var health: int = 0
	var best: int = -1
	for bound: BoundMechanic in unit.hooks():
		var offered: int = bound.mechanic.return_offer(c, unit, bound.params)
		var rank: int = bound.mechanic.return_priority(bound.params)
		if offered > 0 and rank > best:
			chosen = bound
			health = offered
			best = rank
	if chosen == null:
		return null
	var as_recruit: bool = chosen.mechanic.return_as_recruit(chosen.params)
	var slot: int = c.geometry.summon_slot(c._occupied(unit.side), unit.slot, true)
	var mechanic_id: StringName = chosen.id
	if slot < 0 or not c.trigger(unit, mechanic_id):
		return null
	var back: CombatUnit = CombatUnit.fresh(
		unit.def, c._take_uid(), unit.side, unit.golden, c.registry, c.config.stat_max
	)
	var recruit_copy: Unit = c.bridge(unit.side).recruit_unit(unit)
	if as_recruit and recruit_copy != null:
		back = CombatUnit.from_unit(recruit_copy, back.uid, unit.side)
	back.bought = unit.bought
	back.returns = unit.returns + 1
	back.starting = unit.starting
	back.recruit_uid = unit.recruit_uid
	back.fight_counts = unit.fight_counts.duplicate()
	back.uses = unit.uses.duplicate()
	back.damage = maxi(0, back.max_health() - health)
	c._place(back, slot)
	# The return event shows the unit as it stands once its return has resolved; what
	# pay_return and on_returned logged (a buff, a spent status) follows it, so nothing names the
	# new unit before a screen can place it.
	var outer: Array[Dictionary] = c._held
	var outer_holding: bool = c._holding
	c._held = []
	c._holding = true
	chosen.mechanic.pay_return(c, unit, back, chosen.params)
	for bound: BoundMechanic in unit.hooks():
		bound.mechanic.on_returned(c, unit, back, bound.params)
	var after: Array[Dictionary] = c._held
	c._held = outer
	c._holding = outer_holding
	var event: Dictionary = back.view(c.geometry)
	event["type"] = "return"
	event["from_uid"] = unit.uid
	event["mechanic"] = String(mechanic_id)
	event["source_uid"] = unit.uid
	c._log(event)
	for later: Dictionary in after:
		c._log(later)
	return back


## 9.9 and 10.1.2: the winner, and how many of each side's starting units were killed (a
## starting unit is killed unless it, or its return, is alive on its own side at the end).
func finish() -> Dictionary:
	var c: Combat = _combat()
	var alive: Array[bool] = [not c._board_empty(0), not c._board_empty(1)]
	var winner: int = -1
	if c._halt_reason == Combat.REASON_BOARD_EMPTY and alive[0] != alive[1]:
		winner = 0 if alive[0] else 1
	var killed: Array[int] = [0, 0]
	var starting: Array[int] = [0, 0]
	var kept: Array = [[], []]
	for side_index: int in 2:
		var survivors: Array[int] = []
		for unit: CombatUnit in c._board(side_index):
			if unit.starting:
				survivors.append(unit.recruit_uid)
		var started: Array = c._starting_uids[side_index]
		starting[side_index] = started.size()
		kept[side_index] = _unique(survivors)
		killed[side_index] = maxi(0, started.size() - _unique(survivors).size())
	c.result = {
		"winner": winner,
		"reason": c._halt_reason,
		"starting": starting,
		"killed": killed,
		"attacks": c._attacks,
		"triggers": c._triggers,
		"survivors": [uids(0), uids(1)],
		"survivor_recruit_uids": kept,
		"deaths": [c.bridge(0).deaths, c.bridge(1).deaths],
		"outnumbered_by": [c.outnumbered_by(0), c.outnumbered_by(1)],
	}
	var end_event: Dictionary = c.result.duplicate()
	end_event["type"] = "combat_end"
	c._log(end_event)
	return c.result


static func _unique(values: Array[int]) -> Array[int]:
	var out: Array[int] = []
	for value: int in values:
		if not out.has(value):
			out.append(value)
	return out


## The fight log's views of a side: its unit uids, its units, its slots.
func uids(side_index: int) -> Array[int]:
	var out: Array[int] = []
	for unit: CombatUnit in _combat()._board(side_index):
		out.append(unit.uid)
	return out


func board_view(side_index: int) -> Array:
	var out: Array = []
	for unit: CombatUnit in _combat()._board(side_index):
		out.append(unit.view(_combat().geometry))
	return out


func slots_view(side_index: int) -> Array:
	var out: Array = []
	for slot: int in _combat().geometry.slot_count:
		out.append(_combat().bridge(side_index).slot(slot).view())
	return out
