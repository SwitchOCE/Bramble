//! Validation and restoration mirror gd/fight_run.gd, including first-error order and text.
use bramble_engine::core::{
    mechanics::{
        bound_mechanic::BoundMechanic, mechanic_params::MechanicParams,
        mechanic_registry::MechanicRegistry,
    },
    records::{fight_snapshot::FightSnapshot, record_state::RecordState},
    session::game_session::GameSession,
    state::card_heap::CardHeap,
};
use bramble_engine::game::game_content::GameContent;
use bramble_engine::util::godot_json;
use bramble_engine::{Dictionary, Variant};
use sha2::{Digest, Sha256};
use std::{cell::RefCell, collections::HashSet, rc::Rc};

const MAX_EXACT: i64 = 9_007_199_254_740_991;

pub fn error(id: i64, problem: &str) -> Dictionary {
    let out = Dictionary::new();
    out.insert("id", id.into());
    out.insert("error", problem.into());
    out
}

fn integer(raw: &Variant, low: i64, high: i64) -> bool {
    let number = match raw {
        Variant::Int(value) => *value as f64,
        Variant::Float(value) => *value,
        _ => return false,
    };
    number.is_finite() && number == number.floor() && number >= low as f64 && number <= high as f64
}

fn numbers(raw: &Variant) -> bool {
    let Variant::Dictionary(fields) = raw else {
        return false;
    };
    fields
        .borrow()
        .values()
        .all(|value| integer(value, -MAX_EXACT, MAX_EXACT))
}

pub fn validate(saved: &Dictionary, content: &GameContent) -> Result<(), String> {
    if !integer(&saved.get("id"), 0, MAX_EXACT) {
        return Err("id must be a nonnegative integer".into());
    }
    let seed = saved.get("game_seed");
    if !matches!(&seed, Variant::String(text) if text.parse::<i64>().is_ok_and(|n| n.to_string() == *text))
    {
        return Err("game_seed must be canonical signed int64 decimal text".into());
    }
    if !integer(&saved.get("round"), 1, 50) {
        return Err("round must be in 1..50".into());
    }
    if !matches!(saved.get("mutations"), Variant::Array(values) if values.borrow().iter().all(|v| matches!(v, Variant::String(_))))
    {
        return Err("mutations must be an array of strings".into());
    }
    let mut seen = HashSet::new();
    for side in ["a", "b"] {
        let Variant::Dictionary(payload) = saved.get(side) else {
            return Err(format!("{side}: missing player payload"));
        };
        validate_player(&payload, &mut seen, content)
            .map_err(|problem| format!("{side}: {problem}"))?;
    }
    if saved.get("a").as_dict().get("id").as_i64() == saved.get("b").as_dict().get("id").as_i64() {
        return Err("a and b must have distinct player ids".into());
    }
    Ok(())
}

fn validate_player(
    saved: &Dictionary,
    seen: &mut HashSet<i64>,
    content: &GameContent,
) -> Result<(), String> {
    if !integer(&saved.get("id"), 0, 7) || !integer(&saved.get("tier"), 1, 6) {
        return Err("id must be in 0..7 and tier in 1..6 (ghosts unsupported)".into());
    }
    for key in ["board", "hand", "slots", "standing"] {
        if !matches!(saved.get(key), Variant::Array(_)) {
            return Err(format!("{key} must be an array"));
        }
    }
    let board = saved.get("board").as_array();
    let slots = saved.get("slots").as_array();
    let hand = saved.get("hand").as_array();
    if board.len() != 7 || slots.len() != 7 || hand.len() > 7 {
        return Err("expected 7 board slots, 7 slot states, and at most 7 hand cards".into());
    }
    for key in ["board", "hand"] {
        for raw in saved.get(key).as_array().to_vec() {
            if raw == Variant::Nil && key == "board" {
                continue;
            }
            let Variant::Dictionary(unit) = raw else {
                return Err(format!("{key}: expected unit object"));
            };
            validate_unit(&unit, seen, key == "board", content)
                .map_err(|problem| format!("{key}: {problem}"))?;
        }
    }
    for raw in slots.to_vec() {
        let Variant::Dictionary(slot) = raw else {
            return Err("slot must be an object".into());
        };
        if !integer(&slot.get("attack"), 0, MAX_EXACT)
            || !integer(&slot.get("health"), 0, MAX_EXACT)
        {
            return Err("slot stats must be nonnegative integers".into());
        }
        let Variant::Array(keywords) = slot.get("keywords") else {
            return Err("slot keywords must be an array".into());
        };
        for keyword in keywords.to_vec() {
            if !matches!(&keyword, Variant::String(id) if content.registry.borrow().has(id)) {
                return Err("unknown slot keyword".into());
            }
            if !content
                .registry
                .borrow()
                .kinds_of(&keyword.as_text())
                .is_empty()
            {
                return Err("slot keyword requires parameters".into());
            }
        }
    }
    if !numbers(&saved.get("counters")) {
        return Err("counters must be an integer dictionary".into());
    }
    let Variant::Dictionary(heaps) = saved.get("heaps") else {
        return Err("heaps must be an object".into());
    };
    for (key, raw) in heaps.borrow().iter() {
        if !MechanicRegistry::name_problem(&content.registry.borrow().prefixes, key, "heap")
            .is_empty()
        {
            return Err("heap name must have a content prefix".into());
        }
        let Variant::Dictionary(heap) = raw else {
            return Err("heap must be an object".into());
        };
        if !integer(&heap.get("_next_n"), 1, MAX_EXACT)
            || !matches!(heap.get("entries"), Variant::Array(_))
        {
            return Err("heap requires entries and positive _next_n".into());
        }
        let mut previous = 0;
        for raw in heap.get("entries").as_array().to_vec() {
            let Variant::Dictionary(entry) = raw else {
                return Err("heap entry must be an object".into());
            };
            let card = content
                .library
                .borrow()
                .get_card(&entry.get_or("id", "".into()).as_text());
            if card.as_ref().is_none_or(|card| {
                let card = card.borrow();
                card.is_spell() || !integer(&entry.get("tier"), card.tier, card.tier)
            }) {
                return Err("heap entry requires a valid unit card id and its exact tier".into());
            }
            if !integer(
                &entry.get("n"),
                previous + 1,
                heap.get("_next_n").as_i64() - 1,
            ) {
                return Err("heap entry n must increase and be below _next_n".into());
            }
            previous = entry.get("n").as_i64();
        }
    }
    for raw in saved.get("standing").as_array().to_vec() {
        let Variant::Dictionary(bound) = raw else {
            return Err("standing effect must be an object".into());
        };
        if !content
            .registry
            .borrow()
            .has(&bound.get_or("id", "".into()).as_text())
        {
            return Err("unknown standing effect".into());
        }
        if !matches!(bound.get("granted"), Variant::Bool(_))
            || !matches!(bound.get("params"), Variant::Dictionary(_))
        {
            return Err("standing effect requires granted and params".into());
        }
        let params = bound.get("params").as_dict();
        if !matches!(params.get("golden"), Variant::Bool(_))
            || !matches!(params.get("_texts"), Variant::Dictionary(_))
        {
            return Err("invalid standing parameter fields".into());
        }
        for key in ["_ints", "_kinds", "_golden_ints"] {
            if !numbers(&params.get(key)) {
                return Err("invalid standing parameter fields".into());
            }
        }
        for value in params.get("_texts").as_dict().borrow().values() {
            if !matches!(value, Variant::String(_)) {
                return Err("standing text parameter must be text".into());
            }
        }
    }
    Ok(())
}

fn validate_unit(
    saved: &Dictionary,
    seen: &mut HashSet<i64>,
    on_board: bool,
    content: &GameContent,
) -> Result<(), String> {
    let card = content
        .library
        .borrow()
        .get_card(&saved.get_or("def", "".into()).as_text());
    if card
        .as_ref()
        .is_none_or(|card| on_board && card.borrow().is_spell())
    {
        return Err("unknown card or board spell".into());
    }
    if !integer(&saved.get("uid"), 1, MAX_EXACT) || !matches!(saved.get("golden"), Variant::Bool(_))
    {
        return Err("unit requires positive uid and boolean golden".into());
    }
    let uid = saved.get("uid").as_i64();
    if !seen.insert(uid) {
        return Err(format!("duplicate uid {uid}"));
    }
    if saved.has("bought_copies") && !integer(&saved.get("bought_copies"), 0, MAX_EXACT) {
        return Err("bought_copies must be a nonnegative integer".into());
    }
    for key in ["stats", "counters", "turn_counters"] {
        if saved.has(key) && !numbers(&saved.get(key)) {
            return Err(format!("{key} must be an integer dictionary"));
        }
    }
    for key in saved.get("stats").as_dict().borrow().keys() {
        if !FightSnapshot::LAYERS.contains(&key.as_str()) {
            return Err(format!("unknown stat layer: {key}"));
        }
    }
    for key in ["grants", "aura_grants"] {
        if saved.has(key) && !matches!(saved.get(key), Variant::Array(_)) {
            return Err(format!("{key} must be an array"));
        }
        for raw in saved.get(key).as_array().to_vec() {
            let Variant::Array(entry) = raw else {
                return Err("grant must be an array".into());
            };
            if entry.is_empty() || entry.len() > 2 {
                return Err("grant must contain an id and optional values".into());
            }
            let id = entry.get(0).unwrap().as_text();
            if !content.registry.borrow().has(&id) {
                return Err("unknown granted mechanic".into());
            }
            if entry.len() == 2 && !matches!(entry.get(1), Some(Variant::Dictionary(_))) {
                return Err("grant values must be an object".into());
            }
            if (entry.len() == 2 || key == "aura_grants")
                && content
                    .registry
                    .borrow()
                    .bind_given(&id, &entry.get(1).unwrap_or_default().as_dict())
                    .is_none()
            {
                return Err("invalid granted mechanic parameters".into());
            }
        }
    }
    Ok(())
}

pub fn restore_player(game: &mut GameSession, saved: &Dictionary) {
    let owner = game.player(saved.get("id").as_i64());
    owner.borrow_mut().tier = saved.get("tier").as_i64();
    // All counter values are validated scalars; duplicating the dictionary is a deep copy.
    owner.borrow_mut().counters = saved.get("counters").as_dict().duplicate();
    for (slot, raw) in saved
        .get("board")
        .as_array()
        .to_vec()
        .into_iter()
        .enumerate()
    {
        if raw != Variant::Nil {
            let card = FightSnapshot::restore_unit(&raw.as_dict(), game, slot as i64);
            game._next_uid = game._next_uid.max(card.borrow().uid + 1);
            owner.borrow().board.borrow_mut()[slot] = Some(card);
        }
    }
    for raw in saved.get("hand").as_array().to_vec() {
        let card = FightSnapshot::restore_unit(&raw.as_dict(), game, -1);
        game._next_uid = game._next_uid.max(card.borrow().uid + 1);
        owner.borrow().hand.push(card);
    }
    for (i, raw) in saved
        .get("slots")
        .as_array()
        .to_vec()
        .into_iter()
        .enumerate()
    {
        let saved_slot = raw.as_dict();
        let slot = owner.borrow().slots.get(i).unwrap();
        slot.borrow_mut().attack = saved_slot.get("attack").as_i64();
        slot.borrow_mut().health = saved_slot.get("health").as_i64();
        for keyword in saved_slot.get("keywords").as_array().to_vec() {
            slot.borrow().keywords.push(keyword.as_text());
        }
    }
    for (key, raw) in saved.get("heaps").as_dict().borrow().iter() {
        let raw = raw.as_dict();
        let mut heap = CardHeap::new();
        heap._next_n = raw.get("_next_n").as_i64();
        for raw in raw.get("entries").as_array().to_vec() {
            let entry = raw.as_dict();
            let restored = Dictionary::new();
            restored.insert("id", entry.get("id").as_text().into());
            restored.insert("tier", entry.get("tier").as_i64().into());
            restored.insert("n", entry.get("n").as_i64().into());
            heap.entries.push(restored);
        }
        owner
            .borrow()
            .heaps
            .borrow_mut()
            .insert(key.clone(), Rc::new(RefCell::new(heap)));
    }
    owner.borrow().standing.clear();
    for raw in saved.get("standing").as_array().to_vec() {
        let raw = raw.as_dict();
        let fields = raw.get("params").as_dict();
        let params = MechanicParams::new();
        {
            let mut params = params.borrow_mut();
            params.golden = matches!(fields.get("golden"), Variant::Bool(true));
            params._ints = integer_fields(&fields.get("_ints").as_dict());
            params._kinds = integer_fields(&fields.get("_kinds").as_dict());
            params._golden_ints = integer_fields(&fields.get("_golden_ints").as_dict());
            params._texts = fields
                .get("_texts")
                .as_dict()
                .borrow()
                .iter()
                .map(|(key, value)| (key.clone(), value.as_text()))
                .collect();
        }
        let id = raw.get("id").as_text();
        let registry = game.registry.as_ref().expect("session registry");
        owner.borrow().standing.push(BoundMechanic::new(
            &id,
            registry.borrow().get_mechanic(&id),
            params,
            matches!(raw.get("granted"), Variant::Bool(true)),
        ));
    }
}

fn integer_fields(raw: &Dictionary) -> Dictionary<i64> {
    raw.borrow()
        .iter()
        .map(|(key, value)| (key.clone(), value.as_i64()))
        .collect()
}

pub fn result(id: i64, fight: &Dictionary, game: &GameSession) -> Dictionary {
    let result = fight.get("result").as_dict();
    let state = godot_json::stringify(&Variant::Dictionary(RecordState::session_state(game)));
    let hash = format!("{:x}", Sha256::digest(state.as_bytes()));
    let out = Dictionary::new();
    out.insert("id", id.into());
    out.insert("winner", result.get("winner"));
    out.insert("loser", fight.get("loser"));
    out.insert("damage", fight.get("damage"));
    out.insert("reason", result.get("reason"));
    out.insert("state", state.into());
    out.insert("hash", hash.into());
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use bramble_engine::Array;
    use std::path::Path;

    fn content() -> bramble_engine::game::game_content::GameContentRef {
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
        GameContent::load_folders(&root, &Array::new())
    }

    fn fixture() -> Dictionary {
        let player = |id| {
            let out = Dictionary::new();
            out.insert("id", Variant::Int(id));
            out.insert("tier", 1i64.into());
            out.insert("board", Variant::array(vec![Variant::Nil; 7]));
            out.insert("hand", Variant::array(vec![]));
            out.insert(
                "slots",
                Variant::array(
                    (0..7)
                        .map(|_| {
                            godot_json::parse_string(r#"{"attack":0,"health":0,"keywords":[]}"#)
                        })
                        .collect(),
                ),
            );
            out.insert("standing", Variant::array(vec![]));
            out.insert("counters", Variant::Dictionary(Dictionary::new()));
            out.insert("heaps", Variant::Dictionary(Dictionary::new()));
            Variant::Dictionary(out)
        };
        let out = Dictionary::new();
        out.insert("id", 0i64.into());
        out.insert("game_seed", "-9223372036854775808".into());
        out.insert("round", 1i64.into());
        out.insert("mutations", Variant::array(vec![]));
        out.insert("a", player(3));
        out.insert("b", player(7));
        out
    }

    #[test]
    fn rejects_noncanonical_seeds_and_unsafe_numbers_in_source_order() {
        let content = content();
        for seed in ["+1", "01", "-0", "9223372036854775808", " 1"] {
            let saved = fixture();
            saved.insert("game_seed", seed.into());
            assert_eq!(
                validate(&saved, &content.borrow()).unwrap_err(),
                "game_seed must be canonical signed int64 decimal text"
            );
        }
        let saved = fixture();
        saved.insert("id", Variant::Float(9_007_199_254_740_992.0));
        assert_eq!(
            validate(&saved, &content.borrow()).unwrap_err(),
            "id must be a nonnegative integer"
        );
        assert!(validate(&fixture(), &content.borrow()).is_ok());
    }

    #[test]
    fn uid_uniqueness_spans_both_boards_and_hands() {
        let saved = fixture();
        let unit = godot_json::parse_string(r#"{"def":"t1_plain","uid":41,"golden":true}"#);
        saved
            .get("a")
            .as_dict()
            .get("board")
            .as_array()
            .borrow_mut()[4] = unit.clone();
        saved.get("b").as_dict().get("hand").as_array().push(unit);
        assert_eq!(
            validate(&saved, &content().borrow()).unwrap_err(),
            "b: hand: duplicate uid 41"
        );
    }

    #[test]
    fn restoration_preserves_slots_defaults_and_uid_floor_without_running_hooks() {
        let content = content();
        let game = content.borrow().new_session(42, &Array::new());
        let saved = fixture().get("a").as_dict();
        saved.get("board").as_array().borrow_mut()[5] =
            godot_json::parse_string(r#"{"def":"t1_plain","uid":17,"golden":true}"#);
        saved.get("hand").as_array().push(godot_json::parse_string(
            r#"{"def":"t1_plain","uid":1000,"golden":false}"#,
        ));
        restore_player(&mut game.borrow_mut(), &saved);
        assert_eq!(game.borrow()._next_uid, 1001);
        let player = game.borrow().player(3);
        let card = player.borrow().board.get(5).unwrap().unwrap();
        assert_eq!(card.borrow().slot, 5);
        assert_eq!(
            card.borrow().stats.as_ref().unwrap().borrow().base_attack,
            4
        );
        assert_eq!(player.borrow().health, 40);
        assert_eq!(player.borrow().hand.get(0).unwrap().borrow().slot, -1);
        assert_eq!(
            player
                .borrow()
                .board
                .borrow()
                .iter()
                .filter(|u| u.is_some())
                .count(),
            1
        );
    }
}
