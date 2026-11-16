extends RefCounted
## Rules the Badger mechanics share (SHARED-RULES, "Badgers own"): how much Fury a unit has.
## Not a mechanic: the scripts in mechanics/ preload it.

## side_query: what this side's Fury is multiplied by (base 1; the Marshal answers 2).
const Q_FURY_TIMES: StringName = &"badger_fury_times"
const FURY: StringName = &"badger_fury"
const GRUDGE: StringName = &"badger_grudge"
const KNIGHT: String = "Knight"
const BADGER: String = "Badger"


## Fury from every source, before the Marshal: every badger_fury the unit has, printed, given
## (Master-at-Arms for good; Sett Sexton and Sword-heir this fight) and from auras (Dame). They
## add up.
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


## Gives `target` +`amount` Fury for the rest of this fight (Sett Sexton, Sword-heir): a
## badger_fury of its own, so a unit with no Fury now has some.
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


## Fury N (9.6.1 steps 1 and 2): +N x the count in Attack, this fight.
static func rage(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if unit == null or unit.gone or not resolves_fury(unit, params):
		return
	var times: int = maxi(1, combat.side_query(unit.side, Q_FURY_TIMES, 1))
	var gain: int = fury(unit) * times * combat.outnumbered_by(unit.side)
	if gain <= 0 or not combat.trigger(unit, FURY):
		return
	combat.buff(unit, gain, 0, unit)


static func is_knight(def: UnitDef) -> bool:
	return def != null and def.types.has(KNIGHT)
