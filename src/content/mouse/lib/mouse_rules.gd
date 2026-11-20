extends RefCounted
## The Mice's shared rules (docs/ideation-track-2/tribes/mouse/units.json "rules"), used by the
## scripts in mechanics/. Not a mechanic itself, so it lives in lib/.

const TRIBE: String = "Mouse"
const COUSIN: StringName = &"cousin"
## Pile on N (11.7.11): the mechanic id, also the key its uses left show under.
const PILE_ON: StringName = &"mouse_pile_on"
## Fight count: how many neighbour attacks a counted piler has heard (its N spent).
const PILE_ON_HEARD: StringName = &"mouse_pile_on_heard"
## Hand-me-down (11.7.12-11.7.13): the death effect's id.
const HAND_ME_DOWN: StringName = &"mouse_hand_me_down"
## side_query: percent of its Attack a pile-on hit deals (base 100; Dame Bodkin 200, golden 300).
const Q_PILE_PERCENT: StringName = &"mouse_pile_percent"


static func is_mouse(def: UnitDef) -> bool:
	return def != null and def.has_tribe(TRIBE)


static func pile_on_count(unit: CombatUnit) -> int:
	var total: int = 0
	for bound: BoundMechanic in unit.hooks():
		if bound.id != PILE_ON:
			continue
		total += bound.params.num(&"pile_on")
	return total


## True for the one mouse_pile_on of a unit that resolves its Pile on (the first in its hooks),
## so a unit with Pile on from several sources piles on once.
static func resolves_pile_on(unit: CombatUnit, params: MechanicParams) -> bool:
	for bound: BoundMechanic in unit.hooks():
		if bound.id == PILE_ON:
			return bound.params == params
	return false


## A neighbour attacked: spends one of `unit`'s N and shows the uses left. False once the first
## N are spent.
static func use_pile_on(combat: Combat, unit: CombatUnit) -> bool:
	var limit: int = pile_on_count(unit)
	if unit.fight_count(PILE_ON_HEARD) >= limit:
		return false
	unit.add_fight_count(PILE_ON_HEARD)
	combat.show_uses(unit, PILE_ON, limit - unit.fight_count(PILE_ON_HEARD), unit)
	return true


## Spend the charge before resolving an effect that might itself trigger another use.
static func charge(combat: Combat, unit: CombatUnit, id: StringName, limit: int) -> bool:
	if unit.fight_count(id) >= limit or not combat.trigger(unit, id):
		return false
	unit.add_fight_count(id)
	combat.show_uses(unit, &"mouse_charge_left", limit - unit.fight_count(id), unit)
	return true


## Only living Mice can inherit, including during simultaneous death resolution.
static func nearest_mice(combat: Combat, origin: CombatUnit) -> Array[CombatUnit]:
	var steps: Array[int] = combat.geometry.neighbour_steps(origin.slot)
	var heirs: Array[CombatUnit] = []
	for friend: CombatUnit in combat.units(origin.side):
		if friend != origin and is_mouse(friend.def) and steps[friend.slot] >= 0:
			heirs.append(friend)
	heirs.sort_custom(
		func(a: CombatUnit, b: CombatUnit) -> bool:
			if steps[a.slot] == steps[b.slot]:
				return a.slot < b.slot
			return steps[a.slot] < steps[b.slot]
	)
	return heirs


static func hand_me_down(combat: Combat, giver: CombatUnit) -> void:
	var attack: int = giver.stats.own_attack()
	var heirs: Array[CombatUnit] = nearest_mice(combat, giver)
	if attack <= 0 or heirs.is_empty() or not combat.trigger(giver, HAND_ME_DOWN):
		return
	var count: int = 1
	var permanent: bool = false
	for friend: CombatUnit in combat.units(giver.side):
		for bound: BoundMechanic in friend.hooks():
			match bound.id:
				&"mouse_bell_ringer":
					attack += bound.params.num(&"attack")
				&"mouse_widow":
					# Proposal: multiple Widows use the largest recipient count.
					count = maxi(count, bound.params.num(&"heirs"))
				&"mouse_old_mother":
					# Proposal: one Mother pays for the entire gift, in reading order.
					if not permanent:
						permanent = charge(combat, friend, bound.id, bound.params.num(&"limit"))
	heirs.resize(mini(count, heirs.size()))
	# Proposal: distribute first, then resolve each heir's Hobs before its Sister attack.
	for heir: CombatUnit in heirs:
		combat.buff(heir, attack, 0, giver, permanent)
	for heir: CombatUnit in heirs:
		if not heir.gone and not heir.should_die():
			after_inheriting(combat, heir)


static func after_inheriting(combat: Combat, heir: CombatUnit) -> void:
	for friend: CombatUnit in combat.units(heir.side):
		for bound: BoundMechanic in friend.hooks():
			if (
				bound.id == &"mouse_hob"
				and charge(combat, friend, bound.id, bound.params.num(&"limit"))
			):
				combat.buff(heir, bound.params.num(&"attack"), 0, friend, true)
	for bound: BoundMechanic in heir.hooks():
		if (
			bound.id == &"mouse_sister"
			and charge(combat, heir, bound.id, bound.params.num(&"limit"))
		):
			combat.attack_now(heir)


static func after_pile_on(combat: Combat, piler: CombatUnit) -> void:
	for bound: BoundMechanic in piler.hooks():
		match bound.id:
			&"mouse_pikeman":
				if combat.trigger(piler, bound.id):
					for friend: CombatUnit in combat.units(piler.side):
						if is_mouse(friend.def) and friend.has_mechanic(PILE_ON):
							combat.buff(friend, bound.params.num(&"attack"), 0, piler, true)
			&"mouse_cutpurse":
				if combat.trigger(piler, bound.id):
					combat.bridge(piler.side).add_gold(bound.params.num(&"gold"), piler)
			&"mouse_fencing_master":
				if combat.trigger(piler, bound.id):
					combat.buff(piler, bound.params.num(&"attack"), 0, piler, true)


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
