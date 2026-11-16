# gdlint: disable=max-public-methods
# The hook interface is one class on purpose: a mechanic overrides any hooks from either phase.
class_name Mechanic
extends RefCounted
## The hook interface every keyword and card effect implements (and tribe mechanics will).
## One shared, stateless instance per mechanic id (MechanicRegistry); per-unit state goes on the
## unit (Unit.counters for the game, CombatUnit.state for one fight). Every hook is a no-op here.
## Each says the rule step it runs in, so the order lives in the engine and the rulebook.
## A hook that does something calls ctx.trigger(unit, id) first: that logs the trigger and
## counts it against the trigger limits (9.10.2).
##
## Self hooks run for the unit's own mechanics. Listener hooks ("a friendly unit ...", "any
## ...") run for every unit on that board in reading order and then for the player's standing
## mechanics (PlayerState.standing), which get unit = null.

## What playing a card or using an ability aims at. The action's "target" is a uid for
## FRIENDLY_UNIT, a board slot (0-6) for SLOT and a unit shop index for SHOP_UNIT.
enum Target { NONE, FRIENDLY_UNIT, SLOT, SHOP_UNIT }

## combat_query names. Each is asked of every mechanic on the unit, in order.
## 9.5.4 must be attacked (1 = yes).
const Q_TAUNT: StringName = &"must_be_attacked"
## 9.5.2 can't be targeted by attacks (1 = yes).
const Q_UNTARGETABLE: StringName = &"untargetable"
## 11.2.7 also damages the units adjacent to the target (1 = yes).
const Q_CLEAVE: StringName = &"cleave"
## 9.4.3, 9.4.11 attacks per turn (base 1).
const Q_ATTACKS: StringName = &"attacks_per_turn"
## 9.8.2 Health to return with after dying (0 = doesn't return).
const Q_RETURN_HEALTH: StringName = &"return_health"
## 9.6.1 step 3: this unit's damage lands first; a defender it kills doesn't strike back.
const Q_STRIKES_FIRST: StringName = &"strikes_first"
## 9.5.7 text that overrides which row this unit attacks: ROW_NORMAL (9.5.1), ROW_BACK (the
## back row while it has units) or ROW_ANY (either row).
const Q_TARGET_ROW: StringName = &"target_row"
const ROW_NORMAL: int = 0
const ROW_BACK: int = 1
const ROW_ANY: int = 2
## 9.4.5 skipped in the attack order (1 = can't attack).
const Q_CANT_ATTACK: StringName = &"cant_attack"
## side_query: how many times each own death effect resolves (base 1; 9.7.2 step 2).
const Q_DEATH_EFFECT_TIMES: StringName = &"death_effect_times"


## Parameter name -> MechanicParams.Kind. Declared once; the library checks card data against it.
func param_kinds() -> Dictionary:
	return {}


## Whether playing or casting this needs a target, and what kind.
func play_target(_params: MechanicParams) -> Target:
	return Target.NONE


## --- Recruit Phase: self hooks -------------------------------------------------------------


## 7.2.3 after the unit is placed ("when played"); for a spell, when it is cast. `target` is the
## chosen friendly unit or null; ctx.target_index holds a SLOT or SHOP_UNIT target.
func on_played(_ctx: RecruitContext, _unit: Unit, _target: Unit, _params: MechanicParams) -> void:
	pass


## 3.2.1 step 5, board units in reading order, then standing mechanics.
func on_start_of_turn(_ctx: RecruitContext, _unit: Unit, _params: MechanicParams) -> void:
	pass


## 3.4.1 step 1, board units in reading order, then standing mechanics.
func on_end_of_turn(_ctx: RecruitContext, _unit: Unit, _params: MechanicParams) -> void:
	pass


## 4.3: when this unit is sold, after its gold is paid.
func on_sold(_ctx: RecruitContext, _unit: Unit, _params: MechanicParams) -> void:
	pass


## A death effect resolving in the Recruit Phase (RecruitContext.run_death_effects): summons
## land on the recruit board; there is no enemy.
func on_recruit_death(_ctx: RecruitContext, _unit: Unit, _params: MechanicParams) -> void:
	pass


## --- Recruit Phase: activated abilities (3.3.1) ----------------------------------------------


## True if this mechanic gives its unit an ability the player can use from the board.
func has_ability() -> bool:
	return false


## Gold the ability costs.
func ability_cost(_params: MechanicParams) -> int:
	return 0


## Uses per turn.
func ability_uses(_params: MechanicParams) -> int:
	return 1


func ability_target(_params: MechanicParams) -> Target:
	return Target.NONE


## The ability's effect; gold is already paid. `target` / ctx.target_index as in on_played.
func on_ability(_ctx: RecruitContext, _unit: Unit, _target: Unit, _params: MechanicParams) -> void:
	pass


## --- Recruit Phase: listeners ----------------------------------------------------------------


## A unit entered this player's board: played (after its own on_played) or summoned.
func on_board_enter(
	_ctx: RecruitContext, _unit: Unit, _entered: Unit, _params: MechanicParams
) -> void:
	pass


## Any unit of this player was sold (after its own on_sold). `sold` is off the board.
func on_any_sold(_ctx: RecruitContext, _unit: Unit, _sold: Unit, _params: MechanicParams) -> void:
	pass


## An entry went into one of this player's heaps, in the Recruit Phase.
func on_heap_added(
	_ctx: RecruitContext,
	_unit: Unit,
	_heap: StringName,
	_card_id: StringName,
	_params: MechanicParams
) -> void:
	pass


## After this player's fight, for every unit on the real board, then standing mechanics.
## Changes here are on the recruit board, so they last (12.1.1).
func after_fight(
	_ctx: RecruitContext, _unit: Unit, _report: FightReport, _params: MechanicParams
) -> void:
	pass


## --- Combat: self hooks ----------------------------------------------------------------------


## 9.1.1 setup, before anything is logged, and when the unit enters later: set this combat's
## state (a shield is up). Not a trigger and must not change other units.
func on_combat_begin(_combat: Combat, _unit: CombatUnit, _params: MechanicParams) -> void:
	pass


## 9.3.2 Start of Combat, units in reading order.
func on_start_of_combat(_combat: Combat, _unit: CombatUnit, _params: MechanicParams) -> void:
	pass


## 9.4.5: this unit's turn to attack came; true takes the turn "instead of attacking" (the
## pointer and flags have moved as for an attack). Deaths resolve after.
func instead_of_attack(_combat: Combat, _unit: CombatUnit, _params: MechanicParams) -> bool:
	return false


## 9.6.1 step 1: this unit is attacked.
func on_attacked(
	_combat: Combat, _unit: CombatUnit, _attacker: CombatUnit, _params: MechanicParams
) -> void:
	pass


## 9.6.1 step 2: whenever this unit attacks, before damage.
func on_attack(
	_combat: Combat, _unit: CombatUnit, _defender: CombatUnit, _params: MechanicParams
) -> void:
	pass


## 9.6.1 step 4: after this unit attacks (after damage, before deaths).
func after_attack(
	_combat: Combat, _unit: CombatUnit, _defender: CombatUnit, _params: MechanicParams
) -> void:
	pass


## 9.6.2: this unit dealt `amount` (> 0) damage to `target`. The attacker's resolve first.
func on_damage_dealt(
	_combat: Combat, _unit: CombatUnit, _target: CombatUnit, _amount: int, _params: MechanicParams
) -> void:
	pass


## Damage prevention: return how much of `amount` this unit actually takes (11.2.2).
## `from_attack` is true for the damage exchange and its splash (9.6.1 step 3).
func absorb_damage(
	_combat: Combat, _unit: CombatUnit, amount: int, _from_attack: bool, _params: MechanicParams
) -> int:
	return amount


## 9.7.2 step 1: this unit killed `victim` (even if this unit also died).
func on_kill(
	_combat: Combat, _unit: CombatUnit, _victim: CombatUnit, _params: MechanicParams
) -> void:
	pass


## 9.7.2 step 2: this unit's own death effect. `unit.slot` is its last-known slot (12.2.3).
## Also run by Combat.run_death_effects without a death.
func on_death(_combat: Combat, _unit: CombatUnit, _params: MechanicParams) -> void:
	pass


## 9.8.2: Health to come back with after dying, 0 for none; asked after Q_RETURN_HEALTH, with
## the fight in reach (a return that costs something checks here and pays in on_returned).
func return_health(_combat: Combat, _unit: CombatUnit, health: int, _params: MechanicParams) -> int:
	return health


## 9.8.2: `back` is this unit's return; `gone` the unit that died.
func on_returned(
	_combat: Combat, _gone: CombatUnit, _back: CombatUnit, _params: MechanicParams
) -> void:
	pass


## A combat rule the engine asks about this unit (the Q_ names above). Returns the new answer.
func combat_query(
	_unit: CombatUnit, _query: StringName, value: int, _params: MechanicParams
) -> int:
	return value


## A rule about a whole side (Combat.side_query), asked of every unit and standing mechanic
## on that side. `unit` is null for a standing mechanic.
func side_query(
	_combat: Combat, _unit: CombatUnit, _query: StringName, value: int, _params: MechanicParams
) -> int:
	return value


## --- Combat: listeners -----------------------------------------------------------------------


## 9.6.1 step 2: another friendly unit attacks, before damage (Combat.join_attack joins it).
func on_friendly_attack(
	_combat: Combat,
	_unit: CombatUnit,
	_attacker: CombatUnit,
	_defender: CombatUnit,
	_params: MechanicParams
) -> void:
	pass


## 9.6.1 step 4: another friendly unit attacked (after damage, before deaths).
func after_friendly_attack(
	_combat: Combat,
	_unit: CombatUnit,
	_attacker: CombatUnit,
	_defender: CombatUnit,
	_params: MechanicParams
) -> void:
	pass


## 9.7.2 step 1: "whenever a unit dies", any side. Check `dead.side` for friend or enemy.
func on_any_death(
	_combat: Combat, _unit: CombatUnit, _dead: CombatUnit, _params: MechanicParams
) -> void:
	pass


## 9.7.2 step 2: a friendly unit died; death counters advance here (9.7.4).
func on_friendly_death(
	_combat: Combat, _unit: CombatUnit, _dead: CombatUnit, _params: MechanicParams
) -> void:
	pass


## 9.7.2 step 3: "after a friendly unit dies", once every death effect and counter is done.
func after_friendly_death(
	_combat: Combat, _unit: CombatUnit, _dead: CombatUnit, _params: MechanicParams
) -> void:
	pass


## 9.7.2 step 5: a friendly unit came back.
func after_friendly_return(
	_combat: Combat, _unit: CombatUnit, _back: CombatUnit, _params: MechanicParams
) -> void:
	pass


## A unit entered a board in the fight (summoned, returned, landed after waiting, stepped
## in). Any side: check `entered.side`.
func on_fight_enter(
	_combat: Combat, _unit: CombatUnit, _entered: CombatUnit, _params: MechanicParams
) -> void:
	pass


## An entry went into one of this side's heaps during the fight.
func on_heap_added_in_fight(
	_combat: Combat,
	_unit: CombatUnit,
	_heap: StringName,
	_card_id: StringName,
	_params: MechanicParams
) -> void:
	pass


## --- Both phases -----------------------------------------------------------------------------


## True if aura() or aura_keywords() can return anything; the engine skips everyone else.
func has_aura() -> bool:
	return false


## 12.2.1 an aura from the unit in `source_slot` (-1 for a standing mechanic) onto the unit in
## `target_slot` of the same board: (Attack, Health) to add. Recalculated whenever a board, a
## player number or a heap changes; `view` says what the aura may read.
func aura(
	_view: AuraContext, _source_slot: int, _target_slot: int, _params: MechanicParams
) -> Vector2i:
	return Vector2i.ZERO


## 12.2.1 keywords (mechanic ids with no parameters) the aura gives the unit in `target_slot`.
func aura_keywords(
	_view: AuraContext, _source_slot: int, _target_slot: int, _params: MechanicParams
) -> Array[StringName]:
	return []


## The unit layer of a rule query (Rules.ask): this unit's text changing a rule.
func modify_int(
	_query: StringName, value: int, _player: PlayerState, _unit: Unit, _params: MechanicParams
) -> int:
	return value
