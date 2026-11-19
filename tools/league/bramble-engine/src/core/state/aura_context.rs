#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/state/aura_context.gd`; gameplay TODO bodies belong to the later port workers.
use crate::core::board::board_geometry::BoardGeometryRef;
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::state::card_heap::CardHeapRef;

use crate::core::units::unit_def::UnitDefRef;

// GDScript rule and contract comments:
// What an aura may read (12.2.1) in either phase: the board it sits on, each unit's numbers
// as they stand, the fixed Outnumbered count in a fight, and its player's lasting numbers and
// heaps. Rebuilt whenever auras are
// recalculated, so an aura that reads any of these follows them.
// The unit defs on this board by slot (null for an empty slot).
// The player's lasting numbers (PlayerState.counters, or the fight's copy).
// The player's heaps by name (CardHeap).
// Each slot's unit's lasting numbers (Unit.counters; Medals), {} for an empty slot.
// Outnumbered: fixed at fight start (Combat.outnumbered_by); 0 outside a fight.
// Each slot's unit's numbers as they stand (Attack, maximum Health, Health), for auras that lend
// a unit's own total (Lends): read them with attack_at, max_health_at, health_at.
// Set when an aura read stats: the core then runs the aura pass a second time on the totals.
// A number on the unit in `slot` (Unit.counters), 0 if none.
// The Attack of the unit in `slot` as it stands (its slot's buff, doubling and other auras
// included), 0 for an empty slot. Lends: "extra Attack equal to this unit's Attack".
// The maximum Health of the unit in `slot` as it stands (slot buff and auras included).
// The current Health of the unit in `slot` (maximum Health less damage in a fight).
pub type AuraContextRef = Rc<RefCell<AuraContext>>;
pub struct AuraContext {
    pub geometry: Option<BoardGeometryRef>,
    pub defs: Array<Option<UnitDefRef>>,
    pub reservist_slots: Array<i64>,
    pub in_combat: bool,
    pub counters: Dictionary,
    pub heaps: Dictionary<CardHeapRef>,
    pub unit_counters: Array<Dictionary>,
    pub outnumbered_by: i64,
    pub stats: Array<[i64; 3]>,
    pub read_stats: bool,
}
impl Default for AuraContext {
    fn default() -> Self {
        Self {
            geometry: None,
            defs: Array::new(),
            reservist_slots: Array::new(),
            in_combat: false,
            counters: Default::default(),
            heaps: Default::default(),
            unit_counters: Array::new(),
            outnumbered_by: 0,
            stats: Array::new(),
            read_stats: false,
        }
    }
}
impl ToState for AuraContext {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "geometry" => &self.geometry,
            "defs" => &self.defs,
            "reservist_slots" => &self.reservist_slots,
            "in_combat" => &self.in_combat,
            "counters" => &self.counters,
            "heaps" => &self.heaps,
            "unit_counters" => &self.unit_counters,
            "outnumbered_by" => &self.outnumbered_by,
            "stats" => &self.stats,
            "read_stats" => &self.read_stats,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "geometry",
            "defs",
            "reservist_slots",
            "in_combat",
            "counters",
            "heaps",
            "unit_counters",
            "outnumbered_by",
            "stats",
            "read_stats",
        ]
    }
}
impl AuraContext {
    pub fn own_count(&self) -> i64 {
        self.defs
            .borrow()
            .iter()
            .filter(|def| def.is_some())
            .count() as i64
    }
    pub fn count_tribe(&self, tribe: &str) -> i64 {
        self.defs
            .borrow()
            .iter()
            .filter(|def| {
                def.as_ref()
                    .is_some_and(|def| def.borrow().has_tribe(tribe))
            })
            .count() as i64
    }
    pub fn def_at(&self, slot: i64) -> Option<UnitDefRef> {
        if slot < 0 {
            None
        } else {
            self.defs.get(slot as usize).flatten()
        }
    }
    pub fn unit_counter(&self, slot: i64, key: &str) -> i64 {
        if slot < 0 {
            0
        } else {
            self.unit_counters
                .get(slot as usize)
                .map_or(0, |counters| counters.get(key).as_i64())
        }
    }
    pub fn counter(&self, key: &str) -> i64 {
        self.counters.get(key).as_i64()
    }
    pub fn heap_size(&self, heap_name: &str) -> i64 {
        self.heaps
            .borrow()
            .get(heap_name)
            .map_or(0, |heap| heap.borrow().size())
    }
    pub fn attack_at(&mut self, slot: i64) -> i64 {
        self._stat(slot)[0]
    }
    pub fn max_health_at(&mut self, slot: i64) -> i64 {
        self._stat(slot)[1]
    }
    pub fn health_at(&mut self, slot: i64) -> i64 {
        self._stat(slot)[2]
    }
    pub fn _stat(&mut self, slot: i64) -> [i64; 3] {
        self.read_stats = true;
        if slot < 0 {
            [0, 0, 0]
        } else {
            self.stats.get(slot as usize).unwrap_or([0, 0, 0])
        }
    }
    pub fn new() -> Self {
        Self::default()
    }
}
