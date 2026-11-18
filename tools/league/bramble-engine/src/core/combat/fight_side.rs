#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/combat/fight_side.gd`; gameplay TODO bodies belong to the later port workers.
use std::{cell::RefCell, rc::{Rc, Weak}};
use crate::{Array, Dictionary, ToState, Variant};

use crate::core::mechanics::bound_mechanic::{BoundMechanicRef};
use crate::core::state::card_heap::{CardHeapRef};

use crate::core::combat::combat::{Combat, CombatRef};
use crate::core::combat::combat_unit::{CombatUnitRef};

use crate::core::recruit::player_state::{PlayerStateRef};

use crate::core::state::slot_state::{SlotStateRef};

use crate::core::units::unit::{UnitRef};

// GDScript rule and contract comments:
// A fight hook may use any of these, so the fight API is one class on purpose.
// One side of a fight and its bridge to the player (12.1.1, 9.1.1's exception). Mechanics reach
// it with combat.bridge(n). It holds the player's lasting numbers and heaps (the real ones when the
// side writes back, copies for the ghost or a bare test fight), the slot effects copied into the
// fight (8.5.2), and this fight's per-side numbers. "Permanently" changes also go to the real
// unit, slot or player when the side writes back; otherwise they last this fight only.
// The player, or null for a bare fight (tests).
// True when permanent changes reach the player (a live player; not the ghost).
// Units of this side that died this fight (9.7), tokens included.
// Numbers a mechanic keeps for this side for this fight only.
// Heap name -> the `n` of each entry marked used for this fight (heap_use); the heap itself
// doesn't change.
// The percent of their Attack buff this side's slots give for the rest of the fight (base 100;
// the Edgewright sets 200). Kept if the unit that set it dies (set_slot_attack_percent).
// The recruit unit (board or hand) a fight unit copies, to read; null for one made in the
// fight. A ghost or saved board has one too; use real_unit to change it.
// The recruit-board unit a fight unit copies, when this side writes back; else null.
// A player-level number ("this game", 12.1.1). Lasts the game when this side writes back.
// A number on a unit. `permanent` writes it to the recruit unit too (Unit.counters).
// The named heap, made empty on first use (the player's own when this side writes back).
// Spends the `count` lowest entries (CardHeap.spend_lowest). False, and nothing spent, if the
// heap has fewer.
// Marks the `count` highest-tier entries not yet used this fight (newest first on a tie) used
// for this fight; they stay in the heap. False, and nothing marked, if fewer are unused. The
// `heap_use` event names each entry (`ids`, `entries` by `n`) so a screen shows which.
// "Copy the highest-tier unit in your Compost" (Old Stump, Elder Mother): marks the highest-tier
// entry not yet used this fight and returns it ({"id", "tier", "n"}), or {} with nothing marked
// when none is left. Right when the heap changes mid-fight: marks name entries, not a count.
// Entries still in the heap and not yet marked used this fight.
// Takes the highest entry (CardHeap.take_highest); &"" when empty.
// "Your slots give double Attack this fight" (SHARED-RULES 13): the side's slots give `percent`
// of their stored Attack buff for the rest of the fight, even if `source` dies. Two don't stack:
// the bigger applies. Logged as `slot_percent`; every unit whose Attack changes gets `stats`.
// The Attack the slot gives this fight: its stored buff at the fight's percent (what a unit
// there gets, and what anything that reads a slot's Attack buff should read).
// A slot as a screen shows it in a fight: the stored buff and keywords, plus `given_attack`
// (what it gives at this fight's percent) and the `percent`.
// 8.5 a slot buff, and optionally a keyword the slot gives. This fight only, unless
// `permanent` and this side writes back (8.5.2).
// Sets a slot's buff to these values, unscaled (a copy is not a buff given: Colour Ensign,
// SHARED-RULES 12). This fight only, unless `permanent` and this side writes back.
// Clears a keyword from a slot (moving a Guard post): this fight, or for good.
// 11.1.1 a unit gains a keyword (a mechanic with no parameters): this fight, or for good.
// A unit gains a mechanic with parameters ("+2 Fury" onto a unit with none: Sett Sexton,
// Sword-heir): this fight, or also on the recruit unit when `permanent` and this side writes
// back. `raw` holds its parameters as card data does; the numbers are the giver's, never doubled
// by a golden target. Its on_combat_begin runs; logged as `effect`. False when unknown or bad.
// Gold earned in the fight, paid at the start of the next turn; nothing for a copy side.
// Heap name -> its size, for the fight log.
pub type FightSideRef = Rc<RefCell<FightSide>>;
pub struct FightSide {
    pub index: i64,
    pub player: Option<PlayerStateRef>,
    pub writes_back: bool,
    pub counters: Dictionary,
    pub heaps: Dictionary<CardHeapRef>,
    pub slots: Array<SlotStateRef>,
    pub standing: Array<BoundMechanicRef>,
    pub deaths: i64,
    pub state: Dictionary,
    pub used: Dictionary<Array<i64>>,
    pub slot_attack_percent: i64,
    pub _combat_ref: Option<Weak<RefCell<Combat>>>,
}
impl Default for FightSide {
    fn default() -> Self {
        Self {
            index: 0,
            player: None,
            writes_back: false,
            counters: Default::default(),
            heaps: Default::default(),
            slots: Array::new(),
            standing: Array::new(),
            deaths: 0,
            state: Default::default(),
            used: Default::default(),
            slot_attack_percent: 100,
            _combat_ref: None,
        }
    }
}
impl ToState for FightSide {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "index" => &self.index,
            "player" => &self.player,
            "writes_back" => &self.writes_back,
            "counters" => &self.counters,
            "heaps" => &self.heaps,
            "slots" => &self.slots,
            "standing" => &self.standing,
            "deaths" => &self.deaths,
            "state" => &self.state,
            "used" => &self.used,
            "slot_attack_percent" => &self.slot_attack_percent,
            "_combat_ref" => &if self._combat_ref.is_some() { Variant::dictionary(Default::default()) } else { Variant::Nil },
        }
    }
    fn field_names() -> &'static [&'static str] {
        &["index", "player", "writes_back", "counters", "heaps", "slots", "standing", "deaths", "state", "used", "slot_attack_percent", "_combat_ref"]
    }
}
impl FightSide {
    pub fn create(combat: &CombatRef, side: i64, owner: Option<&PlayerStateRef>, live: bool, slot_count: i64) -> FightSideRef {
        todo!("port src/core/combat/fight_side.gd:create")
    }
    pub fn _combat(&self) -> Option<CombatRef> {
        self._combat_ref.as_ref().and_then(Weak::upgrade)
    }
    pub fn recruit_unit(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>) -> Option<UnitRef> {
        todo!("port src/core/combat/fight_side.gd:recruit_unit")
    }
    pub fn real_unit(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>) -> Option<UnitRef> {
        todo!("port src/core/combat/fight_side.gd:real_unit")
    }
    pub fn counter(&self, combat: &mut Combat, key: &str) -> i64 {
        todo!("port src/core/combat/fight_side.gd:counter")
    }
    pub fn add_counter(&mut self, combat: &mut Combat, key: &str, amount: i64, source: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/fight_side.gd:add_counter")
    }
    pub fn add_unit_counter(&mut self, combat: &mut Combat, unit: Option<&CombatUnitRef>, key: &str, amount: i64, permanent: bool, source: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/fight_side.gd:add_unit_counter")
    }
    pub fn heap(&mut self, combat: &mut Combat, heap_name: &str) -> CardHeapRef {
        todo!("port src/core/combat/fight_side.gd:heap")
    }
    pub fn heap_add(&mut self, combat: &mut Combat, heap_name: &str, card_id: &str, tier: i64, source: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/fight_side.gd:heap_add")
    }
    pub fn heap_spend(&mut self, combat: &mut Combat, heap_name: &str, count: i64, source: Option<&CombatUnitRef>) -> bool {
        todo!("port src/core/combat/fight_side.gd:heap_spend")
    }
    pub fn heap_use(&mut self, combat: &mut Combat, heap_name: &str, count: i64, source: Option<&CombatUnitRef>) -> bool {
        todo!("port src/core/combat/fight_side.gd:heap_use")
    }
    pub fn heap_use_highest(&mut self, combat: &mut Combat, heap_name: &str, source: Option<&CombatUnitRef>) -> Dictionary {
        todo!("port src/core/combat/fight_side.gd:heap_use_highest")
    }
    pub fn heap_unused(&mut self, combat: &mut Combat, heap_name: &str) -> i64 {
        todo!("port src/core/combat/fight_side.gd:heap_unused")
    }
    pub fn _mark(&mut self, combat: &mut Combat, heap_name: &str) -> Dictionary {
        todo!("port src/core/combat/fight_side.gd:_mark")
    }
    pub fn _log_use(&mut self, combat: &mut Combat, heap_name: &str, marked: &Array<Dictionary>, source: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/fight_side.gd:_log_use")
    }
    pub fn heap_take(&mut self, combat: &mut Combat, heap_name: &str, source: Option<&CombatUnitRef>) -> String {
        todo!("port src/core/combat/fight_side.gd:heap_take")
    }
    pub fn _heap_removed(&mut self, combat: &mut Combat, heap_name: &str, ids: &Array<String>, source: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/fight_side.gd:_heap_removed")
    }
    pub fn slot(&mut self, combat: &mut Combat, slot_index: i64) -> SlotStateRef {
        todo!("port src/core/combat/fight_side.gd:slot")
    }
    pub fn set_slot_attack_percent(&mut self, combat: &mut Combat, percent: i64, source: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/fight_side.gd:set_slot_attack_percent")
    }
    pub fn slot_attack_given(&mut self, combat: &mut Combat, slot_index: i64) -> i64 {
        todo!("port src/core/combat/fight_side.gd:slot_attack_given")
    }
    pub fn slot_view(&mut self, combat: &mut Combat, slot_index: i64) -> Dictionary {
        todo!("port src/core/combat/fight_side.gd:slot_view")
    }
    pub fn slot_buff(&mut self, combat: &mut Combat, slot_index: i64, attack: i64, health: i64, permanent: bool, source: Option<&CombatUnitRef>, keyword: &str) {
        todo!("port src/core/combat/fight_side.gd:slot_buff")
    }
    pub fn slot_set(&mut self, combat: &mut Combat, slot_index: i64, attack: i64, health: i64, permanent: bool, source: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/fight_side.gd:slot_set")
    }
    pub fn slot_clear_keyword(&mut self, combat: &mut Combat, slot_index: i64, keyword: &str, permanent: bool, source: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/fight_side.gd:slot_clear_keyword")
    }
    pub fn _log_slot(&mut self, combat: &mut Combat, slot_index: i64, attack: i64, health: i64, lasting: bool, source: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/fight_side.gd:_log_slot")
    }
    pub fn give_keyword(&mut self, combat: &mut Combat, unit: Option<&CombatUnitRef>, keyword: &str, permanent: bool, source: Option<&CombatUnitRef>) -> bool {
        todo!("port src/core/combat/fight_side.gd:give_keyword")
    }
    pub fn give_effect(&mut self, combat: &mut Combat, unit: Option<&CombatUnitRef>, mechanic_id: &str, raw: &Dictionary, permanent: bool, source: Option<&CombatUnitRef>) -> bool {
        todo!("port src/core/combat/fight_side.gd:give_effect")
    }
    pub fn add_gold(&mut self, combat: &mut Combat, amount: i64, source: Option<&CombatUnitRef>) {
        todo!("port src/core/combat/fight_side.gd:add_gold")
    }
    pub fn heap_sizes(&self, combat: &mut Combat) -> Dictionary {
        todo!("port src/core/combat/fight_side.gd:heap_sizes")
    }
    pub fn state_int(&self, combat: &mut Combat, key: &str) -> i64 {
        todo!("port src/core/combat/fight_side.gd:state_int")
    }
    pub fn set_state(&mut self, combat: &mut Combat, key: &str, value: i64) {
        todo!("port src/core/combat/fight_side.gd:set_state")
    }
    pub fn new() -> Self { Self::default() }
}
