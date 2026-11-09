class_name Pass3BogGrowth
extends RefCounted
## A whole death batch agrees its witnesses before any Sink reward changes the board.


static func deaths(combat: Combat, dying: Array[CombatUnit], witnesses: Array) -> void:
	if not combat.notes.get("bog_active", false):
		return
	for side: int in 2:
		var sinks: Array[CombatUnit] = []
		for dead: CombatUnit in dying:
			if dead.side != side and dead.has_status("mired"):
				sinks.append(dead)
		if sinks.is_empty():
			continue
		var friends: Array = witnesses[side]
		_kiss(combat, side, friends, sinks.size())
		for dead: CombatUnit in sinks:
			for unit: CombatUnit in witnesses[side]:
				_rewards(combat, unit, dead)


static func _kiss(combat: Combat, side: int, witnesses: Array, sink_count: int) -> void:
	var frogs: Array[CombatUnit] = []
	for unit: CombatUnit in witnesses:
		if Pass3BogCombat.has(unit, "frog"):
			frogs.append(unit)
	if frogs.is_empty():
		return
	var used: Array = combat.notes.get("bog_kisses_this_fight", [0, 0])
	var limit: int = Pass3Rates.integer(combat.config, "bog_kisses_per_fight")
	var count: int = (
		sink_count
		if not Pass3BogCombat.guards(combat)
		else mini(sink_count, maxi(0, limit - CoreUtil.to_int(used[side])))
	)
	var kisses: Array = combat.notes.get("bog_kisses", [0, 0])
	var period: int = maxi(1, Pass3Rates.integer(combat.config, "bog_kiss_period"))
	for _time: int in count:
		used[side] += 1
		kisses[side] += 1
		for frog: CombatUnit in frogs:
			frog.counters["kisses"] = kisses[side]
			combat.emit_event(
				"kiss", {"side": side, "target": frog.uid, "count": kisses[side], "period": period}
			)
		if CoreUtil.to_int(kisses[side]) % period == 0:
			_break_curse(combat, frogs, witnesses)
	combat.notes["bog_kisses_this_fight"] = used
	combat.notes["bog_kisses"] = kisses


static func _break_curse(combat: Combat, frogs: Array[CombatUnit], witnesses: Array) -> void:
	var gains: Dictionary = {}
	for frog: CombatUnit in frogs:
		var multiplier: float = Pass3BogCombat.rate(combat, frog, "frog", "frog_multiplier")
		for target: CombatUnit in witnesses:
			if BoardGeometry.adjacent(frog.slot).has(target.slot):
				var key: String = (
					str(target.uid)
					if Pass3BogCombat.guards(combat)
					else "%d_%d" % [target.uid, frog.uid]
				)
				var previous: Dictionary = gains.get(key, {})
				if multiplier > CoreUtil.to_float(previous.get("multiplier", 0)):
					gains[key] = {"target": target, "source": frog, "multiplier": multiplier}
	for entry: Dictionary in gains.values():
		var target: CombatUnit = entry["target"]
		var source: CombatUnit = entry["source"]
		var used: bool = (
			CoreUtil.to_int(target.counters.get("bog_frog_turn", -1)) == combat.round_number
		)
		var cap: int = Pass3Rates.integer(combat.config, "bog_frog_doubles_per_turn")
		var count: int = CoreUtil.to_int(target.limits.get("bog_doubled", 0))
		if Pass3BogCombat.guards(combat) and (used or count >= cap):
			continue
		target.limits["bog_doubled"] = count + 1
		target.counters["bog_frog_turn"] = combat.round_number
		var times: float = maxf(0.0, CoreUtil.to_float(entry["multiplier"]) - 1.0)
		var attack: int = floori(maxi(0, target.base_attack_now() + target.perm_attack) * times)
		var health: int = floori(maxi(1, target.base_health_now() + target.perm_health) * times)
		permanent(combat, target, attack, health, source, "Curse break")
		if target.iid != 0:
			combat.carry_back(
				CoreUtil.to_int(combat.starting_sides.get(target.uid, target.side)),
				{
					"op": "counter",
					"iid": target.iid,
					"key": "bog_frog_turn",
					"value": combat.round_number
				}
			)
	for frog: CombatUnit in frogs:
		if CoreUtil.to_bool(Pass3BogCombat.ability(frog, "frog").get("restore", false)):
			var health_before: int = frog.health
			BogFolk.restore_prince(combat, frog)
			if health_before <= 0:
				frog.damage_taken += maxi(0, frog.health - health_before)


## Immediate permanent growth also updates the permanent layer read by a later curse break.
static func permanent(
	combat: Combat, unit: CombatUnit, attack: int, health: int, source: CombatUnit, cause: String
) -> void:
	var old_health: int = unit.health
	var old_attack: int = unit.attack
	var departed: bool = not unit.on_board or unit.is_dead()
	unit.add_permanent(attack, health)
	if departed:
		unit.damage_taken += unit.health - old_health
		combat.emit_event(
			"permanent_reward",
			{
				"target": unit.uid,
				"source": source.uid,
				"attack_delta": attack,
				"health_delta": health,
				"cause": cause
			}
		)
	else:
		CombatMoves.emit_stats(
			combat, unit, unit.attack - old_attack, unit.health - old_health, source, true, cause
		)
	if unit.iid != 0:
		combat.carry_back(
			CoreUtil.to_int(combat.starting_sides.get(unit.uid, unit.side)),
			{"op": "buff", "iid": unit.iid, "attack": attack, "health": health}
		)


static func _rewards(combat: Combat, unit: CombatUnit, dead: CombatUnit) -> void:
	if Pass3BogCombat.has(unit, "pretender") and dead.killed_by == unit.uid:
		_gold(combat, unit, "pretender")
	if Pass3BogCombat.has(unit, "cutter"):
		if not Pass3BogCombat.guards(combat) or not unit.limits.has("bog_cutter"):
			unit.limits["bog_cutter"] = true
			_gold(combat, unit, "cutter")
	if Pass3BogCombat.has(unit, "king"):
		_peatling(combat, unit, dead)


static func _gold(combat: Combat, unit: CombatUnit, name: String) -> void:
	var amount: int = roundi(Pass3BogCombat.rate(combat, unit, name, name + "_gold"))
	combat.trigger(unit, "pass3_bog:" + name)
	combat.carry_back(
		CoreUtil.to_int(combat.starting_sides.get(unit.uid, unit.side)),
		{"op": "gold_next_turn", "amount": amount}
	)


static func _peatling(combat: Combat, unit: CombatUnit, dead: CombatUnit) -> void:
	var used: int = CoreUtil.to_int(unit.limits.get("bog_king", 0))
	var cap: int = roundi(Pass3BogCombat.rate(combat, unit, "king", "king_peatlings"))
	if Pass3BogCombat.guards(combat) and used >= cap:
		return
	var slot: int = BoardGeometry.summon_slot(combat._occupied(unit.side), unit.slot, true)
	if slot < 0:
		combat.emit_event(
			"no_room", {"uid": unit.uid, "def_id": "peatling", "mechanic": "pass3_bog:king"}
		)
		return
	var share: float = Pass3Rates.number(combat.config, "bog_peatling_stat_share")
	var attack: int = floori(
		CoreUtil.to_int(dead.counters.get("bog_start_attack", dead.attack)) * share
	)
	var health: int = maxi(
		1, floori(CoreUtil.to_int(dead.counters.get("bog_start_health", dead.max_health)) * share)
	)
	var token: CombatUnit = combat.enter_from_spec(
		{"def_id": "peatling", "attack": attack, "health": health}, unit.side, slot, unit
	)
	if token != null:
		unit.limits["bog_king"] = used + 1
		combat.trigger(unit, "pass3_bog:king")
