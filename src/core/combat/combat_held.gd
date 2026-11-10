class_name CombatHeld
extends RefCounted
## The fight's side of held units: Bellies opening, units swallowed mid-fight, and what birds away
## do (Nests, Mother Goose, the Ratchet). Combat keeps the state; RecruitRules' side is HeldUnits.

const SYLLABUB: String = "syllabub"


## How many more units this fighter's Belly can take right now.
static func room(unit: CombatUnit) -> int:
	var at: int = unit.mechanic_ids.find(HeldUnits.BELLY)
	if at < 0:
		return 0
	var size: int = CoreUtil.to_int(unit.params[at].get("size", 0))
	return maxi(0, size - unit.held_specs.size() - unit.inside.size())


# --- Coming out ---------------------------------------------------------------------------------


## Dying Oozes open: whoever they swallowed goes back first, then bellies, last in first. Across all
## that died together, every first-out lands before any second-out. Sides never compete for slots.
static func open_bellies(combat: Combat, dying: Array[CombatUnit]) -> void:
	var opening: Array[CombatUnit] = []
	var out_counts: Dictionary = {}
	for unit: CombatUnit in dying:
		if not unit.inside.is_empty():
			return_inside(combat, unit)
		if not unit.held_specs.is_empty():
			opening.append(unit)
			out_counts[unit.uid] = 0
	var first: bool = true
	var anyone_left: bool = not opening.is_empty()
	while anyone_left and not combat._halted:
		anyone_left = false
		for unit: CombatUnit in opening:
			if unit.held_specs.is_empty():
				continue
			anyone_left = anyone_left or unit.held_specs.size() > 1
			if pop_one(combat, unit, first) != null:
				out_counts[unit.uid] = CoreUtil.to_int(out_counts[unit.uid]) + 1
		first = false
	for unit: CombatUnit in opening:
		for index: int in unit.scripts.size():
			unit.scripts[index].after_release(
				combat, unit, unit.params[index], CoreUtil.to_int(out_counts[unit.uid])
			)


## The last unit in comes out, into the holder's own slot when `own_slot` and free, else the
## nearest gap. No room: it's lost for this fight (8.4.5). Null then.
static func pop_one(combat: Combat, holder: CombatUnit, own_slot: bool) -> CombatUnit:
	var spec: Dictionary = holder.held_specs.pop_back()
	var side: int = holder.side
	var slot: int = BoardGeometry.summon_slot(combat._occupied(side), holder.slot, own_slot)
	if slot < 0:
		combat.emit_event(
			"no_room", {"uid": holder.uid, "def_id": str(spec["def_id"]), "outcome": "lost"}
		)
		return null
	var fields: Dictionary = {"came_out": true}
	var fighter: CombatUnit = spec.get("_pass3_fighter")
	if fighter != null:
		fighter.slot = slot
		combat._apply_slot_grants(fighter)
		combat.enter_board(fighter, holder, fields)
	else:
		fighter = combat.enter_from_spec(spec, side, slot, holder, fields)
	if fighter != null:
		_syllabub(combat, fighter)
	return fighter


## Mr Syllabub: a unit coming out of a Belly fires its Start of Combat text.
static func _syllabub(combat: Combat, fighter: CombatUnit, native_only: bool = false) -> void:
	for ally: CombatUnit in combat.units_of(fighter.side):
		var at: int = ally.mechanic_ids.find(SYLLABUB)
		if at < 0:
			continue
		var first: Dictionary = ally.params[at]
		if not CoreUtil.to_bool(first.get("pass3", false)):
			if not native_only:
				if ally != fighter:
					_syllabub_times(combat, ally, fighter, CoreUtil.to_int(first.get("times", 1)))
				continue
		var times: int = 0
		var guarded: bool = combat.config.get_value("pass3_loop_guards") != false
		for index: int in ally.scripts.size():
			if ally.mechanic_ids[index] != SYLLABUB:
				continue
			if native_only and not CoreUtil.to_bool(ally.params[index].get("pass3", false)):
				continue
			var count: int = CoreUtil.to_int(ally.params[index].get("times", 1))
			times = maxi(times, count) if guarded else times + count
		_syllabub_times(combat, ally, fighter, times)


static func _syllabub_times(
	combat: Combat, source: CombatUnit, fighter: CombatUnit, times: int
) -> void:
	for _time: int in times:
		combat.trigger(source, SYLLABUB)
		start_again(combat, fighter)


## Each replay is a new dispatch; duplicate copies of one growth ability still compete.
static func start_again(combat: Combat, fighter: CombatUnit) -> void:
	Pass3HunterStart.begin_dispatch(fighter)
	for index: int in fighter.scripts.size():
		if not fighter.on_board or combat._halted:
			return
		fighter.scripts[index].on_start_of_combat(combat, fighter, fighter.params[index])


# --- Swallowed mid-fight ------------------------------------------------------------------------


## `holder` takes `target` off the board, alive, for now. It keeps its own Belly and damage.
static func swallow(combat: Combat, holder: CombatUnit, target: CombatUnit) -> void:
	CombatLanes.lose_unit(combat, target)
	var row: Array = combat.sides[target.side]
	row[target.slot] = null
	target.on_board = false
	holder.inside.append(target)
	combat.swallowing = true
	combat.emit_event(
		"swallowed", {"uid": target.uid, "side": target.side, "slot": target.slot, "by": holder.uid}
	)
	combat._recalc_auras(true)


## Everyone `holder` swallowed goes back to their own side and their own slot, or the nearest gap.
static func return_inside(combat: Combat, holder: CombatUnit) -> void:
	var units: Array[CombatUnit] = holder.inside
	holder.inside = []
	if Pass3OozeCombat.has(holder, "granny_stir_up"):
		_return_family(combat, holder, units)
		return
	for unit: CombatUnit in units:
		var occupied: Array[bool] = combat._occupied(unit.side)
		var slot: int = BoardGeometry.summon_slot(occupied, unit.slot, true)
		if slot < 0:
			combat.emit_event(
				"no_room", {"uid": holder.uid, "def_id": unit.def_id(), "outcome": "lost"}
			)
			continue
		unit.slot = slot
		combat.enter_board(unit, holder, {"came_out": true})
		if unit.side == holder.side:
			_syllabub(combat, unit, true)


## Granny returns the family together, so a gathered Moss is present for every sibling's
## emergence. Reserve all slots before release effects can gather or summon another body.
static func _return_family(combat: Combat, holder: CombatUnit, units: Array[CombatUnit]) -> void:
	var returning: Array[CombatUnit] = []
	for unit: CombatUnit in units:
		var slot: int = BoardGeometry.summon_slot(combat._occupied(unit.side), unit.slot, true)
		if slot < 0:
			combat.emit_event(
				"no_room", {"uid": holder.uid, "def_id": unit.def_id(), "outcome": "lost"}
			)
			continue
		unit.slot = slot
		unit.on_board = true
		var row: Array = combat.sides[unit.side]
		row[slot] = unit
		returning.append(unit)
	for unit: CombatUnit in returning:
		if not unit.on_board or unit.is_dead():
			continue
		combat.enter_board(unit, holder, {"came_out": true})
		if unit.on_board and not unit.is_dead() and unit.side == holder.side:
			_syllabub(combat, unit, true)


## A side with nobody left on the board gets its swallowed units back, or the fight would end with
## them still inside.
static func check_sides(combat: Combat) -> void:
	for side: int in 2:
		if not combat.units_of(side).is_empty():
			continue
		for holder: CombatUnit in combat.units_of(1 - side):
			_return_side(combat, holder, side)


static func _return_side(combat: Combat, holder: CombatUnit, side: int) -> void:
	var kept: Array[CombatUnit] = []
	var going: Array[CombatUnit] = []
	for unit: CombatUnit in holder.inside:
		if unit.side == side:
			going.append(unit)
		else:
			kept.append(unit)
	if going.is_empty():
		return
	holder.inside = going
	return_inside(combat, holder)
	holder.inside = kept


# --- Before the first attack --------------------------------------------------------------------


## Mag Pye's phase: before any Start of Combat text, in the same random player order.
static func first_of_all(combat: Combat, first: int) -> void:
	for side: int in [first, 1 - first]:
		for unit: CombatUnit in combat.units_of(side):
			var count: int = unit.scripts.size()
			for index: int in count:
				if index < unit.scripts.size():
					unit.scripts[index].first_of_all(combat, unit, unit.params[index])


## Mag Pye: the thief takes the victim's text and the statuses it gave.
static func steal_text(combat: Combat, thief: CombatUnit, victim: CombatUnit) -> void:
	var fields: Dictionary = {"uid": thief.uid, "from": victim.uid}
	if Pass3Combat.has_content(combat):
		fields.merge(Pass3Combat.take_words(thief, victim))
	var statuses: Dictionary = victim.statuses.duplicate()
	for status: Variant in statuses:
		combat.set_status(victim, str(status), false, null)
	if victim.counters.has("hex"):
		thief.counters["hex"] = victim.counters["hex"]
	victim.lend_text_to(thief)
	for status: Variant in statuses:
		var data: Dictionary = statuses[status]
		combat.set_status(thief, str(status), true, thief, data)
	combat.emit_event("text_taken", fields)
	combat._recalc_auras(true)


## Mother Goose away: each Nest strikes across for flat damage, with no source to hit back.
## Her own Nest too. Only the strongest Goose applies.
static func goose_strikes(combat: Combat, first: int) -> void:
	for side: int in [first, 1 - first]:
		var rules: Dictionary = combat.side_rules[side]
		var damage: int = CoreUtil.to_int(rules.get("goose", 0))
		if damage <= 0:
			continue
		var nests: Array = rules.get("nests", [])
		for value: Variant in nests:
			var nest: Dictionary = value
			_strike(combat, side, nest, damage)
		combat._resolve_deaths(side)


static func _strike(combat: Combat, side: int, nest: Dictionary, amount: int) -> void:
	var slot: int = nest["slot"]
	var target: CombatUnit = combat.unit_at(1 - side, BoardGeometry.across(slot))
	if target == null or amount <= 0 or target.health <= 0:
		return
	combat.emit_event(
		"goose_strike", {"side": side, "slot": slot, "target": target.uid, "bird": nest["def_id"]}
	)
	combat.deal_effect_damage(null, target, amount, side)


## The Nest on a slot in this fight; {} if none.
static func nest_at(combat: Combat, side: int, slot: int) -> Dictionary:
	var rules: Dictionary = combat.side_rules[side]
	var nests: Array = rules.get("nests", [])
	for value: Variant in nests:
		var nest: Dictionary = value
		if CoreUtil.to_int(nest["slot"]) == slot:
			return nest
	return {}


## How many Nests a side has in this fight.
static func nest_count(combat: Combat, side: int) -> int:
	var rules: Dictionary = combat.side_rules[side]
	var nests: Array = rules.get("nests", [])
	return nests.size()


## The Gabble Ratchet: this bird lands in `slot` for the fight, once. Ring and Hex apply there.
static func land_bird(
	combat: Combat, source: CombatUnit, nest: Dictionary, slot: int, attack_factor: int
) -> void:
	var key: String = "landed_%d_%d" % [source.side, CoreUtil.to_int(nest["slot"])]
	if combat.notes.has(key):
		return
	combat.notes[key] = true
	if combat.unit_at(source.side, slot) != null:
		combat.emit_event("no_room", {"uid": source.uid, "def_id": str(nest["def_id"])})
		return
	combat.trigger(source, "gabble_ratchet")
	var original: Dictionary = nest["spec"]
	var spec: Dictionary = original.duplicate(true)
	spec["attack"] = CoreUtil.to_int(spec["attack"]) * attack_factor
	combat.enter_from_spec(spec, source.side, slot, source, {"landed": true})


## Friendly releases and Wobbly's Drips count. Returned enemy prisoners do not count.
static func emerged(
	combat: Combat, unit: CombatUnit, holder: CombatUnit, fields: Dictionary
) -> void:
	Pass3OozeCombat.emerged(combat, unit, holder, fields)
	if holder == null:
		return
	if not fields.get("came_out", false) and not fields.get("wobbly_drip", false):
		return
	if holder.side != unit.side or not holder.has_tribe("Oozes"):
		return
	var elders: Array[CombatUnit] = combat.units_of(unit.side)
	if not elders.has(holder):
		elders.append(holder)
	for elder: CombatUnit in elders:
		if elder != holder and elder.is_dead():
			continue
		for index: int in elder.scripts.size():
			if elder.mechanic_ids[index] != "elder_ooze":
				continue
			var params: Dictionary = elder.params[index]
			var bonus: int = CoreUtil.to_int(params["stats"])
			combat.trigger(elder, "elder_ooze")
			combat.buff(unit, bonus, bonus, elder)
