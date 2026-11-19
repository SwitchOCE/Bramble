extends RefCounted
## Rules the Badger mechanics share (SHARED-RULES, "Badgers own"): how much Fury a unit has.
## Not a mechanic: the scripts in mechanics/ preload it.

## side_query: what this side's Fury is multiplied by (base 1; the Marshal answers 2).
const Q_FURY_TIMES: StringName = &"badger_fury_times"
const FURY: StringName = &"badger_fury"
const GRUDGE: StringName = &"badger_grudge"
const SEXTON: StringName = &"badger_sexton"
const KNIGHT: String = "Knight"
const BADGER: String = "Badger"


## Fury from every source, before the Marshal: every badger_fury the unit has, printed, given
## (Master-at-Arms for good; Sword-heir this fight) and from auras (Dame). They add up.
static func fury(unit: CombatUnit) -> int:
	var total: int = 0
	for bound: BoundMechanic in unit.hooks():
		if bound.id == FURY:
			total += bound.params.num(&"fury")
	return total


## The unit's own Fury (Sword-heir takes it): printed and given, not an aura's (Dame) or the
## Marshal's doubling.
static func own_fury(unit: CombatUnit) -> int:
	var total: int = 0
	for bound: BoundMechanic in unit.mechanics:
		if bound.id == FURY:
			total += bound.params.num(&"fury")
	return total


## Gives `target` +`amount` Fury for the rest of this fight (Sword-heir): a badger_fury of its
## own, so a unit with no Fury now has some.
static func give_fight_fury(
	combat: Combat, target: CombatUnit, amount: int, source: CombatUnit
) -> void:
	if amount > 0:
		combat.bridge(target.side).give_effect(target, FURY, {"fury": amount}, false, source)


## True for the one badger_fury of a unit that resolves its Fury (the first in its hooks), so
## Fury from several sources triggers once.
static func resolves_fury(unit: CombatUnit, params: MechanicParams) -> bool:
	for bound: BoundMechanic in unit.hooks():
		if bound.id == FURY:
			return bound.params == params
	return false


## Fury N (9.6.1 steps 1 and 2): +N Attack, and +N more for each unit the side is outnumbered
## by, this fight: N x (1 + the count). A pass 1 proposal (19 Nov) gave it the floor; it was
## N x the count. Then any Sett Sexton behind the unit pays (sexton_pays).
static func rage(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if unit == null or unit.gone or not resolves_fury(unit, params):
		return
	var times: int = maxi(1, combat.side_query(unit.side, Q_FURY_TIMES, 1))
	var gain: int = fury(unit) * times * (1 + combat.outnumbered_by(unit.side))
	if gain <= 0 or not combat.trigger(unit, FURY):
		return
	combat.buff(unit, gain, 0, unit)
	sexton_pays(combat, unit)


## Sett Sexton: after a unit in front of a Sexton gains Attack from Fury, it gains +amount
## Attack permanently (on the recruit unit as well as this fight's copy), `limit` times a fight
## for each unit from each Sexton. The count is the unit's fight count, so a return keeps it.
static func sexton_pays(combat: Combat, unit: CombatUnit) -> void:
	for holder: CombatUnit in combat.units(unit.side).duplicate():
		if holder == unit or holder.gone:
			continue
		if not combat.geometry.in_front_of(holder.slot).has(unit.slot):
			continue
		for bound: BoundMechanic in holder.hooks():
			if bound.id != SEXTON or combat.halted() or unit.gone:
				continue
			var key: StringName = StringName("%s_%d" % [SEXTON, holder.uid])
			if unit.fight_count(key) >= bound.params.num(&"limit"):
				continue
			if not combat.trigger(holder, SEXTON):
				return
			unit.add_fight_count(key)
			combat.buff(unit, bound.params.num(&"amount"), 0, holder, true)


static func is_knight(def: UnitDef) -> bool:
	return def != null and def.types.has(KNIGHT)
