//! Mirrors src/core/units/card_pool.gd.
use super::unit_def::UnitDefRef;
use crate::core::util::rng::RngRef;
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
pub type CardPoolRef = Rc<RefCell<CardPool>>;
#[derive(Default)]
pub struct CardPool {
    pub _copies: Dictionary<i64>,
    pub _start: Dictionary<i64>,
    pub _tiers: Dictionary<i64>,
    pub _order: Array<String>,
}
impl CardPool {
    // 5.1.2's row for this kind of card; empty lobby_tribes permits all tribes.
    pub fn create(
        cards: &Array<UnitDefRef>,
        copies_by_tier: &Array<i64>,
        lobby_tribes: &Array<String>,
    ) -> CardPoolRef {
        let pool = Self::default();
        for card in cards.borrow().iter() {
            if !Self::_in_lobby(card, lobby_tribes) {
                continue;
            }
            let card = card.borrow();
            let copies = if card.tier <= copies_by_tier.len() as i64 {
                copies_by_tier.borrow()[(card.tier - 1) as usize]
            } else {
                0
            };
            pool._order.push(card.id.clone());
            pool._tiers.borrow_mut().insert(card.id.clone(), card.tier);
            pool._copies.borrow_mut().insert(card.id.clone(), copies);
            pool._start.borrow_mut().insert(card.id.clone(), copies);
        }
        Rc::new(RefCell::new(pool))
    }
    pub fn _in_lobby(card: &UnitDefRef, lobby_tribes: &Array<String>) -> bool {
        let c = card.borrow();
        lobby_tribes.is_empty()
            || c.tribes.is_empty()
            || lobby_tribes.borrow().iter().any(|t| c.has_tribe(t))
    }
    pub fn ids(&self) -> Array<String> {
        self._order.duplicate()
    }
    pub fn has_card(&self, id: &str) -> bool {
        self._copies.borrow().contains_key(id)
    }
    pub fn copies_left(&self, id: &str) -> i64 {
        self._copies.borrow().get(id).copied().unwrap_or(0)
    }
    pub fn starting_copies(&self, id: &str) -> i64 {
        self._start.borrow().get(id).copied().unwrap_or(0)
    }
    pub fn tier_of(&self, id: &str) -> i64 {
        self._tiers.borrow().get(id).copied().unwrap_or(0)
    }
    pub fn eligible_copies(&self, min_tier: i64, max_tier: i64, exclude: &Array<String>) -> i64 {
        let mut total = 0;
        for id in self._order.borrow().iter() {
            let tier = self.tier_of(id);
            if tier >= min_tier && tier <= max_tier && !exclude.borrow().contains(id) {
                total += self.copies_left(id);
            }
        }
        total
    }
    // 6.1.3: uniformly choose a copy, not a distinct card. 6.2.2 excludes prior choices.
    pub fn draw(
        &mut self,
        min_tier: i64,
        max_tier: i64,
        rng: &RngRef,
        exclude: &Array<String>,
    ) -> String {
        let total = self.eligible_copies(min_tier, max_tier, exclude);
        if total <= 0 {
            return String::new();
        }
        let mut pick = rng.borrow_mut().range_int(0, total - 1);
        for id in self._order.borrow().iter() {
            let tier = self.tier_of(id);
            if tier < min_tier || tier > max_tier || exclude.borrow().contains(id) {
                continue;
            }
            let count = self.copies_left(id);
            if pick < count {
                self._copies.borrow_mut().insert(id.clone(), count - 1);
                return id.clone();
            }
            pick -= count;
        }
        String::new()
    }
    pub fn take(&mut self, id: &str) -> bool {
        let n = self.copies_left(id);
        if n <= 0 {
            return false;
        }
        self._copies.borrow_mut().insert(id.into(), n - 1);
        true
    }
    // 5.3, 5.3.6: ignore cards the pool never held.
    pub fn give_back(&mut self, id: &str, count: i64) {
        if !self.has_card(id) || count <= 0 {
            return;
        }
        let n = self.copies_left(id);
        self._copies.borrow_mut().insert(id.into(), n + count);
    }
    pub fn total_left(&self) -> i64 {
        self._order
            .borrow()
            .iter()
            .map(|id| self.copies_left(id))
            .sum()
    }
}
impl ToState for CardPool {
    fn to_state(&self) -> Variant {
        crate::state_dict! {"_copies"=>&self._copies,"_start"=>&self._start,"_tiers"=>&self._tiers,"_order"=>&self._order}
    }
    fn field_names() -> &'static [&'static str] {
        &["_copies", "_start", "_tiers", "_order"]
    }
}
