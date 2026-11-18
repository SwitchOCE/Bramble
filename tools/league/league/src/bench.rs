//! `league bench`: the speed figures. Whole games with records.gd's seats (FlowBot even,
//! RandomBot odd), and `Sim.fight` on late-game payloads taken from records.
use crate::game::{self, GamePlan};
use crate::selfcheck::records_gd_seats;
use crate::watchdog::Watch;
use bramble_engine::util::godot_json;
use league_api::harness;
use serde_json::{Value, json};
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};
use std::time::Instant;

fn median(mut v: Vec<f64>) -> f64 {
    if v.is_empty() {
        return 0.0;
    }
    v.sort_by(|a, b| a.partial_cmp(b).expect("finite"));
    v[v.len() / 2]
}

/// Late payload pairs (round >= 12, both non-ghost, from one fight_boards line) from records.
fn late_pairs(
    dir: &Path,
    want: usize,
) -> Result<Vec<(i64, league_api::Payload, league_api::Payload)>, String> {
    let mut files: Vec<PathBuf> = std::fs::read_dir(dir)
        .map_err(|e| format!("{}: {e}", dir.display()))?
        .flatten()
        .map(|e| e.path())
        .filter(|p| {
            p.extension().is_some_and(|x| x == "jsonl")
                && !p.to_string_lossy().ends_with(".legal.jsonl")
        })
        .collect();
    files.sort();
    let mut out = Vec::new();
    for file in files {
        let reader = BufReader::new(std::fs::File::open(&file).map_err(|e| e.to_string())?);
        for line in reader.lines() {
            let line = line.map_err(|e| e.to_string())?;
            if !line.contains("\"op\":\"fight_boards\"") {
                continue;
            }
            let entry = godot_json::parse_string(&line).as_dict();
            let round = entry.get("turn").as_i64();
            if round < 12 {
                continue;
            }
            let players: Vec<_> = entry
                .get("players")
                .as_array()
                .to_vec()
                .into_iter()
                .filter(|p| p.as_dict().get("id").as_i64() >= 0)
                .collect();
            if players.len() >= 2 {
                let text = |v: &bramble_engine::Variant| godot_json::stringify(v);
                let a = league_api::Payload::from_json(&text(&players[0])).ok_or("bad payload")?;
                let b = league_api::Payload::from_json(&text(&players[1])).ok_or("bad payload")?;
                out.push((round, a, b));
                break;
            }
        }
        if out.len() >= want {
            break;
        }
    }
    Ok(out)
}

pub fn run(
    root: &Path,
    content: Option<&str>,
    games: usize,
    fight_records: Option<PathBuf>,
    fights: usize,
) -> Result<Value, String> {
    let engine = crate::engine_for(root, &|| crate::load_content(root, content))?;
    let watch = Watch::none();
    let mut game_secs = Vec::new();
    let mut rounds = Vec::new();
    for g in 0..games {
        let seed = 1 + g as i64;
        let plan = GamePlan {
            index: g,
            seed,
            swapped: false,
            rotation: 0,
            seats: records_gd_seats(seed),
            clock_ns: i64::MAX / 4,
        };
        let start = Instant::now();
        let out = game::play(&engine, plan, &watch);
        game_secs.push(start.elapsed().as_secs_f64());
        rounds.push(out.game["rounds"].as_i64().unwrap_or(0));
    }
    let profile = crate::game::PROFILE.with(|p| *p.borrow());
    let mut report = json!({
        "cpu_ms_per_game_by_part": {
            "state_hashes": profile[0] as f64 / 1e6 / games.max(1) as f64,
            "views": profile[1] as f64 / 1e6 / games.max(1) as f64,
            "engine_act": profile[2] as f64 / 1e6 / games.max(1) as f64,
            "bots": profile[3] as f64 / 1e6 / games.max(1) as f64,
            "round_stats": profile[4] as f64 / 1e6 / games.max(1) as f64,
        },
        "content": content.unwrap_or("all"),
        "games": games,
        "game_seconds_median": median(game_secs.clone()),
        "game_seconds_mean": game_secs.iter().sum::<f64>() / games.max(1) as f64,
        "rounds_mean": rounds.iter().sum::<i64>() as f64 / games.max(1) as f64,
    });
    if let Some(dir) = fight_records {
        let pairs = late_pairs(&dir, fights.min(500))?;
        if pairs.is_empty() {
            return Err("no round 12+ payload pairs found".into());
        }
        let mut cpu = Vec::new();
        let mut errors = 0;
        let mut n = 0;
        let begin = harness::thread_cpu_ns();
        while n < fights {
            let (round, a, b) = &pairs[n % pairs.len()];
            let start = harness::thread_cpu_ns();
            if harness::run_fight(&engine.sim_content, *round, a, b, n as i64).is_err() {
                errors += 1;
            }
            cpu.push((harness::thread_cpu_ns() - start) as f64 / 1e6);
            n += 1;
        }
        let total = (harness::thread_cpu_ns() - begin) as f64 / 1e6;
        let mut sorted = cpu.clone();
        sorted.sort_by(|a, b| a.partial_cmp(b).expect("finite"));
        let p90 = sorted[(sorted.len() * 9) / 10];
        report["fight"] = json!({
            "pairs": pairs.len(), "fights": n, "errors": errors,
            "cpu_ms_median": median(cpu.clone()),
            "cpu_ms_mean": total / n as f64,
            "cpu_ms_p90": p90,
        });
    }
    Ok(report)
}
