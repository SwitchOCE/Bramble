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

use crate::core::mechanics::mechanic::{Hook, HookArgs};
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
        todo!("port src/core/combat/combat.gd:create")
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
        todo!("port src/core/combat/combat.gd:run")
    }
    pub fn bridge(&mut self, index: i64) -> FightSideRef {
        todo!("port src/core/combat/combat.gd:bridge")
    }
    pub fn _setup(&mut self, boards: &Array<Array<Option<UnitRef>>>) {
        todo!("port src/core/combat/combat.gd:_setup")
    }
    pub fn _counted(&self, side_index: i64) -> i64 {
        todo!("port src/core/combat/combat.gd:_counted")
    }
    pub fn outnumbered_by(&self, side_index: i64) -> i64 {
        todo!("port src/core/combat/combat.gd:outnumbered_by")
    }
    pub fn halted(&self) -> bool {
        todo!("port src/core/combat/combat.gd:halted")
    }
    pub fn _take_uid(&mut self) -> i64 {
        todo!("port src/core/combat/combat.gd:_take_uid")
    }
    pub fn _first_side(&mut self) -> i64 {
        todo!("port src/core/combat/combat.gd:_first_side")
    }
    pub fn _start_of_combat(&mut self) {
        todo!("port src/core/combat/combat.gd:_start_of_combat")
    }
    pub fn _can_attack(&mut self, unit: Option<&CombatUnitRef>) -> bool {
        todo!("port src/core/combat/combat.gd:_can_attack")
    }
    pub fn _side_can_attack(&mut self, side_index: i64) -> bool {
        todo!("port src/core/combat/combat.gd:_side_can_attack")
    }
    pub fn _next_attacker(&mut self, side_index: i64) -> Option<CombatUnitRef> {
        todo!("port src/core/combat/combat.gd:_next_attacker")
    }
    pub fn _take_turn(&mut self, side_index: i64) {
        todo!("port src/core/combat/combat.gd:_take_turn")
    }
    pub fn choose_target(&mut self, attacker: &CombatUnitRef) -> Option<CombatUnitRef> {
        todo!("port src/core/combat/combat.gd:choose_target")
    }
    pub fn _attack(
        &mut self,
        attacker: &CombatUnitRef,
        defender: &CombatUnitRef,
        out_of_turn: bool,
    ) {
        todo!("port src/core/combat/combat.gd:_attack")
    }
    pub fn _attack_steps(&mut self, attacker: &CombatUnitRef, defender: &CombatUnitRef) {
        todo!("port src/core/combat/combat.gd:_attack_steps")
    }
    pub fn _exchange(&mut self, attacker: &CombatUnitRef, defender: &CombatUnitRef) {
        todo!("port src/core/combat/combat.gd:_exchange")
    }
    pub fn attack_now(
        &mut self,
        unit: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        takes_no_damage: bool,
    ) -> bool {
        todo!("port src/core/combat/combat.gd:attack_now")
    }
    pub fn hit(
        &mut self,
        unit: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        percent: i64,
    ) {
        todo!("port src/core/combat/combat.gd:hit")
    }
    pub fn _land_joined_hits(&mut self) {
        todo!("port src/core/combat/combat.gd:_land_joined_hits")
    }
    pub fn _log_hit(&mut self, unit: Option<&CombatUnitRef>, target: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/combat.gd:_log_hit")
    }
    pub fn rules_percent(&self, player: &PlayerStateRef) -> i64 {
        todo!("port src/core/combat/combat.gd:rules_percent")
    }
    pub fn trigger(&mut self, unit: Option<&CombatUnitRef>, mechanic_id: &str) -> bool {
        todo!("port src/core/combat/combat.gd:trigger")
    }
    pub fn trigger_side(&mut self, side_index: i64, mechanic_id: &str) -> bool {
        todo!("port src/core/combat/combat.gd:trigger_side")
    }
    pub fn deal_damage(
        &mut self,
        source: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        amount: i64,
        from_attack: bool,
    ) {
        todo!("port src/core/combat/combat.gd:deal_damage")
    }
    pub fn damage_from_attack(&self) -> bool {
        todo!("port src/core/combat/combat.gd:damage_from_attack")
    }
    pub fn damage_from_own_attack(&self) -> bool {
        todo!("port src/core/combat/combat.gd:damage_from_own_attack")
    }
    pub fn _log_prevented(
        &mut self,
        source: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        amount: i64,
        why: &str,
    ) {
        todo!("port src/core/combat/combat.gd:_log_prevented")
    }
    pub fn destroy(&mut self, source: Option<&CombatUnitRef>, target: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/combat.gd:destroy")
    }
    pub fn buff(
        &mut self,
        unit: Option<&CombatUnitRef>,
        attack: i64,
        health: i64,
        source: Option<&CombatUnitRef>,
        permanent: bool,
    ) {
        todo!("port src/core/combat/combat.gd:buff")
    }
    pub fn show_uses(
        &mut self,
        unit: Option<&CombatUnitRef>,
        key: &str,
        left: i64,
        source: Option<&CombatUnitRef>,
    ) {
        todo!("port src/core/combat/combat.gd:show_uses")
    }
    pub fn show_status(
        &mut self,
        unit: Option<&CombatUnitRef>,
        status: &str,
        on: bool,
        source: Option<&CombatUnitRef>,
    ) {
        todo!("port src/core/combat/combat.gd:show_status")
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
        todo!("port src/core/combat/combat.gd:summon")
    }
    pub fn _enter(
        &mut self,
        unit: Option<&CombatUnitRef>,
        slot: i64,
        source: Option<&CombatUnitRef>,
        kind: &str,
        extra: &Dictionary,
    ) {
        todo!("port src/core/combat/combat.gd:_enter")
    }
    pub fn _place(&mut self, unit: Option<&CombatUnitRef>, slot: i64) {
        todo!("port src/core/combat/combat.gd:_place")
    }
    pub fn select(&mut self, unit: Option<&CombatUnitRef>, selector: &str) -> Array<CombatUnitRef> {
        todo!("port src/core/combat/combat.gd:select")
    }
    pub fn random_enemy(&mut self, unit: Option<&CombatUnitRef>) -> Option<CombatUnitRef> {
        todo!("port src/core/combat/combat.gd:random_enemy")
    }
    pub fn weakest_enemy(&mut self, unit: Option<&CombatUnitRef>) -> Option<CombatUnitRef> {
        todo!("port src/core/combat/combat.gd:weakest_enemy")
    }
    pub fn unit_at(&mut self, side_index: i64, slot: i64) -> Option<CombatUnitRef> {
        todo!("port src/core/combat/combat.gd:unit_at")
    }
    pub fn units(&mut self, side_index: i64) -> Array<CombatUnitRef> {
        todo!("port src/core/combat/combat.gd:units")
    }
    pub fn _board(&mut self, side_index: i64) -> Array<CombatUnitRef> {
        todo!("port src/core/combat/combat.gd:_board")
    }
    pub fn side_query(&mut self, side_index: i64, query: &str, base: i64) -> i64 {
        todo!("port src/core/combat/combat.gd:side_query")
    }
    pub fn run_death_effects(&mut self, unit: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/combat.gd:run_death_effects")
    }
    pub fn _notify(&mut self, side_index: i64, hook: Hook, args: &HookArgs) {
        todo!("port src/core/combat/combat.gd:_notify")
    }
    pub fn _notify_joiners(&mut self, attacker: &CombatUnitRef, defender: &CombatUnitRef) {
        todo!("port src/core/combat/combat.gd:_notify_joiners")
    }
    pub fn _joiners_hear(&mut self, attacker: &CombatUnitRef, defender: &CombatUnitRef) {
        todo!("port src/core/combat/combat.gd:_joiners_hear")
    }
    pub fn _notify_friends(&mut self, subject: &CombatUnitRef, hook: Hook, args: &HookArgs) {
        todo!("port src/core/combat/combat.gd:_notify_friends")
    }
    pub fn _notify_heap_added(&mut self, side_index: i64, heap_name: &str, card_id: &str) {
        todo!("port src/core/combat/combat.gd:_notify_heap_added")
    }
    pub fn _resolve_deaths(&mut self, active_side: i64) {
        todo!("port src/core/combat/combat.gd:_resolve_deaths")
    }
    pub fn _occupied(&mut self, side_index: i64) -> Array<bool> {
        todo!("port src/core/combat/combat.gd:_occupied")
    }
    pub fn _board_empty(&self, side_index: i64) -> bool {
        todo!("port src/core/combat/combat.gd:_board_empty")
    }
    pub fn _refresh_auras(&mut self) {
        todo!("port src/core/combat/combat.gd:_refresh_auras")
    }
    pub fn _finish(&mut self) -> Dictionary {
        todo!("port src/core/combat/combat.gd:_finish")
    }
    pub fn log_side(
        &mut self,
        from_side: &FightSideRef,
        event: &Dictionary,
        source: Option<&CombatUnitRef>,
    ) {
        todo!("port src/core/combat/combat.gd:log_side")
    }
    pub fn _log(&mut self, event: &Dictionary) {
        todo!("port src/core/combat/combat.gd:_log")
    }
    pub fn _release(&mut self, event: &Dictionary) {
        todo!("port src/core/combat/combat.gd:_release")
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
