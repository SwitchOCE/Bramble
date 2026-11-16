extends RefCounted
## Names and small rules the Locust mechanics share (not a mechanic: the loader only registers
## scripts in mechanics/). Design: docs/ideation-track-2/tribes/locust/.

const TRIBE: String = "Locust"
const HOPPER: StringName = &"hopper"
## Player numbers (SHARED-RULES: Tide +N, Hopper bonus).
const TIDE: StringName = &"locust_tide"
const HOPPER_BONUS: StringName = &"locust_hopper_bonus"
## Molt charges, as per-fight counts on the unit (CombatUnit.fight_count; the core carries them
## across a return): extra ones given this fight (Skin-shedder) and those used. The screen sees
## what is left as `uses` under the Molt id.
const MOLT: StringName = &"locust_molt"
const MOLT_EXTRA: StringName = &"locust_molt_extra"
const MOLT_USED: StringName = &"locust_molt_used"
## How many Hoppers each Hopper summon makes (Mother of Thousands); asked as a side_query in a
## fight and through Rules.ask in the Recruit Phase.
const Q_HOPPER_TIMES: StringName = &"locust_hopper_times"
## Eat: the mechanics that eat, the Gorger's once-a-turn mark and the mark on an eaten sale.
const GORGE: StringName = &"locust_gorge"
const GLUT: StringName = &"locust_glut"
const ATE: StringName = &"locust_ate"
const EATEN: StringName = &"locust_eaten"


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


## Summons Hoppers on the recruit board from the slot the unit left (an eaten unit's death
## effect): the first into that slot when it is empty (8.4.1), the rest nearest (8.4.2); with no
## room they are lost (8.4.5).
static func recruit_summon_hoppers(ctx: RecruitContext, unit: Unit, count: int) -> void:
	for _i: int in recruit_hopper_count(ctx, count):
		ctx.summon(HOPPER, unit.slot, true)


## Printed Molt is one charge a fight; Skin-shedder adds MOLT_EXTRA for this fight.
static func molt_charges(unit: CombatUnit) -> int:
	var printed: int = 1 if unit.def.keywords.has(MOLT) else 0
	return printed + unit.fight_count(MOLT_EXTRA)


static func molt_left(unit: CombatUnit) -> int:
	return molt_charges(unit) - unit.fight_count(MOLT_USED)


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
	# The sale is eaten once, and a Gorger eats once a turn (turn counters clear each turn).
	ctx.add_turn_counter(sold, EATEN, 1, unit)
	if mechanic_id == GORGE:
		ctx.add_turn_counter(unit, ATE, 1, unit)
	var gain_attack: int = sold.stats.own_attack() * times
	var gain_health: int = sold.stats.own_health() * times
	ctx.buff(unit, gain_attack, gain_health, true, unit)
	ctx.run_death_effects(sold)
