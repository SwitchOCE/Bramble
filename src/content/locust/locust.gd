extends RefCounted
## Names and small rules the Locust mechanics share (not a mechanic: the loader only registers
## scripts in mechanics/). Design: docs/ideation-track-2/tribes/locust/.

const TRIBE: String = "Locust"
const HOPPER: StringName = &"hopper"
## Player numbers (SHARED-RULES: Tide +N, Hopper bonus).
const TIDE: StringName = &"locust_tide"
const HOPPER_BONUS: StringName = &"locust_hopper_bonus"
## Molt charges on a fight unit: extra ones given this fight (Skin-shedder), and those used.
const MOLT: StringName = &"locust_molt"
const MOLT_EXTRA: StringName = &"locust_molt_extra"
const MOLT_USED: StringName = &"locust_molt_used"
## Set on the dying unit when Molt is the return that claims its death.
const MOLT_CLAIM: StringName = &"locust_molt_claim"
## How many Hoppers each Hopper summon makes (Mother of Thousands); asked as a side_query in a
## fight and through Rules.ask in the Recruit Phase.
const Q_HOPPER_TIMES: StringName = &"locust_hopper_times"
## Eat: the mechanics that eat, the Gorger's once-a-turn mark and the mark on an eaten sale.
const GORGE: StringName = &"locust_gorge"
const GLUT: StringName = &"locust_glut"
const ATE: StringName = &"locust_ate"
const EATEN: StringName = &"locust_eaten"
## Each friendly death's number in this fight (FightSide.state count, CombatUnit.state mark).
const DEATHS: StringName = &"locust_deaths"
const DEATH_NUMBER: StringName = &"locust_death_number"


## Hoppers one summon makes in a fight: `count` times the side's multiplier.
static func hopper_count(combat: Combat, side: int, count: int) -> int:
	return count * maxi(1, combat.side_query(side, Q_HOPPER_TIMES, 1))


## The same in the Recruit Phase, from the recruit board.
static func recruit_hopper_count(ctx: RecruitContext, count: int) -> int:
	return count * maxi(1, ctx.session.rules.ask(Q_HOPPER_TIMES, 1, ctx.player, null))


## Summons `count` Hoppers in a fight from `slot` (own slot first for a dying unit's own
## effect); with no room they wait (SHARED-RULES, Waiting).
static func summon_hoppers(
	combat: Combat, unit: CombatUnit, count: int, own_slot_first: bool
) -> void:
	for _i: int in hopper_count(combat, unit.side, count):
		combat.summon(unit.side, HOPPER, unit.slot, own_slot_first, unit, true)


## Summons Hoppers on the recruit board, nearest to the slot the unit left; with no room they
## are lost (8.4.5). RecruitContext.summon never fills the source slot itself, so when that slot
## is the only one left, the Hopper is summoned with no source (first empty slot: that one).
static func recruit_summon_hoppers(ctx: RecruitContext, unit: Unit, count: int) -> void:
	for _i: int in recruit_hopper_count(ctx, count):
		var free: Array[int] = ctx.player.empty_slots()
		var only_own: bool = free.size() == 1 and free[0] == unit.slot
		ctx.summon(HOPPER, -1 if only_own else unit.slot)


## Printed Molt is one charge a fight; Skin-shedder adds MOLT_EXTRA for this fight.
static func molt_charges(unit: CombatUnit) -> int:
	var printed: int = 1 if unit.def.keywords.has(MOLT) else 0
	return printed + unit.counter(MOLT_EXTRA)


static func molt_left(unit: CombatUnit) -> int:
	return molt_charges(unit) - unit.counter(MOLT_USED)


## The enemies of `unit` still standing (Health above 0), in reading order.
static func living_enemies(combat: Combat, unit: CombatUnit) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for enemy: CombatUnit in combat.units(1 - unit.side):
		if not enemy.gone and not enemy.should_die():
			out.append(enemy)
	return out


## 9.5.6 a random enemy from either row that is still standing; null if none.
static func random_living_enemy(combat: Combat, unit: CombatUnit) -> CombatUnit:
	var enemies: Array[CombatUnit] = living_enemies(combat, unit)
	if enemies.is_empty():
		return null
	return enemies[combat.effect_rng.index(enemies.size())]


## Who eats a sale: each sold unit is eaten once. A Gorger that hasn't eaten this turn first
## (reading order), else, for a sold Locust, the first Granary Glutton. Null for none.
static func eater(player: PlayerState, sold: Unit) -> Unit:
	if sold.is_spell() or sold.turn_counter(EATEN) > 0:
		return null
	for unit: Unit in player.board_units():
		if unit.has_mechanic(GORGE) and unit.turn_counter(ATE) == 0:
			return unit
	if sold.def.has_tribe(TRIBE):
		for unit: Unit in player.board_units():
			if unit.has_mechanic(GLUT):
				return unit
	return null


## Eat: `unit` gains the sold unit's own stats (times `times`) permanently, then the sold
## unit's death effects resolve in the Recruit Phase (SHARED-RULES, Eat; ruling 43).
static func eat(
	ctx: RecruitContext, unit: Unit, sold: Unit, mechanic_id: StringName, times: int
) -> void:
	if eater(ctx.player, sold) != unit or not ctx.trigger(unit, mechanic_id):
		return
	# Bookkeeping only (no event): the sale is eaten once, and a Gorger once a turn. Turn
	# counters clear at the start of each turn. RecruitContext has no turn-counter method.
	sold.turn_counters[EATEN] = 1
	if mechanic_id == GORGE:
		unit.turn_counters[ATE] = 1
	var gain_attack: int = sold.stats.own_attack() * times
	var gain_health: int = sold.stats.own_health() * times
	ctx.buff(unit, gain_attack, gain_health, true, unit)
	ctx.run_death_effects(sold)
