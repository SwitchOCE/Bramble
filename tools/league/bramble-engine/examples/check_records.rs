//! Replay an oracle batch and compare the generator's ordered turn-1 legal actions.
//! cargo run --offline --locked -p bramble-engine --example check_records -- DIR [prefix|full] [LIMIT]
use bramble_engine::core::{
    records::{record_replay::RecordReplay, record_state::RecordState},
    recruit::legal_actions::LegalActions,
};
use bramble_engine::util::{godot_json, godot_sort};
use bramble_engine::{ToState, Variant};
use std::path::{Path, PathBuf};
fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}
fn canonical(value: &Variant) -> String {
    godot_json::stringify(&RecordState::value(value))
}
fn run() -> Result<(), String> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    let folder = Path::new(args.first().ok_or("missing record directory")?);
    let full = args.get(1).is_some_and(|arg| arg == "full");
    let limit = args
        .get(2)
        .map(|n| n.parse::<usize>())
        .transpose()
        .map_err(|e| e.to_string())?
        .unwrap_or(usize::MAX);
    let root = Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .expect("repo root");
    let mut files: Vec<PathBuf> = std::fs::read_dir(folder)
        .map_err(|e| e.to_string())?
        .map(|entry| entry.map(|e| e.path()))
        .collect::<Result<_, _>>()
        .map_err(|e| e.to_string())?;
    files.retain(|p| {
        p.extension().is_some_and(|s| s == "jsonl")
            && !p.to_string_lossy().ends_with(".legal.jsonl")
    });
    godot_sort::sort_by(&mut files, |a, b| a < b);
    files.truncate(limit);
    if files.is_empty() {
        return Err("no records".into());
    }
    let (mut records, mut checkpoints, mut actions, mut decisions, mut turns) = (0, 0, 0, 0, 0);
    for file in files {
        let entries = RecordReplay::read_entries(&file).map_err(|e| e.message)?;
        let legal_file = file.with_extension("legal.jsonl");
        let legal = RecordReplay::read_entries(&legal_file).map_err(|e| e.message)?;
        let initial = RecordReplay::rebuild_to(root, &entries, Some(0));
        if !initial.ok {
            return Err(format!("{}: {}", file.display(), initial.message));
        }
        let game = initial.session.expect("replay session");
        let mut phase = String::from("between");
        let mut legal_index = 0;
        for index in 1..entries.len() {
            let entry = entries.get(index).expect("record entry");
            if !full && entry.get("turn").as_i64() > 1 {
                break;
            }
            let op = entry.get("op").as_text();
            if !full && op == "finish" {
                break;
            }
            if let Some(observation) = legal.get(legal_index) {
                let observed = observation.get("record_index").as_i64() as usize;
                if observed < index {
                    return Err(format!(
                        "{}: skipped legal observation {}",
                        file.display(),
                        legal_index
                    ));
                }
                if observed == index {
                    if observation.get("turn").as_i64() != 1
                        || entry.get("turn").as_i64() != 1
                        || observation.get("player").as_i64() != entry.get("player").as_i64()
                        || op != "act"
                    {
                        return Err(format!(
                            "{}: invalid legal observation {}",
                            file.display(),
                            legal_index
                        ));
                    }
                    let player = game.borrow().player(observation.get("player").as_i64());
                    let actual = LegalActions::of(&game, &player).to_state();
                    if canonical(&actual) != canonical(&observation.get("legal")) {
                        return Err(format!(
                            "{}: legal actions differ at record index {} player {}\nactual {}\nexpected {}",
                            file.display(),
                            index,
                            player.borrow().id,
                            canonical(&actual),
                            canonical(&observation.get("legal"))
                        ));
                    }
                    decisions += 1;
                    legal_index += 1;
                }
            }
            phase = RecordReplay::_step(&game, &entry, &phase).map_err(|error| {
                let dump = folder.join("rust-mismatch-state.json");
                let _ = std::fs::write(
                    &dump,
                    canonical(&Variant::Dictionary(RecordState::session_state(
                        &game.borrow(),
                    ))),
                );
                format!(
                    "{} op {} ({}) seed {}: {}; state {}",
                    file.display(),
                    index,
                    op,
                    game.borrow().seed_value,
                    error.message,
                    dump.display()
                )
            })?;
            if entry.has("hash") {
                checkpoints += 1;
            }
            if op == "act" {
                actions += 1;
            }
        }
        if legal_index != legal.len() {
            return Err(format!(
                "{}: unused legal observations {}/{}",
                file.display(),
                legal_index,
                legal.len()
            ));
        }
        if full && !game.borrow().over {
            return Err(format!("{}: incomplete replay", file.display()));
        }
        turns += game.borrow().round_number;
        records += 1;
    }
    println!(
        "PASS records={records} checkpoints={checkpoints} actions={actions} ordered_legal_decisions={decisions} turns={turns} mode={}",
        if full { "full" } else { "turn1" }
    );
    Ok(())
}
