#![allow(unused_variables)]
//! Mirrors src/core/records/fight_snapshot.gd.
use crate::core::{
    mechanics::bound_mechanic::BoundMechanicRef,
    session::game_session::GameSession,
    units::{
        stat_block::StatBlock,
        unit::{Unit, UnitRef},
    },
    util::core_util::CoreUtil,
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
        "renown",
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
        let stats = card.stats.as_ref().expect("unit stats").borrow();
        // These i64 fields are the same values as stats.to_state()[key], in
        // LAYERS order; read them directly without allocating a full state dictionary.
        let values = [
            stats.base_attack,
            stats.base_health,
            stats.set_attack,
            stats.set_health,
            stats.perm_attack,
            stats.perm_health,
            stats.turn_attack,
            stats.turn_health,
            stats.combat_attack,
            stats.combat_health,
            stats.aura_attack,
            stats.aura_health,
            stats.slot_attack,
            stats.slot_health,
            stats.renown,
        ];
        for (key, actual) in Self::LAYERS.iter().zip(values) {
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
            if actual != default {
                layers.insert(*key, actual.into());
            }
        }
        drop(stats);
        if !layers.is_empty() {
            out.insert("stats", Variant::Dictionary(layers));
        }
        if card.bought_copies != 0 {
            out.insert("bought_copies", card.bought_copies.into());
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
        let registry = game.registry.as_ref().expect("session registry");
        let card = game
            .library
            .as_ref()
            .expect("session library")
            .borrow()
            .get_card(&saved.get("def").as_text())
            .expect("snapshot definition");
        let restored = Unit::create(
            &card,
            saved.get("uid").as_i64(),
            CoreUtil::to_bool(&saved.get("golden")),
            registry,
            game.config
                .as_ref()
                .expect("session config")
                .borrow()
                .stat_max,
        );
        {
            let mut unit = restored.borrow_mut();
            unit.slot = slot;
            if saved.has("bought_copies") {
                unit.bought_copies = saved.get("bought_copies").as_i64();
            }
            for (key, value) in saved.get("counters").as_dict().borrow().iter() {
                unit.counters.insert(key, value.clone());
            }
            if saved.has("turn_counters") {
                unit.turn_counters = saved.get("turn_counters").as_dict();
            }
            let mut stats = unit.stats.as_ref().expect("unit stats").borrow_mut();
            for (key, value) in saved.get("stats").as_dict().borrow().iter() {
                let target = match key.as_str() {
                    "base_attack" => &mut stats.base_attack,
                    "base_health" => &mut stats.base_health,
                    "set_attack" => &mut stats.set_attack,
                    "set_health" => &mut stats.set_health,
                    "perm_attack" => &mut stats.perm_attack,
                    "perm_health" => &mut stats.perm_health,
                    "turn_attack" => &mut stats.turn_attack,
                    "turn_health" => &mut stats.turn_health,
                    "combat_attack" => &mut stats.combat_attack,
                    "combat_health" => &mut stats.combat_health,
                    "aura_attack" => &mut stats.aura_attack,
                    "aura_health" => &mut stats.aura_health,
                    "slot_attack" => &mut stats.slot_attack,
                    "slot_health" => &mut stats.slot_health,
                    "renown" => &mut stats.renown,
                    _ => continue,
                };
                *target = value.as_i64();
            }
        }
        for raw in saved.get("grants").as_array().to_vec() {
            let entry = raw.as_array();
            let id = entry.get(0).expect("grant id").as_text();
            if entry.len() == 1 {
                restored.borrow_mut().grant(registry, &id);
            } else {
                restored
                    .borrow_mut()
                    .grant_effect(registry, &id, &entry.get(1).unwrap().as_dict());
            }
        }
        for raw in saved.get("aura_grants").as_array().to_vec() {
            let entry = raw.as_array();
            let id = entry.get(0).expect("aura grant id").as_text();
            let values = entry.get(1).unwrap_or_default().as_dict();
            let effect = registry
                .borrow()
                .bind_given(&id, &values)
                .expect("aura grant binding");
            restored.borrow().aura_mechanics.push(effect);
        }
        restored
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{game::game_content::GameContent, util::godot_json};
    use std::path::Path;

    #[test]
    fn snapshot_direct_layers_match_full_state_lookup() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
        let content = GameContent::load_folders(&root, &Array::new());
        let game = content.borrow().new_session(42, &Array::new());
        let card = content
            .borrow()
            .library
            .borrow()
            .get_card("t1_plain")
            .unwrap();
        for golden in [false, true] {
            let unit = game.borrow_mut().new_unit(&card, golden);
            // Distinct values make swapped or omitted layer reads observable.
            {
                let u = unit.borrow();
                let mut stats = u.stats.as_ref().unwrap().borrow_mut();
                stats.base_attack = 101;
                stats.base_health = 102;
                stats.set_attack = 103;
                stats.set_health = 104;
                stats.perm_attack = 105;
                stats.perm_health = 106;
                stats.turn_attack = 107;
                stats.turn_health = 108;
                stats.combat_attack = 109;
                stats.combat_health = 110;
                stats.aura_attack = 111;
                stats.aura_health = 112;
                stats.slot_attack = 113;
                stats.slot_health = 114;
                stats.renown = 115;
            }
            let saved = FightSnapshot::unit(&unit);
            let state = unit
                .borrow()
                .stats
                .as_ref()
                .unwrap()
                .borrow()
                .to_state()
                .as_dict();
            let expected_layers = Dictionary::new();
            for key in FightSnapshot::LAYERS {
                expected_layers.insert(*key, state.get(key));
            }
            let actual_layers = saved.get("stats").as_dict();
            assert_eq!(
                actual_layers.borrow().keys().collect::<Vec<_>>(),
                expected_layers.borrow().keys().collect::<Vec<_>>()
            );
            assert_eq!(actual_layers, expected_layers, "golden={golden}");
        }
    }

    #[test]
    fn snapshots_round_trip_every_card_without_allocating_uids() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
        let content = GameContent::load_default(&root);
        let game = content.borrow().new_session(42, &Array::new());
        let ids = content.borrow().library.borrow().ids();
        for id in ids.to_vec() {
            let card = content.borrow().library.borrow().get_card(&id).unwrap();
            for golden in [false, true] {
                let unit = game.borrow_mut().new_unit(&card, golden);
                {
                    let mut u = unit.borrow_mut();
                    u.slot = 3;
                    u.bought_copies = 2;
                    u.counters.insert("lasting", 7.into());
                    u.turn_counters.insert("turn", 4.into());
                    u.stats.as_ref().unwrap().borrow_mut().perm_health = 17;
                    u.stats.as_ref().unwrap().borrow_mut().set_attack = 5;
                    let registry = game.borrow().registry.clone().unwrap();
                    u.grant(&registry, "taunt");
                    assert!(u.grant_effect(
                        &registry,
                        "kill_gain",
                        &crate::state_dict! {"attack"=>&3_i64,"health"=>&2_i64}.as_dict(),
                    ));
                    u.aura_mechanics.push(
                        registry
                            .borrow()
                            .bind_given("windfury", &Dictionary::new())
                            .unwrap(),
                    );
                }
                let saved = FightSnapshot::unit(&unit);
                let before_uid = game.borrow()._next_uid;
                let restored = FightSnapshot::restore_unit(&saved, &mut game.borrow_mut(), 3);
                assert_eq!(game.borrow()._next_uid, before_uid);
                assert_eq!(
                    godot_json::stringify(&unit.to_state()),
                    godot_json::stringify(&restored.to_state()),
                    "{id}, golden={golden}"
                );
                let units = FightSnapshot::units(&Array::from(vec![None, Some(unit)]));
                assert_eq!(units.get(0), Some(Variant::Nil));
                assert_eq!(units.get(1), Some(Variant::Dictionary(saved)));
            }
        }
    }
}
