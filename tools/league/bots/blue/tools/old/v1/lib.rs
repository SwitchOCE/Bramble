//! The blue team's bot.
//! Rules: brief 5a and tools/league/league/README.md (`check-crate`). Tables built offline go
//! in `data/` and come in with `include_bytes!("../data/...")`; `tools/` is out of reach.
#![forbid(unsafe_code)]

pub mod cards;

use cards::{Pos, know};
use league_api::{Action, Bot, BotSetup, BotView, Me, Report, Rng, Sim, UnitView};

pub const TRIBES: [&str; 5] = ["Badger", "Mouse", "Pigeon", "Locust", "Briar"];

/// Tunable numbers. `Params::default()` is what plays in a match.
#[derive(Clone, Debug)]
pub struct Params {
    pub tier_w: f64,
    pub stat_w: f64,
    pub scale_w: f64,
    pub syn_w: f64,
    pub syn_cap: f64,
    pub off_tribe_pen: f64,
    pub commit_round: i64,
    pub pair_bonus: f64,
    pub triple_bonus: f64,
    pub golden_bonus: f64,
    /// Round at which to reach tier t+2 (index 0: tier 2).
    pub up_round: [i64; 5],
    /// Upgrade early when the cost is at most this.
    pub cheap_up: i64,
    pub replace_margin: f64,
    pub max_refresh: i64,
    pub sharpen_until: i64,
    pub seek_tier: i64,
}

impl Default for Params {
    fn default() -> Self {
        Self {
            tier_w: 10.0,
            stat_w: 0.5,
            scale_w: 1.0,
            syn_w: 2.0,
            syn_cap: 6.0,
            off_tribe_pen: 6.0,
            commit_round: 6,
            pair_bonus: 6.0,
            triple_bonus: 25.0,
            golden_bonus: 15.0,
            up_round: [2, 4, 6, 8, 10],
            cheap_up: 2,
            replace_margin: 4.0,
            max_refresh: 8,
            sharpen_until: 7,
            seek_tier: 4,
        }
    }
}

pub struct Blue {
    #[allow(dead_code)]
    rng: Rng,
    p: Params,
    round: i64,
    refreshes: i64,
    moves: i64,
    abilities: Vec<(i64, String)>,
    guard_posts: Vec<i64>,
    sold_this_turn: i64,
}

/// The league's constructor.
pub fn new_bot(seed: u64, setup: &BotSetup) -> Box<dyn Bot> {
    new_bot_with(seed, setup, Params::default())
}

pub fn new_bot_with(seed: u64, _setup: &BotSetup, p: Params) -> Box<dyn Bot> {
    Box::new(Blue {
        rng: Rng::new(seed as i64),
        p,
        round: -1,
        refreshes: 0,
        moves: 0,
        abilities: Vec::new(),
        guard_posts: Vec::new(),
        sold_this_turn: 0,
    })
}

fn find(legal: &[Action], want: &Action) -> Option<usize> {
    legal.iter().position(|a| a == want)
}

fn is_token(view: &BotView, id: &str) -> bool {
    view.library().get(id).is_some_and(|c| c.token)
}

/// What the bot knows about its own cards this decision.
struct Ctx<'a> {
    view: &'a BotView,
    me: &'a Me,
    p: &'a Params,
    /// Units of each tribe owned (board + hand), `TRIBES` order.
    tribe_n: [f64; 5],
    main: Option<usize>,
}

impl<'a> Ctx<'a> {
    fn new(view: &'a BotView, p: &'a Params) -> Self {
        let me = view.me();
        let mut tribe_n = [0.0; 5];
        for u in me.all_cards() {
            if u.spell {
                continue;
            }
            if let Some(c) = view.library().get(&u.def) {
                for (i, t) in TRIBES.iter().enumerate() {
                    if c.has_tribe(t) {
                        tribe_n[i] += if c.token { 0.5 } else { 1.0 };
                    }
                }
            }
        }
        let mut main = None;
        let mut best = 0.0;
        for (i, &n) in tribe_n.iter().enumerate() {
            if n > best {
                best = n;
                main = Some(i);
            }
        }
        if best < 3.0 {
            main = None;
        }
        Ctx {
            view,
            me,
            p,
            tribe_n,
            main,
        }
    }

    fn round(&self) -> i64 {
        self.view.round()
    }

    fn copies_held(&self, id: &str) -> i64 {
        self.me
            .all_cards()
            .filter(|u| u.def == id && !u.golden)
            .count() as i64
    }

    fn synergy(&self, id: &str) -> f64 {
        let Some(c) = self.view.library().get(id) else {
            return 0.0;
        };
        let mut best: f64 = 0.0;
        let mut in_main = false;
        for (i, t) in TRIBES.iter().enumerate() {
            if c.has_tribe(t) {
                best = best.max(self.tribe_n[i].min(self.p.syn_cap));
                if self.main == Some(i) {
                    in_main = true;
                }
            }
        }
        let mut s = best * self.p.syn_w;
        if self.main.is_some() && !in_main && self.round() >= self.p.commit_round {
            s -= self.p.off_tribe_pen;
        }
        s
    }

    /// Value of a fresh copy of `id` if we got it now (not counting copies held).
    fn card_value(&self, id: &str, golden: bool) -> f64 {
        let Some(c) = self.view.library().get(id) else {
            return 0.0;
        };
        let kn = know(id);
        let g = if golden { 2.0 } else { 1.0 };
        let left = (14 - self.round()).max(0) as f64 / 4.0;
        c.tier as f64 * self.p.tier_w
            + (c.attack + c.health) as f64 * self.p.stat_w * g
            + kn.bonus * g
            + kn.scale * left * self.p.scale_w * g
            + if golden { self.p.golden_bonus } else { 0.0 }
            + self.synergy(id)
    }

    /// Value of buying `id` from the shop now (triples included).
    fn buy_value(&self, id: &str) -> f64 {
        let held = self.copies_held(id);
        let mut v = self.card_value(id, false);
        if is_token(self.view, id) {
            return v;
        }
        if held == 1 {
            v += self.p.pair_bonus;
        } else if held >= 2 {
            v += self.p.triple_bonus;
        }
        v
    }

    /// Value of a unit we hold, as it stands.
    fn unit_value(&self, u: &UnitView) -> f64 {
        let Some(c) = self.view.library().get(&u.def) else {
            return 0.0;
        };
        let kn = know(&u.def);
        let g = if u.golden { 2.0 } else { 1.0 };
        let left = (14 - self.round()).max(0) as f64 / 4.0;
        let (a, h) = own_stats(self.me, u);
        let mut v = c.tier as f64 * self.p.tier_w
            + (a + h) as f64 * self.p.stat_w
            + kn.bonus * g
            + kn.scale * left * self.p.scale_w * g
            + if u.golden { self.p.golden_bonus } else { 0.0 }
            + self.synergy(&u.def);
        if !u.golden && !c.token {
            let held = self.copies_held(&u.def);
            if held >= 2 {
                v += self.p.pair_bonus;
            }
        }
        v
    }
}

/// A unit's stats without its slot's buff.
fn own_stats(me: &Me, u: &UnitView) -> (i64, i64) {
    if u.slot >= 0
        && let Some(s) = me.slots.get(u.slot as usize)
    {
        return (u.attack - s.attack, u.health - s.health);
    }
    (u.attack, u.health)
}

fn front(slot: i64) -> bool {
    (0..4).contains(&slot)
}

impl Blue {
    fn new_turn(&mut self, view: &BotView) {
        if view.round() != self.round {
            self.round = view.round();
            self.refreshes = 0;
            self.moves = 0;
            self.abilities.clear();
            self.sold_this_turn = 0;
        }
    }

    fn wants_upgrade(&self, cx: &Ctx) -> bool {
        let me = cx.me;
        if me.upgrade_cost < 0 || me.tier >= 6 {
            return false;
        }
        if me.gold < me.upgrade_cost {
            return false;
        }
        let r = cx.round();
        let goal_round = self.p.up_round[(me.tier - 1) as usize];
        if r >= goal_round {
            return true;
        }
        me.upgrade_cost <= self.p.cheap_up && r + 1 >= goal_round
    }

    /// Gold to keep this turn for next turn's planned upgrade.
    fn reserve(&self, cx: &Ctx) -> i64 {
        let me = cx.me;
        if me.tier >= 6 || me.upgrade_cost < 0 {
            return 0;
        }
        let r = cx.round();
        let goal_round = self.p.up_round[(me.tier - 1) as usize];
        if r + 1 != goal_round {
            return 0;
        }
        let income = income(r + 1);
        // Next turn the cost drops by the next discount step.
        let next_cost = (me.upgrade_cost - (me.turns_waited + 1).min(5)).max(0);
        (next_cost - income).max(0)
    }

    fn pick(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
        self.new_turn(view);
        let legal = view.legal();
        let end = find(legal, &Action::EndTurn).unwrap_or(0);
        let params = self.p.clone();
        let cx = Ctx::new(view, &params);
        let me = cx.me;

        // 1. Discover.
        let picks: Vec<(usize, i64)> = legal
            .iter()
            .enumerate()
            .filter_map(|(i, a)| match a {
                Action::Pick { index } => Some((i, *index)),
                _ => None,
            })
            .collect();
        if !picks.is_empty() {
            let mut best = picks[0].0;
            let mut bv = f64::MIN;
            for (i, index) in picks {
                let id = &me.discover_options[index as usize];
                let v = cx.buy_value(id);
                if v > bv {
                    bv = v;
                    best = i;
                }
            }
            return best;
        }

        // 2. Upgrade.
        if self.wants_upgrade(&cx)
            && let Some(i) = find(legal, &Action::Upgrade)
        {
            return i;
        }

        // 3. Spells in hand.
        if let Some(i) = self.play_spell(&cx, legal) {
            return i;
        }

        // 4. Units from hand to board.
        if let Some(i) = self.play_unit(&cx, legal) {
            return i;
        }

        // 5. Buy.
        if let Some(i) = self.buy(&cx, legal) {
            return i;
        }

        // 6. Abilities.
        if let Some(i) = self.ability(&cx, legal) {
            return i;
        }

        // 7. Refresh.
        let reserve = self.reserve(&cx);
        if self.refreshes < self.p.max_refresh
            && me.gold - me.refresh_cost - reserve >= 2.max(me.tier.min(3))
            && let Some(i) = find(legal, &Action::Refresh)
        {
            self.refreshes += 1;
            return i;
        }

        // 8. Arrange.
        if let Some(i) = self.arrange(&cx, legal) {
            return i;
        }
        end
    }

    fn play_spell(&mut self, cx: &Ctx, legal: &[Action]) -> Option<usize> {
        let me = cx.me;
        for (i, a) in legal.iter().enumerate() {
            let Action::Play { hand, slot, target } = a else {
                continue;
            };
            let card = &me.hand[*hand as usize];
            if !card.spell || *slot >= 0 {
                continue;
            }
            match card.def.as_str() {
                "triple_reward" | "sp_seek" | "sp_forage" => {
                    if *target < 0 {
                        return Some(i);
                    }
                }
                _ => {}
            }
        }
        // Targeted spells (Sharpen): best target.
        let mut best = None;
        let mut bv = f64::MIN;
        for (i, a) in legal.iter().enumerate() {
            let Action::Play { hand, slot, target } = a else {
                continue;
            };
            let card = &me.hand[*hand as usize];
            if !card.spell || *slot >= 0 {
                continue;
            }
            let v = match me.find_uid(*target) {
                Some(u) if u.slot >= 0 => {
                    let kn = know(&u.def);
                    let mut v = cx.unit_value(u);
                    if kn.pos == Pos::Front || front(u.slot) {
                        v += 5.0;
                    }
                    if u.keywords.iter().any(|k| k == "taunt") {
                        v += 5.0;
                    }
                    v
                }
                Some(_) => -100.0,
                None => 0.0,
            };
            if v > bv {
                bv = v;
                best = Some(i);
            }
        }
        best
    }

    fn worst_board(&self, cx: &Ctx) -> Option<(i64, f64)> {
        let mut worst = None;
        let mut wv = f64::MAX;
        for u in cx.me.board_units() {
            let v = cx.unit_value(u);
            if v < wv {
                wv = v;
                worst = Some(u.slot);
            }
        }
        worst.map(|s| (s, wv))
    }

    fn play_unit(&mut self, cx: &Ctx, legal: &[Action]) -> Option<usize> {
        let me = cx.me;
        // Best unit in hand.
        let mut best_hand = None;
        let mut bv = f64::MIN;
        for (h, u) in me.hand.iter().enumerate() {
            if u.spell {
                continue;
            }
            let v = cx.unit_value(u);
            if v > bv {
                bv = v;
                best_hand = Some(h as i64);
            }
        }
        let h = best_hand?;
        let empty = me.empty_slots();
        if !empty.is_empty() {
            let u = &me.hand[h as usize];
            let slot = choose_slot(cx, u, &empty);
            for (i, a) in legal.iter().enumerate() {
                if let Action::Play { hand, slot: s, .. } = a
                    && *hand == h
                    && *s == slot
                {
                    return Some(i);
                }
            }
            // Any slot.
            for (i, a) in legal.iter().enumerate() {
                if let Action::Play { hand, slot: s, .. } = a
                    && *hand == h
                    && *s >= 0
                {
                    return Some(i);
                }
            }
            return None;
        }
        // Board full: sell the worst if the hand's best is better.
        if let Some((slot, wv)) = self.worst_board(cx)
            && bv > wv + 0.5
            && let Some(i) = find(legal, &Action::Sell { slot })
        {
            self.sold_this_turn += 1;
            return Some(i);
        }
        None
    }

    fn buy(&mut self, cx: &Ctx, legal: &[Action]) -> Option<usize> {
        let me = cx.me;
        let units_in_hand = me.hand.iter().filter(|u| !u.spell).count() as i64;
        let room = me.board_count() + units_in_hand < 7;
        let hand_room = (me.hand.len() as i64) < me.hand_limit;
        if !hand_room {
            return None;
        }
        let reserve = self.reserve(cx);
        let worst = self.worst_board(cx).map(|w| w.1);
        let mut best = None;
        let mut bv = f64::MIN;
        for (i, a) in legal.iter().enumerate() {
            let Action::Buy { spell, index } = a else {
                continue;
            };
            if *spell {
                continue;
            }
            let id = &me.shop_units[*index as usize];
            let price = me.unit_prices[*index as usize];
            let mut v = cx.buy_value(id);
            let held = cx.copies_held(id);
            let triples = held >= 2;
            if me.gold - price < reserve && !triples {
                continue;
            }
            if !room && !triples {
                let Some(w) = worst else { continue };
                if v < w + self.p.replace_margin {
                    continue;
                }
                v -= w;
            }
            // Slight preference for cheaper buys of similar value.
            v -= price as f64 * 0.1;
            if v > bv {
                bv = v;
                best = Some(i);
            }
        }
        if best.is_some() {
            return best;
        }
        // Spells.
        let mut sbest = None;
        let mut sv = f64::MIN;
        for (i, a) in legal.iter().enumerate() {
            let Action::Buy { spell: true, index } = a else {
                continue;
            };
            let id = &me.shop_spells[*index as usize];
            let price = me.spell_prices[*index as usize];
            if me.gold - price < reserve {
                continue;
            }
            let v = match id.as_str() {
                "sp_sharpen" => {
                    if cx.round() <= self.p.sharpen_until && me.board_count() > 0 {
                        1.0
                    } else {
                        -1.0
                    }
                }
                "sp_seek" | "sp_forage" => {
                    if me.tier >= self.p.seek_tier && (room || worst.is_some()) {
                        3.0
                    } else {
                        -1.0
                    }
                }
                _ => -1.0,
            };
            if v > sv {
                sv = v;
                sbest = Some(i);
            }
        }
        if sv > 0.0 { sbest } else { None }
    }

    fn ability(&mut self, cx: &Ctx, legal: &[Action]) -> Option<usize> {
        let me = cx.me;
        let mut chosen: Option<usize> = None;
        let mut best_v = f64::MIN;
        for (i, a) in legal.iter().enumerate() {
            let Action::Ability {
                uid,
                mechanic,
                target,
            } = a
            else {
                continue;
            };
            if self.abilities.iter().any(|(u, m)| u == uid && m == mechanic) {
                continue;
            }
            let v = if mechanic.contains("bury") {
                // Bury the highest-tier shop unit we don't plan to buy.
                match me.shop_units.get(*target as usize) {
                    Some(id) if !id.is_empty() => {
                        let tier = cx.view.library().get(id).map_or(0, |c| c.tier) as f64;
                        let held = cx.copies_held(id) as f64;
                        10.0 + tier - held * 5.0
                    }
                    _ => 1.0,
                }
            } else if mechanic == "pigeon_grenadier" {
                if self.guard_posts.contains(uid) {
                    -1.0
                } else {
                    match me.board.get(*target as usize) {
                        Some(Some(u)) if front(u.slot) => 5.0 + u.health as f64 * 0.1,
                        Some(None) if front(*target) => 2.0,
                        _ => 0.5,
                    }
                }
            } else {
                5.0
            };
            if v > best_v {
                best_v = v;
                chosen = Some(i);
            }
        }
        if best_v <= 0.0 {
            return None;
        }
        let i = chosen?;
        if let Action::Ability { uid, mechanic, .. } = &legal[i] {
            self.abilities.push((*uid, mechanic.clone()));
            if mechanic == "pigeon_grenadier" {
                self.guard_posts.push(*uid);
            }
        }
        Some(i)
    }

    /// Moves toward the target arrangement, one move a call.
    fn arrange(&mut self, cx: &Ctx, legal: &[Action]) -> Option<usize> {
        if self.moves >= 12 {
            return None;
        }
        let target = target_arrangement(cx);
        for (slot, want) in target.iter().enumerate() {
            let have = cx.me.board[slot].as_ref().map(|u| u.uid);
            if have == *want {
                continue;
            }
            let Some(want) = want else { continue };
            let from = cx.me.board_units().find(|u| u.uid == *want)?.slot;
            if let Some(i) = find(
                legal,
                &Action::Move {
                    from,
                    to: slot as i64,
                },
            ) {
                self.moves += 1;
                return Some(i);
            }
        }
        None
    }
}

/// How much a unit wants the back row (positive) or the front (negative).
fn backness(cx: &Ctx, u: &UnitView) -> f64 {
    let kn = know(&u.def);
    let mut b = match kn.pos {
        Pos::Back => 10.0,
        Pos::Front => -10.0,
        Pos::Any => 0.0,
    };
    if u.keywords.iter().any(|k| k == "taunt") {
        b -= 20.0;
    }
    let (a, h) = own_stats(cx.me, u);
    b += (a - h) as f64 / (a + h).max(1) as f64 * 4.0;
    b
}

fn choose_slot(cx: &Ctx, u: &UnitView, empty: &[i64]) -> i64 {
    let back = backness(cx, u) > 0.0;
    let order: [i64; 7] = if back {
        [5, 4, 6, 1, 2, 0, 3]
    } else {
        [1, 2, 0, 3, 5, 4, 6]
    };
    for s in order {
        if empty.contains(&s) {
            return s;
        }
    }
    empty[0]
}

/// The slot each board unit should stand in (uid or empty), by row preference and strength.
fn target_arrangement(cx: &Ctx) -> [Option<i64>; 7] {
    let me = cx.me;
    let mut units: Vec<(&UnitView, f64, f64)> = me
        .board_units()
        .map(|u| (u, backness(cx, u), cx.unit_value(u)))
        .collect();
    let n = units.len();
    let mut out = [None; 7];
    if n == 0 {
        return out;
    }
    // Back row: the most back-minded units, at least n-4, at most 3, and leave 2 in front.
    units.sort_by(|a, b| b.1.total_cmp(&a.1).then(a.0.uid.cmp(&b.0.uid)));
    let min_back = n.saturating_sub(4);
    let max_back = 3.min(n.saturating_sub(2.min(n)));
    let mut nb = units.iter().filter(|x| x.1 > 0.0).count();
    nb = nb.max(min_back).min(max_back.max(min_back));
    let mut back: Vec<_> = units[..nb].to_vec();
    let mut fr: Vec<_> = units[nb..].to_vec();
    // Strongest in the middle.
    fr.sort_by(|a, b| b.2.total_cmp(&a.2).then(a.0.uid.cmp(&b.0.uid)));
    back.sort_by(|a, b| b.2.total_cmp(&a.2).then(a.0.uid.cmp(&b.0.uid)));
    let fslots = [1usize, 2, 0, 3];
    let bslots = [5usize, 4, 6];
    // Prefer slots with the biggest buffs for the strongest units.
    let fslots = by_buff(me, &fslots);
    let bslots = by_buff(me, &bslots);
    for (i, x) in fr.iter().enumerate() {
        out[fslots[i]] = Some(x.0.uid);
    }
    for (i, x) in back.iter().enumerate() {
        out[bslots[i]] = Some(x.0.uid);
    }
    out
}

/// Slots in their default order, re-sorted so heavily buffed slots come first.
fn by_buff(me: &Me, order: &[usize]) -> Vec<usize> {
    let mut v: Vec<(usize, i64, usize)> = order
        .iter()
        .enumerate()
        .map(|(rank, &s)| {
            let b = me.slots.get(s).map_or(0, |x| x.attack + x.health);
            (s, b, rank)
        })
        .collect();
    v.sort_by(|a, b| b.1.cmp(&a.1).then(a.2.cmp(&b.2)));
    v.into_iter().map(|x| x.0).collect()
}

/// Income on round `r` (4.1.1).
pub fn income(r: i64) -> i64 {
    let mut amount = 5;
    for _ in 1..r {
        if amount < 15 {
            amount = (amount + 2).min(15);
        } else {
            amount += 1;
        }
    }
    amount
}

impl Bot for Blue {
    fn choose(&mut self, view: &BotView, sim: &mut Sim) -> usize {
        let i = self.pick(view, sim);
        if i < view.legal().len() {
            i
        } else {
            view.legal().len() - 1
        }
    }

    fn report(&mut self, view: &BotView, _sim: &mut Sim) -> Option<Report> {
        let cx = Ctx::new(view, &self.p);
        let me = view.me();
        let offered = me
            .shop_units
            .iter()
            .chain(me.discover_options.iter())
            .filter(|c| !c.is_empty());
        let strategy = match cx.main {
            Some(t) => format!("main:{}", TRIBES[t]),
            None => "open".to_string(),
        };
        Some(Report {
            strategy,
            values: offered.map(|c| (c.clone(), cx.buy_value(c))).collect(),
        })
    }
}
