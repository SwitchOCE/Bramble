//! Mirrors src/core/units/shop_odds.gd.
use super::unit_def::UnitDefRef;
use crate::core::util::rng::RngRef;
use crate::{Array, ToState, Variant};
use indexmap::IndexMap;
use std::rc::Rc;

pub type ShopOddsRef = Rc<ShopOdds>;

#[derive(Default)]
pub struct ShopOdds {
    _order: Vec<String>,
    _tiers: IndexMap<String, i64>,
    _weights: IndexMap<String, i64>,
}

impl ShopOdds {
    // Empty lobby_tribes permits all tribes.
    pub fn create(
        cards: &Array<UnitDefRef>,
        weights_by_tier: &Array<i64>,
        lobby_tribes: &Array<String>,
    ) -> ShopOddsRef {
        let mut odds = Self::default();
        let weights_by_tier = weights_by_tier.borrow();
        for card in cards.borrow().iter() {
            let tier = card.borrow().tier;
            if tier < 1
                || tier > weights_by_tier.len() as i64
                || !Self::_in_lobby(card, lobby_tribes)
            {
                continue;
            }
            let weight = weights_by_tier[tier as usize - 1];
            if weight <= 0 {
                continue;
            }
            let id = &card.borrow().id;
            odds._order.push(id.clone());
            odds._tiers.insert(id.clone(), tier);
            odds._weights.insert(id.clone(), weight);
        }
        Rc::new(odds)
    }

    pub fn _in_lobby(card: &UnitDefRef, lobby_tribes: &Array<String>) -> bool {
        let card = card.borrow();
        lobby_tribes.is_empty()
            || card.tribes.is_empty()
            || lobby_tribes
                .borrow()
                .iter()
                .any(|tribe| card.has_tribe(tribe))
    }

    pub fn weight_of(&self, card_id: &str) -> i64 {
        self._weights.get(card_id).copied().unwrap_or(0)
    }

    // Pick by fixed weight. Discover excludes the ids already offered.
    pub fn draw(
        &self,
        min_tier: i64,
        max_tier: i64,
        rng: &RngRef,
        exclude: &Array<String>,
    ) -> String {
        let exclude = exclude.borrow();
        let mut total = 0_i64;
        for card_id in &self._order {
            let tier = self._tiers[card_id];
            if tier >= min_tier && tier <= max_tier && !exclude.contains(card_id) {
                total = total.wrapping_add(self._weights[card_id]);
            }
        }
        if total == 0 {
            return String::new();
        }
        let mut pick = rng.borrow_mut().range_int(0, total.wrapping_sub(1));
        for card_id in &self._order {
            let tier = self._tiers[card_id];
            if tier < min_tier || tier > max_tier || exclude.contains(card_id) {
                continue;
            }
            let weight = self._weights[card_id];
            if pick < weight {
                return card_id.clone();
            }
            pick -= weight;
        }
        String::new()
    }
}

impl ToState for ShopOdds {
    fn to_state(&self) -> Variant {
        crate::state_dict! {"_order"=>&self._order,"_tiers"=>&self._tiers,"_weights"=>&self._weights}
    }

    fn field_names() -> &'static [&'static str] {
        &["_order", "_tiers", "_weights"]
    }
}

impl ToState for ShopOddsRef {
    fn to_state(&self) -> Variant {
        self.as_ref().to_state()
    }
}
