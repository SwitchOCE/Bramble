//! Reuse a completed match's boards and pairings for paired combat comparisons.
mod input;
mod modes;
mod restore;
mod switch;

pub use modes::{ModeReport, Modes, run as run_modes};

use bramble_engine::{Dictionary, Variant};
use serde_json::{Value, json};
use std::collections::{BTreeMap, BTreeSet};
use std::fmt;
use std::fs::{self, File};
use std::io::{BufWriter, Write};
use std::path::Path;
use std::str::FromStr;

#[derive(Debug)]
pub struct Selection {
    tribe: String,
    min: usize,
}

impl FromStr for Selection {
    type Err = String;

    fn from_str(rule: &str) -> Result<Self, Self::Err> {
        let invalid =
            || format!("usage: invalid selection {rule:?}, expected tribe:<name>[:<positive min>]");
        let rest = rule.strip_prefix("tribe:").ok_or_else(invalid)?;
        let (tribe, min) = match rest.split_once(':') {
            Some((tribe, min)) => (tribe, min.parse().map_err(|_| invalid())?),
            None => (rest, 4),
        };
        if tribe.trim().is_empty() || tribe.trim() != tribe || min == 0 {
            return Err(invalid());
        }
        Ok(Self {
            tribe: tribe.to_lowercase(),
            min,
        })
    }
}

struct Selector<'a> {
    rule: &'a Selection,
    cards: BTreeMap<String, bool>,
}

impl<'a> Selector<'a> {
    fn load(rule: &'a Selection, dir: &Path) -> Result<Self, String> {
        let library = input::read_json(&dir.join("library.json"))?;
        let cards = library
            .as_array()
            .ok_or("library.json: expected a card array")?;
        let mut known = BTreeSet::new();
        let mut matches = BTreeMap::new();
        for card in cards {
            let id = card["id"].as_str().ok_or("library.json: missing card id")?;
            let tribes = card["tribes"]
                .as_array()
                .ok_or("library.json: missing card tribes")?;
            let mut qualified = false;
            for tribe in tribes {
                let tribe = tribe
                    .as_str()
                    .ok_or("library.json: invalid tribe name")?
                    .to_lowercase();
                qualified |= tribe == rule.tribe || tribe == "all";
                known.insert(tribe);
            }
            matches.insert(id.to_owned(), qualified && card["spell"] == false);
        }
        if !known.contains(&rule.tribe) {
            return Err(format!(
                "tribe {:?} is absent from the baseline library",
                rule.tribe
            ));
        }
        Ok(Self {
            rule,
            cards: matches,
        })
    }

    fn qualifies(&self, payload: &Dictionary) -> Result<bool, String> {
        let mut count = 0;
        for unit in restore::units(payload, "board")?.to_vec() {
            if unit == Variant::Nil {
                continue;
            }
            let id = restore::card_id(&unit.as_dict())?;
            let matches = self
                .cards
                .get(&id)
                .ok_or_else(|| format!("card {id} is absent from baseline library"))?;
            count += usize::from(*matches);
        }
        Ok(count >= self.rule.min)
    }
}

#[derive(Debug, Default, PartialEq, Eq)]
pub struct Report {
    pub total: usize,
    pub selected: usize,
    pub reproduced: usize,
    pub mismatches: usize,
    pub missing_cards: usize,
    pub unrestorable: usize,
    verifying: bool,
}

impl Report {
    pub fn verify(&self) -> Result<(), String> {
        if self.verifying && self.total > 0 && self.reproduced == self.total {
            Ok(())
        } else {
            Err(format!(
                "verification failed: {} / {} fights reproduced",
                self.reproduced, self.total
            ))
        }
    }
}

impl fmt::Display for Report {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "refight: {} of {} fights selected, {} skipped ({} missing cards, {} unrestorable)",
            self.selected,
            self.total,
            self.missing_cards + self.unrestorable,
            self.missing_cards,
            self.unrestorable
        )?;
        if self.verifying {
            write!(
                f,
                "\nverify: {} / {} fights reproduced ({} mismatches)",
                self.reproduced, self.total, self.mismatches
            )?;
        }
        Ok(())
    }
}

type Verdict = Result<restore::Outcome, restore::Skip>;

struct Comparison<'a> {
    game: usize,
    round: i64,
    original: &'a input::Fight,
    qualifying: [bool; 2],
    verdict: Verdict,
}

impl Comparison<'_> {
    fn mismatch(&self, new: &restore::Outcome) -> Option<String> {
        if (self.original.winner, self.original.damage) != (new.winner, new.damage) {
            return Some(format!(
                "winner/damage {:?}/{} became {:?}/{}",
                self.original.winner, self.original.damage, new.winner, new.damage
            ));
        }
        if self.original.result != new.result {
            let before = self
                .original
                .result
                .as_object()
                .expect("original combat result");
            let field = before
                .keys()
                .find(|key| before.get(*key) != new.result.get(*key));
            return Some(field.map_or_else(
                || "combat result fields differ".into(),
                |key| {
                    format!(
                        "combat result {key}: {} became {}",
                        before[key], new.result[key]
                    )
                },
            ));
        }
        None
    }

    fn json(&self, mismatch: Option<&str>) -> Value {
        let outcome = self.verdict.as_ref().ok();
        let selected: Vec<_> = self
            .original
            .players
            .into_iter()
            .zip(self.qualifying)
            .filter_map(|(id, qualifies)| qualifies.then_some(id))
            .collect();
        json!({
            "game": self.game,
            "round": self.round,
            "players": self.original.players,
            "ghost_of": self.original.ghost_of,
            "qualifying_sides": selected,
            "original_winner": self.original.winner,
            "original_damage": self.original.damage,
            "new_winner": outcome.and_then(|o| o.winner),
            "new_damage": outcome.map(|o| o.damage),
            "skip": self.verdict.as_ref().err().map(restore::Skip::message),
            "verify_mismatch": mismatch,
        })
    }
}

fn comparisons<'a>(
    dir: &Path,
    root: &Path,
    spec: &str,
    games: &'a [input::Game],
    selector: Option<&Selector<'_>>,
    verify: bool,
) -> Result<Vec<Comparison<'a>>, String> {
    let content = crate::load_content(root, Some(spec))?;
    let mut out = Vec::new();
    for game in games {
        let boards = input::read_boards(dir, game)?;
        for round in &game.rounds {
            let players = boards.get(&round.number);
            input::check_pairings(round, players)
                .map_err(|e| format!("game {}: {e}", game.index))?;
            for fight in &round.fights {
                let [a, b] = fight.players;
                let payloads =
                    input::payload(players, a).and_then(|a| Ok([a, input::payload(players, b)?]));
                let qualifying = match (&payloads, selector) {
                    (Ok([a, b]), Some(s)) => s.qualifies(a).and_then(|a| Ok([a, s.qualifies(b)?])),
                    (_, None) => Ok([true; 2]),
                    (Err(error), Some(_)) => Err(error.clone()),
                };
                if !verify && qualifying == Ok([false; 2]) {
                    continue;
                }
                let verdict = match (&payloads, &qualifying) {
                    (Ok(payloads), Ok(_)) => {
                        restore::fight(&content, game.seed, round.number, fight, payloads, verify)
                    }
                    (Err(error), _) | (_, Err(error)) => Err(restore::Skip::Payload(error.clone())),
                };
                out.push(Comparison {
                    game: game.index,
                    round: round.number,
                    original: fight,
                    qualifying: qualifying.unwrap_or([false; 2]),
                    verdict,
                });
            }
        }
    }
    Ok(out)
}

pub fn run(
    dir: &Path,
    root: &Path,
    out: &Path,
    selection: Option<&Selection>,
    threads: usize,
    verify: bool,
) -> Result<Report, String> {
    let input::Match { content, games } = input::read_match(dir, verify)?;
    let selector = selection.map(|s| Selector::load(s, dir)).transpose()?;
    let chunk_size = games.len().div_ceil(threads.max(1));
    let batches = std::thread::scope(|scope| {
        let handles: Vec<_> = games
            .chunks(chunk_size)
            .map(|chunk| {
                let (selector, content) = (selector.as_ref(), content.as_str());
                scope.spawn(move || comparisons(dir, root, content, chunk, selector, verify))
            })
            .collect();
        handles
            .into_iter()
            .map(|handle| {
                handle.join().map_err(|panic| {
                    format!(
                        "refight worker failed: {}",
                        league_api::harness::panic_text(&panic)
                    )
                })?
            })
            .collect::<Result<Vec<_>, String>>()
    })?;
    let mut report = Report {
        total: games
            .iter()
            .flat_map(|g| &g.rounds)
            .map(|r| r.fights.len())
            .sum(),
        verifying: verify,
        ..Report::default()
    };
    let mut stats = [Summary::default(), Summary::default(), Summary::default()];
    fs::create_dir_all(out).map_err(|e| format!("{}: {e}", out.display()))?;
    let path = out.join("refights.jsonl");
    let mut log =
        BufWriter::new(File::create(&path).map_err(|e| format!("{}: {e}", path.display()))?);
    let write_err = |e| format!("{}: {e}", path.display());
    for row in batches.into_iter().flatten() {
        let selected = row.qualifying.contains(&true);
        report.selected += usize::from(selected);
        let mut mismatch = None;
        match &row.verdict {
            Ok(new) => {
                if verify {
                    mismatch = row.mismatch(new);
                    report.reproduced += usize::from(mismatch.is_none());
                    report.mismatches += usize::from(mismatch.is_some());
                }
                // A fight where both sides qualify cancels to zero, so it is left out of
                // the pooled row; the per-side rows still count it.
                let mirror = row.qualifying.iter().all(|&q| q);
                for (side, id) in row.original.players.into_iter().enumerate() {
                    if row.qualifying[side] {
                        let old = outcome_for(row.original.winner, id);
                        let new = outcome_for(new.winner, id);
                        if !mirror {
                            stats[0].add(row.game, old, new);
                        }
                        stats[side + 1].add(row.game, old, new);
                    }
                }
            }
            Err(restore::Skip::MissingCard(_)) => report.missing_cards += 1,
            Err(restore::Skip::Payload(_)) => report.unrestorable += 1,
        }
        if let Some(reason) = row
            .verdict
            .as_ref()
            .err()
            .map(restore::Skip::message)
            .or(mismatch.as_deref())
        {
            eprintln!(
                "refight: game {}, round {}, players {:?}: {reason}",
                row.game, row.round, row.original.players
            );
        }
        if selected || row.verdict.is_err() || mismatch.is_some() {
            serde_json::to_writer(&mut log, &row.json(mismatch.as_deref()))
                .map_err(|e| format!("{}: {e}", path.display()))?;
            writeln!(log).map_err(write_err)?;
        }
    }
    log.flush().map_err(write_err)?;
    let summary = out.join("summary.tsv");
    fs::write(&summary, summary_tsv(&stats)).map_err(|e| format!("{}: {e}", summary.display()))?;
    Ok(report)
}

// Index by win, draw, loss from the qualifying board's perspective.
fn outcome_for(winner: Option<i64>, side: i64) -> usize {
    match winner {
        Some(id) if id == side => 0,
        None => 1,
        _ => 2,
    }
}

/// Fewer seed lines than this give no interval: the cluster estimate is too unsure.
const MIN_SEED_LINES: usize = 10;

/// The 97.5% point of Student's t with `df` degrees of freedom (Cornish-Fisher expansion
/// around the normal; within 0.2% of the exact value for `df >= 9`).
fn t_quantile_975(df: f64) -> f64 {
    let z: f64 = 1.959_963_984_540_054;
    z + (z.powi(3) + z) / (4.0 * df)
        + (5.0 * z.powi(5) + 16.0 * z.powi(3) + 3.0 * z) / (96.0 * df * df)
        + (3.0 * z.powi(7) + 19.0 * z.powi(5) + 17.0 * z.powi(3) - 15.0 * z) / (384.0 * df.powi(3))
}

#[derive(Default)]
struct Summary {
    original: [usize; 3],
    new: [usize; 3],
    pairs: BTreeMap<usize, SeedPair>,
}

#[derive(Default)]
struct SeedPair {
    n: usize,
    change: [i64; 3],
}

impl Summary {
    fn add(&mut self, game: usize, old: usize, new: usize) {
        self.original[old] += 1;
        self.new[new] += 1;
        let pair = self.pairs.entry(game / 2).or_default();
        pair.n += 1;
        pair.change[old] -= 1;
        pair.change[new] += 1;
    }

    fn interval(&self, outcome: usize, delta: f64, n: f64) -> Option<(f64, f64)> {
        if self.pairs.len() < MIN_SEED_LINES {
            return None;
        }
        // Cluster the paired indicator differences by seeds-file line: rounds, both sides,
        // and the colour-swapped game from the same seed can all be correlated.
        let residual_squares: f64 = self
            .pairs
            .values()
            .map(|pair| (pair.change[outcome] as f64 - delta * pair.n as f64).powi(2))
            .sum();
        let pairs = self.pairs.len() as f64;
        let half_width =
            t_quantile_975(pairs - 1.0) * (residual_squares * pairs / (pairs - 1.0)).sqrt() / n;
        Some((
            (delta - half_width).max(-1.0),
            (delta + half_width).min(1.0),
        ))
    }
}

fn summary_tsv(stats: &[Summary; 3]) -> String {
    use std::fmt::Write as _;
    let mut text = String::from("side\tsides");
    for outcome in ["win", "draw", "loss"] {
        write!(text, "\toriginal_{outcome}\tnew_{outcome}\tdelta_{outcome}\t{outcome}_ci95_low\t{outcome}_ci95_high").unwrap();
    }
    text.push('\n');
    for (side, stats) in ["all", "a", "b"].into_iter().zip(stats) {
        let n: usize = stats.original.iter().sum();
        write!(text, "{side}\t{n}").unwrap();
        for i in 0..3 {
            if n == 0 {
                text.push_str("\tNA\tNA\tNA\tNA\tNA");
                continue;
            }
            let original = stats.original[i] as f64 / n as f64;
            let new = stats.new[i] as f64 / n as f64;
            let delta = (stats.new[i] as f64 - stats.original[i] as f64) / n as f64;
            write!(text, "\t{original:.6}\t{new:.6}\t{delta:.6}").unwrap();
            match stats.interval(i, delta, n as f64) {
                Some((low, high)) => write!(text, "\t{low:.6}\t{high:.6}").unwrap(),
                None => text.push_str("\tNA\tNA"),
            }
        }
        text.push('\n');
    }
    text
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tribe_rule_defaults_to_four_and_accepts_an_explicit_minimum() {
        let rule: Selection = "tribe:Badger".parse().unwrap();
        assert_eq!((rule.tribe.as_str(), rule.min), ("badger", 4));
        assert_eq!("tribe:mouse:2".parse::<Selection>().unwrap().min, 2);
        for bad in [
            "badger",
            "tribe:",
            "tribe:badger:0",
            "tribe:badger:x",
            "tribe:badger:2:3",
        ] {
            assert!(bad.parse::<Selection>().is_err(), "{bad}");
        }
    }

    #[test]
    fn interval_pairs_outcomes_and_clusters_rematches() {
        let mut stats = Summary::default();
        stats.add(0, 2, 0); // loss becomes a win
        stats.add(1, 0, 2); // its colour-swapped game cancels the change
        for line in 1..MIN_SEED_LINES - 1 {
            stats.add(line * 2, 1, 1); // independent seed lines, no change
        }
        assert_eq!(
            stats.interval(0, 0.0, 10.0),
            None,
            "nine seed lines give no interval"
        );
        stats.add(18, 1, 1);
        assert_eq!(stats.interval(0, 0.0, 11.0), Some((0.0, 0.0)));
        stats.add(19, 1, 0); // seed line 9 now holds one win gained
        // Clusters: line 0 changes by 0 over 2 sides, line 9 by 1 over 2, eight lines by 0 over 1.
        let delta: f64 = 1.0 / 12.0;
        let residuals = (2.0 * delta).powi(2) + (1.0 - 2.0 * delta).powi(2) + 8.0 * delta.powi(2);
        let half = t_quantile_975(9.0) * (residuals * 10.0 / 9.0).sqrt() / 12.0;
        let (low, high) = stats.interval(0, delta, 12.0).unwrap();
        assert!((low - (delta - half)).abs() < 1e-12);
        assert!((high - (delta + half)).abs() < 1e-12);
    }

    #[test]
    fn t_quantile_matches_tables() {
        for (df, exact) in [(9.0, 2.262_157), (29.0, 2.045_230), (499.0, 1.964_729)] {
            assert!(
                (t_quantile_975(df) - exact).abs() / exact < 0.002,
                "df {df}"
            );
        }
    }
}
