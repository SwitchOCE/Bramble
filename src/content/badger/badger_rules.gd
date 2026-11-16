extends RefCounted
## Rules the Badger mechanics share (SHARED-RULES, "Badgers own"): how much Fury a unit has, and
## the targeting Overrun uses. Not a mechanic: the scripts in mechanics/ preload it.

## A unit's Fury given for good (Master-at-Arms), on the unit; the standing badger_fury_given
## turns it into a Fury grant.
const FURY_KEPT: StringName = &"badger_fury_kept"
## A unit's Fury for this fight only (Sett Sexton, Sword-heir), on the fight unit.
const FURY_FIGHT: StringName = &"badger_fury_fight"
## side_query: what this side's Fury is multiplied by (base 1; the Marshal answers 2).
const Q_FURY_TIMES: StringName = &"badger_fury_times"
const FURY: StringName = &"badger_fury"
const RAGE: StringName = &"badger_rage"
const GRUDGE: StringName = &"badger_grudge"
const KNIGHT: String = "Knight"
const BADGER: String = "Badger"


## Fury from every source, before the Marshal: printed and given Fury (every badger_fury the
## unit has, its own and from auras) plus this fight's Fury.
static func fury(unit: CombatUnit) -> int:
	var total: int = unit.counter(FURY_FIGHT)
	for bound: BoundMechanic in unit.hooks():
		if bound.id == FURY:
			total += bound.params.num(&"fury")
	return total


## The unit's own Fury (Sword-heir takes it): printed, given for good and this fight's, but not
## an aura's (Dame) or the Marshal's doubling.
static func own_fury(unit: CombatUnit) -> int:
	var total: int = unit.counter(FURY_FIGHT) + unit.counter(FURY_KEPT)
	for bound: BoundMechanic in unit.mechanics:
		if bound.id == FURY:
			total += bound.params.num(&"fury")
	return total


## True for the one mechanic of a unit that resolves its Fury, so Fury from several sources
## triggers once: the first badger_fury or badger_rage in its hooks.
static func resolves_fury(unit: CombatUnit, params: MechanicParams) -> bool:
	for bound: BoundMechanic in unit.hooks():
		if bound.id == FURY or bound.id == RAGE:
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


## Overrun's next target: picked as `attacker`'s next attack would pick (9.5.1-9.5.5, its row
## rule), among enemies not already dying. Combat.choose_target can return a unit at 0 Health
## that hasn't left the board yet, so this filters first.
static func next_target(combat: Combat, attacker: CombatUnit) -> CombatUnit:
	var front: Array[CombatUnit] = []
	var back: Array[CombatUnit] = []
	for unit: CombatUnit in combat.units(1 - attacker.side):
		if unit.gone or unit.should_die():
			continue
		if combat.geometry.is_front(unit.slot):
			front.append(unit)
		else:
			back.append(unit)
	var candidates: Array[CombatUnit] = front if not front.is_empty() else back
	var row_rule: int = attacker.query(Mechanic.Q_TARGET_ROW, 0)
	if row_rule == Mechanic.ROW_BACK and not back.is_empty():
		candidates = back
	elif row_rule == Mechanic.ROW_ANY:
		candidates = front + back
	if candidates.is_empty():
		return null
	var visible: Array[CombatUnit] = candidates.filter(
		func(u: CombatUnit) -> bool: return u.query(Mechanic.Q_UNTARGETABLE, 0) == 0
	)
	if not visible.is_empty():
		candidates = visible
	var guards: Array[CombatUnit] = candidates.filter(
		func(u: CombatUnit) -> bool: return u.query(Mechanic.Q_TAUNT, 0) != 0
	)
	if not guards.is_empty():
		candidates = guards
	return candidates[combat.effect_rng.index(candidates.size())]
