//! A recruit action, typed. The harness turns each `LegalActions.of` dictionary into one of
//! these, in the same order, and plays the original dictionary for the index a bot returns.
use bramble_engine::{Dictionary, Variant};

#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub enum Action {
    /// Take Discover option `index` (only actions while a Discover is pending).
    Pick { index: i64 },
    /// Buy shop slot `index`, from the spell row when `spell`.
    Buy { spell: bool, index: i64 },
    /// Sell the unit on board slot `slot`.
    Sell { slot: i64 },
    /// Play hand card `hand` to board slot `slot` (-1 for a spell), aimed at uid `target` (-1: none).
    Play { hand: i64, slot: i64, target: i64 },
    /// Use board unit `uid`'s ability `mechanic`, aimed at uid `target` (-1: none).
    Ability { uid: i64, mechanic: String, target: i64 },
    /// Move the unit on slot `from` to slot `to` (swapping with any unit there).
    Move { from: i64, to: i64 },
    Refresh,
    Freeze,
    Upgrade,
    EndTurn,
}

impl Action {
    /// The engine's action type name ("buy", "end_turn", ...).
    pub fn kind(&self) -> &'static str {
        match self {
            Self::Pick { .. } => "pick",
            Self::Buy { .. } => "buy",
            Self::Sell { .. } => "sell",
            Self::Play { .. } => "play",
            Self::Ability { .. } => "ability",
            Self::Move { .. } => "move",
            Self::Refresh => "refresh",
            Self::Freeze => "freeze",
            Self::Upgrade => "upgrade",
            Self::EndTurn => "end_turn",
        }
    }

    pub(crate) fn from_dict(raw: &Dictionary) -> Self {
        let int = |key: &str| raw.get(key).as_i64();
        match raw.get("type").as_text().as_str() {
            "pick" => Self::Pick { index: int("index") },
            "buy" => Self::Buy {
                spell: matches!(raw.get("spell"), Variant::Bool(true)),
                index: int("index"),
            },
            "sell" => Self::Sell { slot: int("slot") },
            "play" => Self::Play { hand: int("hand"), slot: int("slot"), target: int("target") },
            "ability" => Self::Ability {
                uid: int("uid"),
                mechanic: raw.get("mechanic").as_text(),
                target: int("target"),
            },
            "move" => Self::Move { from: int("from"), to: int("to") },
            "refresh" => Self::Refresh,
            "freeze" => Self::Freeze,
            "upgrade" => Self::Upgrade,
            _ => Self::EndTurn,
        }
    }

    /// The engine dictionary, with the keys in `LegalActions` order.
    pub(crate) fn to_dict(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("type", self.kind().into());
        match self {
            Self::Pick { index } => {
                out.insert("index", (*index).into());
            }
            Self::Buy { spell, index } => {
                out.insert("spell", (*spell).into());
                out.insert("index", (*index).into());
            }
            Self::Sell { slot } => {
                out.insert("slot", (*slot).into());
            }
            Self::Play { hand, slot, target } => {
                out.insert("hand", (*hand).into());
                out.insert("slot", (*slot).into());
                out.insert("target", (*target).into());
            }
            Self::Ability { uid, mechanic, target } => {
                out.insert("uid", (*uid).into());
                out.insert("mechanic", mechanic.clone().into());
                out.insert("target", (*target).into());
            }
            Self::Move { from, to } => {
                out.insert("from", (*from).into());
                out.insert("to", (*to).into());
            }
            Self::Refresh | Self::Freeze | Self::Upgrade | Self::EndTurn => {}
        }
        out
    }
}
