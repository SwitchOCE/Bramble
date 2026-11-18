mod observe;

use bramble_engine::core::records::{
    game_record::GameRecord, record_build::RecordBuild, record_replay::RecordReplay,
    record_state::RecordState,
};
use bramble_engine::{Dictionary, Variant};
use observe::{Observer, Report};
use serde_json::Value;
use std::{
    fs::{self, File, OpenOptions},
    io::{BufWriter, Write},
    path::{Component, Path, PathBuf},
    process::{Command, Stdio},
};

type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

fn main() {
    if let Err(error) = run() {
        eprintln!("bramble-events: {error}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let mut args = std::env::args_os().skip(1);
    let directory = PathBuf::from(
        args.next()
            .ok_or("usage: bramble-events MATCH_DIR [--example]")?,
    );
    let flag = args.next();
    let example = flag.as_ref().is_some_and(|flag| flag == "--example");
    if (flag.is_some() && !example) || args.next().is_some() {
        return Err("usage: bramble-events MATCH_DIR [--example]".into());
    }
    let root = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../..")
        .canonicalize()?;
    let rules_hash = RecordBuild::identity(&root).get("rules_hash");
    let records = records(&directory)?;

    let output = directory.join("events.jsonl.gz");
    let staged = directory.join(format!(".events.{}.tmp", std::process::id()));
    let file = OpenOptions::new()
        .create_new(true)
        .write(true)
        .open(&staged)?;
    let mut clean = Staged(staged);
    let mut gzip = Command::new("gzip")
        .arg("-n")
        .stdin(Stdio::piped())
        .stdout(file)
        .spawn()?;
    let result = {
        let mut writer = BufWriter::new(gzip.stdin.take().expect("gzip stdin"));
        write_events(&mut writer, &root, &rules_hash, &records, example).and_then(|report| {
            writer.flush()?;
            Ok(report)
        })
    };
    let status = gzip.wait()?;
    let (checked, totals, example) = result?;
    if !status.success() {
        return Err(format!("gzip failed: {status}").into());
    }
    fs::rename(&clean.0, &output)?;
    clean.0.clear();
    println!(
        "{} games, {checked} verified hashes. Wrote {}",
        records.len(),
        output.display()
    );
    println!(
        "Final-board Gorgers: {}/{} reconciled ({} with other permanent buffs, {} with triple ancestry).",
        totals.exact, totals.gorgers, totals.other, totals.triples
    );
    if let Some(example) = example {
        println!(
            "Gorger sale example\n{}",
            serde_json::to_string_pretty(&example)?
        );
    }
    Ok(())
}

struct Staged(PathBuf);
impl Drop for Staged {
    fn drop(&mut self) {
        if !self.0.as_os_str().is_empty() {
            let _ = fs::remove_file(&self.0);
        }
    }
}

fn records(directory: &Path) -> Result<Vec<(usize, PathBuf)>> {
    let mut out = Vec::new();
    for file in fs::read_dir(directory.join("records"))? {
        let path = file?.path();
        if let Some(number) = path
            .file_name()
            .and_then(|name| name.to_str())
            .and_then(|name| name.strip_prefix("game-")?.strip_suffix(".jsonl"))
        {
            out.push((number.parse()?, path));
        }
    }
    out.sort_by_key(|(game, _)| *game);
    if out.is_empty()
        || out
            .iter()
            .enumerate()
            .any(|(index, (game, _))| index != *game)
    {
        return Err("expected consecutively numbered records starting at game 0".into());
    }
    let summary = directory.join("summary.json");
    if summary.try_exists()? {
        let manifest: Value = serde_json::from_reader(File::open(summary)?)?;
        if manifest["complete"] != true || manifest["games"].as_u64() != Some(out.len() as u64) {
            return Err("records do not match the completed match manifest".into());
        }
    }
    Ok(out)
}

fn write_events(
    writer: &mut impl Write,
    root: &Path,
    rules_hash: &Variant,
    records: &[(usize, PathBuf)],
    example: bool,
) -> Result<(usize, Report, Option<Value>)> {
    let mut checked = 0;
    let mut totals = Report::default();
    let mut sample = None;
    for (game, path) in records {
        let (hashes, report, found) = replay(
            writer,
            root,
            rules_hash,
            *game,
            path,
            example && sample.is_none(),
        )
        .map_err(|error| format!("{}: {error}", path.display()))?;
        checked += hashes;
        totals.add(report);
        sample = sample.or(found);
    }
    Ok((checked, totals, sample))
}

fn replay(
    writer: &mut impl Write,
    root: &Path,
    rules_hash: &Variant,
    number: usize,
    path: &Path,
    example: bool,
) -> Result<(usize, Report, Option<Value>)> {
    let entries = RecordReplay::read_entries(path).map_err(|e| e.message)?;
    let header = entries.get(0).ok_or("empty record")?;
    if header.get("op").as_text() != "header" || header.get("format").as_i64() != GameRecord::FORMAT
    {
        return Err("unsupported record format".into());
    }
    if header.get("build").as_dict().get("rules_hash") != *rules_hash {
        return Err("build differs; use the build that wrote the record".into());
    }
    let game = RecordReplay::_create(root, &local_header(&header, root)?).map_err(|e| e.message)?;
    if header.get("initial_hash").as_text() != RecordState::state_hash(&game.borrow()) {
        return Err("initial state differs".into());
    }

    // The engine excludes historical logs and this flag from the state hash.
    game.borrow_mut().keep_fight_events = true;
    let mut observer = Observer::new(number, example);
    let mut checked = 1;
    let mut phase = "between".to_owned();
    for (index, entry) in entries.borrow().iter().enumerate().skip(1) {
        let before = observer.before(&game, entry);
        phase = RecordReplay::_step(&game, entry, &phase)
            .map_err(|e| format!("line {}: {}", index + 1, e.message))?;
        let op = entry.get("op").as_text();
        checked += usize::from(matches!(op.as_str(), "start" | "fight_boards" | "finish"));
        for row in observer.after(&game, entry, before)? {
            serde_json::to_writer(&mut *writer, &row)?;
            writer.write_all(b"\n")?;
        }
    }
    if phase != "between" || !game.borrow().over {
        return Err("incomplete record".into());
    }
    Ok((checked, observer.report(), observer.example))
}

fn local_header(header: &Dictionary, root: &Path) -> Result<Dictionary> {
    let header = header.duplicate();
    let recipe = header.get("recipe").as_dict().duplicate();
    let paths = recipe.get("paths").as_array();
    let local = paths
        .borrow()
        .iter()
        .map(|entry| {
            let path = entry.as_text();
            let suffix = path
                .rsplit_once("/src/content/")
                .map(|(_, suffix)| suffix)
                .or_else(|| path.strip_prefix("src/content/"))
                .ok_or_else(|| format!("cannot relocate content folder {path:?}"))?;
            let relative = Path::new(suffix);
            let content = root.join("src/content").canonicalize()?;
            if suffix.is_empty()
                || relative
                    .components()
                    .any(|c| !matches!(c, Component::Normal(_)))
            {
                return Err(format!("invalid content folder {path:?}").into());
            }
            let local = content.join(relative).canonicalize()?;
            if !local.starts_with(content) {
                return Err(format!("content folder escapes the checkout: {path:?}").into());
            }
            Ok(Variant::from(local.to_string_lossy().into_owned()))
        })
        .collect::<Result<bramble_engine::Array<_>>>()?;
    recipe.insert("paths", Variant::Array(local));
    header.insert("recipe", Variant::Dictionary(recipe));
    Ok(header)
}
