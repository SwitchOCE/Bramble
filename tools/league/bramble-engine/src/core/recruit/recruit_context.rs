//! Port of `src/core/recruit/recruit_context.gd`.
#![allow(unused_variables)]
use crate::core::board::board_geometry::BoardGeometryRef;
use crate::core::recruit::{
    player_state::PlayerStateRef,
    recruit::{Recruit, RecruitRef},
};
use crate::core::session::game_session::GameSessionRef;
use crate::core::units::unit::UnitRef;
use crate::core::util::rng::RngRef;
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
pub type RecruitContextRef = Rc<RefCell<RecruitContext>>;
pub struct RecruitContext {
    pub session: Option<GameSessionRef>,
    pub player: Option<PlayerStateRef>,
    pub rng: Option<RngRef>,
    pub target_index: i64,
    pub _recruit: Option<RecruitRef>,
    pub _triggers: i64,
    pub _limit: i64,
}
impl Default for RecruitContext {
    fn default() -> Self {
        Self {
            session: None,
            player: None,
            rng: None,
            target_index: -1,
            _recruit: None,
            _triggers: 0,
            _limit: 1000,
        }
    }
}
impl RecruitContext {
    pub fn new(game: &GameSessionRef, recruit: &RecruitRef, who: &PlayerStateRef) -> Self {
        let rng = Recruit::effect_rng(recruit, who);
        let limit = game
            .borrow()
            .config
            .as_ref()
            .expect("session config")
            .borrow()
            .action_trigger_limit;
        Self {
            session: Some(game.clone()),
            player: Some(who.clone()),
            rng: Some(rng),
            target_index: -1,
            _recruit: Some(recruit.clone()),
            _triggers: 0,
            _limit: limit,
        }
    }
    pub fn geometry(&self) -> BoardGeometryRef {
        self.session
            .as_ref()
            .expect("RecruitContext session")
            .borrow()
            .geometry
            .as_ref()
            .expect("session geometry")
            .clone()
    }

    // Call before a hook acts: logs the trigger. False once the action's trigger limit is reached,
    // and the hook must then do nothing.
    pub fn trigger(&mut self, unit: Option<&UnitRef>, mechanic_id: &str) -> bool {
        todo!("port src/core/recruit/recruit_context.gd:trigger")
    }
    pub fn triggers_used(&self) -> i64 {
        self._triggers
    }

    // 12.1.1: `permanent` for the rest of the game, otherwise this turn.
    pub fn buff(
        &mut self,
        unit: &UnitRef,
        attack: i64,
        health: i64,
        permanent: bool,
        source: Option<&UnitRef>,
    ) {
        todo!("port src/core/recruit/recruit_context.gd:buff")
    }
    pub fn gain_gold(&mut self, amount: i64, source: Option<&UnitRef>) {
        todo!("port src/core/recruit/recruit_context.gd:gain_gold")
    }

    // 8.4.7 a summon in the Recruit Phase: placed by 8.4, Created (4.3.1). Null when it fails.
    // `own_slot_first` for a unit's own effect that summons into its own slot when that is empty (an
    // eaten unit's death effect: the slot the sold unit left, 8.4.1); `golden` for a golden token.
    pub fn summon(
        &mut self,
        card_id: &str,
        source_slot: i64,
        own_slot_first: bool,
        golden: bool,
    ) -> Option<UnitRef> {
        todo!("port src/core/recruit/recruit_context.gd:summon")
    }

    // 6.2 Discover a unit with a tier in [min_tier, max_tier].
    pub fn discover(&mut self, min_tier: i64, max_tier: i64) {
        todo!("port src/core/recruit/recruit_context.gd:discover")
    }

    // The units on this player's board for a selector (Selectors), in reading order.
    pub fn select(&self, unit: &UnitRef, selector: &str) -> Array<UnitRef> {
        todo!("port src/core/recruit/recruit_context.gd:select")
    }
    pub fn random_of(&self, units: &Array<UnitRef>) -> Option<UnitRef> {
        todo!("port src/core/recruit/recruit_context.gd:random_of")
    }

    // A player-level number that lasts the game (PlayerState.counters).
    pub fn add_counter(&mut self, key: &str, amount: i64, source: Option<&UnitRef>) {
        todo!("port src/core/recruit/recruit_context.gd:add_counter")
    }

    // A number on a unit for this turn only (Unit.turn_counters; "ate this turn"), logged as
    // `turn_counter`. Cleared at the start of each turn.
    pub fn add_turn_counter(
        &mut self,
        unit: &UnitRef,
        key: &str,
        amount: i64,
        source: Option<&UnitRef>,
    ) {
        todo!("port src/core/recruit/recruit_context.gd:add_turn_counter")
    }

    // A number on a unit that lasts the game (Unit.counters).
    pub fn add_unit_counter(
        &mut self,
        unit: &UnitRef,
        key: &str,
        amount: i64,
        source: Option<&UnitRef>,
    ) {
        todo!("port src/core/recruit/recruit_context.gd:add_unit_counter")
    }

    // An entry into one of the player's heaps; "whenever an entry goes in" listeners hear it.
    pub fn heap_add(&mut self, heap_name: &str, card_id: &str, source: Option<&UnitRef>) {
        todo!("port src/core/recruit/recruit_context.gd:heap_add")
    }

    // Spends the `count` lowest entries; false, and nothing spent, when there are fewer.
    pub fn heap_spend(&mut self, heap_name: &str, count: i64, source: Option<&UnitRef>) -> bool {
        todo!("port src/core/recruit/recruit_context.gd:heap_spend")
    }

    // Takes the highest entry; &"" when the heap is empty.
    pub fn heap_take(&mut self, heap_name: &str, source: Option<&UnitRef>) -> String {
        todo!("port src/core/recruit/recruit_context.gd:heap_take")
    }
    pub fn _heap_removed(
        &mut self,
        heap_name: &str,
        ids: &Array<String>,
        source: Option<&UnitRef>,
    ) {
        todo!("port src/core/recruit/recruit_context.gd:_heap_removed")
    }

    // 8.5 a slot buff given in the Recruit Phase, and optionally a keyword the slot gives; it
    // lasts the game (8.5.3).
    pub fn slot_buff(
        &mut self,
        slot: i64,
        attack: i64,
        health: i64,
        source: Option<&UnitRef>,
        keyword: &str,
    ) {
        todo!("port src/core/recruit/recruit_context.gd:slot_buff")
    }

    // Clears a keyword from a slot for good (moving a Guard post).
    pub fn slot_clear_keyword(&mut self, slot: i64, keyword: &str, source: Option<&UnitRef>) {
        todo!("port src/core/recruit/recruit_context.gd:slot_clear_keyword")
    }

    // A new copy of a card into the hand (a Created card: no pool copy, sells for nothing, 4.3.1).
    // Lost if the hand is full (7.1.2). Returns it, or null.
    pub fn give_card(&mut self, card_id: &str, source: Option<&UnitRef>) -> Option<UnitRef> {
        todo!("port src/core/recruit/recruit_context.gd:give_card")
    }

    // 11.1.1 a unit gains a keyword for good. False if it had it or the keyword is unknown.
    pub fn give_keyword(
        &mut self,
        unit: &UnitRef,
        keyword: &str,
        source: Option<&UnitRef>,
    ) -> bool {
        todo!("port src/core/recruit/recruit_context.gd:give_keyword")
    }

    // A unit gains a mechanic with parameters for good ('Give a unit "+1 Fury"', Master-at-Arms):
    // `raw` holds its parameters as card data does. The numbers are the giver's: a golden target
    // never doubles them (pass the giver's params.num value). Logged as `effect`. False when the
    // mechanic is unknown or the parameters are wrong.
    pub fn give_effect(
        &mut self,
        unit: &UnitRef,
        mechanic_id: &str,
        raw: &Dictionary,
        source: Option<&UnitRef>,
    ) -> bool {
        todo!("port src/core/recruit/recruit_context.gd:give_effect")
    }

    // Takes a unit card out of the shop: its pool copy goes back (5.3.7) and its id is returned
    // (&"" for an empty slot). What happens to it next is the mechanic's (a heap entry, say).
    pub fn take_from_shop(&mut self, index: i64, source: Option<&UnitRef>) -> String {
        todo!("port src/core/recruit/recruit_context.gd:take_from_shop")
    }

    // A unit's death effects in the Recruit Phase, without a death (Mechanic.on_recruit_death).
    pub fn run_death_effects(&mut self, unit: &UnitRef) {
        todo!("port src/core/recruit/recruit_context.gd:run_death_effects")
    }

    // Gives the player a standing mechanic (no unit) once; false if it has it or it's unknown.
    pub fn add_standing(&mut self, mechanic_id: &str) -> bool {
        todo!("port src/core/recruit/recruit_context.gd:add_standing")
    }
    pub fn _log(&mut self, event: &Dictionary, source: Option<&UnitRef>) {
        todo!("port src/core/recruit/recruit_context.gd:_log")
    }
}
impl ToState for RecruitContext {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "session"=> &self.session, "player"=> &self.player, "rng"=> &self.rng, "target_index"=> &self.target_index, "_recruit"=> &self._recruit, "_triggers"=> &self._triggers, "_limit"=> &self._limit }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "session",
            "player",
            "rng",
            "target_index",
            "_recruit",
            "_triggers",
            "_limit",
        ]
    }
}

// Rule comments retained for the pending bodies:
// limit (9.10.2).
// --- Lasting state (12.1.1 "this game") -----------------------------------------------------
