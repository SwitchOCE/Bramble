class_name CombatHunt
extends RefCounted
## Hunter exchanges, live neighbour auras, and finite Pounce chains.


static func can_lead(combat: Combat, unit: CombatUnit) -> bool:
	if not CombatLanes.parameters(unit, "pack").get("repeat", false):
		return true
	for slot: int in BoardGeometry.adjacent(unit.slot):
		var neighbour: CombatUnit = combat.unit_at(unit.side, slot)
		if (
			neighbour != null
			and not neighbour.acts_without_attack
			and not neighbour.is_stopped()
			and not neighbour.has_status("waiting")
			and (neighbour.can_attack() or neighbour.held_down())
		):
			if not CombatLanes.parameters(neighbour, "pack").get("repeat", false):
				return false
	return true


static func joiners(combat: Combat, leader: CombatUnit, defender: CombatUnit) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	if combat.reactions.kind != "":
		return out
	for slot: int in BoardGeometry.adjacent(leader.slot):
		var unit: CombatUnit = combat.unit_at(leader.side, slot)
		if (
			unit == null
			or not unit.has_mechanic("pack")
			or not unit.can_attack()
			or unit.is_stopped()
		):
			continue
		var repeat: bool = CoreUtil.to_bool(
			CombatLanes.parameters(unit, "pack").get("repeat", false)
		)
		var key: String = "pack_%d" % leader.uid
		if repeat:
			if CoreUtil.to_int(unit.limits.get(key, 0)) == combat.cycles[unit.side] + 1:
				continue
		elif unit.flagged:
			continue
		var lock: CombatUnit = CombatLanes.lock_target(combat, unit)
		if lock != null and lock != defender:
			combat.emit_event(
				"pack_blocked", {"joiner": unit.uid, "leader": leader.uid, "maker": lock.uid}
			)
			continue
		unit.limits[key] = combat.cycles[unit.side] + 1
		unit.flagged = true
		out.append(unit)
	for joiner: CombatUnit in out:
		combat.trigger(joiner, "pack")
	return out


static func has_pounce(combat: Combat, unit: CombatUnit) -> bool:
	if unit.has_mechanic("pounce"):
		return true
	for slot: int in BoardGeometry.neighbours(unit.slot):
		var neighbour: CombatUnit = combat.unit_at(unit.side, slot)
		if neighbour != null and neighbour.has_mechanic("brock_aura") and not neighbour.is_dead():
			return true
	return false


static func use_pounce(combat: Combat, unit: CombatUnit) -> bool:
	var cycle: int = combat.cycles[unit.side] + 1
	if not has_pounce(combat, unit) or CoreUtil.to_int(unit.limits.get("pounce", 0)) == cycle:
		return false
	unit.limits["pounce"] = cycle
	combat.trigger(unit, "pounce")
	return true


static func damage_dealt(combat: Combat, hit: Hit) -> void:
	if (
		hit.owner_side < 0
		or hit.amount <= 0
		or hit.target.is_dead()
		or hit.owner_side == hit.target.side
	):
		return
	var side: int = hit.owner_side
	for unit: CombatUnit in combat.units_of(side):
		if (
			not unit.can_attack()
			or unit.is_dead()
			or unit.is_stopped()
			or not has_pounce(combat, unit)
		):
			continue
		if CoreUtil.to_int(unit.limits.get("pounce", 0)) == combat.cycles[side] + 1:
			continue
		var lock: CombatUnit = CombatLanes.lock_target(combat, unit)
		if lock != null and lock != hit.target:
			continue
		for slot: int in BoardGeometry.neighbours(unit.slot):
			var neighbour: CombatUnit = combat.unit_at(side, slot)
			if neighbour != null and neighbour.quarry == hit.target.uid:
				combat.queue_attack(unit, hit.target, "pounce")
				break


static func after_attack(combat: Combat, attacker: CombatUnit, kind: String) -> void:
	for joiner: CombatUnit in combat.reactions.pack_joiners:
		var grow: int = CoreUtil.to_int(CombatLanes.parameters(joiner, "wick").get("attack", 0))
		if grow > 0:
			combat.buff(joiner, grow, 0, joiner)
	if kind == "pounce" and attacker.on_board:
		var grow: Dictionary = CombatLanes.parameters(attacker, "lodger")
		if not grow.is_empty():
			combat.buff(
				attacker, CoreUtil.to_int(grow["attack"]), CoreUtil.to_int(grow["health"]), attacker
			)


## Read before the simultaneous death batch leaves, including a Grizel trading in that exchange.
static func pack_kill(combat: Combat) -> void:
	var reactions: CombatReactions = combat.reactions
	var target: CombatUnit = reactions.current_defender
	if (
		reactions.pack_rewarded
		or target == null
		or not target.is_dead()
		or reactions.pack_joiners.is_empty()
	):
		return
	var group: Array[CombatUnit] = [reactions.current_attacker]
	group.append_array(reactions.pack_joiners)
	var killed_by_pack: bool = false
	for unit: CombatUnit in group:
		killed_by_pack = killed_by_pack or unit.uid == target.killed_by
	if not killed_by_pack:
		return
	reactions.pack_rewarded = true
	for grizel: CombatUnit in combat.units_of(reactions.current_attacker.side):
		var bonus: int = CoreUtil.to_int(CombatLanes.parameters(grizel, "grizel").get("attack", 0))
		if bonus > 0:
			combat.trigger(grizel, "grizel")
			for unit: CombatUnit in group:
				combat.buff(unit, bonus, 0, grizel, true)


static func quarry_attacked(combat: Combat, attacker: CombatUnit) -> void:
	for unit: CombatUnit in combat.units_of(1 - attacker.side):
		var params: Dictionary = CombatLanes.parameters(unit, "toll_bard")
		if params.is_empty() or unit.quarry != attacker.uid:
			continue
		var paid: int = CoreUtil.to_int(unit.limits.get("toll_bard", 0))
		var gold: int = mini(CoreUtil.to_int(params["gold"]), CoreUtil.to_int(params["cap"]) - paid)
		if gold > 0:
			unit.limits["toll_bard"] = paid + gold
			combat.trigger(unit, "toll_bard")
			combat.carry_back(unit.side, {"op": "gold_next_turn", "amount": gold})
