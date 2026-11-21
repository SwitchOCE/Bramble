//! `league selfcheck`: plays the games of `tools/checks/records.gd` (FlowBot on even seats,
//! RandomBot on odd, streams `Rng.derive(seed, "bot:%d" % seat)`) through the harness's own
//! game loop and baseline ports, and checks every record equals the GDScript reference record
//! line for line: same actions, same results, same state hashes.
use crate::baselines::{FlowBot, RandomBot, TribeBot, tribe_of_seat};
use crate::game::{self, GamePlan, SeatPlan};
use crate::watchdog::Watch;
use bramble_engine::core::util::rng::Rng;
use bramble_engine::util::godot_json;
use std::collections::BTreeMap;
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::Instant;

struct Reference {
    seed: i64,
    paths: Vec<String>,
    file: PathBuf,
}

fn references(dirs: &[PathBuf]) -> Result<Vec<Reference>, String> {
    let mut out = Vec::new();
    for dir in dirs {
        let mut files: Vec<PathBuf> = std::fs::read_dir(dir)
            .map_err(|e| format!("{}: {e}", dir.display()))?
            .flatten()
            .map(|e| e.path())
            .filter(|p| {
                p.extension().is_some_and(|x| x == "jsonl")
                    && !p.to_string_lossy().ends_with(".legal.jsonl")
                    && !p.to_string_lossy().contains("-changed-")
            })
            .collect();
        files.sort();
        for file in files {
            let mut line = String::new();
            BufReader::new(std::fs::File::open(&file).map_err(|e| e.to_string())?)
                .read_line(&mut line)
                .map_err(|e| e.to_string())?;
            let header = godot_json::parse_string(&line).as_dict();
            if header.get("op").as_text() != "header" {
                continue;
            }
            let seed = header
                .get("seed")
                .as_text()
                .parse::<i64>()
                .map_err(|e| format!("{}: {e}", file.display()))?;
            let paths = header
                .get("recipe")
                .as_dict()
                .get("paths")
                .as_array()
                .borrow()
                .iter()
                .map(|v| v.as_text())
                .collect();
            out.push(Reference { seed, paths, file });
        }
    }
    out.sort_by_key(|r| r.seed);
    Ok(out)
}

/// The records.gd seats for one seed.
pub fn records_gd_seats(seed: i64) -> Vec<SeatPlan> {
    (0..8)
        .map(|seat| {
            let stream = Rng::derive(seed, &format!("bot:{seat}")).borrow().clone();
            let (name, make): (&str, game::Maker) = if seat % 2 == 0 {
                ("flow", Box::new(move |_| Box::new(FlowBot::new(stream))))
            } else {
                (
                    "random",
                    Box::new(move |_| Box::new(RandomBot::new(stream))),
                )
            };
            SeatPlan {
                colour: "none",
                name: name.into(),
                make,
                sim_seed: seat as u64,
            }
        })
        .collect()
}

/// The seats of `tools/league/gd/tribe_records.gd`: the balance pass's lobby, seat `id` playing
/// TribeBot of `TRIBES[(id + seed) % 5]` with stream `Rng.derive(seed, "bot:%d" % id)`.
pub fn tribe_seats(seed: i64) -> Vec<SeatPlan> {
    (0..8)
        .map(|seat| {
            let stream = Rng::derive(seed, &format!("bot:{seat}")).borrow().clone();
            let tribe = tribe_of_seat(seat, seed);
            let make: game::Maker = Box::new(move |_| Box::new(TribeBot::new(stream, tribe)));
            SeatPlan {
                colour: "none",
                name: "tribe".into(),
                make,
                sim_seed: seat as u64,
            }
        })
        .collect()
}

pub struct Report {
    pub games: usize,
    pub matched: usize,
    pub lines: usize,
    pub acts: usize,
    pub failures: Vec<String>,
    pub seconds: f64,
}

pub fn run(
    root: &Path,
    dirs: &[PathBuf],
    limit: Option<usize>,
    threads: usize,
    keep: Option<&Path>,
) -> Result<Report, String> {
    run_with(root, dirs, limit, threads, keep, records_gd_seats)
}

/// `run`, with the seats a reference set was made with.
pub fn run_with(
    root: &Path,
    dirs: &[PathBuf],
    limit: Option<usize>,
    threads: usize,
    keep: Option<&Path>,
    seats: fn(i64) -> Vec<SeatPlan>,
) -> Result<Report, String> {
    let mut refs = references(dirs)?;
    if let Some(n) = limit {
        refs.truncate(n);
    }
    let started = Instant::now();
    let total = refs.len();
    let queue = Arc::new(Mutex::new(
        refs.into_iter().collect::<std::collections::VecDeque<_>>(),
    ));
    let results = Arc::new(Mutex::new(Vec::new()));
    let mut handles = Vec::new();
    for _ in 0..threads.max(1) {
        let (queue, results, root) = (queue.clone(), results.clone(), root.to_owned());
        let keep = keep.map(Path::to_owned);
        handles.push(std::thread::spawn(move || {
            let mut engines: BTreeMap<Vec<String>, game::Engine> = BTreeMap::new();
            let watch = Watch::none();
            loop {
                let Some(r) = queue.lock().expect("queue").pop_front() else {
                    break;
                };
                if !engines.contains_key(&r.paths) {
                    let paths = r.paths.clone();
                    match crate::engine_for(&root, &|| crate::load_recipe(&root, &paths)) {
                        Ok(e) => {
                            engines.insert(r.paths.clone(), e);
                        }
                        Err(e) => {
                            results
                                .lock()
                                .expect("results")
                                .push((r.seed, Err(e), 0, 0));
                            continue;
                        }
                    }
                }
                let engine = &engines[&r.paths];
                let plan = GamePlan {
                    index: r.seed as usize,
                    seed: r.seed,
                    swapped: false,
                    red_seats: [false; 8],
                    seats: seats(r.seed),
                    clock_ns: i64::MAX / 4,
                    log_decisions: false,
                    debug_logs: false,
                };
                let out = game::play(engine, plan, &watch);
                if let Some(dir) = &keep {
                    let _ = std::fs::create_dir_all(dir);
                    let _ = std::fs::write(dir.join(format!("seed-{}.jsonl", r.seed)), &out.record);
                }
                let reference = std::fs::read_to_string(&r.file).unwrap_or_default();
                let acts = out
                    .record
                    .lines()
                    .filter(|l| l.contains("\"op\":\"act\""))
                    .count();
                let verdict = compare(&reference, &out.record)
                    .map_err(|e| format!("seed {} ({}): {e}", r.seed, r.file.display()));
                results.lock().expect("results").push((
                    r.seed,
                    verdict,
                    out.record.lines().count(),
                    acts,
                ));
            }
        }));
    }
    for h in handles {
        h.join()
            .map_err(|_| "selfcheck thread panicked".to_string())?;
    }
    let results = std::mem::take(&mut *results.lock().expect("results"));
    let mut report = Report {
        games: total,
        matched: 0,
        lines: 0,
        acts: 0,
        failures: Vec::new(),
        seconds: 0.0,
    };
    for (_, verdict, lines, acts) in results {
        report.lines += lines;
        report.acts += acts;
        match verdict {
            Ok(()) => report.matched += 1,
            Err(e) => report.failures.push(e),
        }
    }
    report.failures.sort();
    report.seconds = started.elapsed().as_secs_f64();
    Ok(report)
}

/// Equal line for line; the first difference otherwise.
pub fn compare(reference: &str, ours: &str) -> Result<(), String> {
    let (a, b): (Vec<&str>, Vec<&str>) = (reference.lines().collect(), ours.lines().collect());
    for (i, (x, y)) in a.iter().zip(b.iter()).enumerate() {
        if x != y {
            let cut = |s: &str| s.chars().take(300).collect::<String>();
            return Err(format!(
                "line {}: reference {} | harness {}",
                i + 1,
                cut(x),
                cut(y)
            ));
        }
    }
    if a.len() != b.len() {
        return Err(format!(
            "reference has {} lines, harness {}",
            a.len(),
            b.len()
        ));
    }
    Ok(())
}
