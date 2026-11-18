//! The red team's bot: card values from a table (data/cards.tsv), a tier curve, tribe
//! commitment by board value, triples, and end-of-turn positioning searched with Sim fights
//! against the latest boards seen.
#![forbid(unsafe_code)]

use league_api::{Action, Bot, BotSetup, BotView, Me, Payload, Report, Rng, Sim, UnitView};
use std::collections::BTreeMap;

const TABLE: &[u8] = include_bytes!("../../data/cards.tsv");
const TRIBES: [&str; 5] = ["Badger", "Mouse", "Pigeon", "Locust", "Briar"];

#[derive(Clone, Debug)]
pub struct CardRow {
    pub power: f64,
    pub growth: f64,
    pub syn: f64,
    /// 0 front, 1 back, 2 any
    pub row: u8,
    pub keep_late: f64,
    pub pair: f64,
}

/// Tunable numbers. `Params::default()` is the hand-in setting.
#[derive(Clone, Debug)]
pub struct Params {
    /// Target tier at round r (index r, capped at the end).
    pub tier_curve: Vec<i64>,
    /// Upgrade anyway when it costs at most this.
    pub cheap_upgrade: i64,
    pub growth_turns: f64,
    pub syn_per_unit: f64,
    pub syn_base_penalty: f64,
    pub commit_bonus: f64,
    pub pair_bonus: f64,
    pub triple_bonus: f64,
    pub swap_margin: f64,
    pub max_refresh: i64,
    pub min_buy_value: f64,
    pub spell_value: f64,
    pub sim_positioning: bool,
    pub sim_share: f64,
}

impl Default for Params {
    fn default() -> Self {
        Self {
            tier_curve: vec![1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6],
            cheap_upgrade: 3,
            growth_turns: 0.5,
            syn_per_unit: 1.5,
            syn_base_penalty: 1.0,
            commit_bonus: 2.0,
            pair_bonus: 4.0,
            triple_bonus: 12.0,
            swap_margin: 3.0,
            max_refresh: 12,
            min_buy_value: 0.0,
            spell_value: 1.0,
            sim_positioning: true,
            sim_share: 0.9,
        }
    }
}

pub fn parse_table() -> BTreeMap<String, CardRow> {
    let mut out = BTreeMap::new();
    let text = String::from_utf8_lossy(TABLE);
    for (n, line) in text.lines().enumerate() {
        if n == 0 || line.trim().is_empty() || line.starts_with('#') {
            continue;
        }
        let f: Vec<&str> = line.split('\t').collect();
        if f.len() < 7 {
            continue;
        }
        let num = |i: usize| f[i].trim().parse::<f64>().unwrap_or(0.0);
        let row = match f[4].trim() {
            "F" => 0,
            "B" => 1,
            _ => 2,
        };
        out.insert(
            f[0].trim().to_string(),
            CardRow {
                power: num(1),
                growth: num(2),
                syn: num(3),
                row,
                keep_late: num(5),
                pair: num(6),
            },
        );
    }
    out
}

pub struct Red {
    rng: Rng,
    p: Params,
    table: BTreeMap<String, CardRow>,
    round: i64,
    refreshes: i64,
    /// Planned arrangement for this turn: uid per slot (-1 empty).
    plan: Option<Vec<i64>>,
    planned_round: i64,
    used_once: Vec<(i64, String)>,
    abilities_this_turn: i64,
    clock_total: i64,
}

pub fn new_bot(seed: u64, setup: &BotSetup) -> Box<dyn Bot> {
    Box::new(new_red(seed, setup, Params::default()))
}

pub fn new_red(seed: u64, setup: &BotSetup, p: Params) -> Red {
    Red {
        rng: Rng::new((seed ^ (seed >> 32)) as i64),
        p,
        table: parse_table(),
        round: -1,
        refreshes: 0,
        plan: None,
        planned_round: -1,
        used_once: Vec::new(),
        abilities_this_turn: 0,
        clock_total: setup.clock_ns(),
    }
}

fn tribes_of(view: &BotView, def: &str) -> Vec<&'static str> {
    let Some(c) = view.library().get(def) else {
        return vec![];
    };
    if c.has_tribe("All") {
        return TRIBES.to_vec();
    }
    TRIBES.iter().copied().filter(|t| c.has_tribe(t)).collect()
}

impl Red {
    fn row(&self, def: &str) -> CardRow {
        self.table.get(def).cloned().unwrap_or(CardRow {
            power: 0.0,
            growth: 0.0,
            syn: 1.0,
            row: 2,
            keep_late: 1.0,
            pair: 1.0,
        })
    }

    /// Tribe counts on board (units), plus value weight.
    fn tribe_counts(&self, view: &BotView) -> [f64; 5] {
        let mut out = [0.0; 5];
        for u in view.me().board_units().chain(view.me().hand.iter()) {
            if u.spell {
                continue;
            }
            let w = if u.slot >= 0 { 1.0 } else { 0.7 };
            for t in tribes_of(view, &u.def) {
                let i = TRIBES.iter().position(|x| *x == t).unwrap();
                out[i] += w;
            }
        }
        out
    }

    fn main_tribe(&self, view: &BotView) -> Option<usize> {
        let c = self.tribe_counts(view);
        let mut best = None;
        let mut bv = 1.5;
        for (i, v) in c.iter().enumerate() {
            if *v > bv {
                bv = *v;
                best = Some(i);
            }
        }
        best
    }

    /// Value of a card on my board. `stats` is its current attack+health (None: fresh).
    fn value(&self, view: &BotView, def: &str, golden: bool, stats: Option<i64>, exclude_self: bool) -> f64 {
        let lib = view.library();
        let Some(info) = lib.get(def) else {
            return 0.0;
        };
        if info.spell {
            return 0.0;
        }
        let r = self.row(def);
        let mult = if golden { 2.0 } else { 1.0 };
        let base = (info.attack + info.health) as f64;
        let power = if self.table.contains_key(def) {
            r.power
        } else {
            base + 2.0 * info.tier as f64
        };
        let effect = power - base;
        let cur = stats.map_or(base * mult, |s| s as f64);
        let round = view.round();
        let turns_left = (15 - round).max(1) as f64;
        let mut v = cur + effect * mult + r.growth * mult * turns_left * self.p.growth_turns;
        // Synergy with my tribes.
        let counts = self.tribe_counts(view);
        let mut best_t: f64 = 0.0;
        for t in tribes_of(view, def) {
            let i = TRIBES.iter().position(|x| *x == t).unwrap();
            let n = counts[i] - if exclude_self { 1.0 } else { 0.0 };
            best_t = best_t.max(n);
        }
        v += r.syn * (best_t * self.p.syn_per_unit - self.p.syn_base_penalty * 2.0);
        if let Some(m) = self.main_tribe(view)
            && tribes_of(view, def).contains(&TRIBES[m])
        {
            v += self.p.commit_bonus * (round as f64 / 4.0).min(3.0);
        }
        if round >= 10 {
            v *= 0.75 + 0.08 * r.keep_late;
        }
        v
    }

    fn unit_value(&self, view: &BotView, u: &UnitView) -> f64 {
        // A slot's buff stays with the slot, so it isn't the unit's worth.
        let mut stats = u.attack + u.health;
        if u.slot >= 0
            && let Some(s) = view.me().slots.get(u.slot as usize)
        {
            stats -= s.attack.max(0) + s.health.max(0);
        }
        self.value(view, &u.def, u.golden, Some(stats.max(1)), true)
    }

    fn copies_held(&self, me: &Me, def: &str) -> i64 {
        me.all_cards().filter(|u| u.def == def && !u.golden).count() as i64
    }

    fn shop_value(&self, view: &BotView, def: &str) -> f64 {
        let me = view.me();
        let mut v = self.value(view, def, false, None, false);
        let held = self.copies_held(me, def);
        let pair = self.row(def).pair;
        if held >= 2 {
            v += self.p.triple_bonus + 4.0 * pair + view.me().tier as f64 * 2.0;
        } else if held == 1 {
            v += self.p.pair_bonus * (0.5 + 0.5 * pair);
        }
        v
    }

    fn worst_board<'v>(&self, view: &'v BotView) -> Option<(&'v UnitView, f64)> {
        let mut best: Option<(&'v UnitView, f64)> = None;
        for u in view.me().board_units() {
            let mut v = self.unit_value(view, u);
            // Don't break a pair.
            if !u.golden && self.copies_held(view.me(), &u.def) >= 2 {
                v += self.p.pair_bonus;
            }
            if best.is_none_or(|(_, bv)| v < bv) {
                best = Some((u, v));
            }
        }
        best
    }

    fn target_tier(&self, round: i64) -> i64 {
        let c = &self.p.tier_curve;
        c[(round as usize).min(c.len() - 1)]
    }

    fn pick_discover(&self, view: &BotView) -> usize {
        let me = view.me();
        let legal = view.legal();
        let mut best = 0;
        let mut bv = f64::MIN;
        for (i, a) in legal.iter().enumerate() {
            if let Action::Pick { index } = a {
                let def = &me.discover_options[*index as usize];
                let v = self.shop_value(view, def);
                if v > bv {
                    bv = v;
                    best = i;
                }
            }
        }
        best
    }

    /// Best slot for a unit to be played into now: front or back by its row.
    fn play_slot(&self, view: &BotView, def: &str) -> Option<i64> {
        let me = view.me();
        let empty = me.empty_slots();
        if empty.is_empty() {
            return None;
        }
        let r = self.row(def).row;
        let want_back = r == 1;
        let pick = if want_back {
            empty.iter().rev().find(|s| **s >= 4).or(empty.first())
        } else {
            empty.iter().find(|s| **s < 4).or(empty.first())
        };
        pick.copied()
    }

    fn heuristic(&mut self, view: &BotView) -> Option<Action> {
        let me = view.me();
        let legal = view.legal();
        let has = |a: &Action| legal.contains(a);
        let round = view.round();

        // 1. Play units from hand while there is room; best first.
        let mut best_play: Option<(f64, usize)> = None;
        for (hi, u) in me.hand.iter().enumerate() {
            if u.spell {
                continue;
            }
            let v = self.unit_value(view, u);
            if best_play.is_none_or(|(bv, _)| v > bv) {
                best_play = Some((v, hi));
            }
        }
        if let Some((_, hi)) = best_play
            && let Some(slot) = self.play_slot(view, &me.hand[hi].def)
        {
            // Pick the best target for a when-played effect: the highest-value board unit.
            let mut cands: Vec<&Action> = legal
                .iter()
                .filter(|a| matches!(a, Action::Play { hand, slot: s, .. } if *hand == hi as i64 && *s == slot))
                .collect();
            if cands.is_empty() {
                cands = legal
                    .iter()
                    .filter(|a| matches!(a, Action::Play { hand, slot: s, .. } if *hand == hi as i64 && *s >= 0))
                    .collect();
            }
            if let Some(a) = self.best_target(view, &cands) {
                return Some(a);
            }
        }
        // Spells in hand: play on the best unit.
        for (hi, u) in me.hand.iter().enumerate() {
            if !u.spell {
                continue;
            }
            let cands: Vec<&Action> = legal
                .iter()
                .filter(|a| matches!(a, Action::Play { hand, .. } if *hand == hi as i64))
                .collect();
            if let Some(a) = self.best_target(view, &cands) {
                return Some(a);
            }
        }

        // 2. Upgrade.
        if me.upgrade_cost >= 0 && has(&Action::Upgrade) {
            let want = me.tier < self.target_tier(round)
                || me.upgrade_cost <= self.p.cheap_upgrade;
            if want && me.gold >= me.upgrade_cost {
                return Some(Action::Upgrade);
            }
        }

        // 3. Buy.
        let units_in_hand = me.hand.iter().filter(|u| !u.spell).count() as i64;
        let room = me.board_count() + units_in_hand < 7;
        let hand_room = (me.hand.len() as i64) < me.hand_limit;
        let worst = self.worst_board(view).map(|(u, v)| (u.slot, v, u.sell_value));
        let mut best_buy: Option<(f64, Action)> = None;
        for a in legal {
            if let Action::Buy { spell, index } = a {
                let i = *index as usize;
                if *spell {
                    let def = &me.shop_spells[i];
                    let price = me.spell_prices[i];
                    let v = self.spell_buy_value(view, def, price);
                    if v > 0.0 && best_buy.as_ref().is_none_or(|(bv, _)| v > *bv) {
                        best_buy = Some((v, a.clone()));
                    }
                    continue;
                }
                let def = &me.shop_units[i];
                let price = me.unit_prices[i];
                if price > me.gold {
                    continue;
                }
                let v = self.shop_value(view, def);
                let held = self.copies_held(me, def);
                let ok = if held >= 2 && hand_room {
                    true
                } else if room {
                    v > self.p.min_buy_value
                } else if let Some((_, wv, _)) = worst {
                    hand_room && v > wv + self.p.swap_margin
                } else {
                    false
                };
                if ok {
                    // Compare by value per price lightly.
                    let score = v - 0.3 * price as f64 + 1000.0;
                    if best_buy.as_ref().is_none_or(|(bv, _)| score > *bv) {
                        best_buy = Some((score, a.clone()));
                    }
                }
            }
        }

        // 4. Sell the worst board unit when the hand holds a better unit and the board is full.
        if me.board_count() >= 7
            && let Some((slot, wv, _)) = worst
        {
            for u in &me.hand {
                if !u.spell && self.unit_value(view, u) > wv + 0.5 {
                    let sell = Action::Sell { slot };
                    if has(&sell) {
                        return Some(sell);
                    }
                }
            }
        }

        if let Some((_, a)) = best_buy {
            return Some(a);
        }

        // 5. Abilities.
        if self.abilities_this_turn < 6
            && let Some(a) = self.pick_ability(view)
        {
            self.abilities_this_turn += 1;
            return Some(a);
        }

        // 6. Refresh.
        let keep = if me.upgrade_cost >= 0 && me.tier < self.target_tier(round + 1) {
            // Saving toward next turn's upgrade isn't needed: income covers most of it.
            0
        } else {
            0
        };
        if has(&Action::Refresh)
            && self.refreshes < self.p.max_refresh
            && me.gold >= me.refresh_cost + keep + 2.min(me.tier + 1)
            && (room || hand_room)
        {
            self.refreshes += 1;
            return Some(Action::Refresh);
        }
        None
    }

    fn spell_buy_value(&self, view: &BotView, def: &str, price: i64) -> f64 {
        let me = view.me();
        if price > me.gold || (me.hand.len() as i64) >= me.hand_limit {
            return 0.0;
        }
        match def {
            "sp_sharpen" => {
                if me.board_count() > 0 {
                    1000.0 + 3.0 * self.p.spell_value
                } else {
                    0.0
                }
            }
            "sp_seek" | "sp_forage" => {
                let units_in_hand = me.hand.iter().filter(|u| !u.spell).count() as i64;
                if me.board_count() + units_in_hand < 7 && view.round() >= 3 {
                    1000.0 + self.p.spell_value
                } else {
                    0.0
                }
            }
            _ => 0.0,
        }
    }

    fn best_target(&self, view: &BotView, cands: &[&Action]) -> Option<Action> {
        let me = view.me();
        let mut best: Option<(f64, Action)> = None;
        for a in cands {
            let t = match a {
                Action::Play { target, .. } => *target,
                Action::Ability { target, .. } => *target,
                _ => -1,
            };
            let v = if t < 0 {
                0.0
            } else {
                me.find_uid(t).map_or(0.0, |u| {
                    let r = self.row(&u.def);
                    if u.slot >= 0 { 10.0 + r.keep_late * 5.0 + (u.attack + u.health) as f64 * 0.1 } else { 0.0 }
                })
            };
            if best.as_ref().is_none_or(|(bv, _)| v > *bv) {
                best = Some((v, (*a).clone()));
            }
        }
        best.map(|(_, a)| a)
    }

    fn pick_ability(&mut self, view: &BotView) -> Option<Action> {
        let me = view.me();
        let legal = view.legal();
        let mut groups: BTreeMap<(i64, String), Vec<&Action>> = BTreeMap::new();
        for a in legal {
            if let Action::Ability { uid, mechanic, .. } = a {
                groups.entry((*uid, mechanic.clone())).or_default().push(a);
            }
        }
        for ((uid, mech), acts) in groups {
            let once = mech.contains("grenadier") || mech.contains("guard");
            if once && self.used_once.contains(&(uid, mech.clone())) {
                continue;
            }
            // Order costs gold: keep some for buying.
            if mech.contains("lance") && me.gold < 3 {
                continue;
            }
            let pick = if mech.contains("bury") {
                // Bury: target the shop card I value least.
                let mut best: Option<(f64, Action)> = None;
                for a in &acts {
                    if let Action::Ability { target, .. } = a {
                        let v = if *target >= 0 && (*target as usize) < me.shop_units.len() {
                            -self.shop_value(view, &me.shop_units[*target as usize])
                        } else {
                            0.0
                        };
                        if best.as_ref().is_none_or(|(bv, _)| v > *bv) {
                            best = Some((v, (*a).clone()));
                        }
                    }
                }
                best.map(|(_, a)| a)
            } else if once {
                // Guard post: the front unit with most health.
                let mut best: Option<(f64, Action)> = None;
                for a in &acts {
                    if let Action::Ability { target, .. } = a {
                        let v = me.find_uid(*target).map_or_else(
                            || {
                                // target may be a slot index
                                me.board
                                    .get(*target as usize)
                                    .and_then(|s| s.as_ref())
                                    .map_or(0.0, |u| if u.slot < 4 { u.health as f64 } else { 0.0 })
                            },
                            |u| if u.slot < 4 && u.slot >= 0 { u.health as f64 } else { 0.0 },
                        );
                        if best.as_ref().is_none_or(|(bv, _)| v > *bv) {
                            best = Some((v, (*a).clone()));
                        }
                    }
                }
                best.map(|(_, a)| a)
            } else {
                self.best_target(view, &acts)
            };
            if let Some(a) = pick {
                if once {
                    self.used_once.push((uid, mech));
                }
                return Some(a);
            }
        }
        None
    }

    // ---- positioning ----

    fn heuristic_arrangement(&self, view: &BotView) -> Vec<i64> {
        let me = view.me();
        let units: Vec<&UnitView> = me.board_units().collect();
        let n = units.len();
        let mut front: Vec<(f64, i64)> = Vec::new();
        let mut back: Vec<(f64, i64)> = Vec::new();
        for u in &units {
            let r = self.row(&u.def).row;
            let taunt = u.keywords.iter().any(|k| k == "taunt");
            let tank = u.health as f64 + if taunt { 100.0 } else { 0.0 };
            if r == 1 && !taunt {
                back.push((u.attack as f64, u.uid));
            } else {
                front.push((tank, u.uid));
            }
        }
        front.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap());
        back.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap());
        // Fill front first (max 4), overflow to back.
        while front.len() > 4 {
            let x = front.pop().unwrap();
            back.push(x);
        }
        // If the front is empty but we have back units, move one forward.
        while front.is_empty() && !back.is_empty() {
            front.push(back.remove(0));
        }
        let _ = n;
        let mut out = vec![-1; 7];
        for (i, (_, uid)) in front.iter().enumerate() {
            out[i] = *uid;
        }
        for (i, (_, uid)) in back.iter().enumerate() {
            if 4 + i < 7 {
                out[4 + i] = *uid;
            }
        }
        out
    }

    fn payload_for(&self, view: &BotView, arr: &[i64]) -> Payload {
        let me = view.me();
        let mut p = me.payload().clone();
        let board = p.board();
        let by_uid: BTreeMap<i64, _> = board
            .iter()
            .flatten()
            .map(|s| (s.uid(), s.clone()))
            .collect();
        for (slot, uid) in arr.iter().enumerate() {
            let unit = if *uid >= 0 { by_uid.get(uid).cloned() } else { None };
            p.set_board(slot, unit);
        }
        p
    }

    fn opponents_for_sim(&self, view: &BotView) -> Vec<Payload> {
        let mut out: Vec<Payload> = Vec::new();
        let mut seen: Vec<i64> = Vec::new();
        let next = view.opponent();
        if let Some(f) = view.last_payload_of(next) {
            out.push(f.payload.clone());
            seen.push(next);
        }
        for f in view.past().iter().rev() {
            if out.len() >= 3 {
                break;
            }
            if seen.contains(&f.opponent) {
                continue;
            }
            let alive = view
                .players()
                .iter()
                .find(|p| p.id == f.opponent)
                .is_none_or(|p| p.alive);
            if !alive && f.opponent >= 0 {
                continue;
            }
            seen.push(f.opponent);
            out.push(f.payload.clone());
        }
        out
    }

    fn score_arr(&mut self, view: &BotView, sim: &mut Sim, arr: &[i64], opps: &[Payload], seeds: &[i64]) -> Option<f64> {
        let p = self.payload_for(view, arr);
        let mut s = 0.0;
        for o in opps {
            for seed in seeds {
                let r = sim.fight(&p, o, *seed).ok()?;
                s += match r.winner {
                    0 => 1.0 + 0.01 * r.damage as f64,
                    1 => -1.0 - 0.01 * r.damage as f64,
                    _ => 0.0,
                };
            }
        }
        Some(s)
    }

    fn plan_positions(&mut self, view: &BotView, sim: &mut Sim) -> Vec<i64> {
        let me = view.me();
        let heur = self.heuristic_arrangement(view);
        let n = me.board_count();
        if !self.p.sim_positioning || n <= 1 {
            return heur;
        }
        let opps = self.opponents_for_sim(view);
        if opps.is_empty() {
            return heur;
        }
        // Budget for this round's search.
        let left = sim.clock_left_ns();
        let rounds_left = (16 - view.round()).max(3);
        let budget = ((left as f64 * self.p.sim_share) / rounds_left as f64) as i64;
        if budget < 3_000_000 {
            return heur;
        }
        let start = sim.clock_left_ns();
        let seeds: Vec<i64> = (0..2).map(|_| sim.next_seed()).collect();
        let mut best = heur.clone();
        let Some(mut best_s) = self.score_arr(view, sim, &best, &opps, &seeds) else {
            return heur;
        };
        // Current arrangement too.
        let current: Vec<i64> = me.board.iter().map(|s| s.as_ref().map_or(-1, |u| u.uid)).collect();
        if current != best
            && let Some(s) = self.score_arr(view, sim, &current, &opps, &seeds)
            && s > best_s
        {
            best_s = s;
            best = current;
        }
        let one = (start - sim.clock_left_ns()).max(1);
        // Hill climb with swaps (including into empty slots).
        let mut tries = 0;
        while start - sim.clock_left_ns() + one < budget && tries < 40 {
            tries += 1;
            let a = self.rng.index(7) as usize;
            let b = self.rng.index(7) as usize;
            if a == b || (best[a] < 0 && best[b] < 0) {
                continue;
            }
            let mut cand = best.clone();
            cand.swap(a, b);
            // keep at least one unit in the front if any board units
            if cand[0..4].iter().all(|u| *u < 0) {
                continue;
            }
            if let Some(s) = self.score_arr(view, sim, &cand, &opps, &seeds)
                && s > best_s + 1e-9
            {
                best_s = s;
                best = cand;
            }
        }
        best
    }

    fn next_move(&self, view: &BotView, plan: &[i64]) -> Option<Action> {
        let me = view.me();
        let cur: Vec<i64> = me.board.iter().map(|s| s.as_ref().map_or(-1, |u| u.uid)).collect();
        for slot in 0..7 {
            let want = plan[slot];
            if cur[slot] == want {
                continue;
            }
            if want < 0 {
                continue;
            }
            let from = cur.iter().position(|u| *u == want)?;
            let a = Action::Move {
                from: from as i64,
                to: slot as i64,
            };
            if view.legal().contains(&a) {
                return Some(a);
            }
        }
        None
    }
}

impl Bot for Red {
    fn choose(&mut self, view: &BotView, sim: &mut Sim) -> usize {
        let legal = view.legal();
        if legal.iter().any(|a| matches!(a, Action::Pick { .. })) {
            return self.pick_discover(view);
        }
        if view.round() != self.round {
            self.round = view.round();
            self.refreshes = 0;
            self.plan = None;
            self.abilities_this_turn = 0;
        }
        let end = legal
            .iter()
            .position(|a| *a == Action::EndTurn)
            .unwrap_or(0);
        if self.plan.is_none()
            && let Some(a) = self.heuristic(view)
            && let Some(i) = legal.iter().position(|x| *x == a)
        {
            return i;
        }
        // Positioning, then end the turn.
        if self.plan.is_none() || self.planned_round != view.round() {
            let plan = self.plan_positions(view, sim);
            self.plan = Some(plan);
            self.planned_round = view.round();
        }
        let plan = self.plan.clone().unwrap();
        if let Some(a) = self.next_move(view, &plan)
            && let Some(i) = legal.iter().position(|x| *x == a)
        {
            return i;
        }
        let _ = self.clock_total;
        end
    }

    fn report(&mut self, view: &BotView, _sim: &mut Sim) -> Option<Report> {
        let me = view.me();
        let mut values = Vec::new();
        for c in me.shop_units.iter().chain(me.discover_options.iter()) {
            if !c.is_empty() {
                values.push((c.clone(), (self.shop_value(view, c) * 100.0).round() / 100.0));
            }
        }
        let strategy = match self.main_tribe(view) {
            Some(i) => TRIBES[i].to_lowercase(),
            None => "open".into(),
        };
        Some(Report { strategy, values })
    }
}

impl Params {
    /// Sets one field from text (for the team's tools). Unknown keys are an error.
    pub fn set(&mut self, key: &str, val: &str) -> Result<(), String> {
        let f = || val.parse::<f64>().map_err(|e| format!("{key}: {e}"));
        match key {
            "tier_curve" => {
                self.tier_curve = val
                    .split('/')
                    .map(|x| x.parse::<i64>().map_err(|e| e.to_string()))
                    .collect::<Result<_, _>>()?
            }
            "cheap_upgrade" => self.cheap_upgrade = f()? as i64,
            "growth_turns" => self.growth_turns = f()?,
            "syn_per_unit" => self.syn_per_unit = f()?,
            "syn_base_penalty" => self.syn_base_penalty = f()?,
            "commit_bonus" => self.commit_bonus = f()?,
            "pair_bonus" => self.pair_bonus = f()?,
            "triple_bonus" => self.triple_bonus = f()?,
            "swap_margin" => self.swap_margin = f()?,
            "max_refresh" => self.max_refresh = f()? as i64,
            "min_buy_value" => self.min_buy_value = f()?,
            "spell_value" => self.spell_value = f()?,
            "sim_positioning" => self.sim_positioning = f()? != 0.0,
            "sim_share" => self.sim_share = f()?,
            _ => return Err(format!("unknown param {key}")),
        }
        Ok(())
    }
}
