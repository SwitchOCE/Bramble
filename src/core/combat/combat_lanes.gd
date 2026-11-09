class_name CombatLanes
extends RefCounted
## The bell and the shared targeting table. Patches bind slots; quarry marks bind identities.
## No binding mutates a stat until both sides' bindings have been fixed from the same board.


static func bell(combat: Combat) -> void:
	var snapshot: Array = [combat.units_of(0), combat.units_of(1)]
	var active: bool = false
	for side: int in 2:
		var friends: Array = snapshot[side]
		for unit: CombatUnit in friends:
			active = (
				active
				or _has_mire(unit, friends)
				or unit.has_mechanic("quarry")
				or unit.has_mechanic("lend_quarry")
			)
	if not active:
		return
	combat.emit_event("phase", {"name": "bell"})
	for side: int in 2:
		var friends: Array = snapshot[side]
		var top_attack: int = 0
		for unit: CombatUnit in snapshot[side]:
			top_attack = maxi(top_attack, unit.attack)
		for unit: CombatUnit in snapshot[side]:
			unit.counters["bell_attack"] = unit.attack
			unit.counters["bell_top_attack"] = top_attack
			var across: int = BoardGeometry.across(unit.slot)
			if _has_mire(unit, friends):
				_patch(combat, unit, across)
				if CoreUtil.to_bool(parameters(unit, "mire").get("spread", false)):
					for slot: int in BoardGeometry.adjacent(across):
						_patch(combat, unit, slot)
			if unit.has_mechanic("quarry"):
				_mark(combat, unit, combat.unit_at(1 - side, across), unit)
				unit.quarry_reach = CoreUtil.to_bool(parameters(unit, "quarry").get("reach", false))
	# Own Quarry always beats a loan. Lenders then compete in reading order.
	var buffs: Array[Dictionary] = []
	for side: int in 2:
		for lender: CombatUnit in snapshot[side]:
			for index: int in lender.scripts.size():
				if lender.mechanic_ids[index] != "lend_quarry":
					continue
				var params: Dictionary = lender.params[index]
				var select: String = str(params.get("select", "adjacent"))
				for unit: CombatUnit in snapshot[side]:
					if not _selected(lender, unit, select) or unit.quarry != 0:
						continue
					var slot: int = unit.slot if params.get("own_across", false) else lender.slot
					_mark(
						combat, unit, combat.unit_at(1 - side, BoardGeometry.across(slot)), lender
					)
					if unit.quarry != 0:
						unit.quarry_reach = CoreUtil.to_bool(params.get("reach", false))
						buffs.append(
							{
								"unit": unit,
								"source": lender,
								"attack":
								params.get("attack", 0) if params.get("bell_buff", true) else 0
							}
						)
	sync_mire(combat)
	for buff: Dictionary in buffs:
		var amount: int = CoreUtil.to_int(buff["attack"])
		if amount != 0:
			var unit: CombatUnit = buff["unit"]
			var source: CombatUnit = buff["source"]
			combat.buff(unit, amount, 0, source)

	combat._recalc_auras(true)


static func parameters(unit: CombatUnit, id: String) -> Dictionary:
	var index: int = unit.mechanic_ids.find(id)
	return {} if index < 0 else unit.params[index]


static func _selected(source: CombatUnit, unit: CombatUnit, select: String) -> bool:
	match select:
		"friendly":
			return true
		"neighbours":
			return BoardGeometry.neighbours(source.slot).has(unit.slot)
	return BoardGeometry.adjacent(source.slot).has(unit.slot)


static func _has_mire(unit: CombatUnit, friends: Array) -> bool:
	if unit.has_mechanic("mire"):
		return true
	for friend: CombatUnit in friends:
		if BoardGeometry.adjacent(friend.slot).has(unit.slot):
			if CoreUtil.to_bool(parameters(friend, "bog_aura").get("mire", false)):
				return true
	return false


static func _patch(combat: Combat, maker: CombatUnit, slot: int) -> void:
	var side: int = 1 - maker.side
	var patches: Dictionary = combat.bog_patches[side]
	if patches.has(slot):
		return
	patches[slot] = {"maker": maker, "maker_side": maker.side, "broken": false}
	combat.trigger(maker, "mire")
	combat.emit_event("bog_patch", {"side": side, "slot": slot, "maker": maker.uid})


static func _mark(
	combat: Combat, hunter: CombatUnit, quarry: CombatUnit, source: CombatUnit
) -> void:
	if hunter.has_mechanic("no_quarry") or quarry == null or quarry.def_id() == HeldUnits.EGG:
		return
	hunter.quarry = quarry.uid
	combat.emit_event(
		"quarry_marked", {"hunter": hunter.uid, "quarry": quarry.uid, "source": source.uid}
	)


static func sync_mire(combat: Combat) -> void:
	var first: Dictionary = combat.bog_patches[0]
	var second: Dictionary = combat.bog_patches[1]
	if first.is_empty() and second.is_empty():
		return
	for side: int in 2:
		var patches: Dictionary = combat.bog_patches[side]
		for unit: CombatUnit in combat.units_of(side):
			var patch: Dictionary = patches.get(unit.slot, {})
			var maker: CombatUnit = patch.get("maker")
			if maker == null:
				if unit.has_status("mired"):
					combat.set_status(unit, "mired", false, null)
				continue
			var current: Dictionary = unit.statuses.get("mired", {})
			if CoreUtil.to_int(current.get("maker", 0)) != maker.uid:
				combat.set_status(unit, "mired", true, maker, {"maker": maker.uid})


static func maker_of(combat: Combat, unit: CombatUnit) -> CombatUnit:
	var patches: Dictionary = combat.bog_patches[unit.side]
	var patch: Dictionary = patches.get(unit.slot, {})
	return patch.get("maker")


static func lock_target(combat: Combat, unit: CombatUnit) -> CombatUnit:
	var patches: Dictionary = combat.bog_patches[unit.side]
	var patch: Dictionary = patches.get(unit.slot, {})
	var maker: CombatUnit = patch.get("maker")
	if maker == null or not maker.on_board or maker.is_dead() or patch.get("broken", false):
		return null
	return maker if maker.side == CoreUtil.to_int(patch["maker_side"]) else null


## A mirer gives up its first attack in this cycle to an enemy that has not attacked yet.
static func wait_once(combat: Combat, unit: CombatUnit) -> bool:
	if not combat.mire_wait_enabled:
		return false
	if unit.counters.get("mire_wait", 0) > 0 or unit.counters.get("attacks_started", 0) > 0:
		return false
	for enemy: CombatUnit in combat.units_of(1 - unit.side):
		if lock_target(combat, enemy) == unit and enemy.counters.get("attacks_started", 0) == 0:
			unit.counters["mire_wait"] = 1
			combat.emit_event(
				"mire_wait", {"uid": unit.uid, "target": enemy.uid, "side": unit.side}
			)
			return true
	return false


static func by_uid(combat: Combat, uid: int) -> CombatUnit:
	if uid == 0:
		return null
	for side: int in 2:
		for unit: CombatUnit in combat.units_of(side):
			if unit.uid == uid:
				return unit
	return null


## Mire > quarry > own text (Snap, Swoop, Path) > Taunt > protected-row random.
## There is currently no built Taunt mechanic; its insertion point stays below own text.
static func choose_target(
	combat: Combat, attacker: CombatUnit, announce: bool = false
) -> CombatUnit:
	if attacker == null or not attacker.on_board or attacker.is_dead():
		return null
	var lock: CombatUnit = lock_target(combat, attacker)
	if lock != null:
		return lock
	var quarry: CombatUnit = by_uid(combat, attacker.quarry)
	var candidates: Array[CombatUnit] = normal_targets(combat, attacker)
	if quarry != null and quarry.side != attacker.side:
		if attacker.quarry_reach or candidates.has(quarry):
			return quarry
	for index: int in attacker.scripts.size():
		var forced: CombatUnit = attacker.scripts[index].attack_target(
			combat, attacker, attacker.params[index]
		)
		if forced != null:
			if announce and attacker.mechanic_ids[index] == "snap":
				combat.trigger(attacker, "snap")
			return forced
	if candidates.is_empty():
		return null
	return candidates[combat.rng.randi_range(0, candidates.size() - 1)]


static func normal_targets(combat: Combat, attacker: CombatUnit) -> Array[CombatUnit]:
	var enemies: Array[CombatUnit] = combat.units_of(1 - attacker.side)
	var front: Array[CombatUnit] = []
	for unit: CombatUnit in enemies:
		if BoardGeometry.is_front(unit.slot):
			front.append(unit)
	return front if not front.is_empty() else enemies


static func legal_joiners(
	combat: Combat, joiners: Array[CombatUnit], defender: CombatUnit
) -> Array[CombatUnit]:
	var legal: Array[CombatUnit] = []
	for joiner: CombatUnit in joiners:
		var lock: CombatUnit = lock_target(combat, joiner)
		if lock == null or lock == defender:
			if not legal.has(joiner):
				legal.append(joiner)
		else:
			# The old Swarm hook flags before the target is known.
			joiner.flagged = false
	return legal


## Losing a marked unit to swallow/side change never pays a Take, even if it comes back.
static func lose_unit(combat: Combat, unit: CombatUnit, changes_side: bool = false) -> void:
	for side: int in 2:
		for hunter: CombatUnit in combat.units_of(side):
			if hunter.quarry != 0 and (hunter == unit or hunter.quarry == unit.uid):
				var old: int = hunter.quarry
				hunter.quarry = 0
				combat.emit_event("quarry_lost", {"hunter": hunter.uid, "quarry": old})
		if changes_side:
			var patches: Dictionary = combat.bog_patches[side]
			for patch: Dictionary in patches.values():
				if patch["maker"] == unit:
					patch["broken"] = true


## Witnesses were captured before any death in the batch left the board. This credits a Hunter
## dying alongside its quarry, and prevents credit to a Hunter that fainted in an earlier batch.
static func enemy_deaths(combat: Combat, dying: Array[CombatUnit], witnesses: Array) -> void:
	for dead: CombatUnit in dying:
		var friends: Array = witnesses[1 - dead.side]
		var taker: CombatUnit = null
		for unit: CombatUnit in friends:
			if unit.quarry == dead.uid and unit.has_tribe("Hunters"):
				taker = unit
				break
		for unit: CombatUnit in friends:
			for index: int in unit.scripts.size():
				unit.scripts[index].on_enemy_death(combat, unit, unit.params[index], dead)
		if taker != null:
			combat.takes[taker.side] += 1
			combat.emit_event("take", {"hunter": taker.uid, "quarry": dead.uid, "side": taker.side})
			for unit: CombatUnit in friends:
				for index: int in unit.scripts.size():
					unit.scripts[index].on_take(combat, unit, unit.params[index], taker, dead)
	for dead: CombatUnit in dying:
		lose_unit(combat, dead)
		# A dying Hunter isn't in units_of any more, so clear its own mark separately.
		dead.quarry = 0


## Bitter shrinks only the leading attacker at declaration, after any queued attack bonus.
static func bitter(combat: Combat, defender: CombatUnit, attacker: CombatUnit) -> void:
	if not attacker.on_board or attacker.is_dead():
		return
	var amount: int = 0
	for index: int in defender.scripts.size():
		if defender.mechanic_ids[index] != "bitter":
			continue
		var params: Dictionary = defender.params[index]
		var key: String = "bitter_%d_%d" % [index, attacker.uid]
		if params.get("once_per_enemy", false) and defender.limits.has(key):
			continue
		defender.limits[key] = 1
		amount += StatFraction.loss(combat._strike_attack(attacker), params, "n")
	for friend: CombatUnit in combat.units_of(defender.side):
		if BoardGeometry.adjacent(friend.slot).has(defender.slot):
			amount += CoreUtil.to_int(parameters(friend, "bog_aura").get("bitter", 0))
	var loss: int = mini(amount, maxi(0, combat._strike_attack(attacker) - 1))
	if loss > 0:
		if attacker.has_status("borrowed_attack"):
			attacker.counters["bitter_borrowed"] = loss
		combat.trigger(defender, "bitter")
		combat.buff(attacker, -loss, 0, defender, false, "Bitter")
