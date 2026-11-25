//! Restore the two snapshots into a private session with the original fight's identity.
use super::input::{Fight, integer};
use bramble_engine::core::{
    recruit::player_state::PlayerState,
    session::{game_session::GameSession, matchmaking::Matchmaking},
};
use bramble_engine::game::game_content::GameContentRef;
use bramble_engine::util::godot_json;
use bramble_engine::{Array, Dictionary, Variant};
use league_api::harness;
use serde_json::Value;
use std::panic::{AssertUnwindSafe, catch_unwind};

#[derive(Debug)]
pub(super) enum Skip {
    MissingCard(String),
    Payload(String),
}

impl Skip {
    pub fn message(&self) -> &str {
        match self {
            Self::MissingCard(text) | Self::Payload(text) => text,
        }
    }
}

pub(super) fn units(payload: &Dictionary, key: &str) -> Result<Array<Variant>, String> {
    match payload.get(key) {
        Variant::Array(units) => Ok(units),
        _ => Err(format!("missing or invalid {key}")),
    }
}

pub(super) fn card_id(unit: &Dictionary) -> Result<String, String> {
    match unit.get("def") {
        Variant::String(id) if !id.is_empty() => Ok(id),
        _ => Err("unit has no card id".into()),
    }
}

pub(super) struct Outcome {
    pub winner: Option<i64>,
    pub damage: i64,
    pub result: Value,
}

pub(super) fn fight(
    content: &GameContentRef,
    seed: i64,
    round: i64,
    original: &Fight,
    payloads: &[Dictionary; 2],
    verify: bool,
) -> Result<Outcome, Skip> {
    let content = content.borrow();
    let game = GameSession::create(
        seed,
        &content.library,
        &content.registry,
        None,
        &Array::new(),
    );
    let [a, b] = original.players;
    // Each snapshot is consumed by a single fight. Mutations made by combat stay in this session.
    let result = catch_unwind(AssertUnwindSafe(|| {
        let mut session = game.borrow_mut();
        session.round_number = round;
        session.keep_fight_events = false;
        let slot_count = session.geometry.as_ref().unwrap().borrow().slot_count;
        for (id, payload) in original.players.into_iter().zip(payloads) {
            validate_payload(&session, payload, slot_count)?;
            if id == Matchmaking::GHOST {
                let Some(of) = integer(&payload.get("of"))
                    .filter(|&id| id >= 0 && Some(id) == original.ghost_of)
                else {
                    return Err(Skip::Payload(
                        "ghost source differs from games.jsonl".into(),
                    ));
                };
                let owner = PlayerState::create(of, slot_count, 0, 0);
                owner.borrow_mut().alive = false;
                harness::restore_payload_for(&mut session, payload, &owner);
                session.ghost_board = owner.borrow().board.clone();
                session.ghost_hand = owner.borrow().hand.clone();
                session.ghost_tier = owner.borrow().tier;
                session.ghost_of = of;
                session.ghost_player = Some(owner);
            } else {
                harness::restore_payload(&mut session, payload);
            }
        }
        drop(session);
        // _fight derives the seed from the game seed, round and ordered ids (including -1).
        Ok(GameSession::_fight(&game, a, b))
    }))
    .map_err(|e| Skip::Payload(harness::panic_text(&e)))??;
    let combat = result.get("result");
    let winner = match combat.as_dict().get("winner").as_i64() {
        0 => Some(a),
        1 => Some(b),
        _ => None,
    };
    let combat = if verify {
        serde_json::from_str(&godot_json::stringify(&combat))
            .map_err(|e| Skip::Payload(format!("invalid combat result: {e}")))?
    } else {
        Value::Null
    };
    Ok(Outcome {
        winner,
        damage: result.get("damage").as_i64(),
        result: combat,
    })
}

fn validate_payload(game: &GameSession, payload: &Dictionary, slot_count: i64) -> Result<(), Skip> {
    let player = payload.get("id").as_i64();
    let invalid = |reason: &str| Skip::Payload(format!("player {player}: {reason}"));
    let board = units(payload, "board").map_err(|e| invalid(&e))?;
    let hand = units(payload, "hand").map_err(|e| invalid(&e))?;
    let slots = units(payload, "slots").map_err(|e| invalid(&e))?;
    if board.len() != slot_count as usize || slots.len() != slot_count as usize {
        return Err(invalid(&format!(
            "expected {slot_count} board positions and slots"
        )));
    }
    if !matches!(integer(&payload.get("tier")), Some(1..))
        || !matches!(payload.get("counters"), Variant::Dictionary(_))
    {
        return Err(invalid("invalid tier or counters"));
    }
    let library = game.library.as_ref().unwrap().borrow();
    let registry = game.registry.as_ref().unwrap().borrow();
    for (key, cards) in [("board", board), ("hand", hand)] {
        for (i, unit) in cards.to_vec().into_iter().enumerate() {
            let unit = match unit {
                Variant::Dictionary(unit) => unit,
                Variant::Nil if key == "board" => continue,
                _ => return Err(invalid(&format!("invalid {key}[{i}]"))),
            };
            let id = card_id(&unit).map_err(|e| invalid(&e))?;
            if library.get_card(&id).is_none() {
                return Err(Skip::MissingCard(format!(
                    "player {player}: missing card {id} in {key}[{i}]"
                )));
            }
            if !integer(&unit.get("uid")).is_some_and(|uid| (1..i64::MAX).contains(&uid))
                || !matches!(unit.get("golden"), Variant::Bool(_))
            {
                return Err(invalid(&format!("invalid uid or golden flag for {id}")));
            }
            for field in ["stats", "counters", "turn_counters"] {
                if unit.has(field) && !matches!(unit.get(field), Variant::Dictionary(_)) {
                    return Err(invalid(&format!("invalid {field} for {id}")));
                }
            }
            for field in ["grants", "aura_grants"] {
                if !unit.has(field) {
                    continue;
                }
                for entry in units(&unit, field).map_err(|e| invalid(&e))?.to_vec() {
                    let grant = entry.as_array();
                    let effect = grant.get(0).unwrap_or_default().as_text();
                    let valid = match (field, grant.len(), grant.get(1)) {
                        ("grants", 1, _) => registry.has(&effect),
                        (_, 1, _) => registry.bind_given(&effect, &Dictionary::new()).is_some(),
                        (_, 2, Some(Variant::Dictionary(params))) => {
                            registry.bind_given(&effect, &params).is_some()
                        }
                        _ => false,
                    };
                    if !valid {
                        return Err(invalid(&format!(
                            "cannot restore {field} effect {effect:?} for {id}"
                        )));
                    }
                }
            }
        }
    }
    for raw in slots.to_vec() {
        let slot = raw.as_dict();
        for keyword in units(&slot, "keywords").map_err(|e| invalid(&e))?.to_vec() {
            if !registry.has(&keyword.as_text()) {
                return Err(invalid(&format!(
                    "unknown slot keyword {:?}",
                    keyword.as_text()
                )));
            }
        }
    }
    let Variant::Dictionary(heaps) = payload.get("heaps") else {
        return Err(invalid("missing or invalid heaps"));
    };
    for (key, heap) in heaps.borrow().iter() {
        let heap = heap.as_dict();
        if integer(&heap.get("_next_n")).is_none() {
            return Err(invalid(&format!("invalid heap {key}")));
        }
        for entry in units(&heap, "entries").map_err(|e| invalid(&e))?.to_vec() {
            let entry = entry.as_dict();
            let Variant::String(id) = entry.get("id") else {
                return Err(invalid(&format!("invalid card id in heap {key}")));
            };
            if id.is_empty()
                || integer(&entry.get("tier")).is_none()
                || integer(&entry.get("n")).is_none()
            {
                return Err(invalid(&format!("invalid entry in heap {key}")));
            }
            if library.get_card(&id).is_none() {
                return Err(Skip::MissingCard(format!(
                    "player {player}: missing card {id} in heap {key}"
                )));
            }
        }
    }
    for effect in units(payload, "standing")
        .map_err(|e| invalid(&e))?
        .to_vec()
    {
        let effect = effect.as_dict();
        let id = effect.get("id").as_text();
        if !registry.has(&id) || !matches!(effect.get("params"), Variant::Dictionary(_)) {
            return Err(invalid(&format!("cannot restore standing effect {id:?}")));
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn missing_cards_and_bad_payloads_are_classified() {
        let content = crate::load_content(&crate::default_root(), Some("standin")).unwrap();
        let session = content.borrow().new_session(11, &Array::new());
        let a = harness::fight_payload(&session.borrow().player(0).borrow());
        let b = harness::fight_payload(&session.borrow().player(1).borrow());
        let original = Fight {
            players: [0, 1],
            ghost_of: None,
            winner: None,
            damage: 0,
            result: Value::Null,
        };
        a.get("hand").as_array().push(godot_json::parse_string(
            r#"{"def":"removed-card","uid":1,"golden":false}"#,
        ));
        let payloads = [a, b];
        assert!(matches!(
            fight(&content, 11, 1, &original, &payloads, false),
            Err(Skip::MissingCard(reason)) if reason.contains("removed-card")
        ));
        payloads[0].insert("slots", Variant::Nil);
        assert!(matches!(
            fight(&content, 11, 1, &original, &payloads, false),
            Err(Skip::Payload(reason)) if reason.contains("slots")
        ));
    }
}
