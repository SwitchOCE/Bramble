//! Mirrors src/core/ghosts/ghost_run.gd. A run's ID covers the original file bytes.
use crate::core::{
    mechanics::mechanic_registry::MechanicRegistry, records::fight_snapshot::FightSnapshot,
    units::unit_library::UnitLibrary,
};
use crate::{Dictionary, ToState, Variant, util::godot_json};
use indexmap::{IndexMap, IndexSet};
use sha2::{Digest, Sha256};
use std::path::Path;

const MAX_JSON_INT: i64 = 9_007_199_254_740_991;
pub type RunsBySeat = IndexMap<i64, GhostRun>;

#[derive(Clone)]
pub struct GhostRun {
    id: String,
    payloads: IndexMap<i64, Dictionary>,
}

impl GhostRun {
    pub const FORMAT: i64 = 1;
    pub const UID_STRIDE: i64 = 1_000_000;

    pub fn read(
        path: &Path,
        library: Option<&UnitLibrary>,
        registry: Option<&MechanicRegistry>,
    ) -> Result<Self, String> {
        let bytes = std::fs::read(path)
            .map_err(|error| format!("cannot open run file {}: {error}", path.display()))?;
        Self::parse(&bytes, library, registry)
    }

    pub fn fetch(
        store: &Path,
        id: &str,
        library: Option<&UnitLibrary>,
        registry: Option<&MechanicRegistry>,
    ) -> Result<Self, String> {
        let load = || {
            if !hex(&Variant::from(id), 64) || id.bytes().any(|byte| byte.is_ascii_uppercase()) {
                return Err("invalid SHA-256 ID".into());
            }
            let path = store.join("runs").join(&id[..2]).join(format!("{id}.json"));
            let bytes = std::fs::read(&path)
                .map_err(|error| format!("cannot open {}: {error}", path.display()))?;
            if hash(&bytes) != id {
                return Err("SHA-256 mismatch".into());
            }
            Self::validated(&bytes, library, registry, id.to_owned())
        };
        load().map_err(|problem| format!("run {id}: {problem}"))
    }

    pub fn parse(
        bytes: &[u8],
        library: Option<&UnitLibrary>,
        registry: Option<&MechanicRegistry>,
    ) -> Result<Self, String> {
        Self::validated(bytes, library, registry, hash(bytes))
    }

    fn validated(
        bytes: &[u8],
        library: Option<&UnitLibrary>,
        registry: Option<&MechanicRegistry>,
        id: String,
    ) -> Result<Self, String> {
        let decoded = std::str::from_utf8(bytes).map_err(|_| "run file must be UTF-8")?;
        // Godot's UTF-8 conversion strips a leading BOM and ends at a raw NUL.
        if decoded.starts_with('\u{feff}') || decoded.contains('\0') {
            return Err("run file must be UTF-8".into());
        }
        let parsed = godot_json::try_parse(decoded).ok_or("invalid run JSON")?;
        let Variant::Dictionary(data) = parsed else {
            return Err("run file must contain one JSON object".into());
        };
        header_problem(&data, library)?;
        let final_turn = data.get("last_turn").as_i64();
        let seat = data.get("source").as_dict().get("seat").as_i64();
        let cards = data.get("cards").as_dict();
        let mut held_cards = IndexSet::new();
        let mut payloads = IndexMap::new();
        for raw in data.get("turns").as_array().borrow().iter() {
            let turn = raw.as_dict();
            let number = turn.get("turn");
            if !integer(&number, 1, final_turn) {
                return Err(format!(
                    "turns entries require a turn number in 1..{final_turn}"
                ));
            }
            let number = number.as_i64();
            if payloads.contains_key(&number) {
                return Err(format!("duplicate turn {number}"));
            }
            turn_problem(&turn, seat, &mut held_cards, library, registry)
                .map_err(|problem| format!("turn {number}: {problem}"))?;
            payloads.insert(number, turn.get("payload").as_dict());
        }
        if payloads.len() as i64 != final_turn {
            let missing = (1..=payloads.len() as i64 + 1)
                .find(|number| !payloads.contains_key(number))
                .expect("gap in run turns");
            return Err(format!(
                "missing turn {missing} (expected every turn in 1..{final_turn})"
            ));
        }
        for card_id in &held_cards {
            if !cards.has(card_id) {
                return Err(format!("cards is missing fingerprint for {card_id}"));
            }
        }
        for card_id in cards.borrow().keys() {
            if !held_cards.contains(card_id) {
                return Err(format!(
                    "cards lists {card_id}, which never appears on the board or in hand"
                ));
            }
        }
        Ok(Self { id, payloads })
    }

    pub fn id(&self) -> &str {
        &self.id
    }

    pub fn last_turn(&self) -> i64 {
        self.payloads.len() as i64
    }

    pub fn turn_for_round(&self, round_number: i64) -> i64 {
        round_number.clamp(0, self.last_turn())
    }

    pub fn payload_for_round(&self, round_number: i64) -> Dictionary {
        self.payloads
            .get(&self.turn_for_round(round_number))
            .map_or_else(Dictionary::new, |payload| {
                Variant::Dictionary(payload.clone())
                    .duplicate_deep()
                    .as_dict()
            })
    }

    pub fn reason_for_round(&self, round_number: i64) -> &'static str {
        if round_number < 1 {
            ""
        } else if round_number <= self.last_turn() {
            "same_turn"
        } else {
            "run_ended"
        }
    }
}

pub(crate) fn runs_state(runs: &RunsBySeat) -> Variant {
    Variant::Dictionary(
        runs.iter()
            .map(|(seat, run)| (seat.to_string(), run.to_state()))
            .collect(),
    )
}

impl ToState for GhostRun {
    fn to_state(&self) -> Variant {
        let payloads: Dictionary = self
            .payloads
            .iter()
            .map(|(turn, payload)| (turn.to_string(), payload.to_state()))
            .collect();
        crate::state_dict! {"_id"=>&self.id, "_payloads"=>&payloads }
    }
}

fn hash(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}

fn header_problem(data: &Dictionary, library: Option<&UnitLibrary>) -> Result<(), String> {
    if !integer(&data.get("format"), GhostRun::FORMAT, GhostRun::FORMAT) {
        return Err(format!("expected run format {}", GhostRun::FORMAT));
    }
    let Variant::Dictionary(rules) = data.get("rules") else {
        return Err("rules must be an object".into());
    };
    if !hex(&rules.get("rules_hash"), 64) {
        return Err("rules.rules_hash must be a SHA-256 hex string".into());
    }
    for key in ["version", "revision", "engine"] {
        if !matches!(rules.get(key), Variant::String(_)) {
            return Err(format!("rules.{key} must be text"));
        }
    }
    if !matches!(data.get("patch"), Variant::String(_)) {
        return Err("patch must be text".into());
    }
    for key in ["content", "tribes"] {
        if !strings(&data.get(key)) {
            return Err(format!("{key} must be an array of strings"));
        }
    }
    let Variant::Dictionary(source) = data.get("source") else {
        return Err("source must be an object".into());
    };
    source_problem(&source)?;
    if !nonempty_text(&data.get("made")) {
        return Err("made must be nonempty text".into());
    }
    if !integer(&data.get("placement"), 0, 8) {
        return Err("placement must be an integer in 0..8".into());
    }
    if !matches!(data.get("ended"), Variant::String(value) if ["eliminated", "won", "round_limit", "unfinished"].contains(&value.as_str()))
    {
        return Err("ended must be eliminated, won, round_limit or unfinished".into());
    }
    if !integer(&data.get("last_turn"), 1, MAX_JSON_INT) {
        return Err("last_turn must be a positive integer".into());
    }
    let Variant::Dictionary(cards) = data.get("cards") else {
        return Err("turns must be an array and cards must be an object".into());
    };
    if !matches!(data.get("turns"), Variant::Array(_)) {
        return Err("turns must be an array and cards must be an object".into());
    }
    for (card_id, fingerprint) in cards.borrow().iter() {
        if card_id.is_empty() || !hex(fingerprint, 16) {
            return Err("cards requires card ids and 16-digit hex fingerprints".into());
        }
        if library.is_some_and(|lib| !lib.has(card_id)) {
            return Err(format!("unknown card '{card_id}' in cards"));
        }
    }
    Ok(())
}

fn source_problem(source: &Dictionary) -> Result<(), String> {
    if !matches!(source.get("kind"), Variant::String(value) if ["bot", "player", "internal", "tester", "test_realm"].contains(&value.as_str()))
    {
        return Err("source.kind must be bot, player, internal, tester or test_realm".into());
    }
    for key in ["label", "player"] {
        if !matches!(source.get(key), Variant::String(_)) {
            return Err(format!("source.{key} must be text"));
        }
    }
    let rating = source.get("rating");
    if !source.has("rating") || (rating != Variant::Nil && number(&rating).is_none()) {
        return Err("source.rating must be a number or null".into());
    }
    if !hex(&source.get("record_sha256"), 64) {
        return Err("source.record_sha256 must be a SHA-256 hex string".into());
    }
    if !matches!(source.get("record_mode"), Variant::String(mode) if mode == "live" || mode == "async")
    {
        return Err("source.record_mode must be live or async".into());
    }
    if !matches!(source.get("game_seed"), Variant::String(seed) if seed.parse::<i64>().is_ok_and(|n| n.to_string() == seed))
    {
        return Err("source.game_seed must be canonical signed int64 decimal text".into());
    }
    if !integer(&source.get("seat"), 0, 7) {
        return Err("source.seat must be in 0..7".into());
    }
    Ok(())
}

fn turn_problem(
    turn: &Dictionary,
    seat: i64,
    held_cards: &mut IndexSet<String>,
    library: Option<&UnitLibrary>,
    registry: Option<&MechanicRegistry>,
) -> Result<(), String> {
    let tier = turn.get("tier");
    if !integer(&tier, 1, 6) {
        return Err("tier must be in 1..6".into());
    }
    for key in ["health", "armor", "gold"] {
        if !integer(&turn.get(key), 0, MAX_JSON_INT) {
            return Err(format!("{key} must be a nonnegative integer"));
        }
    }
    let Variant::Array(acts) = turn.get("acts") else {
        return Err("acts must be an array".into());
    };
    for raw in acts.borrow().iter() {
        let act = raw.as_dict();
        if !matches!(act.get("action"), Variant::Dictionary(_))
            || !matches!(act.get("result"), Variant::String(_))
        {
            return Err("acts entries require an action object and a result string".into());
        }
    }
    let Variant::Dictionary(payload) = turn.get("payload") else {
        return Err("payload must be an object".into());
    };
    let tier = tier.as_i64();
    if !integer(&payload.get("id"), seat, seat) || !integer(&payload.get("tier"), tier, tier) {
        return Err("payload id and tier must match the source seat and turn tier".into());
    }
    payload_problem(&payload, held_cards, library, registry)
}

fn payload_problem(
    payload: &Dictionary,
    held_cards: &mut IndexSet<String>,
    library: Option<&UnitLibrary>,
    registry: Option<&MechanicRegistry>,
) -> Result<(), String> {
    for key in ["board", "hand", "slots", "standing"] {
        if !matches!(payload.get(key), Variant::Array(_)) {
            return Err(format!("payload.{key} must be an array"));
        }
    }
    let slots = payload.get("slots").as_array();
    if payload.get("board").as_array().len() != 7
        || slots.len() != 7
        || payload.get("hand").as_array().len() > 7
    {
        return Err(
            "payload requires 7 board slots, 7 slot states and at most 7 hand cards".into(),
        );
    }
    let mut seen = IndexSet::new();
    for key in ["board", "hand"] {
        for unit in payload.get(key).as_array().borrow().iter() {
            if key == "board" && *unit == Variant::Nil {
                continue;
            }
            let unit = unit.as_dict();
            unit_problem(&unit, &mut seen, library, registry, key == "board")
                .map_err(|problem| format!("payload.{key}: {problem}"))?;
            held_cards.insert(unit.get("def").as_text());
        }
    }
    for raw in slots.borrow().iter() {
        let slot = raw.as_dict();
        let keywords = slot.get("keywords");
        if !integer(&slot.get("renown"), -MAX_JSON_INT, MAX_JSON_INT) || !strings(&keywords) {
            return Err(
                "payload.slots entries require integral renown and an array of keyword ids".into(),
            );
        }
        if let Some(registry) = registry {
            for keyword in keywords.as_array().borrow().iter().map(Variant::as_text) {
                if !registry.has(&keyword) || !registry.kinds_of(&keyword).is_empty() {
                    return Err(format!("payload.slots: invalid keyword '{keyword}'"));
                }
            }
        }
    }
    if !integers(&payload.get("counters")) {
        return Err("payload.counters must be an integer dictionary".into());
    }
    heaps_problem(payload.get("heaps"), library)?;
    for effect in payload.get("standing").as_array().borrow().iter() {
        standing_problem(&effect.as_dict(), registry)?;
    }
    Ok(())
}

fn unit_problem(
    raw: &Dictionary,
    seen: &mut IndexSet<i64>,
    library: Option<&UnitLibrary>,
    registry: Option<&MechanicRegistry>,
    on_board: bool,
) -> Result<(), String> {
    if !nonempty_text(&raw.get("def")) || !matches!(raw.get("golden"), Variant::Bool(_)) {
        return Err("unit requires a card id (def) and boolean golden".into());
    }
    let uid = raw.get("uid");
    if !integer(&uid, 1, MAX_JSON_INT) {
        return Err("unit uid must be a positive integer".into());
    }
    let uid = uid.as_i64();
    if uid >= GhostRun::UID_STRIDE {
        return Err(format!(
            "unit uid {uid} must be below {}",
            GhostRun::UID_STRIDE
        ));
    }
    if !seen.insert(uid) {
        return Err(format!("duplicate unit uid {uid}"));
    }
    if let Some(library) = library {
        let id = raw.get("def").as_text();
        let card = library
            .get_card(&id)
            .ok_or_else(|| format!("unknown card '{id}'"))?;
        if on_board && card.borrow().is_spell() {
            return Err(format!("spell '{id}' cannot be on the board"));
        }
    }
    if !integer(&raw.get_or("copies", 1.into()), 1, MAX_JSON_INT)
        || !integer(&raw.get_or("bought_copies", 0.into()), 0, MAX_JSON_INT)
    {
        return Err(
            "unit copies must be positive and bought_copies must be nonnegative integers".into(),
        );
    }
    for key in ["stats", "counters", "turn_counters"] {
        if raw.has(key) && !integers(&raw.get(key)) {
            return Err(format!("unit {key} must be an integer dictionary"));
        }
    }
    for layer in raw.get("stats").as_dict().borrow().keys() {
        if !FightSnapshot::LAYERS.contains(&layer.as_str()) {
            return Err(format!("unknown stat layer '{layer}'"));
        }
    }
    for key in ["grants", "aura_grants"] {
        if raw.has(key) {
            grants_problem(raw.get(key), registry)
                .map_err(|problem| format!("unit {key}: {problem}"))?;
        }
    }
    Ok(())
}

fn grants_problem(raw: Variant, registry: Option<&MechanicRegistry>) -> Result<(), String> {
    let Variant::Array(entries) = raw else {
        return Err("must be an array".into());
    };
    for entry in entries.borrow().iter() {
        let grant = entry.as_array();
        let first = grant.get(0).unwrap_or_default();
        if !matches!(grant.len(), 1 | 2) || !nonempty_text(&first) {
            return Err("entries require a mechanic id and optional parameter object".into());
        }
        let params = match grant.get(1) {
            Some(Variant::Dictionary(params)) => params,
            Some(_) => return Err("parameters must be an object".into()),
            None => Dictionary::new(),
        };
        for value in params.borrow().values() {
            if !matches!(value, Variant::String(_)) && !integer(value, -MAX_JSON_INT, MAX_JSON_INT)
            {
                return Err("parameter values must be text or integers".into());
            }
        }
        let id = first.as_text();
        if registry.is_some_and(|registry| registry.bind_given(&id, &params).is_none()) {
            return Err(format!("unknown mechanic or invalid parameters for '{id}'"));
        }
    }
    Ok(())
}

fn heaps_problem(raw: Variant, library: Option<&UnitLibrary>) -> Result<(), String> {
    let Variant::Dictionary(heaps) = raw else {
        return Err("payload.heaps must be an object".into());
    };
    for (key, raw) in heaps.borrow().iter() {
        let heap = raw.as_dict();
        let next = heap.get("_next_n");
        let entries = heap.get("entries");
        if !integer(&next, 1, MAX_JSON_INT) || !matches!(entries, Variant::Array(_)) {
            return Err(format!(
                "payload.heaps.{key} requires positive _next_n and an entries array"
            ));
        }
        let mut previous = 0;
        for raw in entries.as_array().borrow().iter() {
            let entry = raw.as_dict();
            let id = entry.get("id");
            let tier = entry.get("tier");
            if !nonempty_text(&id) || !integer(&tier, 1, 7) {
                return Err(format!(
                    "payload.heaps.{key} entry requires a card id and tier in 1..7"
                ));
            }
            let n = entry.get("n");
            if !integer(&n, previous + 1, next.as_i64() - 1) {
                return Err(format!(
                    "payload.heaps.{key} entries must have increasing n below _next_n"
                ));
            }
            previous = n.as_i64();
            if let Some(library) = library {
                let id = id.as_text();
                let card = library
                    .get_card(&id)
                    .ok_or_else(|| format!("payload.heaps.{key}: unknown card '{id}'"))?;
                let card = card.borrow();
                if card.is_spell() || tier.as_i64() != card.tier {
                    return Err(format!(
                        "payload.heaps.{key}: '{id}' must be a unit with the saved tier"
                    ));
                }
            }
        }
    }
    Ok(())
}

fn standing_problem(
    effect: &Dictionary,
    registry: Option<&MechanicRegistry>,
) -> Result<(), String> {
    let id = effect.get("id");
    let params = effect.get("params");
    if !nonempty_text(&id)
        || !matches!(effect.get("granted"), Variant::Bool(_))
        || !matches!(params, Variant::Dictionary(_))
    {
        return Err(
            "payload.standing entries require a mechanic id, granted boolean and params object"
                .into(),
        );
    }
    let params = params.as_dict();
    let texts = params.get("_texts");
    if !matches!(params.get("golden"), Variant::Bool(_)) || !matches!(texts, Variant::Dictionary(_))
    {
        return Err("payload.standing params require a golden boolean and a _texts object".into());
    }
    if texts
        .as_dict()
        .borrow()
        .values()
        .any(|value| !matches!(value, Variant::String(_)))
    {
        return Err("payload.standing _texts values must be strings".into());
    }
    for key in ["_ints", "_kinds", "_golden_ints"] {
        if !integers(&params.get(key)) {
            return Err(format!(
                "payload.standing params.{key} must be an integer dictionary"
            ));
        }
    }
    let id = id.as_text();
    if registry.is_some_and(|registry| !registry.has(&id)) {
        return Err(format!("payload.standing: unknown mechanic '{id}'"));
    }
    Ok(())
}

fn integers(value: &Variant) -> bool {
    matches!(value, Variant::Dictionary(fields) if fields.borrow().values().all(|value| integer(value, -MAX_JSON_INT, MAX_JSON_INT)))
}

fn strings(value: &Variant) -> bool {
    matches!(value, Variant::Array(items) if items.borrow().iter().all(|value| matches!(value, Variant::String(_))))
}

fn integer(value: &Variant, low: i64, high: i64) -> bool {
    number(value).is_some_and(|n| n == n.floor() && n >= low as f64 && n <= high as f64)
}

fn number(value: &Variant) -> Option<f64> {
    match value {
        Variant::Int(n) => Some(*n as f64),
        Variant::Float(n) if n.is_finite() => Some(*n),
        _ => None,
    }
}

fn nonempty_text(value: &Variant) -> bool {
    matches!(value, Variant::String(text) if !text.is_empty())
}

fn hex(value: &Variant, length: usize) -> bool {
    matches!(value, Variant::String(text) if text.len() == length && text.bytes().all(|byte| byte.is_ascii_hexdigit()))
}

#[cfg(test)]
mod tests {
    use super::*;

    const FIXTURE: &str = include_str!("../../../../../../tests/core/fixtures/ghost_run.json");

    #[test]
    fn godot_json_accepts_integral_floats_and_the_last_duplicate_key() {
        let original = GhostRun::parse(FIXTURE.as_bytes(), None, None).unwrap();
        let changed_text = FIXTURE.replacen(
            r#""format": 1,"#,
            r#""format": 0, "unknown": [1,], "format": 1.0,"#,
            1,
        );
        let changed_text =
            changed_text.replacen(r#""health": 40"#, r#""health": 999999.9999999999"#, 1);
        let changed = GhostRun::parse(changed_text.as_bytes(), None, None).unwrap();
        assert_ne!(original.id(), changed.id());
        assert_eq!(changed.id(), hash(changed_text.as_bytes()));
        assert_eq!(changed.last_turn(), 4);
        assert_eq!(changed.payload_for_round(5), original.payload_for_round(4));
        assert_eq!(changed.reason_for_round(5), "run_ended");

        let payload = changed.payload_for_round(4);
        payload
            .get("board")
            .as_array()
            .get(3)
            .unwrap()
            .as_dict()
            .insert("uid", 0.into());
        assert_eq!(changed.payload_for_round(4), original.payload_for_round(4));
    }

    #[test]
    fn rejects_bad_encoding_invalid_json_and_fractional_integers() {
        for (bytes, message) in [
            (&b"{"[..], "invalid run JSON"),
            (&b"null"[..], "run file must contain one JSON object"),
            (&b"{}\0"[..], "run file must be UTF-8"),
        ] {
            assert_eq!(
                GhostRun::parse(bytes, None, None).err().as_deref(),
                Some(message)
            );
        }
        let changed = FIXTURE.replacen(r#""format": 1,"#, r#""format": 1.1,"#, 1);
        assert_eq!(
            GhostRun::parse(changed.as_bytes(), None, None)
                .err()
                .as_deref(),
            Some("expected run format 1"),
        );
    }
}
