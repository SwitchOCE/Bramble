//! Refight modes for card power: text off, stat worth, keyword off, the Overrun swing count and
//! fresh copy (docs/workstreams/card-power/definitions.md). One JSON line per observation; nothing is
//! aggregated here.
use super::input::{self, Fight, Game};
use super::restore::{self, Detail, Setup, Skip};
use super::switch;
use bramble_engine::core::util::rng::Rng;
use bramble_engine::game::game_content::GameContentRef;
use bramble_engine::{Dictionary, Variant};
use serde_json::{Value, json};
use std::collections::{BTreeMap, BTreeSet};
use std::fmt;
use std::fs::{self, File};
use std::io::{BufWriter, Write};
use std::path::Path;

/// Stat worth: the plain unit's own Attack and Health, in hundredths of what was recorded.
pub const RUNGS: [i64; 6] = [150, 200, 300, 400, 600, 800];

/// The mechanic whose attacks the swing count follows.
pub const OVERRUN: &str = "badger_overrun";

/// Fresh copy: units of the card's tribe a side must hold for the copy to be tried there.
pub const FRESH_TRIBE_UNITS: usize = 3;

#[derive(Debug, Clone)]
pub struct Modes {
    pub text_off: bool,
    /// With text off: also refight with the unit's own stats at each of `RUNGS`.
    pub stat_worth: bool,
    /// Mechanic ids to switch off, one at a time, for one side.
    pub keywords: Vec<String>,
    pub swings: bool,
    /// Card ids to add as a fresh copy to recorded boards, text on against text off.
    pub fresh: Vec<String>,
    /// Seeds per observation: the recorded one and `seeds - 1` derived from it.
    pub seeds: usize,
    /// Most observations kept per card (or keyword) per stage.
    pub cap: usize,
}

impl Modes {
    pub fn any(&self) -> bool {
        self.text_off || !self.keywords.is_empty() || self.swings || !self.fresh.is_empty()
    }
}

#[derive(Debug, Default)]
pub struct ModeReport {
    pub fights: usize,
    pub fought: usize,
    pub reproduced: usize,
    pub mismatches: usize,
    pub skipped: usize,
    pub text_off: usize,
    pub keyword_off: usize,
    pub swings: usize,
    pub swing_changed: usize,
    pub fresh_copy: usize,
    verifying: bool,
}

impl ModeReport {
    pub fn verify(&self) -> Result<(), String> {
        if self.mismatches == 0 && self.skipped == 0 && self.swing_changed == 0 {
            Ok(())
        } else {
            Err(format!(
                "verification failed: {} / {} fights reproduced",
                self.reproduced, self.fought
            ))
        }
    }
}

impl fmt::Display for ModeReport {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "refight modes: {} fights, {} refought, {} reproduced, {} not reproduced, {} skipped\n\
             observations: {} text off, {} keyword off, {} fresh copy; {} Overrun swings",
            self.fights,
            self.fought,
            self.reproduced,
            self.mismatches,
            self.skipped,
            self.text_off,
            self.keyword_off,
            self.fresh_copy,
            self.swings
        )?;
        if self.swing_changed > 0 {
            write!(f, "\n{} fights changed when counted", self.swing_changed)?;
        }
        if self.verifying {
            write!(
                f,
                "\nverify: {} / {} fights reproduced",
                self.reproduced, self.fought
            )?;
        }
        Ok(())
    }
}

pub fn stage(round: i64) -> &'static str {
    match round {
        ..=4 => "1-4",
        5..=8 => "5-8",
        9..=12 => "9-12",
        _ => "13+",
    }
}

/// The game seed for refight seed `k`: the recorded one, then seeds derived from it.
fn seed_for(game_seed: i64, k: usize) -> i64 {
    if k == 0 {
        game_seed
    } else {
        Rng::hash32(&format!("{game_seed}|refight|{k}"))
    }
}

/// What one observation switches off.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
enum Change {
    /// (pairing position, board slot)
    Text(usize, usize),
    /// (index into Modes::keywords, pairing position)
    Keyword(usize, usize),
    /// (index into Modes::fresh, pairing position)
    Fresh(usize, usize),
}

/// A candidate observation, found from the recorded payloads alone (no fight run).
#[derive(Debug)]
struct Candidate {
    game: usize,
    round: i64,
    fight: usize,
    change: Change,
    group: (String, &'static str),
    hash: i64,
}

/// Mechanic ids one recorded board unit holds: its card's own, what it was given, and what an
/// aura or its slot gave it, as recorded in fight_boards. Restoring the unit gives the same.
fn held(content: &GameContentRef, unit: &Dictionary, slot_keywords: &[String]) -> Vec<String> {
    let mut out = Vec::new();
    if let Ok(id) = restore::card_id(unit)
        && let Some(card) = content.borrow().library.borrow().get_card(&id)
    {
        out.extend(
            card.borrow()
                .mechanics
                .to_vec()
                .iter()
                .map(|spec| spec.borrow().id.clone()),
        );
    }
    for field in ["grants", "aura_grants"] {
        if let Variant::Array(entries) = unit.get(field) {
            for entry in entries.to_vec() {
                out.push(entry.as_array().get(0).unwrap_or_default().as_text());
            }
        }
    }
    out.extend(slot_keywords.iter().cloned());
    out
}

/// Units of one recorded side that hold `keyword` at the start of the fight.
fn keyword_units(content: &GameContentRef, payload: &Dictionary, keyword: &str) -> usize {
    let Ok(board) = restore::units(payload, "board") else {
        return 0;
    };
    let slots = restore::units(payload, "slots")
        .map(|s| s.to_vec())
        .unwrap_or_default();
    board
        .to_vec()
        .into_iter()
        .enumerate()
        .filter(|(slot, unit)| {
            let Variant::Dictionary(unit) = unit else {
                return false;
            };
            let keywords: Vec<String> = slots
                .get(*slot)
                .map(|s| {
                    restore::units(&s.as_dict(), "keywords")
                        .map(|k| k.to_vec().iter().map(Variant::as_text).collect())
                        .unwrap_or_default()
                })
                .unwrap_or_default();
            held(content, unit, &keywords)
                .iter()
                .any(|id| id == keyword)
        })
        .count()
}

/// The card's tier and tribes, from the content's card data.
fn card_info(content: &GameContentRef, id: &str) -> Option<(i64, Vec<String>)> {
    let card = content.borrow().library.borrow().get_card(id)?;
    let card = card.borrow();
    Some((card.tier, card.tribes.to_vec()))
}

/// Units of one recorded side whose card shares a tribe with `tribes`.
fn tribe_units(content: &GameContentRef, payload: &Dictionary, tribes: &[String]) -> usize {
    let Ok(board) = restore::units(payload, "board") else {
        return 0;
    };
    board
        .to_vec()
        .into_iter()
        .filter(|unit| {
            let Variant::Dictionary(unit) = unit else {
                return false;
            };
            restore::card_id(unit)
                .ok()
                .and_then(|id| card_info(content, &id))
                .is_some_and(|(_, own)| own.iter().any(|t| tribes.contains(t)))
        })
        .count()
}

/// A side where a fresh copy of `card` could plausibly stand: the player's tavern tier is at
/// least one below the card's (a triple's reward offers a card one tier up; on r1, 13% of board
/// units sit one tier above their player and none two), and (for a card with a tribe) the side
/// holds `FRESH_TRIBE_UNITS` or more units of that tribe. A card with no tribe fits any side its
/// tier allows.
fn fresh_fits(content: &GameContentRef, payload: &Dictionary, card: &str) -> bool {
    let Some((tier, tribes)) = card_info(content, card) else {
        return false;
    };
    let reached = input::integer(&payload.get("tier")).is_some_and(|t| t + 1 >= tier);
    reached && (tribes.is_empty() || tribe_units(content, payload, &tribes) >= FRESH_TRIBE_UNITS)
}

/// Where the fresh copy goes: the lowest free slot, or else the slot of the side's weakest unit
/// (lowest own Attack plus Health, the lower slot on a tie), whose card is returned.
fn fresh_slot(standing: &[restore::Standing], slots: usize) -> (usize, Option<String>) {
    if let Some(free) = (0..slots).find(|s| standing.iter().all(|u| u.slot != *s)) {
        return (free, None);
    }
    let weakest = standing
        .iter()
        .min_by_key(|u| (u.own_attack + u.own_health, u.slot))
        .expect("a full board has units");
    (weakest.slot, Some(weakest.card.clone()))
}

fn candidates(
    dir: &Path,
    content: &GameContentRef,
    games: &[Game],
    modes: &Modes,
) -> Result<Vec<Candidate>, String> {
    let mut out = Vec::new();
    for game in games {
        let boards = input::read_boards(dir, game)?;
        for round in &game.rounds {
            let players = boards.get(&round.number);
            for (index, fight) in round.fights.iter().enumerate() {
                for (position, id) in fight.players.into_iter().enumerate() {
                    let Ok(payload) = input::payload(players, id) else {
                        continue;
                    };
                    let place = |change: Change, group: String, key: String| Candidate {
                        game: game.index,
                        round: round.number,
                        fight: index,
                        change,
                        group: (group, stage(round.number)),
                        hash: Rng::hash32(&key),
                    };
                    if modes.text_off
                        && let Ok(board) = restore::units(&payload, "board")
                    {
                        for (slot, unit) in board.to_vec().into_iter().enumerate() {
                            let Variant::Dictionary(unit) = unit else {
                                continue;
                            };
                            let Ok(card) = restore::card_id(&unit) else {
                                continue;
                            };
                            let key = format!(
                                "text_off|{}|{}|{position}|{slot}",
                                game.index, round.number
                            );
                            out.push(place(Change::Text(position, slot), card, key));
                        }
                    }
                    for (k, card) in modes.fresh.iter().enumerate() {
                        if fresh_fits(content, &payload, card) {
                            let key = format!(
                                "fresh_copy|{card}|{}|{}|{position}",
                                game.index, round.number
                            );
                            out.push(place(
                                Change::Fresh(k, position),
                                format!("fresh:{card}"),
                                key,
                            ));
                        }
                    }
                    for (k, keyword) in modes.keywords.iter().enumerate() {
                        if keyword_units(content, &payload, keyword) > 0 {
                            let key = format!(
                                "keyword_off|{keyword}|{}|{}|{position}",
                                game.index, round.number
                            );
                            out.push(place(Change::Keyword(k, position), keyword.clone(), key));
                        }
                    }
                }
            }
        }
    }
    Ok(out)
}

/// Keep at most `cap` per card (or keyword) per stage, lowest hash of game, round, side and
/// slot first. The outcome is never looked at.
fn sample(mut all: Vec<Candidate>, cap: usize) -> BTreeMap<(usize, i64, usize), Vec<Change>> {
    all.sort_by(|x, y| {
        (&x.group, x.hash, x.game, x.round, x.fight, &x.change)
            .cmp(&(&y.group, y.hash, y.game, y.round, y.fight, &y.change))
    });
    let mut kept: BTreeMap<_, Vec<Change>> = BTreeMap::new();
    let mut taken: BTreeMap<(String, &str), usize> = BTreeMap::new();
    for c in all {
        let n = taken.entry(c.group.clone()).or_default();
        if *n < cap {
            *n += 1;
            kept.entry((c.game, c.round, c.fight))
                .or_default()
                .push(c.change);
        }
    }
    for changes in kept.values_mut() {
        changes.sort();
    }
    kept
}

/// Score for pairing position `side`: win 1, draw ½, loss 0.
fn score(detail: &Detail, original: &Fight, side: usize) -> f64 {
    match detail.outcome.winner {
        None => 0.5,
        Some(id) if id == original.players[side] => 1.0,
        Some(_) => 0.0,
    }
}

#[derive(Default)]
struct Means {
    score: f64,
    dealt: f64,
}

fn means(details: &[Detail], original: &Fight, side: usize) -> Means {
    let n = details.len() as f64;
    let mut m = Means::default();
    for d in details {
        m.score += score(d, original, side) / n;
        m.dealt += d.damage_to[1 - side] as f64 / n;
    }
    m
}

fn median(values: &mut [i64]) -> Option<f64> {
    values.sort_unstable();
    let n = values.len();
    match n {
        0 => None,
        _ if n % 2 == 1 => Some(values[n / 2] as f64),
        _ => Some((values[n / 2 - 1] + values[n / 2]) as f64 / 2.0),
    }
}

struct Lines {
    text: Vec<Value>,
    keyword: Vec<Value>,
    fresh: Vec<Value>,
    swings: Vec<Value>,
    report: ModeReport,
}

/// Kills of each noted swing: deaths of enemy units credited to the attacker, from its attack
/// event up to the next attack event (carried damage and Cleave included).
fn swing_kills(events: &bramble_engine::Array<Dictionary>, swing: &switch::Swing) -> usize {
    let mut kills = 0;
    for event in events.to_vec().into_iter().skip(swing.event_index) {
        match event.get("type").as_text().as_str() {
            "attack" => break,
            "death"
                if event.get("killer_uid").as_i64() == swing.uid
                    && event.get("side").as_i64() != swing.side =>
            {
                kills += 1
            }
            _ => {}
        }
    }
    kills
}

#[allow(clippy::too_many_arguments)]
fn fight_modes(
    dir: &Path,
    root: &Path,
    spec: &str,
    games: &[Game],
    modes: &Modes,
    tasks: &BTreeMap<(usize, i64, usize), Vec<Change>>,
    verify: bool,
) -> Result<Lines, String> {
    let content = crate::load_content(root, Some(spec))?;
    let base = content.borrow().registry.clone();
    let mut lines = Lines {
        text: Vec::new(),
        keyword: Vec::new(),
        fresh: Vec::new(),
        swings: Vec::new(),
        report: ModeReport::default(),
    };
    let none = Vec::new();
    for game in games {
        let boards = input::read_boards(dir, game)?;
        for round in &game.rounds {
            let players = boards.get(&round.number);
            input::check_pairings(round, players)
                .map_err(|e| format!("game {}: {e}", game.index))?;
            for (index, fight) in round.fights.iter().enumerate() {
                lines.report.fights += 1;
                let changes = tasks
                    .get(&(game.index, round.number, index))
                    .unwrap_or(&none);
                if changes.is_empty() && !modes.swings {
                    continue;
                }
                lines.report.fought += 1;
                let where_ = format!(
                    "refight: game {}, round {}, players {:?}",
                    game.index, round.number, fight.players
                );
                let payloads = match input::payload(players, fight.players[0])
                    .and_then(|a| Ok([a, input::payload(players, fight.players[1])?]))
                {
                    Ok(p) => p,
                    Err(e) => {
                        eprintln!("{where_}: {e}");
                        lines.report.skipped += 1;
                        continue;
                    }
                };
                let run = |setup: Setup, check: bool| {
                    restore::fight_with(
                        &content,
                        &setup,
                        game.seed,
                        round.number,
                        fight,
                        &payloads,
                        check,
                    )
                };
                let seeded = |k: usize, setup: Setup| {
                    run(
                        Setup {
                            seed: Some(seed_for(game.seed, k)),
                            ..setup
                        },
                        verify && k == 0,
                    )
                };
                // The board as recorded, on every seed. Seed 0 must give the recorded result.
                let baseline: Result<Vec<Detail>, Skip> = (0..modes.seeds.max(1))
                    .map(|k| seeded(k, Setup::default()))
                    .collect();
                let baseline = match baseline {
                    Ok(b) => b,
                    Err(skip) => {
                        eprintln!("{where_}: {}", skip.message());
                        lines.report.skipped += 1;
                        continue;
                    }
                };
                let first = &baseline[0].outcome;
                let same = (first.winner, first.damage) == (fight.winner, fight.damage)
                    && (!verify || first.result == fight.result);
                if !same {
                    eprintln!(
                        "{where_}: recorded result not reproduced ({:?}/{} became {:?}/{})",
                        fight.winner, fight.damage, first.winner, first.damage
                    );
                    lines.report.mismatches += 1;
                    continue;
                }
                lines.report.reproduced += 1;
                let side_info = |side: usize| {
                    let id = fight.players[side];
                    let ghost_of = (id
                        == bramble_engine::core::session::matchmaking::Matchmaking::GHOST)
                        .then_some(fight.ghost_of)
                        .flatten();
                    let enemy = &baseline[0].boards[1 - side];
                    let mut health: Vec<i64> = enemy.iter().map(|u| u.health).collect();
                    json!({
                        "game": game.index,
                        "round": round.number,
                        "stage": stage(round.number),
                        "player": id,
                        "ghost_of": ghost_of,
                        "position": (["a", "b"][side]),
                        "seeds": baseline.len(),
                        "own_units": baseline[0].boards[side].len(),
                        "enemy_units": enemy.len(),
                        "enemy_median_health": median(&mut health),
                    })
                };
                let observe = |row: &mut Value, side: usize, changed: &[Detail]| {
                    let before = means(&baseline, fight, side);
                    let after = means(changed, fight, side);
                    let row = row.as_object_mut().unwrap();
                    row.insert("score_recorded".into(), json!(before.score));
                    row.insert("score_off".into(), json!(after.score));
                    row.insert("dealt_recorded".into(), json!(before.dealt));
                    row.insert("dealt_off".into(), json!(after.dealt));
                    row.insert(
                        "result_changed".into(),
                        json!(changed[0].outcome.winner != baseline[0].outcome.winner),
                    );
                };
                for change in changes {
                    if let Change::Fresh(k, side) = change {
                        let card = &modes.fresh[*k];
                        let slots = restore::units(&payloads[*side], "board")
                            .map(|b| b.len())
                            .unwrap_or(0);
                        let (slot, displaced) = fresh_slot(&baseline[0].boards[*side], slots);
                        let arm = |off: bool| -> Result<Vec<Detail>, Skip> {
                            (0..baseline.len())
                                .map(|k| {
                                    seeded(
                                        k,
                                        Setup {
                                            fresh: Some((*side, slot, card.clone())),
                                            text_off: off.then_some((*side, slot)),
                                            ..Setup::default()
                                        },
                                    )
                                })
                                .collect()
                        };
                        let (on, off) = match arm(false).and_then(|on| Ok((on, arm(true)?))) {
                            Ok(arms) => arms,
                            Err(skip) => {
                                eprintln!("{where_}: {change:?}: {}", skip.message());
                                lines.report.skipped += 1;
                                continue;
                            }
                        };
                        let (tier, tribes) = card_info(&content, card).unwrap_or_default();
                        let mut row = side_info(*side);
                        let (recorded, with, without) = (
                            means(&baseline, fight, *side),
                            means(&on, fight, *side),
                            means(&off, fight, *side),
                        );
                        let r = row.as_object_mut().unwrap();
                        r.insert("mode".into(), json!("fresh_copy"));
                        r.insert("card".into(), json!(card));
                        r.insert("tier".into(), json!(tier));
                        r.insert("slot".into(), json!(slot));
                        r.insert("displaced".into(), json!(displaced));
                        r.insert(
                            "player_tier".into(),
                            json!(input::integer(&payloads[*side].get("tier"))),
                        );
                        r.insert(
                            "tribe_units".into(),
                            json!(tribe_units(&content, &payloads[*side], &tribes)),
                        );
                        r.insert("score_recorded".into(), json!(recorded.score));
                        r.insert("score_on".into(), json!(with.score));
                        r.insert("score_off".into(), json!(without.score));
                        r.insert("dealt_on".into(), json!(with.dealt));
                        r.insert("dealt_off".into(), json!(without.dealt));
                        r.insert(
                            "result_changed".into(),
                            json!(on[0].outcome.winner != off[0].outcome.winner),
                        );
                        lines.fresh.push(row);
                        continue;
                    }
                    let (setup, side): (Box<dyn Fn() -> Setup>, usize) = match change {
                        Change::Text(side, slot) => (
                            Box::new(move || Setup {
                                text_off: Some((*side, *slot)),
                                ..Setup::default()
                            }),
                            *side,
                        ),
                        Change::Keyword(k, side) => {
                            let off = [modes.keywords[*k].clone()];
                            let base = base.clone();
                            (
                                Box::new(move || Setup {
                                    registry: Some(switch::registry(
                                        &base,
                                        &off,
                                        *side as i64,
                                        None,
                                    )),
                                    ..Setup::default()
                                }),
                                *side,
                            )
                        }
                        Change::Fresh(..) => unreachable!("handled above"),
                    };
                    let changed: Result<Vec<Detail>, Skip> =
                        (0..baseline.len()).map(|k| seeded(k, setup())).collect();
                    let changed = match changed {
                        Ok(c) => c,
                        Err(skip) => {
                            eprintln!("{where_}: {change:?}: {}", skip.message());
                            continue;
                        }
                    };
                    let mut row = side_info(side);
                    match change {
                        Change::Text(_, slot) => {
                            let unit = baseline[0].boards[side]
                                .iter()
                                .find(|u| u.slot == *slot)
                                .expect("observed unit");
                            let r = row.as_object_mut().unwrap();
                            r.insert("mode".into(), json!("text_off"));
                            r.insert("slot".into(), json!(slot));
                            r.insert("card".into(), json!(unit.card));
                            r.insert("golden".into(), json!(unit.golden));
                            r.insert("tier".into(), json!(unit.tier));
                            let own = (unit.own_attack, unit.own_health);
                            observe(&mut row, side, &changed);
                            if modes.stat_worth {
                                let r = row.as_object_mut().unwrap();
                                r.insert("own_attack".into(), json!(own.0));
                                r.insert("own_health".into(), json!(own.1));
                                let mut failed = None;
                                for percent in RUNGS {
                                    let scaled: Result<Vec<Detail>, Skip> = (0..baseline.len())
                                        .map(|k| {
                                            seeded(
                                                k,
                                                Setup {
                                                    scale_percent: Some(percent),
                                                    ..setup()
                                                },
                                            )
                                        })
                                        .collect();
                                    match scaled {
                                        Ok(scaled) => {
                                            let score = means(&scaled, fight, side).score;
                                            r.insert(format!("score_x{percent}"), json!(score));
                                        }
                                        Err(skip) => {
                                            failed = Some(skip);
                                            break;
                                        }
                                    }
                                }
                                if let Some(skip) = failed {
                                    // The row is left out, so the sample differs from text
                                    // off alone: say so, and count it.
                                    eprintln!("{where_}: {change:?}: {}", skip.message());
                                    lines.report.skipped += 1;
                                    continue;
                                }
                            }
                            lines.text.push(row);
                        }
                        Change::Fresh(..) => unreachable!("handled above"),
                        Change::Keyword(k, _) => {
                            let keyword = &modes.keywords[*k];
                            let count = |s: usize| {
                                baseline[0].boards[s]
                                    .iter()
                                    .filter(|u| u.mechanics.iter().any(|m| m == keyword))
                                    .count()
                            };
                            let r = row.as_object_mut().unwrap();
                            r.insert("mode".into(), json!("keyword_off"));
                            r.insert("keyword".into(), json!(keyword));
                            r.insert("keyword_units".into(), json!(count(side)));
                            r.insert("enemy_keyword_units".into(), json!(count(1 - side)));
                            observe(&mut row, side, &changed);
                            lines.keyword.push(row);
                        }
                    }
                }
                if modes.swings {
                    let swings = switch::Swings::default();
                    let setup = Setup {
                        registry: Some(switch::registry(&base, &[], -1, Some((OVERRUN, &swings)))),
                        keep_events: true,
                        ..Setup::default()
                    };
                    match run(setup, false) {
                        Ok(counted) => {
                            if (counted.outcome.winner, counted.outcome.damage)
                                != (first.winner, first.damage)
                            {
                                eprintln!("{where_}: the swing count changed the fight");
                                lines.report.swing_changed += 1;
                                continue;
                            }
                            for swing in swings.borrow().iter() {
                                let side = swing.side as usize;
                                let kills = swing_kills(&counted.events, swing);
                                let mut row = side_info(side);
                                let r = row.as_object_mut().unwrap();
                                for key in
                                    ["seeds", "own_units", "enemy_units", "enemy_median_health"]
                                {
                                    r.remove(key);
                                }
                                r.insert("card".into(), json!(swing.card));
                                r.insert("golden".into(), json!(swing.golden));
                                r.insert("enemy_standing".into(), json!(swing.enemy_standing));
                                r.insert("kills".into(), json!(kills));
                                r.insert(
                                    "whole_board".into(),
                                    json!(
                                        swing.enemy_standing > 0 && kills >= swing.enemy_standing
                                    ),
                                );
                                lines.swings.push(row);
                            }
                        }
                        Err(skip) => {
                            eprintln!("{where_}: swing count: {}", skip.message());
                            lines.report.swing_changed += 1;
                        }
                    }
                }
            }
        }
    }
    lines.report.text_off = lines.text.len();
    lines.report.keyword_off = lines.keyword.len();
    lines.report.fresh_copy = lines.fresh.len();
    lines.report.swings = lines.swings.len();
    Ok(lines)
}

fn write_lines(path: &Path, rows: &[Value]) -> Result<(), String> {
    let err = |e: std::io::Error| format!("{}: {e}", path.display());
    let mut out = BufWriter::new(File::create(path).map_err(err)?);
    for row in rows {
        serde_json::to_writer(&mut out, row).map_err(|e| format!("{}: {e}", path.display()))?;
        writeln!(out).map_err(err)?;
    }
    out.flush().map_err(err)
}

fn swings_tsv(rows: &[Value]) -> String {
    use std::fmt::Write as _;
    let mut text =
        String::from("stage\tattacks\tkills_0\tkills_1\tkills_2_plus\tkills_3_plus\twhole_board\n");
    for stage in ["all", "1-4", "5-8", "9-12", "13+"] {
        let mut counts = [0usize; 6];
        for row in rows
            .iter()
            .filter(|r| stage == "all" || r["stage"] == stage)
        {
            let kills = row["kills"].as_u64().unwrap_or(0);
            counts[0] += 1;
            counts[1] += usize::from(kills == 0);
            counts[2] += usize::from(kills == 1);
            counts[3] += usize::from(kills >= 2);
            counts[4] += usize::from(kills >= 3);
            counts[5] += usize::from(row["whole_board"] == true);
        }
        let [a, b, c, d, e, f] = counts;
        writeln!(text, "{stage}\t{a}\t{b}\t{c}\t{d}\t{e}\t{f}").unwrap();
    }
    text
}

/// Runs `work` on one chunk of games per thread and returns the results in game order.
fn spread<T: Send>(
    games: &[Game],
    threads: usize,
    work: impl Fn(&[Game]) -> Result<T, String> + Sync,
) -> Result<Vec<T>, String> {
    let chunk_size = games.len().div_ceil(threads.max(1));
    let work = &work;
    std::thread::scope(|scope| {
        let handles: Vec<_> = games
            .chunks(chunk_size)
            .map(|chunk| scope.spawn(move || work(chunk)))
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
            .collect()
    })
}

pub fn run(
    dir: &Path,
    root: &Path,
    out: &Path,
    modes: &Modes,
    threads: usize,
    verify: bool,
) -> Result<ModeReport, String> {
    if modes.seeds == 0 || modes.cap == 0 {
        return Err("usage: --seeds and --cap must be positive".into());
    }
    input::check_rules(dir, root)?;
    let input::Match { content, games } = input::read_match(dir, verify)?;
    let mut modes = modes.clone();
    {
        let loaded = crate::load_content(root, Some(&content))?;
        let registry = loaded.borrow().registry.clone();
        if modes.fresh == ["all"] {
            // Every card the shop can offer: no spells, no tokens.
            let library = loaded.borrow().library.clone();
            let library = library.borrow();
            modes.fresh = library
                .ids()
                .to_vec()
                .into_iter()
                .filter(|id| {
                    let card = library.get_card(id).expect("listed card");
                    let card = card.borrow();
                    !card.is_spell() && !card.token
                })
                .collect();
        }
        let mut seen = BTreeSet::new();
        for keyword in &modes.keywords {
            if !seen.insert(keyword) {
                return Err(format!("usage: keyword {keyword:?} given twice"));
            }
            switch::check_switchable(&registry, keyword)?;
        }
        let mut fresh = BTreeSet::new();
        for card in &modes.fresh {
            if !fresh.insert(card) {
                return Err(format!("usage: fresh copy {card:?} given twice"));
            }
            let def = loaded.borrow().library.borrow().get_card(card);
            match def {
                None => return Err(format!("usage: --fresh-copy: no card {card:?}")),
                Some(def) if def.borrow().is_spell() => {
                    return Err(format!("usage: --fresh-copy: {card:?} is a spell"));
                }
                Some(_) => {}
            }
        }
        if modes.swings && !registry.borrow().has(OVERRUN) {
            return Err(format!("content has no {OVERRUN} mechanic"));
        }
    }
    let found: Vec<Vec<Candidate>> = spread(&games, threads, |chunk: &[Game]| {
        let loaded = crate::load_content(root, Some(&content))?;
        candidates(dir, &loaded, chunk, &modes)
    })?;
    let tasks = sample(found.into_iter().flatten().collect(), modes.cap);
    let done: Vec<Lines> = spread(&games, threads, |chunk: &[Game]| {
        fight_modes(dir, root, &content, chunk, &modes, &tasks, verify)
    })?;
    fs::create_dir_all(out).map_err(|e| format!("{}: {e}", out.display()))?;
    let mut report = ModeReport {
        verifying: verify,
        ..ModeReport::default()
    };
    let (mut text, mut keyword, mut swings) = (Vec::new(), Vec::new(), Vec::new());
    let mut fresh = Vec::new();
    for lines in done {
        let r = lines.report;
        report.fights += r.fights;
        report.fought += r.fought;
        report.reproduced += r.reproduced;
        report.mismatches += r.mismatches;
        report.skipped += r.skipped;
        report.swing_changed += r.swing_changed;
        text.extend(lines.text);
        keyword.extend(lines.keyword);
        fresh.extend(lines.fresh);
        swings.extend(lines.swings);
    }
    report.text_off = text.len();
    report.keyword_off = keyword.len();
    report.swings = swings.len();
    report.fresh_copy = fresh.len();
    if !modes.fresh.is_empty() {
        write_lines(&out.join("fresh_copy.jsonl"), &fresh)?;
    }
    if modes.text_off {
        write_lines(&out.join("text_off.jsonl"), &text)?;
    }
    if !modes.keywords.is_empty() {
        write_lines(&out.join("keyword_off.jsonl"), &keyword)?;
    }
    if modes.swings {
        write_lines(&out.join("overrun_swings.jsonl"), &swings)?;
        let path = out.join("overrun_swings.tsv");
        fs::write(&path, swings_tsv(&swings)).map_err(|e| format!("{}: {e}", path.display()))?;
    }
    Ok(report)
}

#[cfg(test)]
mod tests {
    use super::*;
    use bramble_engine::util::godot_json;
    use bramble_engine::{Array, ToState};
    use league_api::harness;

    fn content() -> GameContentRef {
        crate::load_content(&crate::default_root(), Some("all")).unwrap()
    }

    /// Fight payloads for two constructed boards of (card id, golden), slot by slot.
    fn payloads(content: &GameContentRef, sides: [&[(&str, bool)]; 2]) -> [Dictionary; 2] {
        let session = content.borrow().new_session(5, &Array::new());
        [0, 1].map(|i| {
            let player = session.borrow().player(i as i64);
            player.borrow().board.borrow_mut().fill(None);
            for (slot, (id, golden)) in sides[i].iter().enumerate() {
                let card = content.borrow().library.borrow().get_card(id).unwrap();
                let unit = session.borrow_mut().new_unit(&card, *golden);
                unit.borrow_mut().slot = slot as i64;
                player.borrow().board.borrow_mut()[slot] = Some(unit);
            }
            harness::fight_payload(&player.borrow())
        })
    }

    fn fight() -> Fight {
        Fight {
            players: [0, 1],
            ghost_of: None,
            winner: None,
            damage: 0,
            result: Value::Null,
        }
    }

    fn fought(
        content: &GameContentRef,
        payloads: &[Dictionary; 2],
        k: usize,
        setup: Setup,
    ) -> Detail {
        let setup = Setup {
            seed: Some(seed_for(17, k)),
            ..setup
        };
        restore::fight_with(content, &setup, 17, 8, &fight(), payloads, true).unwrap()
    }

    fn events(detail: &Detail) -> String {
        godot_json::stringify(&detail.events.to_state())
    }

    /// The event log without combat_start, whose board views show each unit's text.
    fn play(detail: &Detail) -> String {
        let events: Array<Dictionary> = detail
            .events
            .to_vec()
            .into_iter()
            .filter(|e| e.get("type").as_text() != "combat_start")
            .collect();
        godot_json::stringify(&events.to_state())
    }

    fn triggers(detail: &Detail, mechanic: &str) -> usize {
        detail
            .events
            .to_vec()
            .iter()
            .filter(|e| {
                e.get("type").as_text() == "trigger" && e.get("mechanic").as_text() == mechanic
            })
            .count()
    }

    #[test]
    fn text_off_on_a_card_without_fight_text_changes_nothing() {
        let content = content();
        // Sentry's text works at the end of a turn only.
        let p = payloads(
            &content,
            [
                &[("sentry", false), ("heath-adder", false)],
                &[("prophet-of-the-dust", true), ("private", false)],
            ],
        );
        for k in 0..4 {
            let base = fought(
                &content,
                &p,
                k,
                Setup {
                    keep_events: true,
                    ..Setup::default()
                },
            );
            // Sentry (a) and the golden Prophet of the Dust (b) have end-of-turn text only.
            for side in [0, 1] {
                let off = fought(
                    &content,
                    &p,
                    k,
                    Setup {
                        text_off: Some((side, 0)),
                        keep_events: true,
                        ..Setup::default()
                    },
                );
                assert_eq!(base.outcome.result, off.outcome.result);
                assert_eq!(play(&base), play(&off));
            }
        }
    }

    #[test]
    fn text_that_decides_a_fight_shows() {
        let content = content();
        // A 1/1 Venomous unit against a 2/5: Venomous trades for a draw, without it a loss.
        let p = payloads(&content, [&[("heath-adder", false)], &[("sentry", false)]]);
        let base: Vec<_> = (0..4)
            .map(|k| fought(&content, &p, k, Setup::default()))
            .collect();
        let off: Vec<_> = (0..4)
            .map(|k| {
                fought(
                    &content,
                    &p,
                    k,
                    Setup {
                        text_off: Some((0, 0)),
                        ..Setup::default()
                    },
                )
            })
            .collect();
        let (before, after) = (means(&base, &fight(), 0), means(&off, &fight(), 0));
        assert_eq!((before.score, after.score), (0.5, 0.0));
        // The unit keeps its stats.
        assert_eq!(off[0].boards[0][0].health, base[0].boards[0][0].health);
        assert!(off[0].boards[0][0].mechanics.is_empty());
    }

    #[test]
    fn stat_worth_scales_the_plain_unit_s_own_stats() {
        let content = content();
        // Heath Adder with its text off is a plain 1/1 and loses to a 2/5 Sentry. At eight
        // times its stats it is an 8/8 and wins; at twice, a 2/2 still loses.
        let p = payloads(&content, [&[("heath-adder", false)], &[("sentry", false)]]);
        let at = |percent: i64| {
            fought(
                &content,
                &p,
                0,
                Setup {
                    text_off: Some((0, 0)),
                    scale_percent: Some(percent),
                    ..Setup::default()
                },
            )
        };
        let (twice, eight) = (at(200), at(800));
        let unit = &eight.boards[0][0];
        assert_eq!((unit.own_attack, unit.own_health), (8, 8));
        assert!(unit.mechanics.is_empty());
        assert_eq!(score(&twice, &fight(), 0), 0.0);
        assert_eq!(score(&eight, &fight(), 0), 1.0);
        // The enemy is untouched.
        assert_eq!(eight.boards[1][0].own_attack, twice.boards[1][0].own_attack);
    }

    #[test]
    fn text_off_keeps_what_other_cards_gave() {
        let content = content();
        let p = payloads(&content, [&[("sentry", false)], &[("private", false)]]);
        let unit = restore::units(&p[0], "board")
            .unwrap()
            .get(0)
            .unwrap()
            .as_dict();
        unit.insert(
            "grants",
            Variant::Array(Array::from(vec![Variant::Array(Array::from(vec![
                Variant::from("venomous"),
            ]))])),
        );
        let off = fought(
            &content,
            &p,
            0,
            Setup {
                text_off: Some((0, 0)),
                ..Setup::default()
            },
        );
        assert_eq!(off.boards[0][0].mechanics, vec!["venomous".to_owned()]);
    }

    #[test]
    fn keyword_off_where_no_unit_has_it_changes_nothing() {
        let content = content();
        let base_registry = content.borrow().registry.clone();
        // Side b has Overrun and Fury; side a has neither, nor does anyone have Cleave.
        let p = payloads(
            &content,
            [
                &[
                    ("private", false),
                    ("private", false),
                    ("hopper", false),
                    ("sentry", false),
                ],
                &[("ironhide-berserker", false)],
            ],
        );
        for k in 0..4 {
            let base = fought(
                &content,
                &p,
                k,
                Setup {
                    keep_events: true,
                    ..Setup::default()
                },
            );
            for (off, side) in [
                ("badger_overrun", 0),
                ("badger_fury", 0),
                ("cleave", 0),
                ("cleave", 1),
            ] {
                let registry = switch::registry(&base_registry, &[off.to_owned()], side, None);
                let changed = fought(
                    &content,
                    &p,
                    k,
                    Setup {
                        registry: Some(registry),
                        keep_events: true,
                        ..Setup::default()
                    },
                );
                assert_eq!(
                    base.outcome.result, changed.outcome.result,
                    "{off} off for side {side}"
                );
                assert_eq!(events(&base), events(&changed), "{off} off for side {side}");
            }
        }
    }

    #[test]
    fn overrun_off_and_the_swing_count_see_a_wide_board_cleared() {
        let content = content();
        let base_registry = content.borrow().registry.clone();
        let wide: Vec<_> = (0..7).map(|_| ("private", false)).collect();
        let p = payloads(&content, [&[("ironhide-berserker", false)], &wide]);
        let mut biggest = 0;
        let mut whole = 0;
        for k in 0..4 {
            let swings = switch::Swings::default();
            let counted = fought(
                &content,
                &p,
                k,
                Setup {
                    registry: Some(switch::registry(
                        &base_registry,
                        &[],
                        -1,
                        Some((OVERRUN, &swings)),
                    )),
                    keep_events: true,
                    ..Setup::default()
                },
            );
            let plain = fought(&content, &p, k, Setup::default());
            assert_eq!(counted.outcome.result, plain.outcome.result);
            assert!(triggers(&counted, OVERRUN) > 0);
            for swing in swings.borrow().iter() {
                assert_eq!((swing.card.as_str(), swing.side), ("ironhide-berserker", 0));
                let kills = swing_kills(&counted.events, swing);
                assert!(kills <= swing.enemy_standing);
                biggest = biggest.max(kills);
                whole += usize::from(kills == swing.enemy_standing);
            }
            let registry = switch::registry(&base_registry, &[OVERRUN.to_owned()], 0, None);
            let off = fought(
                &content,
                &p,
                k,
                Setup {
                    registry: Some(registry),
                    keep_events: true,
                    ..Setup::default()
                },
            );
            assert_eq!(triggers(&off, OVERRUN), 0);
            assert_ne!(events(&off), events(&counted));
        }
        // 8 Attack and Fury 3 per unit it is outnumbered by, into 2/2s: one swing clears the board.
        assert!(biggest >= 4 && whole > 0);
        assert_eq!(keyword_units(&content, &p[0], OVERRUN), 1);
        assert_eq!(keyword_units(&content, &p[1], OVERRUN), 0);
    }

    #[test]
    fn wrapping_every_mechanic_changes_no_fight() {
        let content = content();
        let base_registry = content.borrow().registry.clone();
        let ids: Vec<String> = content
            .borrow()
            .library
            .borrow()
            .ids()
            .to_vec()
            .into_iter()
            .filter(|id| {
                !content
                    .borrow()
                    .library
                    .borrow()
                    .get_card(id)
                    .unwrap()
                    .borrow()
                    .is_spell()
            })
            .collect();
        let mut fights = 0;
        for n in 0..300 {
            let pick = |side: usize, i: usize| Rng::hash32(&format!("{n}|{side}|{i}")) as usize;
            let sides: Vec<Vec<(&str, bool)>> = (0..2)
                .map(|side| {
                    (0..1 + pick(side, 99) % 7)
                        .map(|i| {
                            (
                                ids[pick(side, i) % ids.len()].as_str(),
                                pick(side, i + 50) % 5 == 0,
                            )
                        })
                        .collect()
                })
                .collect();
            let p = payloads(&content, [&sides[0], &sides[1]]);
            let setup = |registry| Setup {
                registry,
                keep_events: true,
                seed: Some(n),
                ..Setup::default()
            };
            let base = restore::fight_with(&content, &setup(None), n, 9, &fight(), &p, true);
            let wrapped = restore::fight_with(
                &content,
                &setup(Some(switch::pass_through(&base_registry))),
                n,
                9,
                &fight(),
                &p,
                true,
            );
            match (base, wrapped) {
                (Ok(base), Ok(wrapped)) => {
                    assert_eq!(base.outcome.result, wrapped.outcome.result, "board {n}");
                    assert_eq!(events(&base), events(&wrapped), "board {n}");
                    fights += 1;
                }
                (Err(a), Err(b)) => assert_eq!(a.message(), b.message()),
                _ => panic!("board {n}: wrapping changed whether the fight runs"),
            }
        }
        assert!(fights > 250);
    }

    #[test]
    fn sampling_keeps_the_lowest_hashes_per_card_and_stage() {
        let make = |game, card: &str, round, hash| Candidate {
            game,
            round,
            fight: 0,
            change: Change::Text(0, 0),
            group: (card.to_owned(), stage(round)),
            hash,
        };
        let kept = sample(
            vec![
                make(0, "x", 1, 5),
                make(1, "x", 2, 1),
                make(2, "x", 3, 3),
                make(3, "x", 9, 9),
                make(4, "y", 1, 7),
            ],
            2,
        );
        let games: Vec<usize> = kept.keys().map(|k| k.0).collect();
        assert_eq!(games, vec![1, 2, 3, 4]);
    }

    fn fresh(side: usize, slot: usize, card: &str, off: bool) -> Setup {
        Setup {
            fresh: Some((side, slot, card.to_owned())),
            text_off: off.then_some((side, slot)),
            keep_events: true,
            ..Setup::default()
        }
    }

    #[test]
    fn a_fresh_copy_without_fight_text_reads_zero() {
        let content = content();
        let p = payloads(
            &content,
            [
                &[("private", false), ("heath-adder", false)],
                &[("prophet-of-the-dust", true), ("private", false)],
            ],
        );
        for k in 0..4 {
            // Sentry's text works at the end of a turn only: on and off fight the same.
            let on = fought(&content, &p, k, fresh(0, 2, "sentry", false));
            let off = fought(&content, &p, k, fresh(0, 2, "sentry", true));
            assert_eq!(on.outcome.result, off.outcome.result);
            assert_eq!(play(&on), play(&off));
            let copy = on.boards[0].iter().find(|u| u.slot == 2).unwrap();
            assert_eq!(
                (
                    copy.card.as_str(),
                    copy.golden,
                    copy.own_attack,
                    copy.own_health
                ),
                ("sentry", false, 2, 5)
            );
            assert_eq!(on.boards[0].len(), 3);
        }
    }

    #[test]
    fn a_fresh_copy_s_text_shows_and_it_takes_the_slot_it_is_given() {
        let content = content();
        // A fresh Heath Adder (1/1 Venomous) in place of a Private, against a 2/5 Sentry:
        // with its text it trades for a draw, without it the side loses.
        let p = payloads(&content, [&[("private", false)], &[("sentry", false)]]);
        let on: Vec<_> = (0..4)
            .map(|k| fought(&content, &p, k, fresh(0, 0, "heath-adder", false)))
            .collect();
        let off: Vec<_> = (0..4)
            .map(|k| fought(&content, &p, k, fresh(0, 0, "heath-adder", true)))
            .collect();
        assert_eq!(
            (
                means(&on, &fight(), 0).score,
                means(&off, &fight(), 0).score
            ),
            (0.5, 0.0)
        );
        let copy = &on[0].boards[0];
        assert_eq!(copy.len(), 1);
        assert_eq!((copy[0].card.as_str(), copy[0].slot), ("heath-adder", 0));
        assert_eq!(
            (off[0].boards[0][0].own_attack, off[0].boards[0][0].health),
            (1, 1)
        );
        assert!(off[0].boards[0][0].mechanics.is_empty());
    }

    #[test]
    fn the_fresh_copy_takes_a_free_slot_or_the_weakest_unit_s() {
        let unit = |slot: usize, card: &str, attack: i64, health: i64| restore::Standing {
            slot,
            card: card.to_owned(),
            golden: false,
            tier: 1,
            health,
            own_attack: attack,
            own_health: health,
            mechanics: Vec::new(),
        };
        let some = [unit(0, "a", 5, 5), unit(2, "b", 1, 1)];
        assert_eq!(fresh_slot(&some, 7), (1, None));
        let full: Vec<_> = (0..7)
            .map(|s| unit(s, &format!("u{s}"), 3, if s == 4 || s == 6 { 1 } else { 9 }))
            .collect();
        assert_eq!(fresh_slot(&full, 7), (4, Some("u4".to_owned())));
    }

    #[test]
    fn fresh_copies_go_where_their_tribe_and_tier_fit() {
        let content = content();
        let badgers = [
            ("brock-cub", false),
            ("brock-cub", false),
            ("brock-cub", false),
            ("private", false),
        ];
        let p = payloads(
            &content,
            [&badgers, &[("brock-cub", false), ("brock-cub", false)]],
        );
        // Player tier 1: a tier 2 card fits, a tier 3 card does not.
        assert!(fresh_fits(&content, &p[0], "heath-adder"));
        assert!(!fresh_fits(&content, &p[0], "sword-heir"));
        p[0].insert("tier", Variant::from(2i64));
        p[1].insert("tier", Variant::from(2i64));
        assert!(fresh_fits(&content, &p[0], "sword-heir"));
        // Two Badgers are too few; a card with no tribe fits any side.
        assert!(!fresh_fits(&content, &p[1], "sword-heir"));
        assert!(fresh_fits(&content, &p[1], "heath-adder"));
        // A Pigeon card needs three Pigeons.
        assert!(!fresh_fits(&content, &p[0], "sentry"));
    }

    #[test]
    fn stages_and_medians() {
        assert_eq!(
            [1, 4, 5, 8, 9, 12, 13, 20].map(stage),
            ["1-4", "1-4", "5-8", "5-8", "9-12", "9-12", "13+", "13+"]
        );
        assert_eq!(median(&mut [5, 1, 3]), Some(3.0));
        assert_eq!(median(&mut [4, 1, 3, 8]), Some(3.5));
        assert_eq!(median(&mut []), None);
    }
}
