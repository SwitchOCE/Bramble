extends RefCounted
## The Mice's shared rules (docs/ideation-track-2/tribes/mouse/units.json "rules"), used by the
## scripts in mechanics/. Not a mechanic itself, so it lives in lib/.

const TRIBE: String = "Mouse"
const COUSIN: StringName = &"cousin"
## side_query: percent of its Attack a pile-on hit deals (base 100; Dame Bodkin 200, golden 300).
const Q_PILE_PERCENT: StringName = &"mouse_pile_percent"
## CombatUnit.state: how many times this unit has piled on this fight.
const PILES: StringName = &"mouse_piles"
## CombatUnit.state: how many times the Needle Pikeman has grown this fight.
const PIKE_GAINS: StringName = &"mouse_pike_gains"
## FightSide.state: the Edgewright's slot Attack percent for this fight (0 = none).
const EDGE_PERCENT: StringName = &"mouse_edge_percent"
## The slot keyword the Edgewright leaves on every slot, so the doubling outlives it.
const EDGED: StringName = &"mouse_edged"


static func is_mouse(def: UnitDef) -> bool:
	return def != null and def.has_tribe(TRIBE)


## "The enemy with the least Health": both rows, current Health, ties at random. Units already
## at 0 Health (dying when deaths next resolve) are left out, so a second Hit chooses again.
static func least_health_enemy(combat: Combat, unit: CombatUnit) -> CombatUnit:
	var lowest: Array[CombatUnit] = []
	var best: int = 0
	for enemy: CombatUnit in combat.units(1 - unit.side):
		if enemy.gone or enemy.should_die():
			continue
		if lowest.is_empty() or enemy.health() < best:
			lowest = [enemy]
			best = enemy.health()
		elif enemy.health() == best:
			lowest.append(enemy)
	if lowest.is_empty():
		return null
	return lowest[combat.effect_rng.index(lowest.size())]


## Hit X `times` times, choosing the least-Health enemy again for each. False if none was hit.
static func hit_weakest(combat: Combat, unit: CombatUnit, times: int) -> bool:
	var any: bool = false
	for _time: int in times:
		if unit.gone or combat.halted():
			break
		var target: CombatUnit = least_health_enemy(combat, unit)
		if target == null:
			break
		combat.hit(unit, target)
		any = true
	return any


## "After this piles on" effects, once `piler` has piled on: its own (Needle Pikeman, Shrew
## Cutpurse) and its side's Fencing Masters. Every unit that piled on counts, even when another
## unit's hit had already killed the target (rules.pile_on.together).
static func after_pile_on(combat: Combat, piler: CombatUnit) -> void:
	piler.set_state(PILES, piler.state_int(PILES) + 1)
	var first: bool = piler.state_int(PILES) == 1
	for holder: CombatUnit in combat.units(piler.side).duplicate():
		if holder.gone:
			continue
		for bound: BoundMechanic in holder.hooks():
			if combat.halted():
				return
			match bound.id:
				&"mouse_pikeman":
					if holder == piler:
						_pikeman_grows(combat, piler, bound.params)
				&"mouse_cutpurse":
					if holder == piler and first and combat.trigger(piler, bound.id):
						combat.bridge(piler.side).add_gold(bound.params.num(&"gold"), piler)
				&"mouse_fencing_master":
					if first and is_mouse(piler.def) and combat.trigger(holder, bound.id):
						combat.buff(piler, bound.params.num(&"attack"), 0, holder, true)


static func _pikeman_grows(combat: Combat, piler: CombatUnit, params: MechanicParams) -> void:
	if piler.state_int(PIKE_GAINS) >= params.num(&"limit"):
		return
	if combat.trigger(piler, &"mouse_pikeman"):
		piler.set_state(PIKE_GAINS, piler.state_int(PIKE_GAINS) + 1)
		combat.buff(piler, params.num(&"attack"), 0, piler, true)


## Summons `count` Cousins from `source`'s slot (8.4.2). A Cousin never waits: with no room it is
## lost. Returns how many landed.
static func summon_cousins(combat: Combat, source: CombatUnit, count: int) -> int:
	var landed: int = 0
	for _i: int in count:
		if combat.summon(source.side, COUSIN, source.slot, false, source) != null:
			landed += 1
	return landed


## The fight's slot Attack percent the Edgewright set for `side_index` (0 if none).
static func edge_percent(combat: Combat, side_index: int) -> int:
	return combat.bridge(side_index).state_int(EDGE_PERCENT)
