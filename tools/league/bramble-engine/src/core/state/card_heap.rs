#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/state/card_heap.gd`; gameplay TODO bodies belong to the later port workers.
use std::{cell::RefCell, rc::{Rc, Weak}};
use crate::{Array, Dictionary, ToState, Variant};

// GDScript rule and contract comments:
// A player's named list of card entries kept for the game (a pile, a graveyard, a heap that
// cards count or spend from). Entries are card ids with their tier, oldest first. Entries hold
// no pool copies: adding never takes from the pool and spending never gives back.
// Each entry: {"id": StringName, "tier": int, "n": int}. `n` names the entry for the game (a
// fight marks entries by it, FightSide.heap_use), so it stays right when others come and go.
// The highest-tier entry whose `n` is not in `skip`, newest first on a tie; {} if none.
// Removes the `count` lowest-tier entries, oldest first on a tie. With fewer than `count`
// entries nothing is removed and the result is empty. Returns the removed ids.
// Removes and returns the highest-tier entry, newest first on a tie; &"" when empty.
// JSON-shaped: entries oldest first.
pub type CardHeapRef = Rc<RefCell<CardHeap>>;
pub struct CardHeap {
    pub entries: Array<Dictionary>,
    pub _next_n: i64,
}
impl Default for CardHeap {
    fn default() -> Self {
        Self {
            entries: Array::new(),
            _next_n: 1,
        }
    }
}
impl ToState for CardHeap {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "entries" => &self.entries,
            "_next_n" => &self._next_n,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &["entries", "_next_n"]
    }
}
impl CardHeap {
    pub fn size(&self) -> i64 {
        self.entries.len() as i64
    }
    pub fn add(&mut self, card_id: &str, tier: i64) {
        let entry = Dictionary::new();
        entry.insert("id", Variant::String(card_id.to_string()));
        entry.insert("tier", Variant::Int(tier));
        entry.insert("n", Variant::Int(self._next_n));
        self.entries.push(entry);
        self._next_n += 1;
    }
    pub fn highest_except(&self, skip: &Array<Variant>) -> Dictionary {
        let mut best = Dictionary::new();
        for entry in self.entries.borrow().iter().rev() {
            let n = entry.get("n").as_i64();
            if skip.borrow().iter().any(|value| value.as_i64() == n) { continue; }
            if best.is_empty() || entry.get("tier").as_i64() > best.get("tier").as_i64() { best = entry.clone(); }
        }
        best
    }
    pub fn spend_lowest(&mut self, count: i64) -> Array<String> {
        let out = Array::new();
        if count <= 0 || count > self.entries.len() as i64 { return out; }
        for _ in 0..count {
            let mut best = 0;
            for i in 0..self.entries.len() { if self._tier(i as i64) < self._tier(best as i64) { best = i; } }
            out.push(self.entries.borrow()[best].get("id").as_text());
            self.entries.borrow_mut().remove(best);
        }
        out
    }
    pub fn take_highest(&mut self) -> String {
        if self.entries.is_empty() { return String::new(); }
        let mut best = self.entries.len() - 1;
        for i in (0..self.entries.len()).rev() { if self._tier(i as i64) > self._tier(best as i64) { best = i; } }
        let card_id = self.entries.borrow()[best].get("id").as_text();
        self.entries.borrow_mut().remove(best);
        card_id
    }
    pub fn _tier(&self, index: i64) -> i64 {
        self.entries.borrow()[index as usize].get("tier").as_i64()
    }
    pub fn duplicate_heap(&self) -> CardHeapRef {
        Rc::new(RefCell::new(Self { _next_n:self._next_n, entries:self.entries.borrow().iter().map(Dictionary::duplicate).collect() }))
    }
    pub fn view(&self) -> Array<Variant> {
        self.entries.borrow().iter().map(|entry| crate::state_dict! { "id"=>&entry.get("id"), "tier"=>&entry.get("tier") }).collect()
    }
    pub fn new() -> Self { Self::default() }
}
