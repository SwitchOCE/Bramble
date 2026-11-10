class_name Pass3BogCombat
extends RefCounted
## Bog state belongs to an owner; patches still belong to slots and their exact makers.


static func ability(unit: CombatUnit, name: String) -> Dictionary:
	var best: Dictionary = {}
	for index: int in unit.params.size():
		if unit.mechanic_ids[index] != "pass3_bog":
			continue
		var entry: Dictionary = unit.params[index]
		if str(entry.get("ability", "")) == name:
			if factor(unit, entry) > CoreUtil.to_int(best.get("factor", 0)):
				best = entry.duplicate()
				best["factor"] = factor(unit, entry)
	return best


static func factor(unit: CombatUnit, params: Dictionary) -> int:
	return CoreUtil.to_int(params.get("factor", unit.golden_factor()))


static func has(unit: CombatUnit, name: String) -> bool:
	return not ability(unit, name).is_empty()


static func active(combat: Combat) -> bool:
	for side: int in 2:
		var rules: Dictionary = combat.side_rules[side]
		if (
			CoreUtil.to_int(rules.get("bog_toll", 0)) > 0
			or CoreUtil.to_int(rules.get("bog_kisses", 0)) > 0
		):
			return true
		for unit: CombatUnit in combat.units_of(side):
			if _contains_bog(combat, unit):
				return true
	return false


static func _contains_bog(combat: Combat, unit: CombatUnit) -> bool:
	if unit.has_mechanic("pass3_bog"):
		return true
	for index: int in unit.params.size():
		if unit.mechanic_ids[index] == "bitter" and unit.params[index].get("pass3", false):
			return true
	for spec: Dictionary in unit.held_specs:
		if _bog_spec(combat, spec):
			return true
	for inside: CombatUnit in unit.inside:
		if _contains_bog(combat, inside):
			return true
	return false


static func _bog_spec(combat: Combat, spec: Dictionary) -> bool:
	var definition: Dictionary = combat.library.get_unit(str(spec.get("def_id", "")))
	for entry: Dictionary in definition.get("mechanics", []):
		if (
			str(entry.get("id", "")) == "pass3_bog"
			or (str(entry.get("id", "")) == "bitter" and entry.get("pass3", false))
		):
			return true
	for inside: Dictionary in spec.get("held", []):
		if _bog_spec(combat, inside):
			return true
	return false


static func prepare(combat: Combat) -> void:
	if not active(combat):
		return
	combat.notes["bog_active"] = true
	combat.notes["bog_toll"] = [0, 0]
	var kisses: Array[int] = []
	var participating: Array[bool] = []
	for side: int in 2:
		var rules: Dictionary = combat.side_rules[side]
		kisses.append(CoreUtil.to_int(rules.get("bog_kisses", 0)))
		var present: bool = kisses[side] > 0 or CoreUtil.to_int(rules.get("bog_toll", 0)) > 0
		for unit: CombatUnit in combat.units_of(side):
			present = present or _contains_bog(combat, unit)
			if has(unit, "frog"):
				unit.counters["kisses"] = kisses[side]
				unit.counters["bog_kiss_period"] = Pass3Rates.integer(
					combat.config, "bog_kiss_period"
				)
		participating.append(present)
	combat.notes["bog_kisses"] = kisses
	combat.notes["bog_participating"] = participating


static func finish(combat: Combat) -> void:
	if not combat.notes.get("bog_active", false):
		return
	var toll: Array = combat.notes.get("bog_toll", [0, 0])
	var kisses: Array = combat.notes.get("bog_kisses", [0, 0])
	for side: int in 2:
		if combat.notes.get("bog_participating", [false, false])[side]:
			combat.carry_back(side, {"op": "bog_state", "toll": toll[side], "kisses": kisses[side]})


static func guards(combat: Combat) -> bool:
	return Pass3Rates.enabled(combat.config, "pass3_loop_guards")


static func rate(combat: Combat, unit: CombatUnit, name: String, key: String) -> float:
	var own: Dictionary = ability(unit, name)
	var scale: int = CoreUtil.to_int(own.get("factor", 1))
	if scale > 1 and Pass3Rates.defaults().has("bog_golden_" + key):
		return Pass3Rates.number(combat.config, "bog_golden_" + key)
	return Pass3Rates.number(combat.config, "bog_" + key) * scale


## Chorus lends only to adjacent Bog. Own and lent copies compete; they never add.
static func soak_keep(combat: Combat, unit: CombatUnit) -> float:
	var result: float = rate(combat, unit, "soak", "soak_keep") if has(unit, "soak") else 0.0
	if unit.has_tribe("Bog folk"):
		for friend: CombatUnit in combat.units_of(unit.side):
			if lends_to(combat, friend, unit):
				result = maxf(result, rate(combat, friend, "chorus", "soak_keep"))
	return result


static func lends_to(combat: Combat, source: CombatUnit, target: CombatUnit) -> bool:
	if not has(source, "chorus") or not target.has_tribe("Bog folk"):
		return false
	var chosen: Array[int] = []
	for slot: int in BoardGeometry.adjacent(source.slot):
		var friend: CombatUnit = combat.unit_at(source.side, slot)
		if friend != null and friend.has_tribe("Bog folk"):
			chosen.append(slot)
	var count: int = maxi(0, Pass3Rates.integer(combat.config, "bog_chorus_lends"))
	if chosen.size() > count:
		chosen.resize(count)
	return chosen.has(target.slot)


static func has_mire(combat: Combat, unit: CombatUnit) -> bool:
	if unit.has_mechanic("mire"):
		return true
	if not unit.has_tribe("Bog folk"):
		return false
	for friend: CombatUnit in combat.units_of(unit.side):
		if lends_to(combat, friend, unit):
			return true
	return false


static func is_bitter(combat: Combat, unit: CombatUnit) -> bool:
	if has(unit, "soak"):
		return true
	for source: CombatUnit in combat.units_of(unit.side):
		if lends_to(combat, source, unit):
			return true
	for index: int in unit.params.size():
		if unit.mechanic_ids[index] == "bitter" and unit.params[index].get("pass3", false):
			return true
	return false


## True means the proportional rule handled this defender, including a zero loss.
static func bitter(combat: Combat, defender: CombatUnit, attacker: CombatUnit) -> bool:
	if not is_bitter(combat, defender):
		return false
	var attack: int = combat._strike_attack(attacker)
	var raw: float = attack * Pass3Rates.number(combat.config, "bog_bitter_share")
	var amount: int = (
		ceili(raw) if Pass3Rates.enabled(combat.config, "bog_bitter_round_up") else floori(raw)
	)
	var loss: int = mini(maxi(0, amount), maxi(0, attack - 1))
	if loss <= 0:
		return true
	if attacker.has_status("borrowed_attack") or attacker.counters.has("bog_hopkin_attack"):
		attacker.counters["bitter_borrowed"] = loss
	combat.trigger(defender, "bitter")
	combat.buff(attacker, -loss, 0, defender, false, "Bitter")
	# Above the unit ceiling, the requested debuff can remove less displayed Attack.
	# Borrowed attacks use the same declaration read, including their Bitter deduction.
	loss = mini(loss, maxi(0, attack - combat._strike_attack(attacker)))
	if loss <= 0:
		return true
	var toll: Array = combat.notes.get("bog_toll", [0, 0])
	toll[defender.side] += loss
	combat.notes["bog_toll"] = toll
	combat.emit_event(
		"bog_toll",
		{
			"side": defender.side,
			"total": toll[defender.side],
			"amount": loss,
			"source": defender.uid
		}
	)
	var keep: float = soak_keep(combat, defender)
	if (
		keep > 0
		and (
			not Pass3Rates.enabled(combat.config, "bog_soak_mired_only")
			or CombatLanes.maker_of(combat, attacker) == defender
		)
	):
		var stats: int = floori(loss * keep)
		PendingGains.queue(combat, defender, stats, stats, defender, "Soak")
	return true


static func before_attack(combat: Combat, unit: CombatUnit) -> void:
	unit.counters.erase("bog_hopkin_attack")
	if not has(unit, "hopkin") or not BoardGeometry.is_back(unit.slot):
		return
	unit.counters["bog_hopkin_attack"] = maxi(unit.attack, borrowed_attack(combat, unit))
	combat.trigger(unit, "pass3_bog:hopkin")


static func sync_hopkin(combat: Combat) -> void:
	if not combat.notes.get("bog_active", false):
		return
	for side: int in 2:
		for unit: CombatUnit in combat.units_of(side):
			unit.bog_can_borrow = borrowed_attack(combat, unit) > 0


static func borrowed_attack(combat: Combat, unit: CombatUnit) -> int:
	if not has(unit, "hopkin") or not BoardGeometry.is_back(unit.slot):
		return 0
	var highest: int = 0
	for slot: int in BoardGeometry.in_front_of(unit.slot):
		var friend: CombatUnit = combat.unit_at(unit.side, slot)
		if friend != null:
			highest = maxi(highest, friend.attack)
	var share: float = Pass3Rates.number(combat.config, "bog_hopkin_share")
	return floori(highest * share * factor(unit, ability(unit, "hopkin")))


static func after_attack(
	combat: Combat, unit: CombatUnit, attacker: CombatUnit, defender: CombatUnit
) -> void:
	if unit != attacker or not has(unit, "ranocchio") or not defender.has_status("mired"):
		return
	var key: String = "bog_ranocchio_%d" % CoreUtil.to_int(unit.counters.get("attacks_started", 0))
	if unit.limits.has(key):
		return
	unit.limits[key] = true
	var stats: int = floori(defender.attack * rate(combat, unit, "ranocchio", "ranocchio_share"))
	combat.trigger(unit, "pass3_bog:ranocchio")
	Pass3BogGrowth.permanent(combat, unit, stats, stats, unit, "Ranocchio")


static func hit_back(combat: Combat, unit: CombatUnit, attacker: CombatUnit) -> void:
	if (
		not has(unit, "gideon")
		or unit.is_dead()
		or attacker.is_dead()
		or CombatLanes.maker_of(combat, attacker) != unit
	):
		return
	var key: String = (
		"bog_gideon_%d_%d"
		% [attacker.uid, CoreUtil.to_int(attacker.counters.get("attacks_started", 0))]
	)
	if unit.limits.has(key):
		return
	unit.limits[key] = true
	var count: int = roundi(rate(combat, unit, "gideon", "gideon_hitbacks"))
	for _time: int in count:
		if attacker.is_dead():
			break
		combat.trigger(unit, "pass3_bog:gideon")
		combat.emit_event("bog_hit_back", {"source": unit.uid, "target": attacker.uid})
		combat.deal_effect_damage(unit, attacker, unit.attack)


static func died(combat: Combat, unit: CombatUnit) -> void:
	if not has(unit, "bufo") or unit.limits.has("bog_bufo_death"):
		return
	unit.limits["bog_bufo_death"] = true
	var killer: CombatUnit = CombatLanes.by_uid(combat, unit.killed_by)
	if killer == null or killer.is_dead() or CombatLanes.maker_of(combat, killer) != unit:
		return
	var count: int = roundi(rate(combat, unit, "bufo", "bufo_halvings"))
	for _time: int in count:
		var loss: int = ceili(killer.attack / 2.0)
		combat.trigger(unit, "pass3_bog:bufo")
		combat.buff(killer, -loss, 0, unit, false, "Bufo")
