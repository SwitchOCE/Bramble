#![allow(unused_imports, unused_variables)]
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef, mechanic_params::MechanicParamsRef,
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
// gdlint: disable=max-public-methods
// The hook interface is one class on purpose: a mechanic overrides any hooks from either phase.
// The hook interface every keyword and card effect implements (and tribe mechanics will).
// One shared, stateless instance per mechanic id (MechanicRegistry); per-unit state goes on the
// unit (Unit.counters for the game, CombatUnit.state for one fight). Every hook is a no-op here.
// Each says the rule step it runs in, so the order lives in the engine and the rulebook.
// A hook that does something calls ctx.trigger(unit, id) first: that logs the trigger and
// counts it against the trigger limits (9.10.2).
//
// Self hooks run for the unit's own mechanics. Listener hooks ("a friendly unit ...", "any
// ...") run for every unit on that board in reading order and then for the player's standing
// mechanics (PlayerState.standing), which get unit = null.
// What playing a card or using an ability aims at. The action's "target" is a uid for
// FRIENDLY_UNIT, a board slot (0-6) for SLOT and a unit shop index for SHOP_UNIT.
// How aura grants of one mechanic to one unit combine (Mechanic.grant_combine): add the
// numbers up (the default: Fury, Thorns, Grow), or take the smallest (Root's cost: "pays the
// lowest cost").
// combat_query names. Each is asked of every mechanic on the unit, in order.
// 9.5.4 must be attacked (1 = yes).
// 9.5.2 can't be targeted by attacks (1 = yes).
// 11.2.7 also damages the units adjacent to the target (1 = yes).
// 9.4.3, 9.4.11 attacks per turn (base 1).
// 9.5.7 text that overrides which row this unit attacks: ROW_NORMAL (9.5.1) or ROW_BACK (the
// back row while it has units).
// 9.4.5 skipped in the attack order (1 = can't attack).
// side_query: how many times each own death effect resolves (base 1; 9.7.2 step 2). Also asked
// through modify_int in the Recruit Phase, for a card that doubles them there too.
// Reserve: a unit in hand with this (1) is copied into the fight and steps into a slot a
// friendly unit died in (FightArrivals).
// side_query: every unit in this side's hand has Reserve (1 = yes; The Colonel).
// side_query: the slot Reserve units fill first, such as a Guard post (-1 = none).
// In the back row, this isn't counted for Outnumbered (1 = a Squire; Combat.outnumbered_by).
// side_query: percent of the Attack its slots give this side's units in this fight (base 100;
// the Edgewright answers 200). The biggest answer applies; it stacks once with the give-time
// Rules.SLOT_BUFF_PERCENT (SHARED-RULES 13).
// Return priorities (Mechanic.return_priority): when a dying unit has several returns, the
// highest offered one fires, ties in hook order. Root answers RETURN_FIRST and Molt
// RETURN_PLAIN (SHARED-RULES 17: Root first when the Compost can pay, else Molt).
// The core's own query names; any other name a mechanic asks is a content name and needs its
// prefix (MechanicRegistry.check_name).
// Start of Combat passes (start_of_combat_priority), highest first: SHARED-RULES 41.
// Parameter name -> MechanicParams.Kind. Declared once; the library checks card data against it.
// Whether playing or casting this needs a target, and what kind.
// --- Recruit Phase: self hooks -------------------------------------------------------------
// 7.2.3 after the unit is placed ("when played"); for a spell, when it is cast. `target` is the
// chosen friendly unit or null; ctx.target_index holds a SLOT or SHOP_UNIT target.
// 3.2.1 step 5, board units in reading order, then standing mechanics.
// 3.4.1 step 1, board units in reading order, then standing mechanics.
// 4.3: when this unit is sold, after its gold is paid.
// A death effect resolving in the Recruit Phase (RecruitContext.run_death_effects): summons
// land on the recruit board; there is no enemy.
// --- Recruit Phase: activated abilities (3.3.1) ----------------------------------------------
// True if this mechanic gives its unit an ability the player can use from the board.
// Gold the ability costs.
// Uses per turn.
// Whether the ability can be used now, from where the unit stands ("give the slots in front of
// this": not from the front row). False keeps it out of the legal actions, and
// Recruit.ability_error says why, so a screen can dim it.
// The ability's effect; gold is already paid. `target` / ctx.target_index as in on_played.
// --- Recruit Phase: listeners ----------------------------------------------------------------
// Any unit of this player was sold (after its own on_sold). `sold` is off the board.
// An entry went into one of this player's heaps, in the Recruit Phase.
// After this player's fight, for every unit on the real board, then standing mechanics.
// Changes here are on the recruit board, so they last (12.1.1).
// --- Combat: self hooks ----------------------------------------------------------------------
// 9.1.1 setup, before anything is logged, and when the unit enters later: set this combat's
// state (a shield is up). Not a trigger and must not change other units.
// 9.3.2 Start of Combat, units in reading order.
// Which Start of Combat pass on_start_of_combat runs in: SOC_SETUP (both sides, before any
// main-pass effect: a summoner filling a slot before a row check) or SOC_MAIN.
// True if this mechanic is a death effect (on_death / on_recruit_death), for "a unit with a
// death effect" (Unit.has_death_effect, CombatUnit.has_death_effect).
// 9.4.5: this unit's turn to attack came; true takes the turn "instead of attacking" (the
// pointer and flags have moved as for an attack). Deaths resolve after.
// 9.6.1 step 1: this unit is attacked.
// 9.6.1 step 2: whenever this unit attacks, before damage.
// 9.6.1 step 4: after this unit attacks (after damage, before deaths).
// 9.6.2: this unit dealt `amount` (> 0) damage to `target`. The attacker's resolve first.
// Damage prevention: return how much of `amount` this unit actually takes (11.2.2).
// `from_attack` is true for the damage exchange and its splash (9.6.1 step 3).
// 9.7.2 step 1: this unit killed `victim` (even if this unit also died).
// 9.7.2 step 2: this unit's own death effect. `unit.slot` is its last-known slot (12.2.3).
// Also run by Combat.run_death_effects without a death.
// The return protocol (Combat._try_return; SHARED-RULES 15-22). Asked of every mechanic of a
// unit that just died: the Health to return with, or 0 for no offer. Check whatever pays for it
// here (the Compost can pay, a charge is left) but pay nothing yet: only the chosen offer pays,
// in pay_return. Per-fight limits read unit.fight_count (carried across returns).
// Which offer wins when several mechanics offer a return: the highest (RETURN_FIRST,
// RETURN_PLAIN), ties in hook order.
// True if this mechanic's return brings the unit back as it stands on the recruit board (Root),
// not as a plain copy.
// Runs only for the mechanic whose offer was chosen, once the unit is back and logged: pay the
// cost (spend Compost, count a charge with back.add_fight_count) and do what the return gives
// (Molt's +2/+2).
// 9.8.2: `back` is this unit's return; `gone` the unit that died. Runs for every mechanic the
// dead unit had, whichever return brought it back: "after this returns" effects and carrying
// state go here.
// A combat rule the engine asks about this unit (the Q_ names above). Returns the new answer.
// A rule about a whole side (Combat.side_query), asked of every unit and standing mechanic
// on that side. `unit` is null for a standing mechanic.
// --- Combat: listeners -----------------------------------------------------------------------
// 9.6.1 step 2: another friendly unit attacks, before damage (combat.hit joins it). Units
// that arrive while friends hear it (a Cousin) hear it too.
// 9.7.2 step 1: "whenever a unit dies", any side. Check `dead.side` for friend or enemy.
// 9.7.2 step 2: a friendly unit died; death counters advance here (9.7.4).
// 9.7.2 step 3: "after a friendly unit dies", once every death effect and counter is done.
// 9.7.2 step 5: a friendly unit came back.
// A unit entered a board in the fight (summoned, returned, landed after waiting, stepped
// in). Any side: check `entered.side`.
// After each round of deaths, once Reserve units stepped in and waiting summons landed
// (FightArrivals; a Recruiting Sergeant's Private).
// An entry went into one of this side's heaps during the fight.
// --- Both phases -----------------------------------------------------------------------------
// True if aura(), aura_keywords() or aura_grants() can return anything; the engine skips
// everyone else.
// 12.2.1 an aura from the unit in `source_slot` (-1 for a standing mechanic) onto the unit in
// `target_slot` of the same board: (Attack, Health) to add. Recalculated whenever a board, a
// player number or a heap changes; `view` says what the aura may read.
// 12.2.1 mechanics with parameters the aura gives the unit in `target_slot`: each
// {"mechanic": id, <param>: value} ("have Grow 1", "+1 Thorns"). Grants of one id to one unit
// add up their numbers (MechanicRegistry.bind_grants).
// How aura grants of this mechanic to one unit combine (Combine): SUM (default) or MIN.
// Asked per parameter.
// Two numbers of one parameter combined as `how` says (aura grants, the unit view's totals).
// 12.2.1 keywords (mechanic ids with no parameters) the aura gives the unit in `target_slot`.
// The unit layer of a rule query (Rules.ask): this unit's text changing a rule.

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
#[repr(i64)]
pub enum Target {
    #[default]
    None,
    FriendlyUnit,
    Slot,
    ShopUnit,
}
impl Target {
    pub const NONE: Self = Self::None;
    pub const FRIENDLY_UNIT: Self = Self::FriendlyUnit;
    pub const SLOT: Self = Self::Slot;
    pub const SHOP_UNIT: Self = Self::ShopUnit;
}
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
#[repr(i64)]
pub enum Combine {
    #[default]
    Sum,
    Min,
}
impl Combine {
    pub const SUM: Self = Self::Sum;
    pub const MIN: Self = Self::Min;
}
pub const Q_TAUNT: &str = "must_be_attacked";
pub const Q_UNTARGETABLE: &str = "untargetable";
pub const Q_CLEAVE: &str = "cleave";
pub const Q_ATTACKS: &str = "attacks_per_turn";
pub const Q_TARGET_ROW: &str = "target_row";
pub const ROW_NORMAL: i64 = 0;
pub const ROW_BACK: i64 = 1;
pub const Q_CANT_ATTACK: &str = "cant_attack";
pub const Q_DEATH_EFFECT_TIMES: &str = "death_effect_times";
pub const Q_RESERVE: &str = "reserve";
pub const Q_HAND_RESERVE: &str = "hand_reserve";
pub const Q_FILL_FIRST: &str = "fill_first_slot";
pub const Q_UNCOUNTED: &str = "uncounted";
pub const Q_SLOT_ATTACK_PERCENT: &str = "slot_attack_percent";
pub const RETURN_FIRST: i64 = 2;
pub const RETURN_PLAIN: i64 = 1;
pub const SOC_SETUP: i64 = 1;
pub const SOC_MAIN: i64 = 0;
pub const QUERIES: &[&str] = &[
    Q_TAUNT,
    Q_UNTARGETABLE,
    Q_CLEAVE,
    Q_ATTACKS,
    Q_TARGET_ROW,
    Q_CANT_ATTACK,
    Q_DEATH_EFFECT_TIMES,
    Q_RESERVE,
    Q_HAND_RESERVE,
    Q_FILL_FIRST,
    Q_UNCOUNTED,
    Q_SLOT_ATTACK_PERCENT,
];

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Hook {
    OnPlayed,
    OnStartOfTurn,
    OnEndOfTurn,
    OnSold,
    OnRecruitDeath,
    OnAbility,
    OnAnySold,
    OnHeapAdded,
    AfterFight,
    OnCombatBegin,
    OnStartOfCombat,
    OnAttacked,
    OnAttack,
    AfterAttack,
    OnDamageDealt,
    OnKill,
    OnDeath,
    OnReturned,
    OnFriendlyAttack,
    OnAnyDeath,
    OnFriendlyDeath,
    AfterFriendlyDeath,
    AfterFriendlyReturn,
    OnFightEnter,
    AfterDeathRound,
    OnHeapAddedInFight,
}
impl Hook {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::OnPlayed => "on_played",
            Self::OnStartOfTurn => "on_start_of_turn",
            Self::OnEndOfTurn => "on_end_of_turn",
            Self::OnSold => "on_sold",
            Self::OnRecruitDeath => "on_recruit_death",
            Self::OnAbility => "on_ability",
            Self::OnAnySold => "on_any_sold",
            Self::OnHeapAdded => "on_heap_added",
            Self::AfterFight => "after_fight",
            Self::OnCombatBegin => "on_combat_begin",
            Self::OnStartOfCombat => "on_start_of_combat",
            Self::OnAttacked => "on_attacked",
            Self::OnAttack => "on_attack",
            Self::AfterAttack => "after_attack",
            Self::OnDamageDealt => "on_damage_dealt",
            Self::OnKill => "on_kill",
            Self::OnDeath => "on_death",
            Self::OnReturned => "on_returned",
            Self::OnFriendlyAttack => "on_friendly_attack",
            Self::OnAnyDeath => "on_any_death",
            Self::OnFriendlyDeath => "on_friendly_death",
            Self::AfterFriendlyDeath => "after_friendly_death",
            Self::AfterFriendlyReturn => "after_friendly_return",
            Self::OnFightEnter => "on_fight_enter",
            Self::AfterDeathRound => "after_death_round",
            Self::OnHeapAddedInFight => "on_heap_added_in_fight",
        }
    }
}

/// Typed arguments for the GDScript dynamic hook calls; units are shared handles.
#[derive(Clone, Default)]
pub enum HookArgs {
    #[default]
    None,
    Played {
        target: Option<UnitRef>,
    },
    Ability {
        target: Option<UnitRef>,
    },
    AnySold {
        sold: UnitRef,
    },
    HeapAdded {
        heap: String,
        card_id: String,
    },
    AfterFight {
        report: FightReportRef,
    },
    Attacked {
        attacker: CombatUnitRef,
    },
    Attack {
        defender: CombatUnitRef,
    },
    DamageDealt {
        target: CombatUnitRef,
        amount: i64,
    },
    Kill {
        victim: CombatUnitRef,
    },
    Return {
        gone: CombatUnitRef,
        back: CombatUnitRef,
    },
    FriendlyAttack {
        attacker: CombatUnitRef,
        defender: CombatUnitRef,
    },
    Death {
        dead: CombatUnitRef,
    },
    FriendlyReturn {
        back: CombatUnitRef,
    },
    FightEnter {
        entered: CombatUnitRef,
    },
}
pub fn combine(how: Combine, had: i64, now: i64) -> i64 {
    if how == Combine::Min {
        had.min(now)
    } else {
        had.wrapping_add(now)
    }
}
pub const AURA_STATS: u8 = 1;
pub const AURA_KEYWORDS: u8 = 2;
pub const AURA_GRANTS: u8 = 4;

pub trait Mechanic: ToState {
    fn param_kinds(&self) -> Dictionary {
        Dictionary::default()
    }
    fn play_target(&self, _params: &MechanicParamsRef) -> Target {
        Target::None
    }
    fn recruit_target(&self, _params: &MechanicParamsRef) -> Target {
        Target::None
    }
    // 7.2.3/7.2.6 after a successful gain, including a golden formed by a triple.
    fn on_recruited(
        &self,
        _ctx: &mut RecruitContext,
        _unit: &UnitRef,
        _target: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    // Spell casting only.
    fn on_played(
        &self,
        _ctx: &mut RecruitContext,
        _unit: Option<&UnitRef>,
        _target: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_start_of_turn(
        &self,
        _ctx: &mut RecruitContext,
        _unit: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_end_of_turn(
        &self,
        _ctx: &mut RecruitContext,
        _unit: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_sold(
        &self,
        _ctx: &mut RecruitContext,
        _unit: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_recruit_death(
        &self,
        _ctx: &mut RecruitContext,
        _unit: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    fn has_ability(&self) -> bool {
        false
    }
    fn ability_cost(&self, _params: &MechanicParamsRef) -> i64 {
        0
    }
    fn ability_uses(&self, _params: &MechanicParamsRef) -> i64 {
        1
    }
    fn ability_target(&self, _params: &MechanicParamsRef) -> Target {
        Target::None
    }
    fn ability_usable(
        &self,
        _player: Option<&PlayerStateRef>,
        _unit: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) -> bool {
        true
    }
    fn on_ability(
        &self,
        _ctx: &mut RecruitContext,
        _unit: Option<&UnitRef>,
        _target: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_any_sold(
        &self,
        _ctx: &mut RecruitContext,
        _unit: Option<&UnitRef>,
        _sold: &UnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_heap_added(
        &self,
        _ctx: &mut RecruitContext,
        _unit: Option<&UnitRef>,
        _heap: &str,
        _card_id: &str,
        _params: &MechanicParamsRef,
    ) {
    }
    fn after_fight(
        &self,
        _ctx: &mut RecruitContext,
        _unit: Option<&UnitRef>,
        _report: &FightReportRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_combat_begin(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_start_of_combat(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    fn start_of_combat_priority(&self, _params: &MechanicParamsRef) -> i64 {
        SOC_MAIN
    }
    fn has_death_effect(&self) -> bool {
        false
    }
    fn instead_of_attack(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) -> bool {
        false
    }
    fn on_attacked(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _attacker: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_attack(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _defender: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn after_attack(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _defender: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_damage_dealt(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _target: Option<&CombatUnitRef>,
        _amount: i64,
        _params: &MechanicParamsRef,
    ) {
    }
    fn absorb_damage(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        amount: i64,
        _from_attack: bool,
        _params: &MechanicParamsRef,
    ) -> i64 {
        amount
    }
    fn on_kill(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _victim: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_death(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    fn return_offer(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) -> i64 {
        0
    }
    fn return_priority(&self, _params: &MechanicParamsRef) -> i64 {
        RETURN_PLAIN
    }
    fn return_as_recruit(&self, _params: &MechanicParamsRef) -> bool {
        false
    }
    fn pay_return(
        &self,
        _combat: &mut Combat,
        _gone: &CombatUnitRef,
        _back: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_returned(
        &self,
        _combat: &mut Combat,
        _gone: &CombatUnitRef,
        _back: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn combat_query(
        &self,
        _unit: Option<&CombatUnitRef>,
        _query: &str,
        value: i64,
        _params: &MechanicParamsRef,
    ) -> i64 {
        value
    }
    fn side_query(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _query: &str,
        value: i64,
        _params: &MechanicParamsRef,
    ) -> i64 {
        value
    }
    fn on_friendly_attack(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _attacker: &CombatUnitRef,
        _defender: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_any_death(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _dead: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_friendly_death(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _dead: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn after_friendly_death(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _dead: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn after_friendly_return(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _back: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_fight_enter(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _entered: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
    }
    fn after_death_round(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
    fn on_heap_added_in_fight(
        &self,
        _combat: &mut Combat,
        _unit: Option<&CombatUnitRef>,
        _heap: &str,
        _card_id: &str,
        _params: &MechanicParamsRef,
    ) {
    }
    fn has_aura(&self) -> bool {
        false
    }
    /// Hooks that may differ from the default zero stats / fresh empty arrays.
    /// Unknown mechanics conservatively retain every hook and its effects.
    fn aura_parts(&self) -> u8 {
        AURA_STATS | AURA_KEYWORDS | AURA_GRANTS
    }
    fn aura(
        &self,
        _view: &mut AuraContext,
        _source_slot: i64,
        _target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> (i64, i64) {
        (0, 0)
    }
    fn aura_grants(
        &self,
        _view: &mut AuraContext,
        _source_slot: i64,
        _target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> Array<Dictionary> {
        Array::default()
    }
    fn grant_combine(&self, _param: &str) -> Combine {
        Combine::Sum
    }
    fn combine(how: Combine, had: i64, now: i64) -> i64
    where
        Self: Sized,
    {
        combine(how, had, now)
    }
    fn aura_keywords(
        &self,
        _view: &mut AuraContext,
        _source_slot: i64,
        _target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> Array<String> {
        Array::default()
    }
    fn modify_int(
        &self,
        _query: &str,
        value: i64,
        _player: Option<&PlayerStateRef>,
        _unit: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) -> i64 {
        value
    }
}

impl ToState for Rc<dyn Mechanic> {
    fn to_state(&self) -> Variant {
        self.as_ref().to_state()
    }
}

/// Concrete empty instance corresponding to Mechanic.new() in GDScript.
#[derive(Clone, Default)]
pub struct BaseMechanic;
impl ToState for BaseMechanic {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
}
impl Mechanic for BaseMechanic {}
pub type MechanicRef = Rc<dyn Mechanic>;
