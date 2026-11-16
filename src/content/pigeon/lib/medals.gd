extends RefCounted
## Medals (SHARED-RULES, Pigeons own): a count on the unit, each a permanent +2/+2 of its own.
## Decorated is 3 or more. Shared by the Pigeon mechanics; not a mechanic itself.

const MEDAL: StringName = &"pigeon_medal"
const DECORATED_AT: int = 3
const STATS: int = 2


## Earns `count` Medals in the Recruit Phase: the count, then the unit's own +2/+2 each.
static func earn(ctx: RecruitContext, unit: Unit, count: int, source: Unit) -> void:
	if unit == null or count <= 0:
		return
	ctx.add_unit_counter(unit, MEDAL, count, source)
	ctx.buff(unit, STATS * count, STATS * count, true, source)


## Earns `count` Medals in a fight, on the fight unit and on the real one at once (kept if it
## dies in the same exchange, SHARED-RULES 35). The count goes first so the buff's aura refresh
## sees it (Decorated mid-fight).
static func earn_in_fight(combat: Combat, unit: CombatUnit, count: int) -> void:
	if unit == null or count <= 0:
		return
	combat.bridge(unit.side).add_unit_counter(unit, MEDAL, count, true, unit)
	combat.buff(unit, STATS * count, STATS * count, unit, true)


static func decorated(view: AuraContext, slot: int) -> bool:
	return view.unit_counter(slot, MEDAL) >= DECORATED_AT


static func is_pigeon(view: AuraContext, slot: int) -> bool:
	var def: UnitDef = view.def_at(slot)
	return def != null and def.has_tribe("Pigeon")
