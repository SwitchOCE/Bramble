//! `blue-tools cardpower <corpus-dir> <out.json> [options]`: each shop card's marginal fight
//! value, measured on the real engine. See `../CARDPOWER.md` for the method.
//!
//! For each round bucket it draws samples (A, B, fight seed): A is a fight payload from the
//! corpus's records, B another game's payload of the same round. For every card X it fights
//! A + X against B with the same seed and scores (A+X result) - (A result), a tie counting half.
//! X goes in by two row rules (front, back; see `place_for`; a full board replaces A's weakest
//! unit of that row) and the better rule's mean is the card's delta.
use league_api::{CardInfo, Library, Payload, SnapUnit, harness};
use serde_json::{Value, json};
use std::collections::BTreeMap;
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};

const USAGE: &str = "usage: blue-tools cardpower <corpus-dir> <out.json> [--pairs N] \
[--golden-pairs N] [--seeds-per-pair K] [--buckets 1-3,4-6,7-9,10-12,13-99] \
[--golden 7-9,13-99] [--seed S] [--max-fights-per-bucket F]";

/// splitmix64: the tool's own stream (sampling and fight seeds).
struct Mix(u64);
impl Mix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9e37_79b9_7f4a_7c15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xbf58_476d_1ce4_e5b9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94d0_49bb_1331_11eb);
        z ^ (z >> 31)
    }
    fn below(&mut self, n: usize) -> usize {
        (self.next() % n as u64) as usize
    }
}

/// One fight payload from the corpus.
struct Entry {
    game: usize,
    round: i64,
    text: String,
}

struct Args {
    corpus: PathBuf,
    out: PathBuf,
    pairs: usize,
    golden_pairs: usize,
    seeds_per_pair: usize,
    buckets: Vec<(i64, i64)>,
    golden: Vec<(i64, i64)>,
    seed: u64,
    max_fights: u64,
}

fn parse_ranges(text: &str) -> Result<Vec<(i64, i64)>, String> {
    text.split(',')
        .filter(|s| !s.is_empty())
        .map(|r| {
            let (a, b) = r.split_once('-').ok_or(format!("bad range {r}"))?;
            Ok((
                a.parse().map_err(|e| format!("{r}: {e}"))?,
                b.parse().map_err(|e| format!("{r}: {e}"))?,
            ))
        })
        .collect()
}

fn parse_args(args: &[String]) -> Result<Args, String> {
    let mut out = Args {
        corpus: PathBuf::new(),
        out: PathBuf::new(),
        pairs: 450,
        golden_pairs: 200,
        seeds_per_pair: 1,
        buckets: parse_ranges("1-3,4-6,7-9,10-12,13-99")?,
        golden: parse_ranges("7-9,13-99")?,
        seed: 1,
        max_fights: u64::MAX,
    };
    let mut positional = Vec::new();
    let mut i = 0;
    while i < args.len() {
        let a = &args[i];
        if let Some(name) = a.strip_prefix("--") {
            let v = args.get(i + 1).ok_or(format!("--{name} needs a value\n{USAGE}"))?;
            let num = |v: &str| v.parse::<u64>().map_err(|e| format!("--{name}: {e}"));
            match name {
                "pairs" => out.pairs = num(v)? as usize,
                "golden-pairs" => out.golden_pairs = num(v)? as usize,
                "seeds-per-pair" => out.seeds_per_pair = num(v)?.max(1) as usize,
                "buckets" => out.buckets = parse_ranges(v)?,
                "golden" => out.golden = parse_ranges(v)?,
                "seed" => out.seed = num(v)?,
                "max-fights-per-bucket" => out.max_fights = num(v)?,
                _ => return Err(format!("unknown option --{name}\n{USAGE}")),
            }
            i += 2;
        } else {
            positional.push(a.clone());
            i += 1;
        }
    }
    let [corpus, json_out] = positional.as_slice() else {
        return Err(USAGE.into());
    };
    out.corpus = corpus.into();
    out.out = json_out.into();
    Ok(out)
}

/// Every non-ghost fight payload in `<dir>/records/*.jsonl` (or `<dir>/*.jsonl`).
fn load_corpus(dir: &Path) -> Result<Vec<Entry>, String> {
    let records = if dir.join("records").is_dir() {
        dir.join("records")
    } else {
        dir.to_path_buf()
    };
    let mut files: Vec<PathBuf> = std::fs::read_dir(&records)
        .map_err(|e| format!("{}: {e}", records.display()))?
        .flatten()
        .map(|e| e.path())
        .filter(|p| p.extension().is_some_and(|x| x == "jsonl"))
        .collect();
    files.sort();
    let mut out = Vec::new();
    for (game, file) in files.iter().enumerate() {
        let reader = BufReader::new(std::fs::File::open(file).map_err(|e| e.to_string())?);
        for line in reader.lines() {
            let line = line.map_err(|e| e.to_string())?;
            if !line.contains("\"op\":\"fight_boards\"") {
                continue;
            }
            let v: Value = serde_json::from_str(&line).map_err(|e| e.to_string())?;
            let round = v["turn"].as_i64().unwrap_or(0);
            for p in v["players"].as_array().into_iter().flatten() {
                if p["id"].as_i64().unwrap_or(-1) < 0 {
                    continue;
                }
                out.push(Entry {
                    game,
                    round,
                    text: p.to_string(),
                });
            }
        }
    }
    Ok(out)
}

/// A unit's attack + health now, from its snapshot layers.
fn unit_total(lib: &Library, u: &SnapUnit) -> i64 {
    let Some(card) = lib.get(&u.def()) else {
        return 0;
    };
    let g = if u.golden() { 2 } else { 1 };
    let side = |name: &str, base: i64| {
        let mut v = u.stat(&format!("base_{name}")).unwrap_or(base * g);
        if let Some(set) = u.stat(&format!("set_{name}")) {
            if set != -1 {
                v = set;
            }
        }
        for layer in ["perm", "turn", "combat", "aura", "slot"] {
            v += u.stat(&format!("{layer}_{name}")).unwrap_or(0);
        }
        v
    };
    side("attack", card.attack) + side("health", card.health)
}

/// Where X goes under a placement rule, as (slot for X, optional (from, to) move of one of A's
/// units first). Front rule: the first empty front slot; else A's weakest front unit moves to
/// the first empty back slot and X takes its place; else X replaces the weakest front unit.
/// Back rule: the first empty back slot; else the first empty front slot; else X replaces the
/// weakest back unit.
fn place_for(
    lib: &Library,
    board: &[Option<SnapUnit>],
    back_rule: bool,
) -> (usize, Option<(usize, usize)>) {
    let empty = |s: &usize| board.get(*s).is_some_and(|u| u.is_none());
    let weakest = |row: std::ops::Range<usize>| {
        row.filter(|&s| board.get(s).is_some_and(|u| u.is_some()))
            .min_by_key(|&s| board[s].as_ref().map_or(0, |u| unit_total(lib, u)))
    };
    let first_front = (0..4).find(empty);
    let first_back = (4..7).find(empty);
    if back_rule {
        if let Some(s) = first_back.or(first_front) {
            return (s, None);
        }
        return (weakest(4..7).or(weakest(0..4)).unwrap_or(4), None);
    }
    if let Some(s) = first_front {
        return (s, None);
    }
    let w = weakest(0..4).unwrap_or(0);
    match first_back {
        Some(to) => (w, Some((w, to))),
        None => (w, None),
    }
}

/// A with X put in by `place`.
fn with_card(a: &Payload, board: &[Option<SnapUnit>], place: (usize, Option<(usize, usize)>), x: SnapUnit) -> Payload {
    let mut out = a.clone();
    if let Some((from, to)) = place.1 {
        out.set_board(to, board[from].clone());
    }
    out.set_board(place.0, Some(x));
    out
}

/// Units of A having each tribe ("All" units count for every tribe).
fn tribe_counts(lib: &Library, board: &[Option<SnapUnit>], tribes: &[String]) -> Vec<i64> {
    tribes
        .iter()
        .map(|t| {
            board
                .iter()
                .flatten()
                .filter(|u| lib.get(&u.def()).is_some_and(|c| c.has_tribe(t)))
                .count() as i64
        })
        .collect()
}

#[derive(Clone, Default)]
struct Acc {
    n: u64,
    sum: f64,
    sq: f64,
}
impl Acc {
    fn add(&mut self, d: f64) {
        self.n += 1;
        self.sum += d;
        self.sq += d * d;
    }
    fn mean(&self) -> Option<f64> {
        (self.n > 0).then(|| self.sum / self.n as f64)
    }
    fn se(&self) -> Option<f64> {
        if self.n < 2 {
            return None;
        }
        let m = self.sum / self.n as f64;
        let var = (self.sq / self.n as f64 - m * m).max(0.0) * self.n as f64 / (self.n - 1) as f64;
        Some((var / self.n as f64).sqrt())
    }
}

/// Per card, per placement rule (0 front-first, 1 back-first): all, in tribe, off tribe.
#[derive(Clone, Default)]
struct CardAcc {
    rule: [[Acc; 3]; 2],
    golden: Acc,
}

fn score(outcome: &Result<league_api::FightOutcome, String>) -> Option<f64> {
    outcome.as_ref().ok().map(|o| match o.winner {
        0 => 1.0,
        1 => 0.0,
        _ => 0.5,
    })
}

struct Sample {
    round: i64,
    a: Payload,
    b: Payload,
    seed: i64,
    base: f64,
    counts: Vec<i64>,
}

fn round4(x: Option<f64>) -> Value {
    x.map_or(Value::Null, |x| json!((x * 10000.0).round() / 10000.0))
}

/// Writes the table so far (buckets not yet run are null).
fn write_doc(
    args: &Args,
    cards: &[CardInfo],
    accs: &[Vec<CardAcc>],
    timing: &[Value],
    fight_errors: u64,
    complete: bool,
) -> Result<(), String> {
    let nb = args.buckets.len();
    let mut out_cards = serde_json::Map::new();
    for (ci, card) in cards.iter().enumerate() {
        let mut delta = Vec::new();
        let mut se = Vec::new();
        let mut front = Vec::new();
        let mut back = Vec::new();
        let mut best_row = Vec::new();
        let mut in_t = Vec::new();
        let mut off_t = Vec::new();
        let mut n_in = Vec::new();
        let mut n = Vec::new();
        let mut gold = Vec::new();
        let mut gold_se = Vec::new();
        for bi in 0..nb {
            let c = &accs[bi][ci];
            let m = |r: usize| c.rule[r][0].mean();
            let r = if m(1).unwrap_or(f64::MIN) > m(0).unwrap_or(f64::MIN) { 1 } else { 0 };
            delta.push(round4(m(r)));
            se.push(round4(c.rule[r][0].se()));
            front.push(round4(m(0)));
            back.push(round4(m(1)));
            best_row.push(if c.rule[0][0].n == 0 { Value::Null } else { json!(if r == 1 { "back" } else { "front" }) });
            in_t.push(round4(c.rule[r][1].mean()));
            off_t.push(round4(c.rule[r][2].mean()));
            n_in.push(json!(c.rule[r][1].n));
            n.push(json!(c.rule[r][0].n));
            gold.push(round4(c.golden.mean()));
            gold_se.push(round4(c.golden.se()));
        }
        out_cards.insert(
            card.id.clone(),
            json!({
                "name": card.name, "tier": card.tier, "tribes": card.tribes,
                "attack": card.attack, "health": card.health,
                "delta": delta, "se": se, "delta_in_tribe": in_t, "delta_off_tribe": off_t,
                "n": n, "n_in_tribe": n_in,
                "delta_front": front, "delta_back": back, "best_row": best_row,
                "golden_delta": gold, "golden_se": gold_se,
            }),
        );
    }
    let buckets: Vec<Value> = args.buckets.iter().map(|&(a, b)| json!([a, b])).collect();
    let doc = json!({
        "buckets": buckets,
        "method": "delta = P(A+X beats B) - P(A beats B), tie = 1/2, same fight seed for both; \
A and B are same-round payloads from different games of the corpus; X fresh (no buffs) in the \
better of two row rules. Front: first empty front slot, else A's weakest front unit moves to an \
empty back slot and X takes its place, else X replaces the weakest front unit. Back: first empty \
back slot, else first empty front slot, else X replaces the weakest back unit (weakest = lowest \
attack + health). In tribe: A has >= 3 units of one of X's tribes before X is added. \
Recruit-phase text (battlecries, end of turn, shop effects) never runs: this is fight value only.",
        "corpus": args.corpus.display().to_string(),
        "pairs": args.pairs, "seeds_per_pair": args.seeds_per_pair, "golden_pairs": args.golden_pairs,
        "seed": args.seed, "fight_errors": fight_errors, "timing": timing,
        "complete": complete,
        "cards": Value::Object(out_cards),
    });
    let text = serde_json::to_string_pretty(&doc).map_err(|e| e.to_string())?;
    if let Some(dir) = args.out.parent() {
        std::fs::create_dir_all(dir).map_err(|e| e.to_string())?;
    }
    // Written to a side file and renamed, so a timeout never leaves a half-written table.
    let tmp = args.out.with_extension("json.tmp");
    let mut f = std::fs::File::create(&tmp).map_err(|e| format!("{}: {e}", tmp.display()))?;
    f.write_all(text.as_bytes()).map_err(|e| e.to_string())?;
    f.write_all(b"\n").map_err(|e| e.to_string())?;
    drop(f);
    std::fs::rename(&tmp, &args.out).map_err(|e| e.to_string())?;
    Ok(())
}

pub fn main(args: &[String]) -> Result<(), String> {
    let args = parse_args(args)?;
    let root = league::default_root();
    let engine = league::engine_for(&root, &|| league::load_content(&root, None))?;
    let lib = engine.library.clone();
    let content = &engine.sim_content;
    let cards: Vec<_> = lib
        .cards()
        .iter()
        .filter(|c| !c.spell && c.in_pool())
        .cloned()
        .collect();
    let mut tribes: Vec<String> = Vec::new();
    for c in lib.cards() {
        for t in &c.tribes {
            if t != "All" && !tribes.contains(t) {
                tribes.push(t.clone());
            }
        }
    }
    tribes.sort();
    // X's tribe indexes (All: every tribe).
    let card_tribes: Vec<Vec<usize>> = cards
        .iter()
        .map(|c| {
            (0..tribes.len())
                .filter(|&i| c.has_tribe(&tribes[i]))
                .collect()
        })
        .collect();

    let t0 = std::time::Instant::now();
    let corpus = load_corpus(&args.corpus)?;
    eprintln!(
        "corpus: {} payloads from {} in {:.1}s; {} cards",
        corpus.len(),
        args.corpus.display(),
        t0.elapsed().as_secs_f64(),
        cards.len()
    );
    let mut by_round: BTreeMap<i64, Vec<usize>> = BTreeMap::new();
    for (i, e) in corpus.iter().enumerate() {
        by_round.entry(e.round).or_default().push(i);
    }

    let mut rng = Mix(args.seed ^ 0x5eed_cafe);
    let nb = args.buckets.len();
    let mut accs: Vec<Vec<CardAcc>> = vec![vec![CardAcc::default(); cards.len()]; nb];
    let mut samples_n = vec![0u64; nb];
    let mut golden_n = vec![0u64; nb];
    let mut timing = Vec::new();
    let mut fight_errors = 0u64;
    let uid = 987_654;

    for (bi, &(lo, hi)) in args.buckets.iter().enumerate() {
        let pool: Vec<usize> = by_round
            .range(lo..=hi)
            .flat_map(|(_, v)| v.iter().copied())
            .collect();
        if pool.is_empty() {
            eprintln!("bucket {lo}-{hi}: no payloads");
            continue;
        }
        let start = harness::thread_cpu_ns();
        let mut fights = 0u64;
        let mut samples: Vec<Sample> = Vec::new();
        let mut pair = 0;
        while pair < args.pairs && fights < args.max_fights {
            let ai = pool[rng.below(pool.len())];
            let a_entry = &corpus[ai];
            let same: Vec<usize> = by_round[&a_entry.round]
                .iter()
                .copied()
                .filter(|&j| corpus[j].game != a_entry.game)
                .collect();
            if same.is_empty() {
                continue;
            }
            let b_entry = &corpus[same[rng.below(same.len())]];
            let (Some(a), Some(b)) = (
                Payload::from_json(&a_entry.text),
                Payload::from_json(&b_entry.text),
            ) else {
                return Err("bad payload JSON in corpus".into());
            };
            pair += 1;
            let board = a.board();
            let counts = tribe_counts(&lib, &board, &tribes);
            let places = [place_for(&lib, &board, false), place_for(&lib, &board, true)];
            for _ in 0..args.seeds_per_pair {
                let seed = (rng.next() >> 2) as i64;
                fights += 1;
                let Some(base) = score(&harness::run_fight(content, a_entry.round, &a, &b, seed))
                else {
                    fight_errors += 1;
                    continue;
                };
                samples_n[bi] += 1;
                for (ci, card) in cards.iter().enumerate() {
                    let best = card_tribes[ci].iter().map(|&t| counts[t]).max();
                    let mut last: Option<((usize, Option<(usize, usize)>), f64)> = None;
                    for (rule, &place) in places.iter().enumerate() {
                        let d = match last {
                            Some((p, d)) if p == place => d,
                            _ => {
                                let x = SnapUnit::fresh(&card.id, uid, false);
                                let a2 = with_card(&a, &board, place, x);
                                fights += 1;
                                let r = harness::run_fight(content, a_entry.round, &a2, &b, seed);
                                let Some(s) = score(&r) else {
                                    fight_errors += 1;
                                    continue;
                                };
                                s - base
                            }
                        };
                        last = Some((place, d));
                        let acc = &mut accs[bi][ci].rule[rule];
                        acc[0].add(d);
                        match best {
                            Some(c) if c >= 3 => acc[1].add(d),
                            _ => acc[2].add(d),
                        }
                    }
                }
                samples.push(Sample {
                    round: a_entry.round,
                    a: a.clone(),
                    b: b.clone(),
                    seed,
                    base,
                    counts: counts.clone(),
                });
            }
        }
        let main_cpu = (harness::thread_cpu_ns() - start) as f64 / 1e9;
        // Golden pass, at each card's better rule, on the first samples of this bucket.
        let mut gold_fights = 0u64;
        let gstart = harness::thread_cpu_ns();
        if args.golden.contains(&(lo, hi)) {
            let rules: Vec<usize> = accs[bi]
                .iter()
                .map(|c| {
                    let m = |r: usize| c.rule[r][0].mean().unwrap_or(f64::MIN);
                    if m(1) > m(0) { 1 } else { 0 }
                })
                .collect();
            for s in samples.iter().take(args.golden_pairs * args.seeds_per_pair) {
                golden_n[bi] += 1;
                let board = s.a.board();
                let _ = &s.counts;
                for (ci, card) in cards.iter().enumerate() {
                    let place = place_for(&lib, &board, rules[ci] == 1);
                    let x = SnapUnit::fresh(&card.id, uid, true);
                    let a2 = with_card(&s.a, &board, place, x);
                    gold_fights += 1;
                    match score(&harness::run_fight(content, s.round, &a2, &s.b, s.seed)) {
                        Some(r) => accs[bi][ci].golden.add(r - s.base),
                        None => fight_errors += 1,
                    }
                }
            }
        }
        let gold_cpu = (harness::thread_cpu_ns() - gstart) as f64 / 1e9;
        let per = (main_cpu + gold_cpu) * 1e3 / (fights + gold_fights).max(1) as f64;
        eprintln!(
            "bucket {lo}-{hi}: {} samples ({} payloads), {} fights in {:.1}s cpu; golden {} samples, {} fights in {:.1}s; {:.3} ms/fight",
            samples_n[bi],
            pool.len(),
            fights,
            main_cpu,
            golden_n[bi],
            gold_fights,
            gold_cpu,
            per
        );
        timing.push(json!({
            "bucket": [lo, hi], "payloads": pool.len(), "samples": samples_n[bi],
            "fights": fights, "cpu_s": (main_cpu * 10.0).round() / 10.0,
            "golden_samples": golden_n[bi], "golden_fights": gold_fights,
            "golden_cpu_s": (gold_cpu * 10.0).round() / 10.0,
            "ms_per_fight": (per * 1000.0).round() / 1000.0,
        }));
        write_doc(&args, &cards, &accs, &timing, fight_errors, false)?;
        eprintln!("bucket {lo}-{hi} written to {}", args.out.display());
    }

    write_doc(&args, &cards, &accs, &timing, fight_errors, true)?;
    eprintln!(
        "wrote {} ({} cards) in {:.0}s wall, {} fight errors",
        args.out.display(),
        cards.len(),
        t0.elapsed().as_secs_f64(),
        fight_errors
    );
    Ok(())
}
