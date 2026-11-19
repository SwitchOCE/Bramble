//! Fixed, disjoint run lobbies drawn in seed order before game threads start.
use crate::{game::Engine, matchrun::MatchArgs};
use bramble_engine::core::{
    ghosts::{ghost_run::RunsBySeat, ghost_store::GhostStore},
    util::rng::Rng,
};
use bramble_ghosts::{Band, FolderStore, GhostStore as _, LocalMatchmaker, Matchmaker};
use serde_json::Value;
use sha2::{Digest, Sha256};
use std::{
    collections::BTreeSet,
    path::{Path, PathBuf},
};

pub fn run(args: &MatchArgs, field: &Path) -> Result<Value, String> {
    if args.games == 0 || !args.games.is_multiple_of(2) {
        return Err("usage: ghost-match --games must be a positive even number".into());
    }
    if !args.records {
        return Err("usage: ghost-match writes records for replay and cutting".into());
    }
    let red = crate::factory(&args.red)?;
    let blue = crate::factory(&args.blue)?;
    crate::matchrun::run_match(args, red, blue, Some(field))
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
