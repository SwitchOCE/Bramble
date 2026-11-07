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
		combat.emit_event("no_room", {"uid": holder.uid, "def_id": str(spec["def_id"])})
		if CombatMoves.spills_all(combat, side):
			combat.spill(side, holder)
		return null
	var fields: Dictionary = {"came_out": true}
	var fighter: CombatUnit = combat.enter_from_spec(spec, side, slot, holder, fields)
	if fighter != null:
		_syllabub(combat, fighter)
	return fighter


## Mr Syllabub: a unit coming out of a Belly fires its Start of Combat text.
static func _syllabub(combat: Combat, fighter: CombatUnit) -> void:
	for ally: CombatUnit in combat.units_of(fighter.side):
		var at: int = ally.mechanic_ids.find(SYLLABUB)
		if at < 0 or ally == fighter:
			continue
		for _time: int in CoreUtil.to_int(ally.params[at].get("times", 1)):
			combat.trigger(ally, SYLLABUB)
			for index: int in fighter.scripts.size():
				if not fighter.on_board or combat._halted:
					return
				fighter.scripts[index].on_start_of_combat(combat, fighter, fighter.params[index])


# --- Swallowed mid-fight ------------------------------------------------------------------------


## `holder` takes `target` off the board, alive, for now. It keeps its own Belly and damage.
static func swallow(combat: Combat, holder: CombatUnit, target: CombatUnit) -> void:
	var row: Array = combat.sides[target.side]
	row[target.slot] = null
	target.on_board = false
	holder.inside.append(target)
	combat.swallowing = true
	combat.emit_event(
		"swallowed",
		{"uid": target.uid, "side": target.side, "slot": target.slot, "by": holder.uid}
	)
	combat._recalc_auras(true)


## Everyone `holder` swallowed goes back to their own side and their own slot, or the nearest gap.
static func return_inside(combat: Combat, holder: CombatUnit) -> void:
	var units: Array[CombatUnit] = holder.inside
	holder.inside = []
	for unit: CombatUnit in units:
		var occupied: Array[bool] = combat._occupied(unit.side)
		var slot: int = BoardGeometry.summon_slot(occupied, unit.slot, true)
		if slot < 0:
			combat.emit_event("no_room", {"uid": holder.uid, "def_id": unit.def_id()})
			continue
		unit.slot = slot
		combat.enter_board(unit, holder, {"came_out": true})


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
	var statuses: Dictionary = victim.statuses.duplicate()
	for status: Variant in statuses:
		combat.set_status(victim, str(status), false, null)
	if victim.counters.has("hex"):
		thief.counters["hex"] = victim.counters["hex"]
	victim.lend_text_to(thief)
	for status: Variant in statuses:
		var data: Dictionary = statuses[status]
		combat.set_status(thief, str(status), true, thief, data)
	combat.emit_event("text_taken", {"uid": thief.uid, "from": victim.uid})
	combat._recalc_auras(true)


## Mother Goose away: each Nest strikes across for its bird's card Attack, no Ring or Hex in it and
## no source, so nothing hits back. Her own Nest too. One Goose per side (the rule holds the most).
static func goose_strikes(combat: Combat, first: int) -> void:
	for side: int in [first, 1 - first]:
		var rules: Dictionary = combat.side_rules[side]
		var strikes: int = CoreUtil.to_int(rules.get("goose", 0))
		if strikes <= 0:
			continue
		var nests: Array = rules.get("nests", [])
		for _time: int in strikes:
			for value: Variant in nests:
				var nest: Dictionary = value
				_strike(combat, side, nest)
			combat._resolve_deaths(side)


static func _strike(combat: Combat, side: int, nest: Dictionary) -> void:
	var slot: int = nest["slot"]
	var target: CombatUnit = combat.unit_at(1 - side, BoardGeometry.across(slot))
	var amount: int = nest["attack"]
	if target == null or amount <= 0 or target.health <= 0:
		return
	combat.emit_event(
		"goose_strike", {"side": side, "slot": slot, "target": target.uid, "bird": nest["def_id"]}
	)
	combat.deal_effect_damage(null, target, amount)


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
	var at: int = slot
	if combat.unit_at(source.side, at) != null:
		at = BoardGeometry.summon_slot(combat._occupied(source.side), slot, false)
	if at < 0:
		return
	combat.notes[key] = true
	combat.trigger(source, "gabble_ratchet")
	var spec: Dictionary = nest["spec"]
	var bird: CombatUnit = combat.enter_from_spec(spec, source.side, at, source, {"landed": true})
	if bird != null and attack_factor > 1:
		combat.buff(bird, bird.attack * (attack_factor - 1), 0, source)
