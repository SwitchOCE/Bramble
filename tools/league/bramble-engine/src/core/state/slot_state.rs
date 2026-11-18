#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/state/slot_state.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

// GDScript rule and contract comments:
// Effects held by one board slot (rulebook 8.5): a stat buff and keywords that whatever unit
// stands in the slot has (a Guard post is a slot keyword). They stay when the
// unit moves, is sold or dies (8.5.1). A fight works on copies (8.5.2); "permanently" writes
// to both.
// Keyword mechanic ids the unit in this slot has.
pub type SlotStateRef = Rc<RefCell<SlotState>>;
pub struct SlotState {
    pub attack: i64,
    pub health: i64,
    pub keywords: Array<String>,
}
impl Default for SlotState {
    fn default() -> Self {
        Self {
            attack: 0,
            health: 0,
            keywords: Array::new(),
        }
    }
}
impl ToState for SlotState {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "attack" => &self.attack,
            "health" => &self.health,
            "keywords" => &self.keywords,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &["attack", "health", "keywords"]
    }
}
impl SlotState {
    pub fn duplicate_slot(&self) -> SlotStateRef {
        Rc::new(RefCell::new(Self {
            attack: self.attack,
            health: self.health,
            keywords: self.keywords.duplicate(),
        }))
    }
    pub fn view(&self) -> Dictionary {
        if let Variant::Dictionary(out) = self.to_state() {
            out
        } else {
            unreachable!()
        }
    }
    pub fn new() -> Self {
        Self::default()
    }
}
