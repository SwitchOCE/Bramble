class_name Mechanic
extends RefCounted
## The hook interface every keyword and card effect implements (and tribe mechanics will).
## One shared, stateless instance per mechanic id (MechanicRegistry); per-unit state goes on the
## unit (CombatUnit.state, Unit stats). Every hook is a no-op here. Each says the rule step it
## runs in, so the order lives in the engine and the rulebook, not in the scripts.
## A hook that does something calls ctx.trigger(unit, id) first: that logs the trigger and
## counts it against the trigger limits (9.10.2).

enum Target { NONE, FRIENDLY_UNIT }

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


## Parameter name -> MechanicParams.Kind. Declared once; the library checks card data against it.
func param_kinds() -> Dictionary:
	return {}


## Whether playing or casting this needs a friendly unit chosen (Battlecry with a target, spells).
func play_target(_params: MechanicParams) -> Target:
	return Target.NONE


## --- Recruit Phase -------------------------------------------------------------------------


## 7.2.3 after the unit is placed ("when played"); for a spell, when it is cast. `target` is the
## chosen friendly unit, or null.
func on_played(_ctx: RecruitContext, _unit: Unit, _target: Unit, _params: MechanicParams) -> void:
	pass


## 3.2.1 step 5, board units in reading order.
func on_start_of_turn(_ctx: RecruitContext, _unit: Unit, _params: MechanicParams) -> void:
	pass


## 3.4.1 step 1, board units in reading order.
func on_end_of_turn(_ctx: RecruitContext, _unit: Unit, _params: MechanicParams) -> void:
	pass


## 4.3: when this unit is sold, after its gold is paid.
func on_sold(_ctx: RecruitContext, _unit: Unit, _params: MechanicParams) -> void:
	pass


## --- Combat ----------------------------------------------------------------------------------


## 9.1.1 setup, before anything is logged: set this combat's state (a shield is up). Not a
## trigger and must not change other units.
func on_combat_begin(_combat: Combat, _unit: CombatUnit, _params: MechanicParams) -> void:
	pass


## 9.3.2 Start of Combat, units in reading order.
func on_start_of_combat(_combat: Combat, _unit: CombatUnit, _params: MechanicParams) -> void:
	pass


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


## 9.6.2: this unit dealt `amount` (> 0) damage to `target`. The attacker's resolve first.
func on_damage_dealt(
	_combat: Combat, _unit: CombatUnit, _target: CombatUnit, _amount: int, _params: MechanicParams
) -> void:
	pass


## Damage prevention: return how much of `amount` this unit actually takes (11.2.2).
func absorb_damage(_combat: Combat, _unit: CombatUnit, amount: int, _params: MechanicParams) -> int:
	return amount


## 9.7.2 step 1: this unit killed `victim` (even if this unit also died).
func on_kill(
	_combat: Combat, _unit: CombatUnit, _victim: CombatUnit, _params: MechanicParams
) -> void:
	pass


## 9.7.2 step 2: this unit's own death effect. `unit.slot` is its last-known slot (12.2.3).
func on_death(_combat: Combat, _unit: CombatUnit, _params: MechanicParams) -> void:
	pass


## 9.7.2 step 2: a friendly unit died; death counters advance here (9.7.4).
func on_friendly_death(
	_combat: Combat, _unit: CombatUnit, _dead: CombatUnit, _params: MechanicParams
) -> void:
	pass


## A combat rule the engine asks about this unit (the Q_ names above). Returns the new answer.
func combat_query(
	_unit: CombatUnit, _query: StringName, value: int, _params: MechanicParams
) -> int:
	return value


## --- Both phases -----------------------------------------------------------------------------


## True if aura() can return anything; lets the engine skip the aura pass for everyone else.
func has_aura() -> bool:
	return false


## 12.2.1 an aura from the unit in `source_slot` onto the unit in `target_slot` (same board):
## (Attack, Health) to add. Recomputed whenever the board changes.
func aura(
	_geometry: BoardGeometry, _source_slot: int, _target_slot: int, _params: MechanicParams
) -> Vector2i:
	return Vector2i.ZERO


## The unit layer of a rule query (Rules.ask): this unit's text changing a rule.
func modify_int(
	_query: StringName, value: int, _player: PlayerState, _unit: Unit, _params: MechanicParams
) -> int:
	return value
