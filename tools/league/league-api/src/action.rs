//! A recruit action, typed. The harness turns each `LegalActions.of` dictionary into one of
//! these, in the same order, and plays the original dictionary for the index a bot returns.
use bramble_engine::core::recruit::legal_actions::ActionOutput;
use bramble_engine::core::{recruit::recruit::Recruit, session::game_session::GameSessionRef};
use bramble_engine::{Dictionary, Variant};

#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub enum Action {
    /// Take Discover option `index` (only actions while a Discover is pending).
    Pick {
        index: i64,
    },
    /// Take a Discover option and aim its Recruit effect at a friendly unit uid.
    PickTarget {
        index: i64,
        target: i64,
    },
    /// Buy shop slot `index`, from the spell row when `spell`.
    Buy {
        spell: bool,
        index: i64,
    },
    /// Buy a shop card and aim its Recruit effect at a friendly unit uid.
    BuyTarget {
        spell: bool,
        index: i64,
        target: i64,
    },
    /// Resolve the pending Recruit effect on the friendly unit with this uid.
    RecruitTarget {
        target: i64,
    },
    /// Sell the unit on board slot `slot`.
    Sell {
        slot: i64,
    },
    /// Sell the unit at hand position `hand`.
    SellHand {
        hand: i64,
    },
    /// Return the unit in board slot `slot` to hand for free.
    ToHand {
        slot: i64,
    },
    /// Play hand card `hand` to board slot `slot` (-1 for a spell), aimed at uid `target` (-1: none).
    Play {
        hand: i64,
        slot: i64,
        target: i64,
    },
    /// Use board unit `uid`'s ability `mechanic`, aimed at uid `target` (-1: none).
    Ability {
        uid: i64,
        mechanic: String,
        target: i64,
    },
    /// Move the unit on slot `from` to slot `to` (swapping with any unit there).
    Move {
        from: i64,
        to: i64,
    },
    Refresh,
    Freeze,
    Upgrade,
    EndTurn,
}

impl Action {
    /// The engine's action type name ("buy", "end_turn", ...).
    pub fn kind(&self) -> &'static str {
        match self {
            Self::Pick { .. } | Self::PickTarget { .. } => "pick",
            Self::Buy { .. } | Self::BuyTarget { .. } => "buy",
            Self::RecruitTarget { .. } => "recruit_target",
            Self::Sell { .. } | Self::SellHand { .. } => "sell",
            Self::ToHand { .. } => "to_hand",
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
        let raw = raw.borrow();
        let kind = raw.get("type").map(Variant::as_text).unwrap_or_default();
        Self::read(&kind, |key| raw.get(key))
    }

    fn read<'a>(kind: &str, get: impl Fn(&str) -> Option<&'a Variant>) -> Self {
        let int = |key: &str| get(key).map_or(0, Variant::as_i64);
        let target = get("target").map_or(-1, Variant::as_i64);
        let spell = matches!(get("spell"), Some(Variant::Bool(true)));
        match kind {
            "recruit_target" => Self::RecruitTarget { target },
            "pick" if target >= 0 => Self::PickTarget {
                index: int("index"),
                target,
            },
            "buy" if target >= 0 => Self::BuyTarget {
                spell,
                index: int("index"),
                target,
            },
            "pick" => Self::Pick {
                index: int("index"),
            },
            "buy" => Self::Buy {
                spell,
                index: int("index"),
            },
            "sell" if get("hand").is_some() => Self::SellHand { hand: int("hand") },
            "sell" => Self::Sell { slot: int("slot") },
            "to_hand" => Self::ToHand { slot: int("slot") },
            "play" => Self::Play {
                hand: int("hand"),
                slot: int("slot"),
                target: int("target"),
            },
            "ability" => Self::Ability {
                uid: int("uid"),
                mechanic: get("mechanic").map(Variant::as_text).unwrap_or_default(),
                target: int("target"),
            },
            "move" => Self::Move {
                from: int("from"),
                to: int("to"),
            },
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
                out.insert("target", (-1).into());
            }
            Self::PickTarget { index, target } => {
                out.insert("index", (*index).into());
                out.insert("target", (*target).into());
            }
            Self::Buy { spell, index } => {
                out.insert("spell", (*spell).into());
                out.insert("index", (*index).into());
                out.insert("target", (-1).into());
            }
            Self::BuyTarget {
                spell,
                index,
                target,
            } => {
                out.insert("spell", (*spell).into());
                out.insert("index", (*index).into());
                out.insert("target", (*target).into());
            }
            Self::RecruitTarget { target } => {
                out.insert("target", (*target).into());
            }
            Self::SellHand { hand } => {
                out.insert("hand", (*hand).into());
            }
            Self::Sell { slot } | Self::ToHand { slot } => {
                out.insert("slot", (*slot).into());
            }
            Self::Play { hand, slot, target } => {
                out.insert("hand", (*hand).into());
                out.insert("slot", (*slot).into());
                out.insert("target", (*target).into());
            }
            Self::Ability {
                uid,
                mechanic,
                target,
            } => {
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

    /// An un-aimed pick still uses the usual self-target when it enters hand immediately.
    pub(crate) fn to_dict_for(&self, game: &GameSessionRef, player_id: i64) -> Dictionary {
        let action = self.to_dict();
        if matches!(self, Self::Pick { .. }) {
            let (recruit, player) = {
                let game = game.borrow();
                (
                    game.recruit.clone().expect("session recruit"),
                    game.player(player_id),
                )
            };
            if Recruit::gain_waits(&recruit, &player) {
                action.erase("target");
            }
        }
        action
    }
}

// Both paths use the same parser; enumeration order and action fields are unchanged.
impl ActionOutput for Action {
    fn from_fields(kind: &'static str, fields: &[(&'static str, Variant)]) -> Self {
        Self::read(kind, |key| {
            fields
                .iter()
                .find(|(name, _)| *name == key)
                .map(|(_, value)| value)
        })
    }
}
