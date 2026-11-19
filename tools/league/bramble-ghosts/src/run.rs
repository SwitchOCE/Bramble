use crate::{is_hex, sha256};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::{BTreeMap, BTreeSet};

pub const RUN_FORMAT: u32 = 1;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Run {
    pub format: u32,
    /// The source record's build dictionary, unchanged.
    pub rules: Value,
    pub patch: String,
    pub content: Vec<String>,
    pub tribes: Vec<String>,
    pub source: RunSource,
    pub made: String,
    pub placement: i64,
    pub last_turn: usize,
    pub ended: Ended,
    pub cards: BTreeMap<String, String>,
    pub turns: Vec<RunTurn>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct RunSource {
    pub kind: SourceKind,
    pub label: String,
    pub player: String,
    pub rating: Option<f64>,
    pub record_sha256: String,
    pub record_mode: String,
    pub game_seed: String,
    pub seat: i64,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum SourceKind {
    Bot,
    Player,
    Internal,
    Tester,
    TestRealm,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Ended {
    Eliminated,
    Won,
    RoundLimit,
    Unfinished,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct RunTurn {
    pub turn: usize,
    pub tier: i64,
    pub health: i64,
    pub armor: i64,
    pub gold: i64,
    pub acts: Vec<Act>,
    /// The recorded fight snapshot. Preserve fields the cutter does not interpret.
    pub payload: Value,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Act {
    pub action: Value,
    pub result: String,
}

impl Run {
    pub fn rules_hash(&self) -> &str {
        self.rules["rules_hash"].as_str().unwrap_or_default()
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<Self, String> {
        let run: Self = serde_json::from_slice(bytes).map_err(|e| e.to_string())?;
        run.validate()?;
        Ok(run)
    }

    pub fn to_bytes(&self) -> Result<Vec<u8>, String> {
        self.validate()?;
        serde_json::to_vec(self).map_err(|e| e.to_string())
    }

    pub fn validate(&self) -> Result<(), String> {
        if self.format != RUN_FORMAT {
            return Err(format!("unsupported run format {}", self.format));
        }
        for (index, turn) in self.turns.iter().enumerate() {
            if turn.turn != index + 1 {
                return Err(format!(
                    "turn gap: expected {}, found {}",
                    index + 1,
                    turn.turn
                ));
            }
        }
        if self.last_turn == 0 || self.turns.len() != self.last_turn {
            return Err(format!(
                "turn gap: last_turn {} with {} recorded turns",
                self.last_turn,
                self.turns.len()
            ));
        }
        if !is_hex(self.rules_hash(), 64) || !is_hex(&self.source.record_sha256, 64) {
            return Err("invalid rules_hash or source record_sha256".into());
        }
        if self.made.is_empty() {
            return Err("missing made time".into());
        }

        let mut cards = BTreeSet::new();
        for turn in &self.turns {
            let payload = &turn.payload;
            if payload["id"].as_i64() != Some(self.source.seat)
                || payload["tier"].as_i64() != Some(turn.tier)
                || !payload["slots"].is_array()
                || !payload["standing"].is_array()
                || !payload["counters"].is_object()
                || !payload["heaps"].is_object()
            {
                return Err(format!("invalid fight payload on turn {}", turn.turn));
            }
            cards.extend(turn.card_ids()?);
        }
        if cards.len() != self.cards.len()
            || cards
                .iter()
                .any(|id| !self.cards.get(*id).is_some_and(|hash| is_hex(hash, 16)))
        {
            return Err("card fingerprints do not cover the board and hand".into());
        }
        Ok(())
    }

    pub(crate) fn verify_bytes(id: &str, bytes: &[u8]) -> Result<Self, String> {
        let actual = sha256(bytes);
        if actual != id {
            return Err(format!("run hash mismatch: expected {id}, got {actual}"));
        }
        Self::from_bytes(bytes)
    }
}

impl RunTurn {
    pub(crate) fn card_ids(&self) -> Result<BTreeSet<&str>, String> {
        let mut cards = BTreeSet::new();
        let board = self.payload["board"].as_array();
        let hand = self.payload["hand"].as_array();
        let (Some(board), Some(hand)) = (board, hand) else {
            return Err(format!("invalid board or hand on turn {}", self.turn));
        };
        for card in board.iter().filter(|card| !card.is_null()).chain(hand) {
            let id = card["def"].as_str().filter(|id| !id.is_empty());
            let uid = card["uid"].as_i64();
            match (id, uid) {
                (Some(id), Some(0..1_000_000)) => {
                    cards.insert(id);
                }
                _ => return Err(format!("invalid card or uid on turn {}", self.turn)),
            }
        }
        Ok(cards)
    }
}
