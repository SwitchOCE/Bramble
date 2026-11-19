extends RefCounted
## The Mice's shared rules (docs/ideation-track-2/tribes/mouse/units.json "rules"), used by the
## scripts in mechanics/. Not a mechanic itself, so it lives in lib/.

const TRIBE: String = "Mouse"
const COUSIN: StringName = &"cousin"
## Pile on N (11.7.11): the mechanic id, also the key its uses left show under.
const PILE_ON: StringName = &"mouse_pile_on"
## Pile on with no count ("Pile on.", today's cards until the card rework prints every N).
const PILE_ON_UNCOUNTED: int = 0
## Fight count: how many neighbour attacks a counted piler has heard (its N spent).
const PILE_ON_HEARD: StringName = &"mouse_pile_on_heard"
## Hand-me-down (11.7.12-11.7.13): the death effect's id.
const HAND_ME_DOWN: StringName = &"mouse_hand_me_down"
## side_query: percent of its Attack a pile-on hit deals (base 100; Dame Bodkin 200, golden 300).
const Q_PILE_PERCENT: StringName = &"mouse_pile_percent"
## Fight count: how many times this unit has piled on this fight (a return carries it).
const PILES: StringName = &"mouse_piles"
## Fight count, and the uses a screen shows: the Needle Pikeman's gains this fight.
const PIKE_GAINS: StringName = &"mouse_pikeman_gains"


static func is_mouse(def: UnitDef) -> bool:
	return def != null and def.has_tribe(TRIBE)


## A unit's Pile on N, every source added up; PILE_ON_UNCOUNTED when any source has no count
## (or the unit has no Pile on). A golden's N is as printed (THRESHOLD, 7.3.5a).
static func pile_on_count(unit: CombatUnit) -> int:
	var total: int = 0
	for bound: BoundMechanic in unit.hooks():
		if bound.id != PILE_ON:
			continue
		var n: int = bound.params.num(&"pile_on")
		if n == PILE_ON_UNCOUNTED:
			return PILE_ON_UNCOUNTED
		total += n
	return total


## True for the one mouse_pile_on of a unit that resolves its Pile on (the first in its hooks),
## so a unit with Pile on from several sources piles on once.
static func resolves_pile_on(unit: CombatUnit, params: MechanicParams) -> bool:
	for bound: BoundMechanic in unit.hooks():
		if bound.id == PILE_ON:
			return bound.params == params
	return false


## A neighbour attacked: spends one of `unit`'s N and shows the uses left. False once the first
## N are spent. An uncounted Pile on never runs out and shows nothing.
static func use_pile_on(combat: Combat, unit: CombatUnit) -> bool:
	var limit: int = pile_on_count(unit)
	if limit == PILE_ON_UNCOUNTED:
		return true
	if unit.fight_count(PILE_ON_HEARD) >= limit:
		return false
	unit.add_fight_count(PILE_ON_HEARD)
	combat.show_uses(unit, PILE_ON, limit - unit.fight_count(PILE_ON_HEARD), unit)
	return true


## Hand-me-down (11.7.12-11.7.13): `giver`'s own Attack (ruling 43: this fight's buffs on it,
## never its slot's buff, Renown or an aura) goes to the nearest friendly Mouse for the rest of
## the fight. Nothing with 0 Attack or no Mouse left. The heir, or null.
static func hand_me_down(combat: Combat, giver: CombatUnit) -> CombatUnit:
	var attack: int = giver.stats.own_attack()
	if attack <= 0:
		return null
	var heir: CombatUnit = nearest_mouse(combat, giver)
	if heir == null or not combat.trigger(giver, HAND_ME_DOWN):
		return null
	combat.buff(heir, attack, 0, giver)
	return heir


## The friendly Mouse on the board fewest neighbour steps (8.2.3) from `origin`'s slot (its
## last-known slot once dead), ties in reading order; never `origin` or a dying unit. Null if none.
static func nearest_mouse(combat: Combat, origin: CombatUnit) -> CombatUnit:
	var steps: Array[int] = combat.geometry.neighbour_steps(origin.slot)
	var best: CombatUnit = null
	var best_away: int = -1
	for friend: CombatUnit in combat.units(origin.side):
		if friend == origin or friend.gone or not is_mouse(friend.def):
			continue
		if not combat.geometry.is_valid(friend.slot) or steps[friend.slot] < 0:
			continue
		var away: int = steps[friend.slot]
		if best == null or away < best_away or (away == best_away and friend.slot < best.slot):
			best = friend
			best_away = away
	return best


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
