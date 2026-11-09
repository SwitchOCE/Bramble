class_name Pass3HunterGains
extends RefCounted
## One Take dispatches its owner's printed rewards, then its observers exactly once.


static func take(combat: Combat, taker: CombatUnit, dead: CombatUnit, witnesses: Array) -> void:
	if not combat.notes.get("hunter_active", false):
		return
	var snapshot: Dictionary = Pass3HunterCombat.prey(combat, dead)
	var repeats: int = _repeats(combat, witnesses)
	for name: String in ["nip", "sable", "lutra"]:
		for _time: int in repeats * Pass3HunterCombat.triggers(combat, taker, name):
			combat.trigger(taker, "pass3_hunter:" + name)
			Pass3HunterCombat.gain(
				combat,
				taker,
				snapshot,
				Pass3HunterCombat.rate(combat, taker, name, name + "_share"),
				taker,
				"Take"
			)
	for _time: int in repeats * Pass3HunterCombat.triggers(combat, taker, "russet"):
		_poach(combat, taker, snapshot)
	for unit: CombatUnit in witnesses:
		for name: String in ["lodger", "glutton"]:
			if name == "lodger" and not BoardGeometry.adjacent(unit.slot).has(taker.slot):
				continue
			for _time: int in Pass3HunterCombat.triggers(combat, unit, name):
				combat.trigger(unit, "pass3_hunter:" + name)
				Pass3HunterCombat.gain(
					combat,
					unit,
					snapshot,
					Pass3HunterCombat.rate(combat, unit, name, name + "_share"),
					unit,
					name.capitalize()
				)


static func _repeats(combat: Combat, witnesses: Array) -> int:
	var result: int = 1
	for unit: CombatUnit in witnesses:
		if not Pass3HunterCombat.has(unit, "laird"):
			continue
		var count: int = maxi(
			1, floori(Pass3HunterCombat.rate(combat, unit, "laird", "laird_multiplier"))
		)
		result = maxi(result, count) if Pass3HunterCombat.guards(combat) else result * count
	return result


static func _poach(combat: Combat, unit: CombatUnit, snapshot: Dictionary) -> void:
	if (
		not CoreUtil.to_bool(snapshot.get("pool", false))
		or CoreUtil.to_int(snapshot.get("tier", 0)) > combat.tier_of(unit.side)
	):
		return
	var share: float = Pass3HunterCombat.rate(combat, unit, "russet", "russet_buff_share")
	var count: int = Pass3Rates.integer(combat.config, "hunters_russet_copies")
	for _copy: int in count:
		combat.carry_back(
			CoreUtil.to_int(combat.starting_sides.get(unit.uid, unit.side)),
			{
				"op": "poach",
				"card": str(snapshot["id"]),
				"discount": 0,
				"perm_attack": floori(maxi(0, CoreUtil.to_int(snapshot["perm_attack"])) * share),
				"perm_health": floori(maxi(0, CoreUtil.to_int(snapshot["perm_health"])) * share)
			}
		)
	combat.trigger(unit, "pass3_hunter:russet")


static func pack_kill(combat: Combat, group: Array[CombatUnit], dead: CombatUnit) -> void:
	if (
		not combat.notes.get("hunter_active", false)
		or CoreUtil.to_int(dead.counters.get("hunter_attack_lethal", 0)) == 0
	):
		return
	var snapshot: Dictionary = Pass3HunterCombat.prey(combat, dead)
	var joiners: Array[CombatUnit] = combat.reactions.pack_joiners
	for unit: CombatUnit in joiners:
		for _time: int in Pass3HunterCombat.triggers(combat, unit, "wick"):
			combat.trigger(unit, "pass3_hunter:wick")
			Pass3HunterCombat.gain(
				combat,
				unit,
				snapshot,
				Pass3HunterCombat.rate(combat, unit, "wick", "wick_share"),
				unit,
				"Wick"
			)
	for grizel: CombatUnit in combat.units_of(group[0].side):
		for _time: int in Pass3HunterCombat.triggers(combat, grizel, "grizel"):
			combat.trigger(grizel, "pass3_hunter:grizel")
			for unit: CombatUnit in group:
				Pass3HunterCombat.gain(
					combat,
					unit,
					snapshot,
					Pass3HunterCombat.rate(combat, grizel, "grizel", "grizel_share"),
					grizel,
					"Grizel"
				)


static func quarry_attacked(combat: Combat, attacker: CombatUnit) -> void:
	for unit: CombatUnit in combat.units_of(1 - attacker.side):
		if not Pass3HunterCombat.has(unit, "lane_bard") or unit.quarry != attacker.uid:
			continue
		var used: int = CoreUtil.to_int(unit.limits.get("hunter_bard", 0))
		if used >= Pass3Rates.integer(combat.config, "hunters_lane_bard_triggers"):
			continue
		unit.limits["hunter_bard"] = used + 1
		var amount: int = roundi(
			Pass3HunterCombat.rate(combat, unit, "lane_bard", "lane_bard_gold")
		)
		combat.carry_back(
			CoreUtil.to_int(combat.starting_sides.get(unit.uid, unit.side)),
			{"op": "gold_next_turn", "amount": amount}
		)
		combat.trigger(unit, "pass3_hunter:lane_bard")


static func finish(combat: Combat) -> void:
	if not combat.notes.get("hunter_active", false):
		return
	var initial: Array = combat.notes.get("hunter_initial", [[], []])
	var marked: Array = combat.notes.get("hunter_marked", [[], []])
	for side: int in 2:
		var biggest: Dictionary = {}
		var marks: Array = marked[side]
		for uid: int in marks:
			var unit: CombatUnit = Pass3HunterCombat.target(combat, uid)
			var snapshot: Dictionary = Pass3HunterCombat.prey(combat, unit)
			if (
				biggest.is_empty()
				or _size(snapshot) > _size(biggest)
				or (
					_size(snapshot) == _size(biggest)
					and (
						CoreUtil.to_int(snapshot.get("reading_rank", 0))
						< CoreUtil.to_int(biggest.get("reading_rank", 0))
					)
				)
			):
				biggest = snapshot
		if biggest.is_empty():
			continue
		for witness: CombatUnit in initial[side]:
			if not Pass3HunterCombat.has(witness, "ermeline"):
				continue
			var count: int = roundi(
				Pass3HunterCombat.rate(combat, witness, "ermeline", "ermeline_pelts")
			)
			var stats: Vector2i = Pass3HunterCombat.shares(
				combat, biggest, Pass3Rates.number(combat.config, "hunters_pelt_share")
			)
			combat.carry_back(
				side,
				{
					"op": "add_card",
					"card": "pelt",
					"count": count,
					"from_pool": false,
					"prey": biggest.duplicate(),
					"attack": stats.x,
					"health": stats.y
				}
			)
			combat.trigger(witness, "pass3_hunter:ermeline")


static func _size(snapshot: Dictionary) -> int:
	return CoreUtil.to_int(snapshot.get("attack", 0)) + CoreUtil.to_int(snapshot.get("health", 0))
