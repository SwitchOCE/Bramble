#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/board/selectors.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::board::board_geometry::BoardGeometryRef;

// GDScript rule and contract comments:
// The selector library (prototype lesson: write each positional selector once). A selector
// names a set of occupied slots on the same board as `slot`, in reading order. Both phases
// use it: the recruit board and each side of a combat.
// self, adjacent, behind, in_front, neighbours, front_row, back_row, all, others
// `slot` is the source's slot (or last-known slot, 12.2.3); -1 means no slot, for which only
// the board-wide selectors find anything.
pub type SelectorsRef = Rc<RefCell<Selectors>>;
pub struct Selectors {}
impl Default for Selectors {
    fn default() -> Self {
        Self {}
    }
}
impl ToState for Selectors {
    fn to_state(&self) -> Variant {
        Variant::dictionary(Default::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Selectors {
    pub const NAMES: &'static [&'static str] = &[
        "self",
        "adjacent",
        "behind",
        "in_front",
        "neighbours",
        "front_row",
        "back_row",
        "all",
        "others",
    ];
    pub fn is_known(selector: &str) -> bool {
        Self::NAMES.contains(&selector)
    }
    pub fn slots(
        geometry: &BoardGeometryRef,
        slot: i64,
        occupied: &Array<bool>,
        selector: &str,
    ) -> Array<i64> {
        let geometry = geometry.borrow();
        let has_slot = geometry.is_valid(slot);
        let candidates = match selector {
            "self" if has_slot => Array::from(vec![slot]),
            "adjacent" if has_slot => geometry.adjacent(slot),
            "behind" if has_slot => geometry.behind(slot),
            "in_front" if has_slot => geometry.in_front_of(slot),
            "neighbours" if has_slot => geometry.neighbours(slot),
            "front_row" => geometry.front.duplicate(),
            "back_row" => geometry.back.duplicate(),
            "all" | "others" => (0..geometry.slot_count)
                .filter(|other| selector == "all" || *other != slot)
                .collect(),
            _ => Array::new(),
        };
        let occupied = occupied.borrow();
        let mut out: Vec<i64> = candidates
            .borrow()
            .iter()
            .copied()
            .filter(|candidate| occupied[*candidate as usize])
            .collect();
        crate::util::godot_sort::sort(&mut out);
        out.into()
    }
    pub fn new() -> Self {
        Self::default()
    }
}
