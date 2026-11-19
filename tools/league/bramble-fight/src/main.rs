//! Streaming implementation of tools/league/fights/FORMAT.md.
mod cases;

use bramble_engine::core::session::game_session::GameSession;
use bramble_engine::game::game_content::{GameContent, GameContentRef};
use bramble_engine::util::godot_json;
use bramble_engine::{Array, Dictionary, Variant};
use std::collections::{HashMap, hash_map::Entry};
use std::fs::File;
use std::io::{BufRead, BufReader, BufWriter, Write};
use std::path::{Component, Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Instant;

/// Time spent inside `GameSession::_fight` only (no restore or serialization), for speed figures.
static FIGHT_NS: AtomicU64 = AtomicU64::new(0);

#[derive(Clone, Debug, PartialEq, Eq, Hash)]
enum ContentRecipe {
    Default,
    Folders(Vec<String>),
}

struct Options {
    root: PathBuf,
    cases: PathBuf,
    out: PathBuf,
    first: u64,
    count: i64,
    recipe: ContentRecipe,
    plant_attack: Option<String>,
}

fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        std::process::exit(2);
    }
}

fn options(args: impl Iterator<Item = String>) -> Result<Options, String> {
    let mut values = HashMap::new();
    let mut args = args.peekable();
    while let Some(arg) = args.next() {
        if arg == "--" {
            continue;
        }
        if let Some((key, value)) = arg.split_once('=') {
            values.insert(key.trim_start_matches("--").to_owned(), value.to_owned());
        } else if let Some(key) = arg.strip_prefix("--") {
            values.insert(key.to_owned(), args.next().ok_or_else(usage)?);
        } else {
            return Err(usage());
        }
    }
    let cases = PathBuf::from(values.get("cases").ok_or_else(usage)?);
    let out = PathBuf::from(values.get("out").ok_or_else(usage)?);
    let root = values.get("repo-root").map_or_else(
        || PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../.."),
        PathBuf::from,
    );
    let first = values
        .get("first")
        .map_or(Ok(0), |n| n.parse::<i64>())
        .map_err(|_| "first must be >= 0; count must be >= 0 or -1 (all)".to_owned())?;
    let count = values
        .get("count")
        .map_or(Ok(-1), |n| n.parse::<i64>())
        .map_err(|_| "first must be >= 0; count must be >= 0 or -1 (all)".to_owned())?;
    if first < 0 || count < -1 {
        return Err("first must be >= 0; count must be >= 0 or -1 (all)".into());
    }
    let recipe = if let Some(folders) = values.get("folders") {
        ContentRecipe::Folders(parse_folders(folders)?)
    } else {
        ContentRecipe::Default
    };
    Ok(Options {
        root,
        cases,
        out,
        first: first as u64,
        count,
        recipe,
        plant_attack: values.get("plant-attack").cloned(),
    })
}

fn usage() -> String {
    "usage: bramble-fight cases=<file> out=<file> [first=<n> count=<n> folders=<comma-list> --repo-root <root> --plant-attack <card-id>]".into()
}

fn parse_folders(text: &str) -> Result<Vec<String>, String> {
    let folders: Vec<String> = if text.is_empty() {
        Vec::new()
    } else {
        text.split(',').map(str::to_owned).collect()
    };
    if folders.iter().any(|name| !valid_folder(name)) {
        return Err("folders must contain src/content folder names".into());
    }
    Ok(folders)
}

fn valid_folder(name: &str) -> bool {
    !name.is_empty()
        && name != "."
        && name != ".."
        && name
            .bytes()
            .all(|c| c.is_ascii_alphanumeric() || c == b'_' || c == b'-')
}

fn recipe_for(saved: &Dictionary, fallback: &ContentRecipe) -> Result<ContentRecipe, String> {
    if !saved.has("content") {
        return Ok(fallback.clone());
    }
    match saved.get("content") {
        Variant::String(text) if text == "standin" => Ok(ContentRecipe::Folders(Vec::new())),
        Variant::Dictionary(content) => {
            let Variant::Array(folders) = content.get("folders") else {
                return Err("content folders must be an array of folder names".into());
            };
            let mut names = Vec::new();
            for raw in folders.to_vec() {
                let Variant::String(name) = raw else {
                    return Err("content folders must be an array of folder names".into());
                };
                if !valid_folder(&name) {
                    return Err("content folders must be an array of folder names".into());
                }
                names.push(name);
            }
            Ok(ContentRecipe::Folders(names))
        }
        _ => Err("content must be standin or an object with folders".into()),
    }
}

fn load_content(
    root: &Path,
    recipe: &ContentRecipe,
    plant_attack: Option<&str>,
) -> Result<GameContentRef, String> {
    let content = match recipe {
        ContentRecipe::Default => GameContent::load_default(root),
        ContentRecipe::Folders(names) => {
            let paths = names
                .iter()
                .map(|name| format!("res://src/content/{name}"))
                .collect();
            GameContent::load_folders(root, &paths)
        }
    };
    if !content.borrow().errors.is_empty() {
        return Err(format!("content errors: {:?}", content.borrow().errors));
    }
    if let Some(id) = plant_attack
        && let Some(card) = content.borrow().library.borrow().get_card(id)
    {
        let attack = card
            .borrow()
            .attack
            .checked_add(1)
            .ok_or("planted attack overflow")?;
        card.borrow_mut().attack = attack;
        eprintln!("planted in-memory attack +1 card={id}");
    }
    Ok(content)
}

fn file_path(root: &Path, path: &Path) -> PathBuf {
    path.to_str()
        .and_then(|s| s.strip_prefix("res://"))
        .map_or_else(|| path.to_owned(), |s| root.join(s))
}

fn absolute_normalized(path: &Path) -> Result<PathBuf, String> {
    if let Ok(resolved) = path.canonicalize() {
        return Ok(resolved);
    }
    let absolute = if path.is_absolute() {
        path.to_owned()
    } else {
        std::env::current_dir()
            .map_err(|e| e.to_string())?
            .join(path)
    };
    // Resolve an existing parent too, so a symlinked output directory cannot truncate cases.
    if let (Some(parent), Some(name)) = (absolute.parent(), absolute.file_name())
        && let Ok(parent) = parent.canonicalize()
    {
        return Ok(parent.join(name));
    }
    let mut clean = PathBuf::new();
    for component in absolute.components() {
        match component {
            Component::ParentDir => {
                clean.pop();
            }
            Component::CurDir => {}
            other => clean.push(other.as_os_str()),
        }
    }
    Ok(clean)
}

fn run() -> Result<(), String> {
    let opts = options(std::env::args().skip(1))?;
    let source_path = file_path(&opts.root, &opts.cases);
    let target_path = file_path(&opts.root, &opts.out);
    if absolute_normalized(&source_path)? == absolute_normalized(&target_path)? {
        return Err("cases and out must differ".into());
    }
    let mut source =
        BufReader::new(File::open(source_path).map_err(|e| format!("cannot open cases: {e}"))?);
    let mut target =
        BufWriter::new(File::create(target_path).map_err(|e| format!("cannot open out: {e}"))?);
    let initial = load_content(&opts.root, &opts.recipe, opts.plant_attack.as_deref())?;
    let mut contents = HashMap::from([(opts.recipe.clone(), initial)]);
    let mut plant_used = false;
    let started = Instant::now();
    let mut line_number = skip_lines(&mut source, opts.first).map_err(|e| e.to_string())?;
    let mut completed = 0i64;
    let mut rejected = 0i64;
    let mut bytes = Vec::new();
    while opts.count < 0 || completed < opts.count {
        bytes.clear();
        if source
            .read_until(b'\n', &mut bytes)
            .map_err(|e| e.to_string())?
            == 0
        {
            break;
        }
        line_number += 1;
        let parsed = godot_json::parse_string(&String::from_utf8_lossy(&bytes));
        let result = if let Variant::Dictionary(saved) = parsed {
            let id = saved.get_or("id", (-1i64).into()).as_i64();
            match recipe_for(&saved, &opts.recipe) {
                Err(problem) => cases::error(id, &problem),
                Ok(recipe) => {
                    let content = match contents.entry(recipe.clone()) {
                        Entry::Occupied(entry) => entry.into_mut(),
                        Entry::Vacant(entry) => entry.insert(load_content(
                            &opts.root,
                            &recipe,
                            opts.plant_attack.as_deref(),
                        )?),
                    };
                    if let Some(id) = &opts.plant_attack {
                        plant_used |= content.borrow().library.borrow().get_card(id).is_some();
                    }
                    run_case(&saved, content)
                }
            }
        } else {
            cases::error(-1, &format!("line {line_number}: expected JSON object"))
        };
        if result.has("error") {
            rejected += 1;
        }
        writeln!(
            target,
            "{}",
            godot_json::stringify(&Variant::Dictionary(result))
        )
        .map_err(|e| format!("cannot write out: {e}"))?;
        completed += 1;
        if completed % 1000 == 0 {
            target
                .flush()
                .map_err(|e| format!("cannot flush out: {e}"))?;
            eprintln!("bramble-fight progress cases={completed} rejected={rejected}");
        }
    }
    target
        .flush()
        .map_err(|e| format!("cannot flush out: {e}"))?;
    let elapsed = started.elapsed().as_micros();
    eprintln!(
        "bramble-fight cases={completed} rejected={rejected} elapsed_us={elapsed} us_per_fight={:.3} fight_only_us_per_fight={:.3}",
        elapsed as f64 / completed.max(1) as f64,
        FIGHT_NS.load(Ordering::Relaxed) as f64 / 1000.0 / completed.max(1) as f64
    );
    if opts.plant_attack.is_some() && !plant_used {
        return Err("plant-attack card is absent from every selected case's content".into());
    }
    Ok(())
}

fn skip_lines(source: &mut impl BufRead, count: u64) -> std::io::Result<u64> {
    let mut skipped = 0;
    while skipped < count {
        let available = source.fill_buf()?;
        if available.is_empty() {
            break;
        }
        let mut consumed = available.len();
        for (i, byte) in available.iter().enumerate() {
            if *byte == b'\n' {
                skipped += 1;
                if skipped == count {
                    consumed = i + 1;
                    break;
                }
            }
        }
        source.consume(consumed);
    }
    Ok(skipped)
}

fn run_case(saved: &Dictionary, content: &GameContentRef) -> Dictionary {
    let id = saved.get_or("id", (-1i64).into()).as_i64();
    if let Err(problem) = cases::validate(saved, &content.borrow()) {
        return cases::error(id, &problem);
    }
    let seed = saved
        .get("game_seed")
        .as_text()
        .parse::<i64>()
        .expect("validated seed");
    let game = content.borrow().new_session(seed, &Array::new());
    {
        let mut session = game.borrow_mut();
        session.keep_fight_events = false;
        session.round_number = saved.get("round").as_i64();
        cases::restore_player(&mut session, &saved.get("a").as_dict());
        cases::restore_player(&mut session, &saved.get("b").as_dict());
    }
    let a = saved.get("a").as_dict().get("id").as_i64();
    let b = saved.get("b").as_dict().get("id").as_i64();
    game.borrow()
        .pairings
        .push(Variant::array(vec![a.into(), b.into()]));
    // This owns damage and both after_fight contexts, including effect RNG initialization.
    let fight_started = Instant::now();
    let fight = GameSession::_fight(&game, a, b);
    FIGHT_NS.fetch_add(fight_started.elapsed().as_nanos() as u64, Ordering::Relaxed);
    cases::result(id, &fight, &game.borrow())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    // expected_hash is the full state hash from tools/league/gd/fight_run.gd.
    #[test]
    fn badger_fights_match_godot_state_hashes() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
        let content = load_content(&root, &ContentRecipe::Default, None).unwrap();
        for line in include_str!("../tests/fixtures/badger_fights.jsonl").lines() {
            let saved = godot_json::parse_string(line).as_dict();
            let result = run_case(&saved, &content);
            assert!(!result.has("error"), "{:?}", result.get("error"));
            assert_eq!(
                result.get("hash"),
                saved.get("expected_hash"),
                "{:?}",
                saved.get("mutations")
            );
        }
    }

    #[test]
    fn line_slicing_counts_physical_lines_and_skips_utf8_without_decoding() {
        let mut prefix = "☃".repeat(500_000).into_bytes();
        prefix.extend_from_slice(b"\n\n{\"id\":2}\n");
        let mut source = BufReader::with_capacity(101, Cursor::new(prefix));
        assert_eq!(skip_lines(&mut source, 2).unwrap(), 2);
        let mut next = String::new();
        source.read_line(&mut next).unwrap();
        assert_eq!(next, "{\"id\":2}\n");
        assert_eq!(skip_lines(&mut source, 1).unwrap(), 0);
    }

    #[test]
    fn content_metadata_preserves_folder_order_and_overrides_cli_default() {
        let saved =
            godot_json::parse_string(r#"{"content":{"folders":["shared","badger"]}}"#).as_dict();
        assert_eq!(
            recipe_for(&saved, &ContentRecipe::Default).unwrap(),
            ContentRecipe::Folders(vec!["shared".into(), "badger".into()])
        );
        saved.insert("content", "standin".into());
        assert_eq!(
            recipe_for(&saved, &ContentRecipe::Default).unwrap(),
            ContentRecipe::Folders(vec![])
        );
        saved.insert(
            "content",
            godot_json::parse_string(r#"{"folders":["../badger"]}"#),
        );
        assert!(recipe_for(&saved, &ContentRecipe::Default).is_err());
    }

    #[test]
    fn planted_attack_changes_only_the_loaded_content_in_memory() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
        let recipe = ContentRecipe::Folders(vec![]);
        let baseline = load_content(&root, &recipe, None).unwrap();
        let planted = load_content(&root, &recipe, Some("t1_plain")).unwrap();
        let attack = |content: &GameContentRef| {
            content
                .borrow()
                .library
                .borrow()
                .get_card("t1_plain")
                .unwrap()
                .borrow()
                .attack
        };
        assert_eq!(attack(&planted), attack(&baseline) + 1);
        assert_eq!(
            attack(&load_content(&root, &recipe, None).unwrap()),
            attack(&baseline)
        );
    }
}
