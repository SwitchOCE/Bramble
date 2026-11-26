//! Fixed, disjoint run lobbies drawn in seed order before game threads start.
use crate::{
    game::{Engine, Grant},
    matchrun::MatchArgs,
};
use bramble_engine::core::{
    ghosts::{ghost_run::RunsBySeat, ghost_store::GhostStore},
    records::record_build::RecordBuild,
    util::rng::Rng,
};
use bramble_engine::{Array, ToState};
use bramble_ghosts::{Band, FolderStore, GhostStore as _, LocalMatchmaker, Matchmaker};
use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use std::{
    collections::{BTreeMap, BTreeSet},
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
    run_with(args, field, debug_logs, &Options::default())
}

/// What a ghost match may change for its live seat, for the card-power tools. All empty for a
/// normal match. Seeds, secret, lobbies and bots are those of the same match without them, so
/// the two pair by game index.
#[derive(Clone, Debug, Default)]
pub struct Options {
    /// `--without <ids>`: the live seat is never offered these units, in the shop or in
    /// Discover; the shop draws other cards in their place by the normal weights.
    pub without: Vec<String>,
    /// `--grant <id>@<round> [--keep <rounds>]`: the live seat is handed one fresh copy at the
    /// start of that round's shop turn (see `grant.rs`).
    pub grant: Option<Grant>,
    /// `--trial-rules`: the card data at `--repo-root` differs from the rules this build and
    /// the field were made for, on purpose (a proposed card change tried in whole games).
    pub trial_rules: bool,
}

impl Options {
    /// Changes that a record could not show (the draw list and the handed-over copy are not
    /// in the state hash), so such a match writes no records.
    fn placement_only(&self) -> Option<&'static str> {
        if !self.without.is_empty() {
            Some("--without")
        } else if self.grant.is_some() {
            Some("--grant")
        } else {
            None
        }
    }
}

/// `ghost-match --without <ids>`: see [`Options::without`]. Placement only: it writes no
/// records (`args.records` must be false), and `summary.json` lists the cards under `without`.
pub fn run_without(
    args: &MatchArgs,
    field: &Path,
    debug_logs: bool,
    without: &[String],
) -> Result<Value, String> {
    let options = Options {
        without: without.to_vec(),
        ..Options::default()
    };
    run_with(args, field, debug_logs, &options)
}

/// A ghost match with the card-power tools' options.
pub fn run_with(
    args: &MatchArgs,
    field: &Path,
    debug_logs: bool,
    options: &Options,
) -> Result<Value, String> {
    let red = crate::factory(&args.red)?;
    let blue = crate::factory(&args.blue)?;
    run_with_factories(args, red, blue, field, debug_logs, options)
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
    run_with_factories(args, red, blue, field, false, &Options::default())
}

fn run_with_factories(
    args: &MatchArgs,
    red: league_api::Factory,
    blue: league_api::Factory,
    field: &Path,
    debug_logs: bool,
    options: &Options,
) -> Result<Value, String> {
    if args.games == 0 || !args.games.is_multiple_of(2) {
        return Err("usage: ghost-match --games must be a positive even number".into());
    }
    match options.placement_only() {
        // A trial's records are optional: they are for the card report, never for a field.
        None if !args.records && !options.trial_rules => {
            return Err("usage: ghost-match writes records for replay and cutting".into());
        }
        // A record cannot say which cards were left out or handed over, so it would neither
        // replay nor cut into a field truthfully. Refuse up front.
        Some(flag) if args.records => {
            return Err(format!(
                "usage: ghost-match {flag} is for placement only and writes no records; \
                 add --no-records"
            ));
        }
        _ => {}
    }
    crate::matchrun::run_match(args, red, blue, Some(field), debug_logs, options)
}

/// The rules hash of the card data a match plays (`RecordBuild::identity` of `--repo-root`)
/// against the one this build and its field were made for. A ghost match refuses a difference
/// unless `--trial-rules` asks for it, and `--trial-rules` refuses card data that is the same.
pub(crate) fn check_rules(root: &Path, built: &str, trial: bool) -> Result<String, String> {
    let played = RecordBuild::identity(root).get("rules_hash").as_text();
    if played != built && !trial {
        return Err(format!(
            "usage: the card data at {} has rules {played}; this build and its fields have \
             {built}. To try changed cards against this field, add --trial-rules",
            root.display()
        ));
    }
    if played == built && trial {
        return Err(format!(
            "usage: --trial-rules: the card data at {} is not changed (rules {built}); drop the flag",
            root.display()
        ));
    }
    Ok(played)
}

/// For `summary.json`'s `trial_rules`: the card-data files and cards that differ between the
/// trial's card data and `reference` (this build's checkout, when its rules are the build's).
pub(crate) fn trial_changes(root: &Path, reference: &Path) -> Value {
    // The files `RecordBuild::identity` hashes.
    let mut paths: BTreeSet<PathBuf> = [
        "src/game/game_content.gd",
        "src/game/data/stand_in_units.json",
    ]
    .into_iter()
    .map(PathBuf::from)
    .collect();
    for dir in ["src/core", "src/content"] {
        for base in [root, reference] {
            list_rule_files(&base.join(dir), Path::new(dir), &mut paths);
        }
    }
    let files: Vec<String> = paths
        .into_iter()
        .filter(|path| {
            std::fs::read(root.join(path)).ok() != std::fs::read(reference.join(path)).ok()
        })
        .map(|path| path.display().to_string())
        .collect();
    let mut cards = Vec::new();
    for file in files.iter().filter(|f| f.ends_with("/units.json")) {
        let read = |base: &Path| -> BTreeMap<String, Value> {
            std::fs::read(base.join(file))
                .ok()
                .and_then(|bytes| serde_json::from_slice::<Value>(&bytes).ok())
                .and_then(|data| data["cards"].as_array().cloned())
                .unwrap_or_default()
                .into_iter()
                .filter_map(|card| Some((card["id"].as_str()?.to_owned(), card)))
                .collect()
        };
        let (now, was) = (read(root), read(reference));
        let ids: BTreeSet<&String> = now.keys().chain(was.keys()).collect();
        for id in ids {
            let (n, w) = (now.get(id), was.get(id));
            if n == w {
                continue;
            }
            let mut changed = serde_json::Map::new();
            let keys: BTreeSet<&String> = n
                .and_then(Value::as_object)
                .into_iter()
                .chain(w.and_then(Value::as_object))
                .flat_map(|o| o.keys())
                .collect();
            for key in keys {
                let (nv, wv) = (n.map(|c| &c[key.as_str()]), w.map(|c| &c[key.as_str()]));
                if nv != wv {
                    changed.insert(key.clone(), json!({"was": wv, "now": nv}));
                }
            }
            cards.push(json!({"id": id, "changed": changed}));
        }
    }
    json!({"files": files, "cards": cards})
}

fn list_rule_files(dir: &Path, rel: &Path, out: &mut BTreeSet<PathBuf>) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let name = entry.file_name();
        let path = entry.path();
        if path.is_dir() {
            list_rule_files(&path, &rel.join(&name), out);
        } else if path.extension().is_some_and(|e| e == "gd" || e == "json") {
            out.insert(rel.join(&name));
        }
    }
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
    use std::path::Path;

    fn copy_dir(from: &Path, to: &Path) {
        std::fs::create_dir_all(to).unwrap();
        for entry in std::fs::read_dir(from).unwrap().flatten() {
            let target = to.join(entry.file_name());
            if entry.path().is_dir() {
                copy_dir(&entry.path(), &target);
            } else {
                std::fs::copy(entry.path(), target).unwrap();
            }
        }
    }

    /// A scratch copy of the rules files `RecordBuild::identity` reads.
    pub(crate) fn scratch_rules(name: &str) -> std::path::PathBuf {
        let root = crate::default_root();
        let dir = std::env::temp_dir().join(format!("league-{name}-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        for sub in ["src/core", "src/content"] {
            copy_dir(&root.join(sub), &dir.join(sub));
        }
        std::fs::create_dir_all(dir.join("src/game/data")).unwrap();
        for file in [
            "src/game/game_content.gd",
            "src/game/data/stand_in_units.json",
            "project.godot",
        ] {
            std::fs::copy(root.join(file), dir.join(file)).unwrap();
        }
        dir
    }

    #[test]
    fn the_checkout_plays_the_builds_rules_and_a_changed_card_needs_trial_rules() {
        let build: serde_json::Value = serde_json::from_str(crate::BUILD).unwrap();
        let built = build["rules_hash"].as_str().unwrap();
        let root = crate::default_root();
        assert_eq!(
            super::check_rules(&root, built, false).as_deref(),
            Ok(built)
        );
        let same = super::check_rules(&root, built, true).unwrap_err();
        assert!(same.contains("not changed"), "{same}");

        let dir = scratch_rules("trial-rules");
        assert_eq!(super::check_rules(&dir, built, false).as_deref(), Ok(built));
        let units = dir.join("src/content/badger/units.json");
        let text = std::fs::read_to_string(&units).unwrap();
        let mut data: serde_json::Value = serde_json::from_str(&text).unwrap();
        let card = data["cards"]
            .as_array_mut()
            .unwrap()
            .iter_mut()
            .find(|c| c["id"] == "sword-heir")
            .unwrap();
        assert_eq!(card["health"], 9);
        card["health"] = 5.into();
        std::fs::write(&units, serde_json::to_string_pretty(&data).unwrap()).unwrap();
        let refused = super::check_rules(&dir, built, false).unwrap_err();
        assert!(refused.contains("--trial-rules"), "{refused}");
        let played = super::check_rules(&dir, built, true).unwrap();
        assert_ne!(played, built);

        let changes = super::trial_changes(&dir, &root);
        assert_eq!(
            changes["files"],
            serde_json::json!(["src/content/badger/units.json"])
        );
        assert_eq!(
            changes["cards"],
            serde_json::json!([{"id": "sword-heir", "changed": {"health": {"was": 9, "now": 5}}}])
        );
        let _ = std::fs::remove_dir_all(dir);
    }

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
