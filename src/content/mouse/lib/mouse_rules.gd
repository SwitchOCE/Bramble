extends RefCounted
## The Mice's shared rules (docs/ideation-track-2/tribes/mouse/units.json "rules"), used by the
## scripts in mechanics/. Not a mechanic itself, so it lives in lib/.

const TRIBE: String = "Mouse"
const COUSIN: StringName = &"cousin"
## side_query: percent of its Attack a pile-on hit deals (base 100; Dame Bodkin 200, golden 300).
const Q_PILE_PERCENT: StringName = &"mouse_pile_percent"
## Fight count: how many times this unit has piled on this fight (a return carries it).
const PILES: StringName = &"mouse_piles"
## Fight count, and the uses a screen shows: the Needle Pikeman's gains this fight.
const PIKE_GAINS: StringName = &"mouse_pikeman_gains"


static func is_mouse(def: UnitDef) -> bool:
	return def != null and def.has_tribe(TRIBE)


## Hit the enemy with the least Health `times` times, choosing again for each (the core's
## weakest_enemy leaves out units already dying). False if none was hit.
static func hit_weakest(combat: Combat, unit: CombatUnit, times: int) -> bool:
	var any: bool = false
	for _time: int in times:
		if unit.gone or combat.halted():
			break
		var target: CombatUnit = combat.weakest_enemy(unit)
		if target == null:
			break
		combat.hit(unit, target)
		any = true
	return any


## "After this piles on" effects, once `piler` has asked for its pile-on hit: its own (Needle
## Pikeman, Shrew Cutpurse) and its side's Fencing Masters. The hits land together after every
## friend has heard the attack, at the Attack each had when it asked, so a gain made here never
## counts for the hit that earned it, and every unit that piled on counts even when another's hit
## killed the target (rules.pile_on.together).
static func after_pile_on(combat: Combat, piler: CombatUnit) -> void:
	piler.add_fight_count(PILES)
	var first: bool = piler.fight_count(PILES) == 1
	for holder: CombatUnit in combat.units(piler.side).duplicate():
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
	var limit: int = params.num(&"limit")
	if piler.fight_count(PIKE_GAINS) >= limit:
		return
	if combat.trigger(piler, &"mouse_pikeman"):
		piler.add_fight_count(PIKE_GAINS)
		combat.buff(piler, params.num(&"attack"), 0, piler, true)
		combat.show_uses(piler, PIKE_GAINS, limit - piler.fight_count(PIKE_GAINS), piler)


## Summons `count` Cousins from `source`'s slot (8.4.2), golden ones when `golden`. A Cousin
## never waits: with no room it is lost. Returns how many landed.
static func summon_cousins(
	combat: Combat, source: CombatUnit, count: int, golden: bool = false
) -> int:
	var landed: int = 0
	for _i: int in count:
		var made: CombatUnit = combat.summon(
			source.side, COUSIN, source.slot, false, source, false, {}, golden
		)
		if made == null:
			break
		landed += 1
	return landed
