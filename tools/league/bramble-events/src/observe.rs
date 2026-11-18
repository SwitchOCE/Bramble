use crate::Result;
use bramble_engine::core::{
    recruit::player_state::PlayerStateRef,
    session::game_session::GameSessionRef,
    units::{stat_block::StatBlock, unit::UnitRef},
};
use bramble_engine::{Dictionary, Variant};
use serde_json::{Value, json};
use std::collections::{HashMap, HashSet};

const GORGER: &str = "gorger";
const GLUT: &str = "granary-glutton";
const COLOUR: &str = "colour-sergeant";
const MAJOR: &str = "regimental-sergeant-major";

#[derive(Clone, Copy, Default, PartialEq, Eq)]
struct Stats(i64, i64);

impl Stats {
    fn add(self, rhs: Self) -> Self {
        Self(self.0 + rhs.0, self.1 + rhs.1)
    }

    fn sub(self, rhs: Self) -> Self {
        Self(self.0 - rhs.0, self.1 - rhs.1)
    }

    fn scale(self, times: i64) -> Self {
        Self(self.0 * times, self.1 * times)
    }

    fn json(self) -> Value {
        json!({"attack": self.0, "health": self.1})
    }

    fn event(event: &Dictionary) -> Self {
        Self(event.get("attack").as_i64(), event.get("health").as_i64())
    }

    fn perm(stats: &StatBlock) -> Self {
        Self(stats.perm_attack, stats.perm_health)
    }
}

fn card(unit: &UnitRef) -> String {
    unit.borrow()
        .def
        .as_ref()
        .expect("unit definition")
        .borrow()
        .id
        .clone()
}

fn permanent(unit: &UnitRef) -> Stats {
    Stats::perm(&unit.borrow().stats.as_ref().expect("unit stats").borrow())
}

fn identity(unit: &UnitRef) -> Value {
    let unit = unit.borrow();
    json!({
        "card": unit.def.as_ref().expect("unit definition").borrow().id,
        "uid": unit.uid, "golden": unit.golden
    })
}

fn unit_stats(unit: &UnitRef) -> Value {
    let value = unit.borrow();
    let stats = value.stats.as_ref().expect("unit stats").borrow();
    let mut out = identity(unit);
    out["tier"] = json!(value.def.as_ref().expect("unit definition").borrow().tier);
    out["slot"] = json!(value.slot);
    out["stats"] = Stats(stats.attack(), stats.max_health()).json();
    out["own_stats"] = Stats(stats.own_attack(), stats.own_health()).json();
    out
}

#[derive(Default)]
struct Snapshot {
    board: Vec<UnitRef>,
    cards: HashMap<i64, UnitRef>,
    gorgers: HashMap<i64, Stats>,
}

impl Snapshot {
    fn read(player: &PlayerStateRef) -> Self {
        let p = player.borrow();
        let board = p.board_units().to_vec();
        let mut cards = HashMap::with_capacity(board.len() + p.hand.len());
        let mut gorgers = HashMap::new();
        for unit in board.iter().chain(p.hand.borrow().iter()) {
            let u = unit.borrow();
            cards.insert(u.uid, unit.clone());
            if u.def.as_ref().expect("unit definition").borrow().id == GORGER {
                gorgers.insert(
                    u.uid,
                    Stats::perm(&u.stats.as_ref().expect("Gorger stats").borrow()),
                );
            }
        }
        Self {
            board,
            cards,
            gorgers,
        }
    }

    fn majors(&self) -> Vec<(i64, i64, Value)> {
        self.board
            .iter()
            .filter_map(|unit| {
                let u = unit.borrow();
                let rule = u
                    .mechanics
                    .borrow()
                    .iter()
                    .find(|hook| hook.borrow().id == "pigeon_sergeant_major")?
                    .clone();
                Some((
                    u.uid,
                    100 + rule.borrow().params.borrow().num("extra_percent"),
                    identity(unit),
                ))
            })
            .collect()
    }
}

struct PendingSale {
    unit: UnitRef,
    sold: Value,
    own: Stats,
    eater_permanent: HashMap<i64, Stats>,
}

pub struct Before {
    log_start: usize,
    fight_start: usize,
    ghost_of: i64,
    ghost_majors: Vec<(i64, i64, Value)>,
    seats: Vec<i64>,
    states: HashMap<i64, Snapshot>,
    sale: Option<PendingSale>,
}

#[derive(Clone, Copy, Default)]
struct Ledger {
    eat: Stats,
    other: Stats,
    inherited: bool,
}

#[derive(Clone, Copy, Default)]
pub struct Report {
    pub gorgers: usize,
    pub other: usize,
    pub triples: usize,
}

impl Report {
    pub fn add(&mut self, other: Self) {
        self.gorgers += other.gorgers;
        self.other += other.other;
        self.triples += other.triples;
    }
}

pub struct Observer {
    game: usize,
    first_board: HashMap<i64, i64>,
    round_units: HashSet<i64>,
    seen_round: i64,
    ledger: HashMap<i64, Ledger>,
    final_boards: HashMap<i64, Report>,
}

impl Observer {
    pub fn new(game: usize) -> Self {
        Self {
            game,
            first_board: HashMap::new(),
            round_units: HashSet::new(),
            seen_round: 0,
            ledger: HashMap::new(),
            final_boards: HashMap::new(),
        }
    }

    pub fn before(&self, game: &GameSessionRef, entry: &Dictionary) -> Before {
        let game = game.borrow();
        let op = entry.get("op").as_text();
        let seat = entry.get_or("player", (-1).into()).as_i64();
        let seats = if matches!(op.as_str(), "act" | "end") {
            (0..game.players.len() as i64)
                .contains(&seat)
                .then_some(seat)
                .into_iter()
                .collect()
        } else {
            game.alive_ids().to_vec()
        };
        let states: HashMap<_, _> = seats
            .iter()
            .map(|&seat| (seat, Snapshot::read(&game.player(seat))))
            .collect();
        let action = entry.get("action").as_dict();
        let sale = if op == "act" && action.get("type").as_text() == "sell" {
            let slot = action.get_or("slot", (-1).into()).as_i64();
            states
                .get(&seat)
                .and_then(|state| state.board.iter().find(|u| u.borrow().slot == slot))
                .map(|unit| {
                    let stats = unit.borrow().stats.as_ref().expect("sale stats").clone();
                    let stats = stats.borrow();
                    PendingSale {
                        unit: unit.clone(),
                        sold: unit_stats(unit),
                        own: Stats(stats.own_attack(), stats.own_health()),
                        eater_permanent: states[&seat]
                            .board
                            .iter()
                            .filter_map(|unit| {
                                matches!(card(unit).as_str(), GORGER | GLUT)
                                    .then(|| (unit.borrow().uid, permanent(unit)))
                            })
                            .collect(),
                    }
                })
        } else {
            None
        };
        let ghost_majors = if op == "finish" {
            game.ghost_player
                .as_ref()
                .map(Snapshot::read)
                .map(|s| s.majors())
                .unwrap_or_default()
        } else {
            Vec::new()
        };
        Before {
            log_start: game.events.len(),
            fight_start: game.fights.len(),
            ghost_of: game.ghost_of,
            ghost_majors,
            seats,
            states,
            sale,
        }
    }

    pub fn after(
        &mut self,
        game: &GameSessionRef,
        entry: &Dictionary,
        before: Before,
    ) -> Result<Vec<Value>> {
        let op = entry.get("op").as_text();
        let round = entry.get("turn").as_i64();
        if round != self.seen_round {
            self.round_units.clear();
            self.seen_round = round;
        }
        let game = game.borrow();
        let after = before
            .seats
            .iter()
            .map(|&seat| (seat, Snapshot::read(&game.player(seat))))
            .collect::<HashMap<_, _>>();
        let new_log = game.events.borrow();
        let logs = &new_log[before.log_start..];
        let mut rows = Vec::new();
        for &seat in &before.seats {
            let pre = &before.states[&seat];
            let post = &after[&seat];
            let sale_log = logs
                .iter()
                .find(|e| e.get("type").as_text() == "sell" && e.get("player").as_i64() == seat);
            let sold_uid = sale_log.map(|e| e.get("uid").as_i64());
            let mut gains = HashMap::new();
            let mut fed = Vec::new();
            if let Some(sell) = sale_log {
                let sale = before.sale.as_ref().ok_or("missing pre-sale unit")?;
                let uid = sell.get("uid").as_i64();
                if uid != sale.unit.borrow().uid {
                    return Err("sale log does not match the pre-sale slot".into());
                }
                if let Some((eater, gain)) = eat(logs, pre, sale)? {
                    let event = self.event(
                        "eat",
                        round,
                        seat,
                        json!({
                            "eater": identity(&eater),
                            "eaten": sale.sold,
                            "gain": gain.json(),
                            "trigger": "sale",
                        }),
                    );
                    if card(&eater) == GORGER {
                        gains.insert(eater.borrow().uid, gain);
                    }
                    fed.push(
                        json!({"type": "eat", "eater": event["eater"], "gain": event["gain"]}),
                    );
                    rows.push(event);
                }
            }

            // A recruit slot hook's source and increment are recorded at the moment of the
            // change. The board before the operation supplies the give-time Major rule.
            let mut majors = pre.majors();
            for log in logs
                .iter()
                .filter(|e| e.has("player") && e.get("player").as_i64() == seat)
            {
                let kind = log.get("type").as_text();
                if log.get("id").as_text() == MAJOR {
                    let uid = log.get("uid").as_i64();
                    match kind.as_str() {
                        "sell" => majors.retain(|m| m.0 != uid),
                        "triple" => {
                            majors.retain(|m| post.cards.contains_key(&m.0));
                            majors.extend(post.majors().into_iter().filter(|m| m.0 == uid));
                        }
                        "play" => majors.extend(post.majors().into_iter().filter(|m| m.0 == uid)),
                        _ => (),
                    }
                }
                if kind != "slot" {
                    continue;
                }
                let amount = Stats::event(log);
                if amount == Stats::default() {
                    continue;
                }
                let uid = log.get("source_uid").as_i64();
                let source = pre
                    .cards
                    .get(&uid)
                    .or_else(|| post.cards.get(&uid))
                    .ok_or_else(|| format!("unknown recruit slot source {uid}"))?;
                let event = self.event(
                    "slot_growth",
                    round,
                    seat,
                    growth(
                        log,
                        amount,
                        identity(source),
                        &majors,
                        trigger(entry),
                        false,
                        false,
                    )?,
                );
                if sale_log.is_some() {
                    fed.push(json!({"type": "slot_growth", "source": event["source"],
                                    "slot": event["slot"], "amount": event["amount"]}));
                }
                rows.push(event);
            }
            if let Some(sell) = sale_log {
                let sale = before.sale.as_ref().expect("matched sale");
                let uid = sell.get("uid").as_i64();
                let first = self
                    .first_board
                    .get(&uid)
                    .ok_or("sold unit has no board entry round")?;
                let event = self.event(
                    "sale",
                    round,
                    seat,
                    json!({
                        "unit": sale.sold, "gold": sell.get("gold").as_i64(),
                        "board_since_round": first, "rounds_on_board": round - first, "fed": fed,
                    }),
                );
                rows.push(event);
            }
            self.account(pre, post, logs, seat, sold_uid, &gains)?;
            self.exposures(post, round, seat, &mut rows);
            if op == "fight_boards" {
                self.check_board(round, seat, post)?;
            }
        }
        if op == "finish" {
            for fight in &game.fights.borrow()[before.fight_start..] {
                self.combat_growth(fight, round, &before, &mut rows)?;
            }
        }
        Ok(rows)
    }

    fn event(&self, kind: &str, round: i64, seat: i64, mut fields: Value) -> Value {
        fields["type"] = json!(kind);
        fields["game"] = json!(self.game);
        fields["round"] = json!(round);
        fields["seat"] = json!(seat);
        fields
    }

    fn exposures(&mut self, post: &Snapshot, round: i64, seat: i64, rows: &mut Vec<Value>) {
        for unit in &post.board {
            let uid = unit.borrow().uid;
            self.first_board.entry(uid).or_insert(round);
            if matches!(card(unit).as_str(), GORGER | GLUT | COLOUR | MAJOR)
                && self.round_units.insert(uid)
            {
                rows.push(self.event("unit_round", round, seat, json!({"unit": identity(unit)})));
            }
        }
    }

    fn account(
        &mut self,
        pre: &Snapshot,
        post: &Snapshot,
        logs: &[Dictionary],
        seat: i64,
        sold_uid: Option<i64>,
        gains: &HashMap<i64, Stats>,
    ) -> Result<()> {
        if pre.gorgers.is_empty() && post.gorgers.is_empty() {
            return Ok(());
        }
        for (&uid, &start) in &pre.gorgers {
            let change = permanent(&pre.cards[&uid]).sub(start);
            let line = self.ledger.entry(uid).or_default();
            if let Some(&gain) = gains.get(&uid) {
                // The eat hook is the only permanent stat mutation on a surviving Gorger
                // during a sale in this ruleset. Keep any discrepancy visible in the audit.
                line.eat = line.eat.add(gain);
            } else {
                line.other = line.other.add(change);
            }
        }
        let mut triples = logs.iter().filter(|e| {
            e.get("type").as_text() == "triple"
                && e.get("id").as_text() == GORGER
                && e.get("player").as_i64() == seat
        });
        if let Some(triple) = triples.next() {
            if triples.next().is_some() {
                return Err("multiple Gorger triples in one replay step for a seat".into());
            }
            let uid = triple.get("uid").as_i64();
            let mut line = Ledger {
                inherited: true,
                ..Ledger::default()
            };
            let mut inherited = Stats::default();
            for &old in pre
                .gorgers
                .keys()
                .filter(|uid| !post.cards.contains_key(uid) && Some(**uid) != sold_uid)
            {
                let old_line = self.ledger.get(&old).copied().unwrap_or_default();
                line.eat = line.eat.add(old_line.eat);
                line.other = line.other.add(old_line.other);
                inherited = inherited.add(permanent(&pre.cards[&old]));
            }
            // A newly acquired third copy contributes zero. The engine floors each combined
            // permanent layer at zero and assigns the new copy its golden base.
            line.other = line
                .other
                .add(Stats(inherited.0.max(0), inherited.1.max(0)).sub(inherited));
            self.ledger.insert(uid, line);
        }
        for (&uid, &perm) in &post.gorgers {
            if !pre.gorgers.contains_key(&uid) {
                self.ledger.entry(uid).or_insert(Ledger {
                    other: perm,
                    ..Ledger::default()
                });
            }
        }
        Ok(())
    }

    fn check_board(&mut self, round: i64, seat: i64, snapshot: &Snapshot) -> Result<()> {
        let mut report = Report::default();
        for unit in &snapshot.board {
            let u = unit.borrow();
            if u.def.as_ref().expect("unit definition").borrow().id != GORGER {
                continue;
            }
            let line = self.ledger.get(&u.uid).copied().unwrap_or_default();
            let stats = u.stats.as_ref().expect("Gorger stats").borrow();
            let mut expected = stats.clone();
            let Stats(attack, health) = line.eat.add(line.other);
            expected.perm_attack = attack;
            expected.perm_health = health;
            let exact = Stats(attack, health) == Stats::perm(&stats)
                && expected.attack() == u.attack()
                && expected.max_health() == u.health();
            if !exact {
                return Err(format!(
                    "game {} round {round} seat {seat} Gorger uid {} failed reconciliation: recorded permanent gains {attack}/{health}, board permanent layer {}/{}",
                    self.game, u.uid, stats.perm_attack, stats.perm_health
                ).into());
            }
            report.gorgers += 1;
            report.other += usize::from(line.other != Stats::default());
            report.triples += usize::from(line.inherited);
        }
        self.final_boards.insert(seat, report);
        Ok(())
    }

    pub fn report(&self) -> Report {
        let mut out = Report::default();
        for r in self.final_boards.values() {
            out.add(*r);
        }
        out
    }

    fn combat_growth(
        &self,
        fight: &Dictionary,
        round: i64,
        before: &Before,
        rows: &mut Vec<Value>,
    ) -> Result<()> {
        let players = fight.get("players").as_array();
        let majors = players
            .borrow()
            .iter()
            .map(|seat| {
                let seat = seat.as_i64();
                if seat < 0 {
                    before.ghost_majors.clone()
                } else {
                    before.states[&seat].majors()
                }
            })
            .collect::<Vec<_>>();
        let mut units = HashMap::new();
        let events = fight.get("events").as_array();
        for value in events.borrow().iter() {
            let event = value.as_dict();
            match event.get("type").as_text().as_str() {
                "combat_start" => {
                    for key in ["boards", "reserve"] {
                        for side in event.get(key).as_array().borrow().iter() {
                            for unit in side.as_array().borrow().iter() {
                                remember(&mut units, &unit.as_dict());
                            }
                        }
                    }
                }
                "summon" | "reserve" | "return" => remember(&mut units, &event),
                "slot" => {
                    let amount = Stats::event(&event);
                    if amount.0 <= 0 && amount.1 <= 0 {
                        continue;
                    }
                    let side = event.get("side").as_i64() as usize;
                    let player = players
                        .get(side)
                        .ok_or("invalid combat slot side")?
                        .as_i64();
                    let ghost = player < 0;
                    let seat = if ghost { before.ghost_of } else { player };
                    let uid = event.get("source_uid").as_i64();
                    let source = units
                        .get(&uid)
                        .ok_or_else(|| format!("unknown combat slot source {uid}"))?;
                    // The Ensign copies stats for this fight, bypassing the slot-buff multiplier.
                    let copy = source["card"] == "colour-ensign";
                    let mut fields = growth(
                        &event,
                        amount,
                        source.clone(),
                        &majors[side],
                        "combat",
                        ghost,
                        copy,
                    )?;
                    fields["fight_players"] = json!([
                        players.get(0).unwrap().as_i64(),
                        players.get(1).unwrap().as_i64()
                    ]);
                    rows.push(self.event("slot_growth", round, seat, fields));
                }
                _ => (),
            }
        }
        Ok(())
    }
}

fn trigger(entry: &Dictionary) -> String {
    match entry.get("op").as_text().as_str() {
        "act" => match entry.get("action").as_dict().get("type").as_text().as_str() {
            "sell" => "sale".into(),
            "buy" => "purchase".into(),
            "end_turn" => "end_turn".into(),
            other => other.into(),
        },
        "start" => "start_turn".into(),
        "finish" => "after_fight".into(),
        _ => "end_turn".into(),
    }
}

fn eat(
    logs: &[Dictionary],
    pre: &Snapshot,
    sale: &PendingSale,
) -> Result<Option<(UnitRef, Stats)>> {
    let sold_uid = sale.unit.borrow().uid;
    let marks = logs
        .iter()
        .filter(|log| {
            log.get("type").as_text() == "turn_counter"
                && log.get("key").as_text() == "locust_eaten"
                && log.get("uid").as_i64() == sold_uid
        })
        .collect::<Vec<_>>();
    if marks.is_empty() && sale.unit.borrow().turn_counter("locust_eaten") == 0 {
        return Ok(None);
    }
    if marks.len() != 1 || sale.unit.borrow().turn_counter("locust_eaten") != 1 {
        return Err("sold unit's eat marker disagrees with the replay log".into());
    }
    let uid = marks[0].get("source_uid").as_i64();
    let eater = pre
        .cards
        .get(&uid)
        .ok_or("eat source missing from pre-sale cards")?;
    let mechanic = logs
        .iter()
        .find_map(|log| {
            let id = log.get("mechanic").as_text();
            (log.get("type").as_text() == "trigger"
                && log.get("uid").as_i64() == uid
                && matches!(id.as_str(), "locust_gorge" | "locust_glut"))
            .then_some(id)
        })
        .ok_or("eat marker without a Gorger or Glutton trigger")?;
    let hook = eater
        .borrow()
        .hooks()
        .to_vec()
        .into_iter()
        .find(|hook| hook.borrow().id == mechanic)
        .ok_or("eater lacks its triggered mechanic")?;
    let times = hook.borrow().params.borrow().num("times");
    let before = sale
        .eater_permanent
        .get(&uid)
        .ok_or("missing pre-sale eater stats")?;
    let gain = permanent(eater).sub(*before);
    if gain != sale.own.scale(times) {
        return Err(format!(
            "eater {uid}'s permanent gain differs from the sold unit's own stats times {times}"
        )
        .into());
    }
    Ok(Some((eater.clone(), gain)))
}

fn remember(units: &mut HashMap<i64, Value>, unit: &Dictionary) {
    let uid = unit.get("uid").as_i64();
    let recruit = unit.get_or("recruit_uid", (-1).into()).as_i64();
    units.insert(
        uid,
        json!({
            "card": unit.get("id").as_text(), "golden": matches!(unit.get("golden"), Variant::Bool(true)),
            "uid": if recruit < 0 { uid } else { recruit },
            "uid_scope": if recruit < 0 { "fight" } else { "game" },
        }),
    );
}

fn growth(
    log: &Dictionary,
    amount: Stats,
    source: Value,
    majors: &[(i64, i64, Value)],
    trigger: impl AsRef<str>,
    ghost: bool,
    copy: bool,
) -> Result<Value> {
    let mut row = json!({
        "slot": log.get("slot").as_i64(), "amount": amount.json(),
        "source": source, "trigger": trigger.as_ref(),
        "permanent": matches!(log.get("permanent"), Variant::Bool(true)), "ghost": ghost,
    });
    if !copy && let Some(percent) = majors.iter().map(|m| m.1).max().filter(|&p| p > 100) {
        let base = Stats(amount.0 * 100 / percent, amount.1 * 100 / percent);
        if base.scale(percent) != amount.scale(100) {
            return Err("slot growth does not match the Sergeant Major multiplier".into());
        }
        row["amplification"] = json!({
            "percent": percent, "amount": amount.sub(base).json(),
            "sources": majors.iter().filter(|m| m.1 == percent).map(|m| &m.2).collect::<Vec<_>>(),
        });
    }
    Ok(row)
}
