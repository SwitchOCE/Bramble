//! `league match`: games in parallel, one per thread, outputs in game order.
use crate::game::{self, GameOut, GamePlan, SeatPlan};
use crate::watchdog::Watchdog;
use bramble_engine::core::util::rng::Rng;
use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, mpsc};
use std::time::{Duration, Instant};

pub struct MatchArgs {
    pub red: String,
    pub blue: String,
    pub games: usize,
    pub seeds: PathBuf,
    pub clock_ms: i64,
    pub threads: usize,
    pub out: PathBuf,
    pub content: Option<String>,
    pub secret: Option<String>,
    pub root: PathBuf,
    pub records: bool,
}

pub fn read_seeds(path: &Path) -> Result<Vec<i64>, String> {
    let text = std::fs::read_to_string(path).map_err(|e| format!("{}: {e}", path.display()))?;
    let mut out = Vec::new();
    for (n, line) in text.lines().enumerate() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        out.push(
            line.parse::<i64>()
                .map_err(|e| format!("{}:{}: {e}", path.display(), n + 1))?,
        );
    }
    Ok(out)
}

fn new_secret() -> Result<String, String> {
    let mut bytes = [0u8; 32];
    let mut file = std::fs::File::open("/dev/urandom").map_err(|e| e.to_string())?;
    std::io::Read::read_exact(&mut file, &mut bytes).map_err(|e| e.to_string())?;
    Ok(bytes.iter().map(|b| format!("{b:02x}")).collect())
}

/// A seat's seed: from the match secret, game index and seat, never from the game seed.
pub fn seat_seed(secret: &str, purpose: &str, game: usize, seat: usize) -> u64 {
    let digest = Sha256::digest(format!("{secret}|{purpose}|{game}|{seat}").as_bytes());
    u64::from_le_bytes(digest[..8].try_into().expect("8 bytes"))
}

/// The seat-order rotation for a seed.
pub fn rotation(seed: i64) -> i64 {
    Rng::derive(seed, "league:rotation").borrow_mut().index(8)
}

/// Seat `seat`'s colour: seats alternate, rotated by the seed, swapped on the second game.
pub fn colour(seat: usize, rotation: i64, swapped: bool) -> &'static str {
    if ((seat as i64 + rotation) % 2 == 0) != swapped {
        "red"
    } else {
        "blue"
    }
}

pub fn run(args: &MatchArgs) -> Result<Value, String> {
    league_api::harness::quiet_panics();
    let seeds = read_seeds(&args.seeds)?;
    let pairs = args.games.div_ceil(2);
    if seeds.len() < pairs {
        return Err(format!(
            "{} games need {pairs} seeds; the file has {}",
            args.games,
            seeds.len()
        ));
    }
    let red = crate::factory(&args.red)?;
    let blue = crate::factory(&args.blue)?;
    let secret = match &args.secret {
        Some(s) => s.clone(),
        None => new_secret()?,
    };
    std::fs::create_dir_all(args.out.join("private")).map_err(|e| e.to_string())?;
    if args.records {
        std::fs::create_dir_all(args.out.join("records")).map_err(|e| e.to_string())?;
    }
    std::fs::write(args.out.join("private/secret.txt"), format!("{secret}\n"))
        .map_err(|e| e.to_string())?;
    // Check the content loads before starting threads.
    crate::load_content(&args.root, args.content.as_deref())?;

    let started = Instant::now();
    let clock_ns = args.clock_ms * 1_000_000;
    let dog = Watchdog::default();
    dog.start(clock_ns, 5_000_000_000, Duration::from_secs(60));
    let next = Arc::new(AtomicUsize::new(0));
    let (send, receive) = mpsc::channel::<Result<GameOut, String>>();
    let mut handles = Vec::new();
    for _ in 0..args.threads.max(1) {
        let (next, send, dog) = (next.clone(), send.clone(), dog.clone());
        let (root, content, secret, out_dir) = (
            args.root.clone(),
            args.content.clone(),
            secret.clone(),
            args.out.clone(),
        );
        let (red_name, blue_name, games, records) = (
            args.red.clone(),
            args.blue.clone(),
            args.games,
            args.records,
        );
        let seeds = seeds.clone();
        handles.push(std::thread::spawn(move || {
            let engine = match crate::engine_for(&root, &|| {
                crate::load_content(&root, content.as_deref())
            }) {
                Ok(e) => e,
                Err(e) => {
                    let _ = send.send(Err(e));
                    return;
                }
            };
            let watch = dog.register();
            loop {
                let index = next.fetch_add(1, Ordering::SeqCst);
                if index >= games {
                    break;
                }
                let seed = seeds[index / 2];
                let swapped = index % 2 == 1;
                let rot = rotation(seed);
                let seats = (0..8)
                    .map(|seat| {
                        let colour = colour(seat, rot, swapped);
                        let (name, factory) = if colour == "red" {
                            (&red_name, red)
                        } else {
                            (&blue_name, blue)
                        };
                        let bot_seed = seat_seed(&secret, "bot", index, seat);
                        SeatPlan {
                            colour,
                            name: name.clone(),
                            make: Box::new(move |setup| factory(bot_seed, setup)),
                            sim_seed: seat_seed(&secret, "sim", index, seat),
                        }
                    })
                    .collect();
                let plan = GamePlan {
                    index,
                    seed,
                    swapped,
                    rotation: rot,
                    seats,
                    clock_ns,
                };
                let out = game::play(&engine, plan, &watch);
                if records {
                    let path = out_path(&out_dir.join("records"), index);
                    if let Err(e) = std::fs::write(&path, &out.record) {
                        let _ = send.send(Err(format!("{}: {e}", path.display())));
                        return;
                    }
                }
                if send.send(Ok(out)).is_err() {
                    return;
                }
            }
        }));
    }
    drop(send);
    let file = |name: &str| -> Result<std::io::BufWriter<std::fs::File>, String> {
        Ok(std::io::BufWriter::new(
            std::fs::File::create(args.out.join(name)).map_err(|e| e.to_string())?,
        ))
    };
    let (mut games_f, mut shops_f, mut disc_f, mut rep_f, mut cpu_f) = (
        file("games.jsonl")?,
        file("shops.jsonl")?,
        file("discovers.jsonl")?,
        file("reports.jsonl")?,
        file("cpu.jsonl")?,
    );
    let mut pending: BTreeMap<usize, GameOut> = BTreeMap::new();
    let mut written = 0;
    let mut place_sum = [0i64; 2];
    let mut seat_count = [0i64; 2];
    let mut problem = None;
    for result in receive {
        match result {
            Err(e) => {
                problem = Some(e);
                break;
            }
            Ok(out) => {
                pending.insert(out.index, out);
            }
        }
        while let Some(out) = pending.remove(&written) {
            let line = |f: &mut std::io::BufWriter<std::fs::File>, v: &Value| {
                writeln!(f, "{v}").map_err(|e| e.to_string())
            };
            line(&mut games_f, &out.game)?;
            line(&mut cpu_f, &out.cpu)?;
            for v in &out.shops {
                line(&mut shops_f, v)?;
            }
            for v in &out.discovers {
                line(&mut disc_f, v)?;
            }
            for v in &out.reports {
                line(&mut rep_f, v)?;
            }
            for (seat, seat_line) in out.game["seats"]
                .as_array()
                .expect("seats")
                .iter()
                .enumerate()
            {
                let c = usize::from(seat_line["colour"] != "red");
                place_sum[c] += out.places[seat];
                seat_count[c] += 1;
            }
            written += 1;
            if written % 100 == 0 {
                eprintln!(
                    "league: {written}/{} games ({:.0} s)",
                    args.games,
                    started.elapsed().as_secs_f64()
                );
            }
        }
    }
    for h in handles {
        let _ = h.join();
    }
    if let Some(e) = problem {
        return Err(e);
    }
    if written != args.games {
        return Err(format!("only {written} of {} games finished", args.games));
    }
    for f in [
        &mut games_f,
        &mut shops_f,
        &mut disc_f,
        &mut rep_f,
        &mut cpu_f,
    ] {
        f.flush().map_err(|e| e.to_string())?;
    }
    let avg = |c: usize| {
        if seat_count[c] > 0 {
            place_sum[c] as f64 / seat_count[c] as f64
        } else {
            0.0
        }
    };
    let summary = json!({
        "games": written, "red": args.red, "blue": args.blue, "clock_ms": args.clock_ms,
        "content": args.content.clone().unwrap_or_else(|| "all".into()),
        "red_avg_place": avg(0), "blue_avg_place": avg(1), "gap_red_minus_blue": avg(0) - avg(1),
    });
    std::fs::write(args.out.join("summary.json"), format!("{summary:#}\n"))
        .map_err(|e| e.to_string())?;
    let seconds = started.elapsed().as_secs_f64();
    let timing = json!({"seconds": seconds, "threads": args.threads, "seconds_per_game": seconds / written.max(1) as f64});
    std::fs::write(args.out.join("timing.json"), format!("{timing:#}\n"))
        .map_err(|e| e.to_string())?;
    Ok(json!({"summary": summary, "timing": timing}))
}

pub fn out_path(dir: &Path, index: usize) -> PathBuf {
    dir.join(format!("game-{index:05}.jsonl"))
}
