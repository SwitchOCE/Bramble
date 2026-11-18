#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/combat/combat.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::board::board_geometry::BoardGeometryRef;

use crate::core::combat::combat_unit::CombatUnitRef;

use crate::core::combat::fight_arrivals::{FightArrivals, FightArrivalsRef};
use crate::core::combat::fight_auras::{FightAuras, FightAurasRef};
use crate::core::combat::fight_deaths::{FightDeaths, FightDeathsRef};

use crate::core::combat::fight_side::FightSideRef;

use crate::core::rules::game_config::GameConfigRef;

use crate::core::mechanics::mechanic_registry::MechanicRegistryRef;

use crate::core::recruit::player_state::PlayerStateRef;

use crate::core::util::rng::RngRef;

use crate::core::units::unit::UnitRef;

use crate::core::units::unit_library::UnitLibraryRef;

use crate::core::mechanics::mechanic::{self, Hook, HookArgs, MechanicRef};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef, mechanic_params::MechanicParamsRef,
};
use crate::core::{
    board::selectors::Selectors,
    combat::{combat_unit::CombatUnit, fight_side::FightSide},
    rules::rules::Rules,
    util::rng::Rng,
};

fn binding(bound: &BoundMechanicRef) -> (MechanicRef, MechanicParamsRef) {
    let bound = bound.borrow();
    (
        bound.mechanic.clone().expect("bound mechanic"),
        bound.params.clone(),
    )
}
fn for_hooks(unit: &CombatUnitRef, mut call: impl FnMut(MechanicRef, MechanicParamsRef)) {
    let hooks = unit.borrow().hooks();
    let mut i = 0;
    while let Some(bound) = hooks.get(i) {
        i += 1;
        let (mechanic, params) = binding(&bound);
        call(mechanic, params);
    }
}
fn uid(unit: Option<&CombatUnitRef>) -> i64 {
    unit.map_or(-1, |u| u.borrow().uid)
}

// GDScript rule and contract comments:
// A fight hook may use any of these, so the fight API is one class on purpose.
// One fight (rulebook chapter 9) between two recruit boards, as a JSON-shaped event log.
// Phase order, each step named by its rule:
// 9.1 copy boards and slot effects -> on_combat_begin -> auras -> combat_start event
// 9.2.1 first attacker -> 9.3 Start of Combat (random player first, reading order, deaths after
// each effect) -> 9.4 alternate attacks (attack pointer, 9.4.5) -> each attack 9.6.1:
// on_attacked; on_attack, on_friendly_attack; hits; damage exchange (+ cleave);
// after_attack; death resolution 9.7 -> 9.9 end, or 9.10 limits.
// Randomness comes from sub-streams of the fight's seed (prototype lesson 7): "first", "soc",
// "target" and "effect", so one new random mechanic can't move every later target.
// Mechanics act only through the public methods below and bridge(n) (FightSide: the bridge to
// the player). Combat names no keyword itself.
// How deep out-of-turn attacks may nest (an attack that starts another attack...).
// CombatUnit.state while an attack that "takes no damage" resolves.
// sides[side][slot] -> CombatUnit or null.
// 9.4.5 per side: the slot of its latest attack this cycle; -1 at the start of a cycle.
// Reserve units and waiting summons, and the order they fill emptied slots (FightArrivals).
// The side whose standing mechanics a listener hook is running for (they get unit = null).
// Victim uid -> the unit whose damage last hit it, for "after a unit kills" (9.7.2 step 1).
// Per side: units counted for Outnumbered when the fight began (fixed; see outnumbered_by).
// The unit whose damage is being absorbed, so a status event can name it.
// True while an attack's damage exchange is being dealt (damage_from_attack).
// True while an attacker's own damage to the unit it attacked is dealt (damage_from_own_attack);
// _next_own_attack marks the next deal_damage call as that damage.
// Pile-on hits asked for while friends hear an attack; they land together (_land_joined_hits).
// The unit being placed (_place): its summon or return event shows its numbers, so auras log no
// `stats` for it before that event.
// Events held back while a return resolves (FightDeaths); see _log.
// The fight's parts (FightArrivals, FightAuras, FightDeaths) exist from construction, so a
// subclass built without create() still works.
// Runs the fight. `boards` is [board_a, board_b], each an Array of Unit or null per slot.
// `owners` gives each side's PlayerState (or null), and `live` whether that side's permanent
// changes reach the player (false for the ghost, 8.5.2 and 2.1.4). `hands` gives each side's
// hand (Array of Unit), for its Reserve units.
// A side's bridge to its player: lasting numbers, heaps, slots, write-back (FightSide).
// --- Setup ----------------------------------------------------------------------------------------
// Units that count toward being outnumbered: all but back-row units that say they don't
// (Q_UNCOUNTED).
// Outnumbered (SHARED-RULES 1-5): how many more counted units the other side had when the
// boards were counted, before any Start of Combat effect; fixed for the whole fight. Back-row
// units with Q_UNCOUNTED (Squires) are left out of both counts; hands never count.
// True once the fight has stopped (a limit or the end): a hook must then do nothing.
// Internal (FightArrivals): a new fight uid.
// 9.2.1 more units attacks first; a tie is random.
// 9.3: only the unit phase applies on this track (no heroes or player modifiers yet). One
// random player resolves all their Start of Combat units, then the other (9.3.2). Deaths
// resolve after each effect (9.3.5). SHARED-RULES 41: passes by Mechanic
// .start_of_combat_priority, highest first: the set-up pass (Mechanic.SOC_SETUP) on both
// sides, then the main pass (SOC_MAIN). Only units on the board when it begins act (42).
// --- Attacks ------------------------------------------------------------------------------------
// 9.4.5 step 1: on the board, Attack above 0, and not "can't attack" (Q_CANT_ATTACK).
// 9.4.5 steps 2-3: the lowest slot that can attack and isn't flagged, resetting the cycle once.
// 9.5.1-9.5.5: front row if any lives, else back row; drop untargetable unless all are;
// must-be-attacked units first; then random. Dying units (killed but not yet removed) are never
// chosen. Public so an effect that picks the next target (Overrun) picks it by the same rules.
// 9.6.1 one attack. `out_of_turn` for an attack made at once (9.4.12); the attack event says
// so, and whether the attacker takes no damage while it resolves.
// 9.6.1 step 3, 9.6.2: both deal damage at once; the attacker's damage (and its splash) resolves
// first. Amounts are read before any damage lands. Only the attacker's damage to its target is
// its own attack's damage (damage_from_own_attack); the splash and the strike back are not.
// 9.4.12 "attacks immediately": an extra attack at once, out of turn, at `target` or a target
// chosen as usual. The pointer and flags don't change. False if it couldn't attack. With
// `takes_no_damage` the unit takes none from anything while the attack resolves, Thorns
// included (SHARED-RULES 26).
// A hit: `unit` deals its Attack (times `percent` / 100) to `target` and takes nothing back.
// Not an attack (no attack count, no attack hooks) and not attack damage (absorb_damage sees
// from_attack false, so Plate doesn't reduce it); deaths wait for the next resolution. From
// on_friendly_attack it is "joining" an attack (Pile on): every hit friends ask for while they
// hear the attack lands together once they all have, each for the Attack it had when it was
// asked (SHARED-RULES, Pile on); a target they kill ends that attack before the exchange.
// Elsewhere a hit on a dying unit does nothing (pick targets with units(), weakest_enemy...).
// Pile-on hits asked for during on_friendly_attack land at the same moment: the amounts were
// fixed when asked, so no hit sees another's damage or misses a target another one killed.
// Internal, for FightSide: the player's slot buff percent (Rules.SLOT_BUFF_PERCENT).
// --- What mechanics may do --------------------------------------------------------------------
// Call before a hook acts: logs the trigger and counts it (9.10.2). False once the limit is
// reached: the hook must then do nothing, and the fight ends as a tie.
// A trigger for a standing mechanic (no unit), counted the same way.
// Damage from `source` (null for no unit). Damage prevention runs first (absorb_damage); then
// Health drops and the source's damage triggers run (9.6.2). Deaths wait for death resolution.
// `from_attack` marks the exchange and its splash (9.6.1 step 3); hooks read it through
// damage_from_attack(). Damage a "takes no damage" attack or absorb_damage stops is logged as
// `prevented`, so a screen can show the Thorns that did nothing.
// True while the damage being dealt (absorb_damage, on_damage_dealt) is an attack's damage
// exchange or its splash, not a Hit or plain damage. Overrun tells an attack from a Hit by it.
// True while the damage being dealt is an attacker's own attack on the unit it attacked: the
// exchange's damage to its target, not the target's strike back, a Cleave splash, a Hit or plain
// damage. Overrun carries only this.
// Destroys a unit outright; it dies at the next death resolution.
// A buff: this combat (12.1.2), or `permanent` also on the recruit unit (12.1.1) when its side
// writes back. A permanent buff a unit earns as it dies (Flying Ace in the same exchange) is
// kept: it still reaches the recruit unit.
// Uses left a screen shows on a unit ("5 a fight", Molt charges): sets unit.uses[key] and logs
// `uses` (side, slot, uid, key, left, source_uid). The unit view carries `uses`; a return keeps
// them.
// A status a mechanic shows (a shield popping, stealth ending): for the UI only. `source` is
// the unit that caused it; left null, the unit whose damage is being prevented.
// 8.4, 9.8.1 a combat summon on `side`. `source_slot` -1 means no source (8.4.3);
// `own_slot_first` for a dying unit's own effect (8.4.1). With no empty slot it fails (8.4.5)
// and returns null, or with `wait` it waits in one line and lands after the next death
// resolution (FightArrivals). A summon keeps its source and `payload`, which goes into the
// landed unit's `state`. `golden` summons a golden token (doubled stats and numbers, 7.3.5):
// a golden King Speck's Cousins.
// 9.4.8 a unit entering slot j mid-cycle is flagged only if j is below the pointer. Internal
// (FightArrivals too): `kind` is the event type ("summon", or "reserve" for a unit stepping in
// from the hand), `extra` more event fields.
// Puts a unit into an empty slot (9.4.8: flagged only if below the pointer), recalculates
// auras and runs its on_combat_begin. Logs nothing: _enter and _try_return log what it was.
// The units of `unit`'s side named by a selector (Selectors), relative to `unit`'s slot.
// Dying units (0 Health or destroyed, waiting for the next death check) are left out: inside
// one effect a unit killed earlier in it is already as good as dead (SHARED-RULES, A4).
// 9.5.6 a random enemy from either row, ignoring targeting rules; never a dying one. Null if
// none.
// The enemy with the least Health now, from either row (9.5.6), never a dying one; ties at
// random (the effect stream). Null if none. "Hit the enemy with the least Health."
// The living units on `side`'s board, in reading order: units at 0 Health or destroyed that
// wait for the next death check are left out (a new list each call).
// Internal: every unit on `side`'s board, dying ones included, in reading order. Cached until
// the board changes; callers must not modify the returned list.
// A rule about a whole side, asked of every unit on it and then its standing mechanics
// (Mechanic.side_query). Example: Q_DEATH_EFFECT_TIMES.
// A unit's own death effects without the death (from where it stands), each resolving as many
// times as Q_DEATH_EFFECT_TIMES says.
// --- Listeners ------------------------------------------------------------------------------------
// Runs a listener hook for every unit on `side` (reading order, skipping the gone), then its
// standing mechanics with unit = null. Arguments go between the unit and the params.
// on_friendly_attack for the attacker's friends, then for any friend that arrived while they
// acted, until none is new; then the side's standing mechanics once.
// As _notify, but not for `subject` itself.
// Internal, for FightSide: an entry went into one of `side`'s heaps.
// --- Deaths ---------------------------------------------------------------------------------------
// 9.7 death resolution and returns (FightDeaths). Internal; FightArrivals and tests call it.
// --- Upkeep and end -------------------------------------------------------------------------------
// Internal (FightSide calls it too): recalculates auras and slot effects (FightAuras).
// 9.9 and 10.1.2 (FightDeaths.finish): the winner and the starting units killed.
// Internal, for FightSide: logs `event` for that side, with the source unit's uid.
// Internal (FightDeaths): an event held back while a return resolved, now logged after it.
// 9.4.5 step 5: P = its slot; it and every unit in a lower slot are flagged.
// "Instead of attacking": a mechanic that takes the turn replaces the attacks, and counts as
// one toward the attack limit (9.10.1).
// 9.4.11 repeat attacks back to back, a new target each, while it lives and has Attack.
// 9.5.7 text that overrides targeting (Q_TARGET_ROW on the attacker).
// Step 1 killed the attacker (Thorns): it doesn't attack, so no "whenever this attacks" and
// no friend joins in. The attack still counts.
// "After this attacks" happens even when a friend joining in killed the target first.
pub type CombatRef = Rc<RefCell<Combat>>;
pub struct Combat {
    pub geometry: Option<BoardGeometryRef>,
    pub config: Option<GameConfigRef>,
    pub registry: Option<MechanicRegistryRef>,
    pub library: Option<UnitLibraryRef>,
    pub events: Array<Dictionary>,
    pub sides: Array<Array<Option<CombatUnitRef>>>,
    pub pointers: Array<i64>,
    pub effect_rng: Option<RngRef>,
    pub player_ids: Array<i64>,
    pub result: Dictionary,
    pub arrivals: Option<FightArrivalsRef>,
    pub listening_side: i64,
    pub _first_rng: Option<RngRef>,
    pub _soc_rng: Option<RngRef>,
    pub _target_rng: Option<RngRef>,
    pub _next_uid: i64,
    pub _attacks: i64,
    pub _triggers: i64,
    pub _halt_reason: String,
    pub _active_side: i64,
    pub _starting_uids: Array<Array<i64>>,
    pub _hit_by: Dictionary<Option<CombatUnitRef>, i64>,
    pub _units_cache: Array<Option<Array<CombatUnitRef>>>,
    pub _bridges: Array<FightSideRef>,
    pub _depth: i64,
    pub _auras: Option<FightAurasRef>,
    pub _deaths: Option<FightDeathsRef>,
    pub _counted_start: Array<i64>,
    pub _started: bool,
    pub _acting: Option<CombatUnitRef>,
    pub _from_attack: bool,
    pub _own_attack: bool,
    pub _next_own_attack: bool,
    pub _joining: bool,
    pub _joined_hits: Array<JoinedHit>,
    pub _placing: Option<CombatUnitRef>,
    pub _held: Array<Dictionary>,
    pub _holding: bool,
}
impl Default for Combat {
    fn default() -> Self {
        Self {
            geometry: None,
            config: None,
            registry: None,
            library: None,
            events: Array::new(),
            sides: Array::from(vec![Array::new(), Array::new()]),
            pointers: Array::from(vec![-1, -1]),
            effect_rng: None,
            player_ids: Array::from(vec![-1, -1]),
            result: Default::default(),
            arrivals: None,
            listening_side: -1,
            _first_rng: None,
            _soc_rng: None,
            _target_rng: None,
            _next_uid: 1,
            _attacks: 0,
            _triggers: 0,
            _halt_reason: "".to_string(),
            _active_side: 0,
            _starting_uids: Array::from(vec![Array::new(), Array::new()]),
            _hit_by: Default::default(),
            _units_cache: Array::from(vec![None, None]),
            _bridges: Array::new(),
            _depth: 0,
            _auras: None,
            _deaths: None,
            _counted_start: Array::from(vec![0, 0]),
            _started: false,
            _acting: None,
            _from_attack: false,
            _own_attack: false,
            _next_own_attack: false,
            _joining: false,
            _joined_hits: Array::new(),
            _placing: None,
            _held: Array::new(),
            _holding: false,
        }
    }
}
impl ToState for Combat {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "geometry" => &self.geometry,
            "config" => &self.config,
            "registry" => &self.registry,
            "library" => &self.library,
            "events" => &self.events,
            "sides" => &self.sides,
            "pointers" => &self.pointers,
            "effect_rng" => &self.effect_rng,
            "player_ids" => &self.player_ids,
            "result" => &self.result,
            "arrivals" => &self.arrivals,
            "listening_side" => &self.listening_side,
            "_first_rng" => &self._first_rng,
            "_soc_rng" => &self._soc_rng,
            "_target_rng" => &self._target_rng,
            "_next_uid" => &self._next_uid,
            "_attacks" => &self._attacks,
            "_triggers" => &self._triggers,
            "_halt_reason" => &self._halt_reason,
            "_active_side" => &self._active_side,
            "_starting_uids" => &self._starting_uids,
            "_hit_by" => &self._hit_by,
            "_units_cache" => &self._units_cache,
            "_bridges" => &self._bridges,
            "_depth" => &self._depth,
            "_auras" => &self._auras,
            "_deaths" => &self._deaths,
            "_counted_start" => &self._counted_start,
            "_started" => &self._started,
            "_acting" => &self._acting,
            "_from_attack" => &self._from_attack,
            "_own_attack" => &self._own_attack,
            "_next_own_attack" => &self._next_own_attack,
            "_joining" => &self._joining,
            "_joined_hits" => &self._joined_hits,
            "_placing" => &self._placing,
            "_held" => &self._held,
            "_holding" => &self._holding,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "geometry",
            "config",
            "registry",
            "library",
            "events",
            "sides",
            "pointers",
            "effect_rng",
            "player_ids",
            "result",
            "arrivals",
            "listening_side",
            "_first_rng",
            "_soc_rng",
            "_target_rng",
            "_next_uid",
            "_attacks",
            "_triggers",
            "_halt_reason",
            "_active_side",
            "_starting_uids",
            "_hit_by",
            "_units_cache",
            "_bridges",
            "_depth",
            "_auras",
            "_deaths",
            "_counted_start",
            "_started",
            "_acting",
            "_from_attack",
            "_own_attack",
            "_next_own_attack",
            "_joining",
            "_joined_hits",
            "_placing",
            "_held",
            "_holding",
        ]
    }
}
impl Combat {
    pub const REASON_BOARD_EMPTY: &'static str = "board_empty";
    pub const REASON_NO_ATTACKS: &'static str = "no_attacks";
    pub const REASON_ATTACK_LIMIT: &'static str = "attack_limit";
    pub const REASON_TRIGGER_LIMIT: &'static str = "trigger_limit";
    pub const REASONS: &'static [&'static str] = &[
        Self::REASON_BOARD_EMPTY,
        Self::REASON_NO_ATTACKS,
        Self::REASON_ATTACK_LIMIT,
        Self::REASON_TRIGGER_LIMIT,
    ];
    pub const MAX_ATTACK_DEPTH: i64 = 4;
    pub const NO_DAMAGE: &'static str = "core_takes_no_damage";
    pub fn create(
        game_geometry: &BoardGeometryRef,
        game_config: &GameConfigRef,
        mechanic_registry: &MechanicRegistryRef,
        unit_library: &UnitLibraryRef,
        fight_seed: i64,
    ) -> CombatRef {
        let made = Self::new();
        {
            let mut c = made.borrow_mut();
            c.geometry = Some(game_geometry.clone());
            c.config = Some(game_config.clone());
            c.registry = Some(mechanic_registry.clone());
            c.library = Some(unit_library.clone());
            c._first_rng = Some(Rng::derive(fight_seed, "first"));
            c._soc_rng = Some(Rng::derive(fight_seed, "soc"));
            c._target_rng = Some(Rng::derive(fight_seed, "target"));
            c.effect_rng = Some(Rng::derive(fight_seed, "effect"));
        }
        made
    }
    /// `_init` creates helpers immediately; weak links refer to this exact shared owner.
    pub fn new() -> CombatRef {
        Rc::new_cyclic(|owner| {
            RefCell::new(Self {
                arrivals: Some(Rc::new(RefCell::new(FightArrivals {
                    _combat_ref: Some(owner.clone()),
                    ..FightArrivals::default()
                }))),
                _auras: Some(Rc::new(RefCell::new(FightAuras {
                    _combat_ref: Some(owner.clone()),
                    ..FightAuras::default()
                }))),
                _deaths: Some(Rc::new(RefCell::new(FightDeaths {
                    _combat_ref: Some(owner.clone()),
                }))),
                ..Self::default()
            })
        })
    }
    pub fn run(
        &mut self,
        boards: &Array<Array<Option<UnitRef>>>,
        ids: &Array<i64>,
        owners: &Array<Option<PlayerStateRef>>,
        live: &Array<bool>,
        hands: &Array<Array<UnitRef>>,
    ) -> Dictionary {
        self.player_ids = ids.clone();
        let owner_ref = self.arrivals.as_ref().unwrap().borrow()._combat().unwrap();
        let slots = self.geometry.as_ref().unwrap().borrow().slot_count;
        for side in 0..2 {
            let owner = owners.get(side).flatten();
            self._bridges.push(FightSide::create(
                &owner_ref,
                side as i64,
                owner.as_ref(),
                live.get(side).unwrap_or(false),
                slots,
            ));
        }
        self._setup(boards);
        self.arrivals_copy().take_reserve(self, hands);
        let first = self._first_side();
        let d = FightDeaths::default();
        let board0 = d.board_view(self, 0);
        let board1 = d.board_view(self, 1);
        let slots0 = d.slots_view(self, 0);
        let slots1 = d.slots_view(self, 1);
        let counters0 = self.bridge(0).borrow().counters.duplicate();
        let counters1 = self.bridge(1).borrow().counters.duplicate();
        let heaps0 = self.bridge(0).borrow().heap_sizes(self);
        let heaps1 = self.bridge(1).borrow().heap_sizes(self);
        let geometry = self.geometry.clone().unwrap();
        let reserve = self.arrivals_copy().reserve_view(self, &geometry);
        self._log(&crate::state_dict! {"type"=>"combat_start","players"=>&self.player_ids.duplicate(),"first"=>&first,
            "boards"=>&Array::from(vec![board0,board1]),"slots"=>&Array::from(vec![slots0,slots1]),
            "counters"=>&Array::from(vec![counters0,counters1]),"heaps"=>&Array::from(vec![heaps0,heaps1]),
            "reserve"=>&reserve,"outnumbered_by"=>&[self.outnumbered_by(0),self.outnumbered_by(1)]}.as_dict());
        self._started = true;
        self._start_of_combat();
        let mut side = first;
        while self._halt_reason.is_empty() {
            if self._board_empty(0) || self._board_empty(1) {
                self._halt_reason = Self::REASON_BOARD_EMPTY.into();
                break;
            }
            if !self._side_can_attack(0) && !self._side_can_attack(1) {
                self._halt_reason = Self::REASON_NO_ATTACKS.into();
                break;
            }
            if self._attacks >= self.config.as_ref().unwrap().borrow().attack_limit {
                self._halt_reason = Self::REASON_ATTACK_LIMIT.into();
                break;
            }
            if self._side_can_attack(side) {
                self._take_turn(side);
            } else {
                self._log(&crate::state_dict! {"type"=>"pass","side"=>&side}.as_dict());
            }
            side = 1 - side;
        }
        self._finish()
    }
    // The helper's mutable state is shared Array storage. A shallow handle avoids retaining
    // a RefCell borrow across recursive summons/attacks from mechanic callbacks.
    fn arrivals_copy(&self) -> FightArrivals {
        let a = self.arrivals.as_ref().unwrap().borrow();
        FightArrivals {
            reserve: a.reserve.clone(),
            waiting: a.waiting.clone(),
            _combat_ref: a._combat_ref.clone(),
        }
    }
    fn call_hook(
        &mut self,
        m: MechanicRef,
        unit: Option<&CombatUnitRef>,
        hook: Hook,
        args: &HookArgs,
        p: &MechanicParamsRef,
    ) {
        match (hook, args) {
            (Hook::OnAnyDeath, HookArgs::Death { dead }) => m.on_any_death(self, unit, dead, p),
            (Hook::OnFriendlyDeath, HookArgs::Death { dead }) => {
                m.on_friendly_death(self, unit, dead, p)
            }
            (Hook::AfterFriendlyDeath, HookArgs::Death { dead }) => {
                m.after_friendly_death(self, unit, dead, p)
            }
            (Hook::AfterFriendlyReturn, HookArgs::FriendlyReturn { back }) => {
                m.after_friendly_return(self, unit, back, p)
            }
            (Hook::OnFightEnter, HookArgs::FightEnter { entered }) => {
                m.on_fight_enter(self, unit, entered, p)
            }
            (Hook::AfterDeathRound, HookArgs::None) => m.after_death_round(self, unit, p),
            (Hook::OnHeapAddedInFight, HookArgs::HeapAdded { heap, card_id }) => {
                m.on_heap_added_in_fight(self, unit, heap, card_id, p)
            }
            _ => panic!("unsupported combat listener {}", hook.as_str()),
        }
    }
    pub fn bridge(&mut self, index: i64) -> FightSideRef {
        self._bridges.get(index as usize).unwrap()
    }
    pub fn _setup(&mut self, boards: &Array<Array<Option<UnitRef>>>) {
        for side in 0..2 {
            let row = Array::from(vec![
                None;
                self.geometry.as_ref().unwrap().borrow().slot_count
                    as usize
            ]);
            self.sides.borrow_mut()[side] = row.clone();
            let board = boards.get(side).unwrap();
            for slot in 0..board.len().min(row.len()) {
                let Some(source) = board.get(slot).flatten() else {
                    continue;
                };
                let unit = CombatUnit::from_unit(&source, self._take_uid(), side as i64);
                unit.borrow_mut().slot = slot as i64;
                row.borrow_mut()[slot] = Some(unit.clone());
                self._units_cache.borrow_mut()[side] = None;
                self._starting_uids
                    .get(side)
                    .unwrap()
                    .push(unit.borrow().uid);
            }
        }
        self._counted_start = Array::from(vec![self._counted(0), self._counted(1)]);
        self._refresh_auras();
        for side in 0..2 {
            let board = self._board(side);
            let mut i = 0;
            while let Some(unit) = board.get(i) {
                i += 1;
                for_hooks(&unit, |m, p| m.on_combat_begin(self, Some(&unit), &p));
            }
        }
        self._refresh_auras();
    }
    pub fn _counted(&self, side_index: i64) -> i64 {
        self.sides
            .get(side_index as usize)
            .unwrap()
            .to_vec()
            .into_iter()
            .flatten()
            .filter(|unit| {
                let slot = unit.borrow().slot;
                self.geometry.as_ref().unwrap().borrow().is_front(slot)
                    || CombatUnit::query(unit, mechanic::Q_UNCOUNTED, 0) == 0
            })
            .count() as i64
    }
    pub fn outnumbered_by(&self, side_index: i64) -> i64 {
        (self._counted_start.get((1 - side_index) as usize).unwrap()
            - self._counted_start.get(side_index as usize).unwrap())
        .max(0)
    }
    pub fn halted(&self) -> bool {
        !self._halt_reason.is_empty()
    }
    pub fn _take_uid(&mut self) -> i64 {
        self._next_uid += 1;
        self._next_uid - 1
    }
    pub fn _first_side(&mut self) -> i64 {
        let counts = [self._board(0).len(), self._board(1).len()];
        if counts[0] != counts[1] {
            return if counts[0] > counts[1] { 0 } else { 1 };
        }
        self._first_rng
            .as_ref()
            .unwrap()
            .borrow_mut()
            .range_int(0, 1)
    }
    pub fn _start_of_combat(&mut self) {
        let first = self._soc_rng.as_ref().unwrap().borrow_mut().range_int(0, 1);
        let mut priorities = Vec::new();
        let present = [self._board(0).duplicate(), self._board(1).duplicate()];
        for side in 0..2 {
            for unit in self._board(side).to_vec() {
                for_hooks(&unit, |m, p| {
                    let rank = m.start_of_combat_priority(&p);
                    if !priorities.contains(&rank) {
                        priorities.push(rank);
                    }
                });
            }
        }
        crate::util::godot_sort::sort(&mut priorities);
        priorities.reverse();
        for rank in priorities {
            for side in [first, 1 - first] {
                for unit in present[side as usize].to_vec() {
                    let hooks = unit.borrow().hooks();
                    let mut i = 0;
                    while let Some(bound) = hooks.get(i) {
                        i += 1;
                        if unit.borrow().gone || !self._halt_reason.is_empty() {
                            break;
                        }
                        let (m, p) = binding(&bound);
                        if m.start_of_combat_priority(&p) != rank {
                            continue;
                        }
                        self._active_side = side;
                        m.on_start_of_combat(self, Some(&unit), &p);
                        self._resolve_deaths(side);
                    }
                }
            }
        }
    }
    pub fn _can_attack(&mut self, unit: Option<&CombatUnitRef>) -> bool {
        let Some(unit) = unit else {
            return false;
        };
        {
            let u = unit.borrow();
            if u.gone || u.should_die() || u.attack() <= 0 {
                return false;
            }
        }
        CombatUnit::query(unit, mechanic::Q_CANT_ATTACK, 0) == 0
    }
    pub fn _side_can_attack(&mut self, side_index: i64) -> bool {
        let board = self._board(side_index);
        for unit in board.to_vec() {
            if self._can_attack(Some(&unit)) {
                return true;
            }
        }
        false
    }
    pub fn _next_attacker(&mut self, side_index: i64) -> Option<CombatUnitRef> {
        for pass in 0..2 {
            for unit in self._board(side_index).to_vec() {
                if self._can_attack(Some(&unit)) && !unit.borrow().flagged {
                    return Some(unit);
                }
            }
            if pass == 0 {
                for unit in self._board(side_index).to_vec() {
                    unit.borrow_mut().flagged = false;
                }
                self.pointers.borrow_mut()[side_index as usize] = -1;
            }
        }
        None
    }
    pub fn _take_turn(&mut self, side_index: i64) {
        let Some(attacker) = self._next_attacker(side_index) else {
            self._log(&crate::state_dict! {"type"=>"pass","side"=>&side_index}.as_dict());
            return;
        };
        self.pointers.borrow_mut()[side_index as usize] = attacker.borrow().slot;
        for unit in self._board(side_index).to_vec() {
            if unit.borrow().slot <= attacker.borrow().slot {
                unit.borrow_mut().flagged = true;
            }
        }
        let hooks = attacker.borrow().hooks();
        let mut i = 0;
        while let Some(bound) = hooks.get(i) {
            i += 1;
            let (m, p) = binding(&bound);
            if m.instead_of_attack(self, Some(&attacker), &p) {
                self._attacks += 1;
                let u = attacker.borrow();
                let event=crate::state_dict!{"type"=>"instead_of_attack","side"=>&u.side,"slot"=>&u.slot,"uid"=>&u.uid,"mechanic"=>&bound.borrow().id}.as_dict();
                drop(u);
                self._log(&event);
                self._resolve_deaths(side_index);
                return;
            }
        }
        let swings = CombatUnit::query(&attacker, mechanic::Q_ATTACKS, 1).max(1);
        for _ in 0..swings {
            if !self._can_attack(Some(&attacker))
                || !self._halt_reason.is_empty()
                || self._attacks >= self.config.as_ref().unwrap().borrow().attack_limit
            {
                break;
            }
            let Some(defender) = self.choose_target(&attacker) else {
                break;
            };
            self._attack(&attacker, &defender, false);
        }
    }
    pub fn choose_target(&mut self, attacker: &CombatUnitRef) -> Option<CombatUnitRef> {
        let enemy = 1 - attacker.borrow().side;
        let mut front = Vec::new();
        let mut back = Vec::new();
        for unit in self.units(enemy).to_vec() {
            let slot = unit.borrow().slot;
            if self.geometry.as_ref().unwrap().borrow().is_front(slot) {
                front.push(unit);
            } else {
                back.push(unit);
            }
        }
        let mut candidates = if !front.is_empty() {
            front
        } else {
            back.clone()
        };
        if CombatUnit::query(attacker, mechanic::Q_TARGET_ROW, 0) == mechanic::ROW_BACK
            && !back.is_empty()
        {
            candidates = back;
        }
        if candidates.is_empty() {
            return None;
        }
        let visible: Vec<_> = candidates
            .iter()
            .filter(|u| CombatUnit::query(u, mechanic::Q_UNTARGETABLE, 0) == 0)
            .cloned()
            .collect();
        if !visible.is_empty() {
            candidates = visible;
        }
        let taunts: Vec<_> = candidates
            .iter()
            .filter(|u| CombatUnit::query(u, mechanic::Q_TAUNT, 0) != 0)
            .cloned()
            .collect();
        if !taunts.is_empty() {
            candidates = taunts;
        }
        let index = self
            ._target_rng
            .as_ref()
            .unwrap()
            .borrow_mut()
            .index(candidates.len() as i64);
        Some(candidates[index as usize].clone())
    }
    pub fn _attack(
        &mut self,
        attacker: &CombatUnitRef,
        defender: &CombatUnitRef,
        out_of_turn: bool,
    ) {
        self._attacks += 1;
        self._active_side = attacker.borrow().side;
        let outer = self._joining;
        self._joining = false;
        let a = attacker.borrow();
        let d = defender.borrow();
        let event=crate::state_dict!{"type"=>"attack","side"=>&a.side,"slot"=>&a.slot,"uid"=>&a.uid,"target_side"=>&d.side,"target_slot"=>&d.slot,"target_uid"=>&d.uid,"out_of_turn"=>&out_of_turn,"takes_no_damage"=>&(a.state_int(Self::NO_DAMAGE)!=0)}.as_dict();
        drop(a);
        drop(d);
        self._log(&event);
        self._attack_steps(attacker, defender);
        self._joining = outer;
    }
    pub fn _attack_steps(&mut self, attacker: &CombatUnitRef, defender: &CombatUnitRef) {
        for_hooks(defender, |m, p| {
            m.on_attacked(self, Some(defender), attacker, &p)
        });
        if attacker.borrow().should_die() || attacker.borrow().gone {
            let side = attacker.borrow().side;
            self._resolve_deaths(side);
            return;
        }
        for_hooks(attacker, |m, p| {
            m.on_attack(self, Some(attacker), defender, &p)
        });
        self._notify_joiners(attacker, defender);
        let both_standing = !defender.borrow().should_die() && !attacker.borrow().should_die();
        if both_standing && !defender.borrow().gone && !attacker.borrow().gone {
            self._exchange(attacker, defender);
        }
        for_hooks(attacker, |m, p| {
            m.after_attack(self, Some(attacker), defender, &p)
        });
        let side = attacker.borrow().side;
        self._resolve_deaths(side);
    }
    pub fn _exchange(&mut self, attacker: &CombatUnitRef, defender: &CombatUnitRef) {
        let dealt = attacker.borrow().attack();
        let taken = defender.borrow().attack();
        let mut splash = Vec::new();
        if CombatUnit::query(attacker, mechanic::Q_CLEAVE, 0) != 0 {
            let side = defender.borrow().side;
            let slot = defender.borrow().slot;
            let adjacent = self.geometry.as_ref().unwrap().borrow().adjacent(slot);
            for slot in adjacent.to_vec() {
                if let Some(near) = self.unit_at(side, slot) {
                    splash.push(near);
                }
            }
        }
        self._next_own_attack = true;
        self.deal_damage(Some(attacker), Some(defender), dealt, true);
        for near in splash {
            self.deal_damage(Some(attacker), Some(&near), dealt, true);
        }
        self.deal_damage(Some(defender), Some(attacker), taken, true);
    }
    pub fn attack_now(
        &mut self,
        unit: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        takes_no_damage: bool,
    ) -> bool {
        if !self._can_attack(unit)
            || !self._halt_reason.is_empty()
            || self._depth >= Self::MAX_ATTACK_DEPTH
        {
            return false;
        }
        if self._attacks >= self.config.as_ref().unwrap().borrow().attack_limit {
            return false;
        }
        let unit = unit.unwrap();
        let mut defender = target.cloned();
        if defender
            .as_ref()
            .is_none_or(|d| d.borrow().gone || d.borrow().side == unit.borrow().side)
        {
            defender = self.choose_target(unit);
        }
        let Some(defender) = defender else {
            return false;
        };
        self._depth += 1;
        if takes_no_damage {
            unit.borrow_mut().set_state(Self::NO_DAMAGE, 1);
        }
        self._attack(unit, &defender, true);
        unit.borrow_mut().set_state(Self::NO_DAMAGE, 0);
        self._depth -= 1;
        true
    }
    pub fn hit(
        &mut self,
        unit: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        percent: i64,
    ) {
        let (Some(unit), Some(target)) = (unit, target) else {
            return;
        };
        if unit.borrow().gone || target.borrow().gone || unit.borrow().attack() <= 0 {
            return;
        }
        let amount = (unit.borrow().attack().wrapping_mul(percent) as f64 / 100.0) as i64;
        if self._joining {
            self._joined_hits.push(JoinedHit {
                unit: unit.clone(),
                target: target.clone(),
                amount,
            });
            return;
        }
        if target.borrow().should_die() {
            return;
        }
        self._log_hit(Some(unit), Some(target));
        self.deal_damage(Some(unit), Some(target), amount, false);
    }
    pub fn _land_joined_hits(&mut self) {
        let landing = std::mem::take(&mut self._joined_hits);
        let mut i = 0;
        while let Some(entry) = landing.get(i) {
            i += 1;
            if !entry.target.borrow().gone {
                self._log_hit(Some(&entry.unit), Some(&entry.target));
                self.deal_damage(Some(&entry.unit), Some(&entry.target), entry.amount, false);
            }
        }
    }
    pub fn _log_hit(&mut self, unit: Option<&CombatUnitRef>, target: Option<&CombatUnitRef>) {
        let u = unit.unwrap().borrow();
        let t = target.unwrap().borrow();
        self._log(&crate::state_dict!{"type"=>"hit","side"=>&u.side,"slot"=>&u.slot,"uid"=>&u.uid,"target_side"=>&t.side,"target_slot"=>&t.slot,"target_uid"=>&t.uid}.as_dict());
    }
    pub fn rules_percent(&self, player: &PlayerStateRef) -> i64 {
        Rules::new(self.config.as_ref().unwrap()).slot_buff_percent(player)
    }
    pub fn trigger(&mut self, unit: Option<&CombatUnitRef>, mechanic_id: &str) -> bool {
        if !self._halt_reason.is_empty() {
            return false;
        }
        if self._triggers >= self.config.as_ref().unwrap().borrow().combat_trigger_limit {
            self._halt_reason = Self::REASON_TRIGGER_LIMIT.into();
            return false;
        }
        self._triggers += 1;
        let u = unit.unwrap().borrow();
        self._log(&crate::state_dict!{"type"=>"trigger","side"=>&u.side,"slot"=>&u.slot,"uid"=>&u.uid,"mechanic"=>mechanic_id}.as_dict());
        true
    }
    pub fn trigger_side(&mut self, side_index: i64, mechanic_id: &str) -> bool {
        if !self._halt_reason.is_empty() {
            return false;
        }
        if self._triggers >= self.config.as_ref().unwrap().borrow().combat_trigger_limit {
            self._halt_reason = Self::REASON_TRIGGER_LIMIT.into();
            return false;
        }
        self._triggers += 1;
        self._log(&crate::state_dict!{"type"=>"trigger","side"=>&side_index,"slot"=>&-1_i64,"uid"=>&-1_i64,"mechanic"=>mechanic_id}.as_dict());
        true
    }
    pub fn deal_damage(
        &mut self,
        source: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        amount: i64,
        from_attack: bool,
    ) {
        let own = self._next_own_attack && from_attack;
        self._next_own_attack = false;
        let Some(target) = target else {
            return;
        };
        if target.borrow().gone || amount <= 0 {
            return;
        }
        if target.borrow().state_int(Self::NO_DAMAGE) != 0 {
            self._log_prevented(source, Some(target), amount, "takes_no_damage");
            return;
        }
        let mut left = amount;
        let outer = self._acting.clone();
        let outer_attack = self._from_attack;
        let outer_own = self._own_attack;
        self._acting = source.cloned();
        self._from_attack = from_attack;
        self._own_attack = own;
        for_hooks(target, |m, p| {
            left = m.absorb_damage(self, Some(target), left, from_attack, &p)
        });
        self._acting = outer;
        if left < amount {
            self._log_prevented(source, Some(target), amount - left.max(0), "absorbed");
        }
        if left <= 0 {
            self._from_attack = outer_attack;
            self._own_attack = outer_own;
            return;
        }
        target.borrow_mut().damage += left;
        self._hit_by
            .borrow_mut()
            .insert(target.borrow().uid, source.cloned());
        let t = target.borrow();
        let event=crate::state_dict!{"type"=>"damage","side"=>&t.side,"slot"=>&t.slot,"uid"=>&t.uid,"amount"=>&left,"health"=>&t.health(),"source_uid"=>&uid(source),"from_attack"=>&from_attack}.as_dict();
        drop(t);
        self._log(&event);
        if let Some(source) = source {
            for_hooks(source, |m, p| {
                m.on_damage_dealt(self, Some(source), Some(target), left, &p)
            });
        }
        self._from_attack = outer_attack;
        self._own_attack = outer_own;
    }
    pub fn damage_from_attack(&self) -> bool {
        self._from_attack
    }
    pub fn damage_from_own_attack(&self) -> bool {
        self._own_attack
    }
    pub fn _log_prevented(
        &mut self,
        source: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        amount: i64,
        why: &str,
    ) {
        let t = target.unwrap().borrow();
        self._log(&crate::state_dict!{"type"=>"prevented","side"=>&t.side,"slot"=>&t.slot,"uid"=>&t.uid,"amount"=>&amount,"reason"=>why,"source_uid"=>&uid(source)}.as_dict());
    }
    pub fn destroy(&mut self, source: Option<&CombatUnitRef>, target: Option<&CombatUnitRef>) {
        let Some(target) = target else {
            return;
        };
        if target.borrow().gone {
            return;
        }
        target.borrow_mut().destroyed = true;
        self._hit_by
            .borrow_mut()
            .insert(target.borrow().uid, source.cloned());
        let t = target.borrow();
        self._log(&crate::state_dict!{"type"=>"destroy","side"=>&t.side,"slot"=>&t.slot,"uid"=>&t.uid,"source_uid"=>&uid(source)}.as_dict());
    }
    pub fn buff(
        &mut self,
        unit: Option<&CombatUnitRef>,
        attack: i64,
        health: i64,
        source: Option<&CombatUnitRef>,
        permanent: bool,
    ) {
        let Some(unit) = unit else {
            return;
        };
        if unit.borrow().gone && !permanent {
            return;
        }
        {
            let u = unit.borrow();
            let mut stats = u.stats.as_ref().unwrap().borrow_mut();
            stats.combat_attack += attack;
            stats.combat_health += health;
        }
        let side = unit.borrow().side;
        let real = if permanent {
            self.bridge(side).borrow().real_unit(self, Some(unit))
        } else {
            None
        };
        if let Some(real) = &real {
            let u = real.borrow();
            let mut stats = u.stats.as_ref().unwrap().borrow_mut();
            stats.perm_attack += attack;
            stats.perm_health += health;
        }
        if unit.borrow().gone && real.is_none() {
            return;
        }
        let u = unit.borrow();
        let event=crate::state_dict!{"type"=>"buff","side"=>&u.side,"slot"=>&u.slot,"uid"=>&u.uid,"attack"=>&u.attack(),"health"=>&u.health(),"source_uid"=>&uid(source),"permanent"=>&real.is_some()}.as_dict();
        drop(u);
        self._log(&event);
        self._refresh_auras();
    }
    pub fn show_uses(
        &mut self,
        unit: Option<&CombatUnitRef>,
        key: &str,
        left: i64,
        source: Option<&CombatUnitRef>,
    ) {
        self.registry
            .as_ref()
            .unwrap()
            .borrow_mut()
            .check_name(key, "uses");
        let u = unit.unwrap().borrow();
        u.uses.insert(key, left.into());
        self._log(&crate::state_dict!{"type"=>"uses","side"=>&u.side,"slot"=>&u.slot,"uid"=>&u.uid,"key"=>key,"left"=>&left,"source_uid"=>&uid(source)}.as_dict());
    }
    pub fn show_status(
        &mut self,
        unit: Option<&CombatUnitRef>,
        status: &str,
        on: bool,
        source: Option<&CombatUnitRef>,
    ) {
        let cause = source.cloned().or_else(|| self._acting.clone());
        let u = unit.unwrap().borrow();
        self._log(&crate::state_dict!{"type"=>"status","side"=>&u.side,"slot"=>&u.slot,"uid"=>&u.uid,"status"=>status,"on"=>&on,"source_uid"=>&uid(cause.as_ref())}.as_dict());
    }
    pub fn summon(
        &mut self,
        side_index: i64,
        card_id: &str,
        source_slot: i64,
        own_slot_first: bool,
        source: Option<&CombatUnitRef>,
        wait: bool,
        payload: &Dictionary,
        golden: bool,
    ) -> Option<CombatUnitRef> {
        let occupied = self._occupied(side_index);
        let slot = self.geometry.as_ref().unwrap().borrow().summon_slot(
            &occupied,
            source_slot,
            own_slot_first,
        );
        let has = self.library.as_ref().unwrap().borrow().has(card_id);
        if slot < 0 || !has {
            if wait && has {
                self.arrivals_copy()
                    .wait(self, side_index, card_id, source, payload, golden);
                self._log(&crate::state_dict!{"type"=>"summon_waiting","side"=>&side_index,"id"=>card_id,"source_uid"=>&uid(source)}.as_dict());
            } else {
                self._log(
                    &crate::state_dict! {"type"=>"summon_failed","side"=>&side_index,"id"=>card_id}
                        .as_dict(),
                );
            }
            return None;
        }
        let card = self
            .library
            .as_ref()
            .unwrap()
            .borrow()
            .get_card(card_id)
            .unwrap();
        let new_uid = self._take_uid();
        let unit = CombatUnit::fresh(
            &card,
            new_uid,
            side_index,
            golden,
            self.registry.as_ref().unwrap(),
            self.config.as_ref().unwrap().borrow().stat_max,
        );
        for (k, v) in payload.borrow().iter() {
            unit.borrow().state.insert(k, v.clone());
        }
        self._enter(Some(&unit), slot, source, "summon", &Dictionary::new());
        Some(unit)
    }
    pub fn _enter(
        &mut self,
        unit: Option<&CombatUnitRef>,
        slot: i64,
        source: Option<&CombatUnitRef>,
        kind: &str,
        extra: &Dictionary,
    ) {
        let unit = unit.unwrap();
        self._place(Some(unit), slot);
        let event = unit.borrow().view(self.geometry.as_ref().unwrap());
        event.insert("type", kind.into());
        event.insert("source_uid", uid(source).into());
        for (k, v) in extra.borrow().iter() {
            event.insert(k, v.clone());
        }
        self._log(&event);
        let side = unit.borrow().side;
        for listener in [side, 1 - side] {
            self._notify(
                listener,
                Hook::OnFightEnter,
                &HookArgs::FightEnter {
                    entered: unit.clone(),
                },
            );
        }
    }
    pub fn _place(&mut self, unit: Option<&CombatUnitRef>, slot: i64) {
        let unit = unit.unwrap();
        let side = unit.borrow().side;
        {
            let mut u = unit.borrow_mut();
            u.slot = slot;
            u.flagged = slot < self.pointers.get(side as usize).unwrap();
        }
        self.sides.get(side as usize).unwrap().borrow_mut()[slot as usize] = Some(unit.clone());
        self._units_cache.borrow_mut()[side as usize] = None;
        self._placing = Some(unit.clone());
        self._refresh_auras();
        for_hooks(unit, |m, p| m.on_combat_begin(self, Some(unit), &p));
        self._placing = None;
    }
    pub fn select(&mut self, unit: Option<&CombatUnitRef>, selector: &str) -> Array<CombatUnitRef> {
        let unit = unit.unwrap();
        let side = unit.borrow().side;
        let slot = unit.borrow().slot;
        let occupied = self._occupied(side);
        let slots = Selectors::slots(self.geometry.as_ref().unwrap(), slot, &occupied, selector);
        let out = Array::new();
        for slot in slots.to_vec() {
            let found = self.unit_at(side, slot).unwrap();
            if !found.borrow().should_die() {
                out.push(found);
            }
        }
        out
    }
    pub fn random_enemy(&mut self, unit: Option<&CombatUnitRef>) -> Option<CombatUnitRef> {
        let enemies = self.units(1 - unit.unwrap().borrow().side);
        if enemies.is_empty() {
            return None;
        }
        let index = self
            .effect_rng
            .as_ref()
            .unwrap()
            .borrow_mut()
            .index(enemies.len() as i64);
        enemies.get(index as usize)
    }
    pub fn weakest_enemy(&mut self, unit: Option<&CombatUnitRef>) -> Option<CombatUnitRef> {
        let mut least = Vec::<CombatUnitRef>::new();
        for enemy in self.units(1 - unit.unwrap().borrow().side).to_vec() {
            let health = enemy.borrow().health();
            if least.is_empty() || health < least[0].borrow().health() {
                least = vec![enemy];
            } else if health == least[0].borrow().health() {
                least.push(enemy);
            }
        }
        if least.is_empty() {
            return None;
        }
        let index = self
            .effect_rng
            .as_ref()
            .unwrap()
            .borrow_mut()
            .index(least.len() as i64);
        Some(least[index as usize].clone())
    }
    pub fn unit_at(&mut self, side_index: i64, slot: i64) -> Option<CombatUnitRef> {
        self.sides
            .get(side_index as usize)
            .unwrap()
            .get(slot as usize)
            .flatten()
    }
    pub fn units(&mut self, side_index: i64) -> Array<CombatUnitRef> {
        self._board(side_index)
            .to_vec()
            .into_iter()
            .filter(|u| !u.borrow().should_die())
            .collect()
    }
    pub fn _board(&mut self, side_index: i64) -> Array<CombatUnitRef> {
        if let Some(cached) = self._units_cache.get(side_index as usize).flatten() {
            return cached;
        }
        let out: Array<CombatUnitRef> = self
            .sides
            .get(side_index as usize)
            .unwrap()
            .to_vec()
            .into_iter()
            .flatten()
            .collect();
        self._units_cache.borrow_mut()[side_index as usize] = Some(out.clone());
        out
    }
    pub fn side_query(&mut self, side_index: i64, query: &str, base: i64) -> i64 {
        if !mechanic::QUERIES.contains(&query) {
            self.registry
                .as_ref()
                .unwrap()
                .borrow_mut()
                .check_name(query, "query");
        }
        let mut value = base;
        for unit in self._board(side_index).to_vec() {
            for_hooks(&unit, |m, p| {
                value = m.side_query(self, Some(&unit), query, value, &p)
            });
        }
        self.listening_side = side_index;
        let standing = self.bridge(side_index).borrow().standing.clone();
        let mut i = 0;
        while let Some(bound) = standing.get(i) {
            i += 1;
            let (m, p) = binding(&bound);
            value = m.side_query(self, None, query, value, &p);
        }
        value
    }
    pub fn run_death_effects(&mut self, unit: Option<&CombatUnitRef>) {
        let unit = unit.unwrap();
        let side = unit.borrow().side;
        let times = self
            .side_query(side, mechanic::Q_DEATH_EFFECT_TIMES, 1)
            .max(1);
        for _ in 0..times {
            let hooks = unit.borrow().hooks();
            let mut i = 0;
            while let Some(bound) = hooks.get(i) {
                i += 1;
                if !self._halt_reason.is_empty() {
                    return;
                }
                let (m, p) = binding(&bound);
                m.on_death(self, Some(unit), &p);
            }
        }
    }
    pub fn _notify(&mut self, side_index: i64, hook: Hook, args: &HookArgs) {
        let board = self._board(side_index);
        let mut i = 0;
        while let Some(unit) = board.get(i) {
            i += 1;
            if unit.borrow().gone {
                continue;
            }
            for_hooks(&unit, |m, p| self.call_hook(m, Some(&unit), hook, args, &p));
        }
        self.listening_side = side_index;
        let standing = self.bridge(side_index).borrow().standing.clone();
        let mut i = 0;
        while let Some(bound) = standing.get(i) {
            i += 1;
            let (m, p) = binding(&bound);
            self.call_hook(m, None, hook, args, &p);
        }
    }
    pub fn _notify_joiners(&mut self, attacker: &CombatUnitRef, defender: &CombatUnitRef) {
        self._joining = true;
        self._joiners_hear(attacker, defender);
        self._joining = false;
        self._land_joined_hits();
    }
    pub fn _joiners_hear(&mut self, attacker: &CombatUnitRef, defender: &CombatUnitRef) {
        let mut heard = vec![attacker.borrow().uid];
        let mut fresh = true;
        let side = attacker.borrow().side;
        while fresh && self._halt_reason.is_empty() {
            fresh = false;
            for unit in self._board(side).duplicate().to_vec() {
                let id = unit.borrow().uid;
                if unit.borrow().gone || heard.contains(&id) {
                    continue;
                }
                heard.push(id);
                fresh = true;
                for_hooks(&unit, |m, p| {
                    m.on_friendly_attack(self, Some(&unit), attacker, defender, &p)
                });
            }
        }
        self.listening_side = side;
        let standing = self.bridge(side).borrow().standing.clone();
        let mut i = 0;
        while let Some(bound) = standing.get(i) {
            i += 1;
            let (m, p) = binding(&bound);
            m.on_friendly_attack(self, None, attacker, defender, &p);
        }
    }
    pub fn _notify_friends(&mut self, subject: &CombatUnitRef, hook: Hook, args: &HookArgs) {
        let side = subject.borrow().side;
        let board = self._board(side);
        let mut i = 0;
        while let Some(unit) = board.get(i) {
            i += 1;
            if unit.borrow().gone || Rc::ptr_eq(&unit, subject) {
                continue;
            }
            for_hooks(&unit, |m, p| self.call_hook(m, Some(&unit), hook, args, &p));
        }
        self.listening_side = side;
        let standing = self.bridge(side).borrow().standing.clone();
        let mut i = 0;
        while let Some(bound) = standing.get(i) {
            i += 1;
            let (m, p) = binding(&bound);
            self.call_hook(m, None, hook, args, &p);
        }
    }
    pub fn _notify_heap_added(&mut self, side_index: i64, heap_name: &str, card_id: &str) {
        self._notify(
            side_index,
            Hook::OnHeapAddedInFight,
            &HookArgs::HeapAdded {
                heap: heap_name.into(),
                card_id: card_id.into(),
            },
        );
    }
    pub fn _resolve_deaths(&mut self, active_side: i64) {
        FightDeaths::default().resolve(self, active_side);
    }
    pub fn _occupied(&mut self, side_index: i64) -> Array<bool> {
        self.sides
            .get(side_index as usize)
            .unwrap()
            .to_vec()
            .into_iter()
            .map(|u| u.is_some())
            .collect()
    }
    pub fn _board_empty(&self, side_index: i64) -> bool {
        self.sides
            .get(side_index as usize)
            .unwrap()
            .borrow()
            .iter()
            .all(Option::is_none)
    }
    pub fn _refresh_auras(&mut self) {
        let auras = self._auras.clone().unwrap();
        let started = self._started;
        auras.borrow_mut().refresh(self, started);
    }
    pub fn _finish(&mut self) -> Dictionary {
        FightDeaths::default().finish(self)
    }
    pub fn log_side(
        &mut self,
        from_side: &FightSideRef,
        event: &Dictionary,
        source: Option<&CombatUnitRef>,
    ) {
        event.insert("side", from_side.borrow().index.into());
        event.insert("source_uid", uid(source).into());
        self._log(event);
    }
    pub fn _log(&mut self, event: &Dictionary) {
        if self._holding {
            self._held.push(event.clone());
        } else {
            self.events.push(event.clone());
        }
    }
    pub fn _release(&mut self, event: &Dictionary) {
        if self._holding {
            self._held.push(event.clone());
        } else {
            self.events.push(event.clone());
        }
    }
}
#[derive(Clone)]
pub struct JoinedHit {
    pub unit: CombatUnitRef,
    pub target: CombatUnitRef,
    pub amount: i64,
}
impl ToState for JoinedHit {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "unit"=>&self.unit, "target"=>&self.target, "amount"=>&self.amount }
    }
}
