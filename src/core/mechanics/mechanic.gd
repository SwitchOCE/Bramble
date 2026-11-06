# gdlint:disable=max-public-methods
# One method per hook: the list of hooks is the interface.
class_name Mechanic
extends RefCounted
## Base class of the mechanic scripts (SPEC section 4): one script per mechanic id, implementing
## only the hooks it needs; every hook here is a no-op. Scripts are stateless and shared: state
## lives on the units (statuses, counters) and in the Combat. `params` are the unit file's
## parameters, with "number" parameters already doubled for a golden unit (4.4).


## Before the fight starts: initial statuses shown at combat_start (Shell, Bide's waiting).
func setup(_unit: CombatUnit, _params: Dictionary) -> void:
	pass


## True for a unit that takes turns without Attack (Whistle).
func acts_without_attack(_params: Dictionary) -> bool:
	return false


## 9.3 Start of Combat.
func on_start_of_combat(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> void:
	pass


## 9.4.5: the unit was chosen. Returns "" to attack, "skip" (the side picks the next unit in the
## same turn) or "turn" (the unit used the side's turn without attacking).
func choose_turn_action(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> String:
	return ""


## Units that join this unit's attack (Swarm). The script flags them.
func joiners(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> Array[CombatUnit]:
	return []


## 9.6.1 before step 1, for every unit on both sides (Bystander, Both Ends).
func on_attack_declared(
	_combat: Combat,
	_unit: CombatUnit,
	_params: Dictionary,
	_attacker: CombatUnit,
	_defender: CombatUnit
) -> void:
	pass


## 9.6.1 step 2, the attacker's "whenever this attacks"; once per strike.
func on_before_attack(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> void:
	pass


## How many strikes this unit's attack makes; 0 = no opinion (1).
func strikes(_params: Dictionary) -> int:
	return 0


## Quick: this unit deals its damage first in this exchange (9.6.2).
func strikes_first(_unit: CombatUnit, _params: Dictionary) -> bool:
	return false


## The amount of an incoming hit after this unit's modifiers; add a name to hit.modifiers.
func modify_damage_taken(_unit: CombatUnit, _params: Dictionary, hit: Hit) -> int:
	return hit.amount


## After a damage event, for its source.
func on_damage_dealt(_combat: Combat, _unit: CombatUnit, _params: Dictionary, _hit: Hit) -> void:
	pass


## After a damage event, for its target, before deaths are checked.
func on_damage_taken(_combat: Combat, _unit: CombatUnit, _params: Dictionary, _hit: Hit) -> void:
	pass


## After the attack's death resolution, for the defender while it is still on the board.
func on_survived_attack(
	_combat: Combat, _unit: CombatUnit, _params: Dictionary, _attacker: CombatUnit
) -> void:
	pass


## 9.7.2 step 2, the dying unit's own death effects. The unit has left its slot; unit.slot is
## its last-known slot (12.2.3).
func on_death(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> void:
	pass


## 12.2.1: the Attack and Health this unit gets from its own aura right now (Both Ends).
func aura(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> Vector2i:
	return Vector2i.ZERO


## 9.7.2 step 3: another unit on this side died (it has left its slot).
func on_friendly_death(
	_combat: Combat, _unit: CombatUnit, _params: Dictionary, _dead: CombatUnit
) -> void:
	pass


## 9.8.1: a unit entered this side's board in combat (this one too, when it is the summon).
func on_ally_summon(
	_combat: Combat, _unit: CombatUnit, _params: Dictionary, _summoned: CombatUnit
) -> void:
	pass


## 12.2.1: whether this entry gives auras to other units (asked once per unit).
func has_board_aura(_params: Dictionary) -> bool:
	return false


## 12.2.1: adds what this unit's aura gives each unit, as `out[uid] += Vector2i(attack, health)`.
func board_aura(_combat: Combat, _unit: CombatUnit, _params: Dictionary, _out: Dictionary) -> void:
	pass


# --- Recruit Phase ------------------------------------------------------------------------------
# One hook per trigger. `ctx` holds the player, the unit, the parameters and the methods to act.


## Every recruit trigger arrives here. Scripts override the named hooks below; a data effect
## overrides this.
func recruit_hook(ctx: RecruitContext) -> void:
	match ctx.trigger:
		"start_of_turn":
			on_start_of_turn(ctx)
		"end_of_turn":
			on_end_of_turn(ctx)
		"on_buy":
			on_buy(ctx)
		"on_play":
			on_play(ctx)
		"on_sell":
			on_sell(ctx)
		"on_summon":
			on_summon(ctx)
		"on_move":
			on_move(ctx)
		"on_refresh":
			on_refresh(ctx)
		"on_spell_cast":
			on_spell_cast(ctx)
		"on_tier_up":
			on_tier_up(ctx)
		"on_triple":
			on_triple(ctx)
		"on_gold_spent":
			on_gold_spent(ctx)
		"after_combat":
			after_combat(ctx)


## 3.2.1 step 5.
func on_start_of_turn(_ctx: RecruitContext) -> void:
	pass


## 3.4.1 step 1, End of Turn on the recruit board.
func on_end_of_turn(_ctx: RecruitContext) -> void:
	pass


## 4.2.1: a unit was bought (ctx.subject). The bought unit hears it too, from the hand.
func on_buy(_ctx: RecruitContext) -> void:
	pass


## 7.2.3: a unit was played (ctx.subject), already placed.
func on_play(_ctx: RecruitContext) -> void:
	pass


## 4.3.7: a unit is being sold (ctx.subject), still in its slot.
func on_sell(_ctx: RecruitContext) -> void:
	pass


## 8.4: a unit was summoned onto the board (ctx.subject).
func on_summon(_ctx: RecruitContext) -> void:
	pass


## 8.3.3: a unit moved (ctx.subject, now in ctx.subject_slot; ctx.amount is the old slot).
func on_move(_ctx: RecruitContext) -> void:
	pass


## 4.4: the shop was refreshed. ctx.paid says whether the player paid.
func on_refresh(_ctx: RecruitContext) -> void:
	pass


## 6.1.5: a spell was cast (ctx.card_def; ctx.chosen is its target, if any).
func on_spell_cast(_ctx: RecruitContext) -> void:
	pass


## 4.6: the player's tier went up.
func on_tier_up(_ctx: RecruitContext) -> void:
	pass


## 7.3.1: a triple formed (ctx.subject is the golden).
func on_triple(_ctx: RecruitContext) -> void:
	pass


## Gold was spent (ctx.amount).
func on_gold_spent(_ctx: RecruitContext) -> void:
	pass


## After every fight, damage and elimination of the round, before the next one starts.
func after_combat(_ctx: RecruitContext) -> void:
	pass
