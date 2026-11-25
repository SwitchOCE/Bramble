//! Fixed, disjoint run lobbies drawn in seed order before game threads start.
use crate::{game::Engine, matchrun::MatchArgs};
use bramble_engine::core::{
    ghosts::{ghost_run::RunsBySeat, ghost_store::GhostStore},
    util::rng::Rng,
};
use bramble_engine::{Array, ToState};
use bramble_ghosts::{Band, FolderStore, GhostStore as _, LocalMatchmaker, Matchmaker};
use serde_json::Value;
use sha2::{Digest, Sha256};
use std::{
    collections::BTreeSet,
    path::{Path, PathBuf},
};

pub fn run(args: &MatchArgs, field: &Path) -> Result<Value, String> {
    run_with_debug_logs(args, field, false)
}

pub fn run_with_debug_logs(
    args: &MatchArgs,
    field: &Path,
    debug_logs: bool,
) -> Result<Value, String> {
    run_without(args, field, debug_logs, &[])
}

/// `ghost-match --without <ids>`: the live seat is never offered these units, in the shop or in
/// Discover; the shop draws other cards in their place by the normal weights. Seeds, secret,
/// lobbies and bots are those of the same match without the flag, so the two pair by game index.
/// Placement only: it writes no records (`args.records` must be false), and `summary.json`
/// lists the cards under `without`.
pub fn run_without(
    args: &MatchArgs,
    field: &Path,
    debug_logs: bool,
    without: &[String],
) -> Result<Value, String> {
    let red = crate::factory(&args.red)?;
    let blue = crate::factory(&args.blue)?;
    run_with_factories(args, red, blue, field, debug_logs, without)
}

/// `run` with the two bots given as constructors, as `matchrun::run_factories` is for live
/// matches. A team's tools crate uses it to play two versions of its own bot against a field:
/// `ghostmatch::run_factories(&args, red::new_bot, old_red::new_bot, field)`.
pub fn run_factories(
    args: &MatchArgs,
    red: league_api::Factory,
    blue: league_api::Factory,
    field: &Path,
) -> Result<Value, String> {
    run_with_factories(args, red, blue, field, false, &[])
}

fn run_with_factories(
    args: &MatchArgs,
    red: league_api::Factory,
    blue: league_api::Factory,
    field: &Path,
    debug_logs: bool,
    without: &[String],
) -> Result<Value, String> {
    if args.games == 0 || !args.games.is_multiple_of(2) {
        return Err("usage: ghost-match --games must be a positive even number".into());
    }
    if without.is_empty() && !args.records {
        return Err("usage: ghost-match writes records for replay and cutting".into());
    }
    if !without.is_empty() && args.records {
        // A record cannot say which cards were left out (the draw list is not in the state
        // hash), so it would neither replay nor cut into a field truthfully. Refuse up front.
        return Err(
            "usage: ghost-match --without is for placement only and writes no records; \
             add --no-records"
                .into(),
        );
    }
    crate::matchrun::run_match(args, red, blue, Some(field), debug_logs, without)
}

/// Every `--without` id must be a unit the shop can draw: not unknown, a spell or a token.
/// Runs before any game is played. Also checks that the rebuilt draw list with nothing left out
/// equals the one `GameSession::create` builds, so leaving cards out changes nothing else.
pub(crate) fn check_without(engine: &Engine, without: &[String]) -> Result<(), String> {
    if without.is_empty() {
        return Ok(());
    }
    let game = engine.content.borrow().new_session(0, &Array::new());
    let odds = game.borrow().unit_odds.clone().expect("unit odds");
    let rebuilt = crate::game::unit_odds_without(&game, &[]);
    if odds.to_state() != rebuilt.to_state() {
        return Err("--without: the harness's unit draw list differs from the game's".into());
    }
    let library = engine.content.borrow().library.clone();
    let library = library.borrow();
    let mut seen = BTreeSet::new();
    for id in without {
        if !seen.insert(id) {
            return Err(format!("usage: --without lists {id} twice"));
        }
        let Some(card) = library.get_card(id) else {
            return Err(format!("usage: --without {id}: no such card"));
        };
        let card = card.borrow();
        if card.is_spell() {
            return Err(format!("usage: --without {id}: a spell, not a unit"));
        }
        if card.token {
            return Err(format!("usage: --without {id}: a token, never in the shop"));
        }
        if odds.weight_of(id) <= 0 {
            return Err(format!("usage: --without {id}: never drawn for the shop"));
        }
    }
    let left = crate::game::unit_odds_without(&game, without);
    if let Some(id) = without.iter().find(|id| left.weight_of(id) != 0) {
        return Err(format!("--without {id}: still in the draw list"));
    }
    Ok(())
}

pub(crate) struct Lobbies {
    field: PathBuf,
    pairs: Vec<[String; 7]>,
}

impl Lobbies {
    pub(crate) fn pick(
        field: &Path,
        rules_hash: &str,
        secret: &str,
        pairs: usize,
    ) -> Result<Self, String> {
        let store = FolderStore::new(field);
        let mut used = BTreeSet::new();
        let mut lobbies = Vec::with_capacity(pairs);
        for pair in 0..pairs {
            let digest = Sha256::digest(format!("{secret}|lobby|{pair}"));
            let seed = u32::from_le_bytes(digest[..4].try_into().expect("4 bytes"));
            let ids = LocalMatchmaker
                .pick(
                    &store,
                    rules_hash,
                    &Band::default(),
                    &used,
                    &mut Rng::new(seed.into()),
                )
                .map_err(|err| format!("lobby {pair} from {}: {err}", field.display()))?;
            // The matchmaker filters on the index, a cache. Check each picked file itself.
            for id in &ids {
                let run = store.fetch(id)?.ok_or_else(|| {
                    format!("lobby {pair}: run {id} is in the index but not the store")
                })?;
                if run.rules_hash() != rules_hash {
                    return Err(format!(
                        "lobby {pair}: run {id} has rules {}, the game has {rules_hash}",
                        run.rules_hash()
                    ));
                }
            }
            used.extend(ids.iter().cloned());
            lobbies.push(ids);
        }
        Ok(Self {
            field: field.into(),
            pairs: lobbies,
        })
    }

    pub(crate) fn load(&self, pair: usize, engine: &Engine) -> Result<RunsBySeat, String> {
        let store = GhostStore::new(&self.field);
        let content = engine.content.borrow();
        let library = content.library.borrow();
        let registry = content.registry.borrow();
        self.pairs[pair]
            .iter()
            .enumerate()
            .map(|(index, id)| {
                store
                    .fetch(id, Some(&library), Some(&registry))
                    .map(|run| (index as i64 + 1, run))
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn without_takes_only_units_the_shop_draws() {
        let root = crate::default_root();
        let engine = crate::engine_for(&root, &|| crate::load_content(&root, None)).unwrap();
        let check = |ids: &[&str]| {
            let ids: Vec<String> = ids.iter().map(|id| (*id).to_owned()).collect();
            super::check_without(&engine, &ids)
        };
        assert_eq!(check(&[]), Ok(()));
        assert_eq!(check(&["green-recruit", "gate-warden"]), Ok(()));
        for (ids, error) in [
            (&["nosuch"][..], "no such card"),
            (&["sp_sharpen"], "a spell"),
            (&["cousin"], "a token"),
            (&["green-recruit", "green-recruit"], "twice"),
        ] {
            let got = check(ids).unwrap_err();
            assert!(got.contains(error), "{ids:?}: {got}");
        }
    }
}
