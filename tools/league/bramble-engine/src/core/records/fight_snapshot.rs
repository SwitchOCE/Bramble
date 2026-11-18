#![allow(unused_variables)]
//! Mirrors src/core/records/fight_snapshot.gd.
use crate::core::{
    mechanics::bound_mechanic::BoundMechanicRef,
    session::game_session::GameSession,
    units::{stat_block::StatBlock, unit::UnitRef},
};
use crate::{Array, Dictionary, ToState, Variant};
pub struct FightSnapshot;
impl FightSnapshot {
    pub const LAYERS: &'static [&'static str] = &[
        "base_attack",
        "base_health",
        "set_attack",
        "set_health",
        "perm_attack",
        "perm_health",
        "turn_attack",
        "turn_health",
        "combat_attack",
        "combat_health",
        "aura_attack",
        "aura_health",
        "slot_attack",
        "slot_health",
    ];
    pub fn units(cards: &Array<Option<UnitRef>>) -> Array<Variant> {
        cards
            .borrow()
            .iter()
            .map(|c| {
                c.as_ref()
                    .map_or(Variant::Nil, |c| Variant::Dictionary(Self::unit(c)))
            })
            .collect()
    }
    pub fn unit(card: &UnitRef) -> Dictionary {
        let card = card.borrow();
        let def = card.def.as_ref().expect("unit definition").borrow();
        let out =
            crate::state_dict! {"def"=>&def.id,"uid"=>&card.uid,"golden"=>&card.golden}.as_dict();
        let layers = Dictionary::new();
        let stats = card
            .stats
            .as_ref()
            .expect("unit stats")
            .borrow()
            .to_state()
            .as_dict();
        for key in Self::LAYERS {
            let default = if key.starts_with("base_") {
                (if *key == "base_attack" {
                    def.attack
                } else {
                    def.health
                }) * if card.golden { 2 } else { 1 }
            } else if key.starts_with("set_") {
                StatBlock::UNSET
            } else {
                0
            };
            let actual = stats.get(key).as_i64();
            if actual != default {
                layers.insert(*key, actual.into());
            }
        }
        if !layers.is_empty() {
            out.insert("stats", Variant::Dictionary(layers));
        }
        if card.from_triple {
            out.insert("from_triple", true.into());
        }
        if card.bought_copies != 0 {
            out.insert("bought_copies", card.bought_copies.into());
        }
        if card.pool_copies != 0 {
            out.insert("pool_copies", card.pool_copies.into());
        }
        if !card.counters.is_empty() {
            out.insert("counters", card.counters.to_state());
        }
        if !card.turn_counters.is_empty() {
            out.insert("turn_counters", card.turn_counters.to_state());
        }
        let added: Array<Variant> = card
            .mechanics
            .borrow()
            .iter()
            .filter(|b| b.borrow().granted)
            .map(|b| Variant::Array(Self::_effect(b)))
            .collect();
        if !added.is_empty() {
            out.insert("grants", Variant::Array(added));
        }
        if !card.aura_mechanics.is_empty() {
            out.insert(
                "aura_grants",
                Variant::Array(
                    card.aura_mechanics
                        .borrow()
                        .iter()
                        .map(|b| Variant::Array(Self::_effect(b)))
                        .collect(),
                ),
            );
        }
        out
    }
    pub fn restore_unit(saved: &Dictionary, game: &mut GameSession, slot: i64) -> UnitRef {
        todo!("port src/core/records/fight_snapshot.gd:restore_unit")
    }
    pub fn _effect(effect: &BoundMechanicRef) -> Array<Variant> {
        let effect = effect.borrow();
        let out = Array::from(vec![Variant::from(effect.id.clone())]);
        let applied = effect.params.borrow().to_dict();
        if !applied.is_empty() {
            out.push(Variant::Dictionary(applied));
        }
        out
    }
}
impl ToState for FightSnapshot {
    fn to_state(&self) -> Variant {
        crate::state_dict! {}
    }
}
