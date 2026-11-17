extends RefCounted
## The Mice's shared rules (docs/ideation-track-2/tribes/mouse/units.json "rules"), used by the
## scripts in mechanics/. Not a mechanic itself, so it lives in lib/.

const TRIBE: String = "Mouse"
const COUSIN: StringName = &"cousin"
## Pile-on Ambush percent: base 25; Dame Bodkin 50, golden 75.
const AMBUSH_USED: StringName = &"mouse_ambush_used"
const Q_PILE_PERCENT: StringName = &"mouse_pile_percent"
## Fight count: how many times this unit has piled on this fight (a return carries it).
const PILES: StringName = &"mouse_piles"
## Fight count, and the uses a screen shows: the Needle Pikeman's gains this fight.
const PIKE_GAINS: StringName = &"mouse_pikeman_gains"


static func is_mouse(def: UnitDef) -> bool:
	return def != null and def.has_tribe(TRIBE)


## All Ambush sources share this one allowance, carried across returns by fight_count.
static func ready(unit: CombatUnit) -> bool:
	return (
		unit != null
		and not unit.gone
		and not unit.should_die()
		and unit.attack() > 0
		and unit.fight_count(AMBUSH_USED) == 0
	)


static func ambush(
	combat: Combat, unit: CombatUnit, target: CombatUnit, mechanic_id: StringName, percent: int = 25
) -> bool:
	if not ready(unit) or target == null or target.gone or target.should_die() or combat.halted():
		return false
	if not combat.trigger(unit, mechanic_id):
		return false
	unit.add_fight_count(AMBUSH_USED)
	# The strike's amount is read now, before any "after pile-on" growth.
	combat.hit(unit, target, clampi(percent, 0, 75), true)
	combat.show_uses(unit, AMBUSH_USED, 0, unit)
	return true


static func ambush_weakest(combat: Combat, unit: CombatUnit, mechanic_id: StringName) -> bool:
	return ambush(combat, unit, combat.weakest_enemy(unit), mechanic_id)


## "After this piles on" effects, once `piler` has asked for its pile-on hit: its own (Needle
## Pikeman, Shrew Cutpurse) and its side's Fencing Masters. The Ambushes land together after every
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
