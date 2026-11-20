#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/state/slot_state.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

// GDScript rule and contract comments:
// Effects held by one board slot (rulebook 8.5): its Renown and keywords the unit standing
// there has (a Guard post is a slot keyword). They stay when the unit moves, is sold or
// dies (8.5.1). A fight works on copies (8.5.2); "permanently" writes to both.
// Renown gained in a fight goes to the real slot only (FightSide.add_renown).
// Keyword mechanic ids the unit in this slot has.
pub type SlotStateRef = Rc<RefCell<SlotState>>;
pub struct SlotState {
    pub keywords: Array<String>,
    /// Permanent +1/+1 per point for starters and reservists.
    pub renown: i64,
}
impl Default for SlotState {
    fn default() -> Self {
        Self {
            keywords: Array::new(),
            renown: 0,
        }
    }
}
impl ToState for SlotState {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "keywords" => &self.keywords,
            "renown" => &self.renown,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &["keywords", "renown"]
    }
}
impl SlotState {
    pub fn duplicate_slot(&self) -> SlotStateRef {
        Rc::new(RefCell::new(Self {
            keywords: self.keywords.duplicate(),
            renown: self.renown,
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
