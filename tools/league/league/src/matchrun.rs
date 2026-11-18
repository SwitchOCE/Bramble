//! `league match`: games in parallel, one per thread, outputs in game order.
use crate::game::{self, GameOut, GamePlan, SeatPlan};
use crate::watchdog::Watchdog;
use league_api::Factory;
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
    /// Optional team tags; default to the registered bot names.
    pub red_label: Option<String>,
    pub blue_label: Option<String>,
    pub games: usize,
    pub seeds: PathBuf,
    pub clock_ms: i64,
    pub threads: usize,
    pub out: PathBuf,
    pub content: Option<String>,
    pub secret: Option<String>,
    pub root: PathBuf,
    pub records: bool,
    /// Write `decisions.jsonl.gz` (about 40 MB a 1,000 games; 1.7 GB before gzip).
    pub decisions: bool,
}

pub fn read_seeds(path: &Path) -> Result<Vec<i64>, String> {
    let text = std::fs::read_to_string(path).map_err(|e| format!("{}: {e}", path.display()))?;
    parse_seeds(path, &text)
}

fn parse_seeds(path: &Path, text: &str) -> Result<Vec<i64>, String> {
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

/// Which 4 of the 8 seats are red in the first game of seed pair `pair`: a shuffle drawn from the
/// match secret, so no bot can tell its teammates from seat numbers (owner, 18 Nov). Both games
/// of a pair use the same layout with the colours swapped, so every seat is red once per pair.
pub fn red_seats(secret: &str, pair: usize) -> [bool; 8] {
    let digest = Sha256::digest(format!("{secret}|colours|{pair}").as_bytes());
    let mut order: [usize; 8] = [0, 1, 2, 3, 4, 5, 6, 7];
    // Fisher-Yates on 32-bit words of the digest; the bias of `% n` for n <= 8 is below 2^-28.
    for i in (1..8).rev() {
        let word = u32::from_le_bytes(digest[i * 4..i * 4 + 4].try_into().expect("4 bytes"));
        order.swap(i, word as usize % (i + 1));
    }
    let mut red = [false; 8];
    for &seat in &order[..4] {
        red[seat] = true;
    }
    red
}

/// Seat `seat`'s colour in a game: red on the layout's red seats, swapped on the second game.
pub fn colour(seat: usize, red: &[bool; 8], swapped: bool) -> &'static str {
    if red[seat] != swapped { "red" } else { "blue" }
}

pub fn run(args: &MatchArgs) -> Result<Value, String> {
    let red = crate::factory(&args.red)?;
    let blue = crate::factory(&args.blue)?;
    run_factories(args, red, blue)
}

/// `run` with the two bots given as constructors instead of registry names; `args.red` and
/// `args.blue` are then only labels in the logs. A team's tools crate uses it to play two
/// versions of its own bot: `run_factories(&args, red::new_bot, old_red::new_bot)`.
pub fn run_factories(args: &MatchArgs, red: Factory, blue: Factory) -> Result<Value, String> {
    league_api::harness::quiet_panics();
    // Invalidate a previous run's manifest before doing any work in a reused directory.
    match std::fs::remove_file(args.out.join("summary.json")) {
        Ok(()) => {}
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
        Err(e) => return Err(e.to_string()),
    }
    let seeds_bytes = std::fs::read(&args.seeds).map_err(|e| e.to_string())?;
    let seeds = parse_seeds(
        &args.seeds,
        std::str::from_utf8(&seeds_bytes).map_err(|e| e.to_string())?,
    )?;
    let seeds_sha256 = format!("{:x}", Sha256::digest(&seeds_bytes));
    let git_sha = std::process::Command::new("git")
        .args(["rev-parse", "HEAD"])
        .current_dir(&args.root)
        .output()
        .ok()
        .filter(|o| o.status.success())
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_owned())
        .filter(|s| !s.is_empty());
    let pairs = args.games.div_ceil(2);
    if seeds.len() < pairs {
        return Err(format!(
            "{} games need {pairs} seeds; the file has {}",
            args.games,
            seeds.len()
        ));
    }
    let secret = match &args.secret {
        Some(s) => s.clone(),
        None => new_secret()?,
    };
    std::fs::create_dir_all(args.out.join("private")).map_err(|e| e.to_string())?;
    // A rerun may fall back to plain text or disable decisions; do not leave old gzip logs.
    for name in ["shops.jsonl.gz", "decisions.jsonl.gz"] {
        match std::fs::remove_file(args.out.join(name)) {
            Ok(()) => {}
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
            Err(e) => return Err(e.to_string()),
        }
    }
    if args.records {
        std::fs::create_dir_all(args.out.join("records")).map_err(|e| e.to_string())?;
    }
    std::fs::write(args.out.join("private/secret.txt"), format!("{secret}\n"))
        .map_err(|e| e.to_string())?;
    // Use the same Library construction as the game threads and BotSetup.
    let engine = crate::engine_for(&args.root, &|| {
        crate::load_content(&args.root, args.content.as_deref())
    })?;
    let mut cards: Vec<_> = engine.library.cards().iter().collect();
    cards.sort_by(|a, b| a.id.cmp(&b.id));
    let library: Vec<Value> = cards
        .into_iter()
        .map(|c| {
            json!({
                "id": c.id, "name": c.name, "tribes": c.tribes, "tier": c.tier,
                "attack": c.attack, "health": c.health, "spell": c.spell, "token": c.token,
            })
        })
        .collect();
    std::fs::write(
        args.out.join("library.json"),
        format!("{}\n", json!(library)),
    )
    .map_err(|e| e.to_string())?;
    let build: Value = serde_json::from_str(crate::BUILD).map_err(|e| e.to_string())?;
    let rules_hash = build["rules_hash"]
        .as_str()
        .ok_or("build.json: no rules_hash")?;
    drop(engine);

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
        let (red_name, blue_name, games, records, decisions) = (
            args.red.clone(),
            args.blue.clone(),
            args.games,
            args.records,
            args.decisions,
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
                let layout = red_seats(&secret, index / 2);
                let seats = (0..8)
                    .map(|seat| {
                        let colour = colour(seat, &layout, swapped);
                        let (name, factory) = if colour == "red" {
                            (&red_name, red)
                        } else {
                            (&blue_name, blue)
                        };
                        let bot_seed = seat_seed(&secret, "bot", index, seat);
                        // TribeBot's tribe goes by seat, as in the balance pass, so all five
                        // tribes are in every lobby. The game seed stays inside the harness.
                        let tribe = (name.as_str() == "tribe")
                            .then(|| crate::baselines::tribe_of_seat(seat, seed));
                        SeatPlan {
                            colour,
                            name: name.clone(),
                            make: Box::new(move |setup| match tribe {
                                Some(t) => crate::baselines::new_tribe_as(bot_seed, t),
                                None => factory(bot_seed, setup),
                            }),
                            sim_seed: seat_seed(&secret, "sim", index, seat),
                        }
                    })
                    .collect();
                let plan = GamePlan {
                    index,
                    seed,
                    swapped,
                    red_seats: layout,
                    seats,
                    clock_ns,
                    log_decisions: decisions,
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
    let (mut games_f, mut shops_f, mut disc_f, mut rep_f, mut cpu_f, mut dec_f) = (
        file("games.jsonl")?,
        file("shops.jsonl")?,
        file("discovers.jsonl")?,
        file("reports.jsonl")?,
        file("cpu.jsonl")?,
        file("decisions.jsonl")?,
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
            for v in &out.decisions {
                line(&mut dec_f, v)?;
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
        &mut dec_f,
    ] {
        f.flush().map_err(|e| e.to_string())?;
    }
    drop(dec_f);
    if !args.decisions {
        let _ = std::fs::remove_file(args.out.join("decisions.jsonl"));
    }
    drop(shops_f);
    // -n omits the name and timestamp. Missing gzip leaves the text logs available.
    for name in ["shops.jsonl", "decisions.jsonl"] {
        if name == "decisions.jsonl" && !args.decisions {
            continue;
        }
        let gz = std::process::Command::new("gzip")
            .args(["-f", "-n"])
            .arg(args.out.join(name))
            .status();
        if !gz.is_ok_and(|s| s.success()) {
            eprintln!("league: gzip failed; {name} left uncompressed");
        }
    }
    let avg = |c: usize| {
        if seat_count[c] > 0 {
            place_sum[c] as f64 / seat_count[c] as f64
        } else {
            0.0
        }
    };
    let summary = json!({
        "schema": 1, "complete": true, "rules_hash": rules_hash, "git_sha": git_sha,
        "seeds_sha256": seeds_sha256,
        "red_label": args.red_label.as_ref().unwrap_or(&args.red),
        "blue_label": args.blue_label.as_ref().unwrap_or(&args.blue),
        "games": written, "red": args.red, "blue": args.blue, "clock_ms": args.clock_ms,
        "content": args.content.clone().unwrap_or_else(|| "all".into()),
        "red_avg_place": avg(0), "blue_avg_place": avg(1), "gap_red_minus_blue": avg(0) - avg(1),
    });
    let seconds = started.elapsed().as_secs_f64();
    let timing = json!({"seconds": seconds, "threads": args.threads, "seconds_per_game": seconds / written.max(1) as f64});
    std::fs::write(args.out.join("timing.json"), format!("{timing:#}\n"))
        .map_err(|e| e.to_string())?;
    // Publish the completion marker last, atomically; an interrupted run has no summary.
    let manifest = args.out.join("private/summary.json.tmp");
    std::fs::write(&manifest, format!("{summary:#}\n")).map_err(|e| e.to_string())?;
    std::fs::rename(manifest, args.out.join("summary.json")).map_err(|e| e.to_string())?;
    Ok(json!({"summary": summary, "timing": timing}))
}

pub fn out_path(dir: &Path, index: usize) -> PathBuf {
    dir.join(format!("game-{index:05}.jsonl"))
}
