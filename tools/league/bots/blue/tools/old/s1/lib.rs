//! The blue team's bot.
//! Rules: brief 5a and tools/league/league/README.md (`check-crate`). Tables built offline go
//! in `data/` and come in with `include_bytes!("../data/...")`; `tools/` is out of reach.
#![forbid(unsafe_code)]

pub mod cards;
pub mod eval;
pub mod lift;

use cards::{Pos, know};
use league_api::{Action, Bot, BotSetup, BotView, Me, Report, Rng, Sim, SnapUnit, UnitView};

/// Clock kept back from every search, in ns.
pub const SAFETY_NS: i64 = 150_000_000;

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
    /// Points per place of measured placement lift (lift.rs).
    pub lift_w: f64,
    /// Upgrade off-schedule when gold after the upgrade would still be at least this.
    pub rich_up: i64,
    pub replace_margin: f64,
    pub max_refresh: i64,
    pub sharpen_until: i64,
    pub seek_tier: i64,
    /// Use simulated fights to arrange the board.
    pub sim_arrange: bool,
    pub sim_opps: usize,
    pub sim_seeds: usize,
    pub sim_margin: f64,
    pub sim_buy: bool,
    /// Reviewer fixes of 20:40 (orders first, targets, freeze, refresh limits).
    pub fixes: bool,
    /// Eat Hoppers with Glutton/Gorger; stock the hand for The Colonel.
    pub combos: bool,
    pub colonel_stock: i64,
    /// Most a turn's searches may spend, in ns.
    pub turn_ns: i64,
    pub spare_gold: i64,
    /// Preference for each tribe (TRIBES order), added to a card of that tribe.
    pub tribe_pref: [f64; 5],
    pub spare_refresh: i64,
    pub spare_margin: f64,
    pub sim_buy_w: f64,
    pub sim_buy_k: usize,
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
            up_round: [4, 8, 12, 13, 14],
            cheap_up: 2,
            lift_w: 15.0,
            rich_up: 999,
            replace_margin: 4.0,
            max_refresh: 8,
            sharpen_until: 7,
            seek_tier: 4,
            sim_arrange: true,
            sim_opps: 3,
            sim_seeds: 3,
            sim_margin: 0.02,
            sim_buy: false,
            fixes: true,
            combos: true,
            colonel_stock: 3,
            turn_ns: 80_000_000,
            spare_gold: 6,
            tribe_pref: [-6.0, 0.0, 0.0, 6.0, 0.0],
            spare_refresh: 30,
            spare_margin: 1.0,
            sim_buy_w: 30.0,
            sim_buy_k: 3,
        }
    }
}

impl Params {
    /// Sets one number by name (for offline tuning); false if the name is unknown.
    pub fn set(&mut self, key: &str, v: f64) -> bool {
        match key {
            "tier_w" => self.tier_w = v,
            "stat_w" => self.stat_w = v,
            "scale_w" => self.scale_w = v,
            "syn_w" => self.syn_w = v,
            "syn_cap" => self.syn_cap = v,
            "off_tribe_pen" => self.off_tribe_pen = v,
            "commit_round" => self.commit_round = v as i64,
            "pair_bonus" => self.pair_bonus = v,
            "triple_bonus" => self.triple_bonus = v,
            "golden_bonus" => self.golden_bonus = v,
            "up2" => self.up_round[0] = v as i64,
            "up3" => self.up_round[1] = v as i64,
            "up4" => self.up_round[2] = v as i64,
            "up5" => self.up_round[3] = v as i64,
            "up6" => self.up_round[4] = v as i64,
            "cheap_up" => self.cheap_up = v as i64,
            "lift_w" => self.lift_w = v,
            "rich_up" => self.rich_up = v as i64,
            "replace_margin" => self.replace_margin = v,
            "max_refresh" => self.max_refresh = v as i64,
            "sharpen_until" => self.sharpen_until = v as i64,
            "seek_tier" => self.seek_tier = v as i64,
            "sim_arrange" => self.sim_arrange = v > 0.5,
            "sim_opps" => self.sim_opps = v as usize,
            "sim_seeds" => self.sim_seeds = v as usize,
            "sim_margin" => self.sim_margin = v,
            "sim_buy" => self.sim_buy = v > 0.5,
            "fixes" => self.fixes = v > 0.5,
            "combos" => self.combos = v > 0.5,
            "colonel_stock" => self.colonel_stock = v as i64,
            "turn_ms" => self.turn_ns = (v * 1e6) as i64,
            "spare_gold" => self.spare_gold = v as i64,
            "pref_badger" => self.tribe_pref[0] = v,
            "pref_mouse" => self.tribe_pref[1] = v,
            "pref_pigeon" => self.tribe_pref[2] = v,
            "pref_locust" => self.tribe_pref[3] = v,
            "pref_briar" => self.tribe_pref[4] = v,
            "spare_refresh" => self.spare_refresh = v as i64,
            "spare_margin" => self.spare_margin = v,
            "sim_buy_w" => self.sim_buy_w = v,
            "sim_buy_k" => self.sim_buy_k = v as usize,
            _ => return false,
        }
        true
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
    actions: i64,
    /// Arrangement chosen by simulation this turn: (round, uids on board sorted, target).
    planned: Option<(i64, Vec<i64>, [Option<i64>; 7])>,
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
        actions: 0,
        planned: None,
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
        let mut pref: f64 = f64::MIN;
        let mut in_main = false;
        for (i, t) in TRIBES.iter().enumerate() {
            if c.has_tribe(t) {
                pref = pref.max(self.p.tribe_pref[i]);
                best = best.max(self.tribe_n[i].min(self.p.syn_cap));
                if self.main == Some(i) {
                    in_main = true;
                }
            }
        }
        let pref = if pref == f64::MIN { 0.0 } else { pref };
        let mut s = best * self.p.syn_w + pref;
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
            - self.p.lift_w * lift::lift(id)
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
            - self.p.lift_w * lift::lift(&u.def)
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
            self.actions = 0;
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
        if me.gold - me.upgrade_cost >= self.p.rich_up {
            return true;
        }
        me.upgrade_cost <= self.p.cheap_up && r + 1 >= goal_round
    }

    /// True when gold is piling up with nothing to save it for.
    fn spare(&self, cx: &Ctx) -> bool {
        let me = cx.me;
        let r = cx.round();
        let saving = me.tier < 6
            && self.p.up_round[(me.tier - 1).clamp(0, 4) as usize] <= r + 1;
        !saving && me.gold - self.reserve(cx) >= self.p.spare_gold
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

    fn pick(&mut self, view: &BotView, sim: &mut Sim) -> usize {
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

        // 4a. Feed Hoppers to an eater.
        if self.p.combos
            && let Some(i) = self.feed_eater(&cx, legal)
        {
            return i;
        }

        // 4. Units from hand to board.
        if let Some(i) = self.play_unit(&cx, legal) {
            return i;
        }

        // 5. Orders that pay for themselves come before buys.
        if self.p.fixes
            && let Some(i) = self.ability_filtered(&cx, legal, true)
        {
            return i;
        }

        // 5b. Buy.
        if let Some(i) = self.buy(&cx, sim, legal) {
            return i;
        }

        // 6. Abilities.
        if let Some(i) = self.ability_filtered(&cx, legal, false) {
            return i;
        }

        // 7. Refresh.
        let reserve = self.reserve(&cx);
        let spare = self.spare(&cx);
        let cap = if spare { self.p.spare_refresh } else { self.p.max_refresh };
        let keep = if spare { 1 } else { 2.max(me.tier.min(3)) };
        let hand_ok = !self.p.fixes
            || ((me.hand.len() as i64) < me.hand_limit && self.actions < 95);
        if self.refreshes < cap
            && hand_ok
            && me.gold - me.refresh_cost - reserve >= keep
            && let Some(i) = find(legal, &Action::Refresh)
        {
            self.refreshes += 1;
            return i;
        }

        // 8. Arrange.
        if self.p.sim_arrange {
            self.plan_arrangement(&cx, sim);
        }
        if let Some(i) = self.arrange(&cx, legal) {
            return i;
        }
        // 9. Freeze a shop that holds a copy we are collecting.
        if self.p.fixes
            && !me.frozen
            && me.shop_units.iter().any(|id| {
                !id.is_empty() && !is_token(view, id) && {
                    let held = cx.copies_held(id);
                    held >= 2 || (held >= 1 && view.library().get(id).is_some_and(|c| c.tier >= 3))
                }
            })
            && let Some(i) = find(legal, &Action::Freeze)
        {
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
            let mut pick = None;
            let mut pv = f64::MIN;
            for (i, a) in legal.iter().enumerate() {
                if let Action::Play { hand, slot: s, target } = a
                    && *hand == h
                    && *s == slot
                {
                    let v = match me.find_uid(*target) {
                        Some(t) if self.p.fixes => {
                            t.attack as f64 + if front(t.slot) { 100.0 } else { 0.0 }
                        }
                        _ => 0.0,
                    };
                    if v > pv {
                        pv = v;
                        pick = Some(i);
                    }
                }
            }
            if pick.is_some() {
                return pick;
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

    /// Sells a Hopper on the board to Granary Glutton (any Locust sale) or Gorger (first sale).
    fn feed_eater(&mut self, cx: &Ctx, legal: &[Action]) -> Option<usize> {
        let me = cx.me;
        let glutton = me.board_units().any(|u| u.def == "granary-glutton");
        let gorger = me.board_units().any(|u| u.def == "gorger") && self.sold_this_turn == 0;
        if !glutton && !gorger {
            return None;
        }
        let hopper = me.board_units().find(|u| u.def == "hopper")?;
        let i = find(legal, &Action::Sell { slot: hopper.slot })?;
        self.sold_this_turn += 1;
        Some(i)
    }

    fn buy(&mut self, cx: &Ctx, sim: &mut Sim, legal: &[Action]) -> Option<usize> {
        let me = cx.me;
        let units_in_hand = me.hand.iter().filter(|u| !u.spell).count() as i64;
        let colonel = self.p.combos && me.board_units().any(|u| u.def == "the-colonel");
        let extra = if colonel { self.p.colonel_stock } else { 0 };
        let room = me.board_count() + units_in_hand < 7 + extra;
        let hand_room = (me.hand.len() as i64) < me.hand_limit;
        if !hand_room {
            return None;
        }
        let reserve = self.reserve(cx);
        let spare = self.spare(cx);
        let margin = if spare { self.p.spare_margin } else { self.p.replace_margin };
        let worst = self.worst_board(cx).map(|w| w.1);
        let mut best = None;
        let mut bv = f64::MIN;
        let mut cands: Vec<(usize, String, f64)> = Vec::new();
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
                if v < w + margin {
                    continue;
                }
                v -= w;
            }
            // Slight preference for cheaper buys of similar value.
            v -= price as f64 * 0.1;
            cands.push((i, id.clone(), v));
            if v > bv {
                bv = v;
                best = Some(i);
            }
        }
        if self.p.sim_buy && cands.len() >= 2 && !room_check_only(cx) {
            if let Some(i) = self.sim_pick(cx, sim, &mut cands, room) {
                return Some(i);
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
                    if (cx.round() <= self.p.sharpen_until || spare) && me.board_count() > 0 {
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

    fn ability_filtered(&mut self, cx: &Ctx, legal: &[Action], orders_only: bool) -> Option<usize> {
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
            if orders_only && !mechanic.starts_with("pigeon_") {
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
                let post_set = self.p.fixes
                    && me.slots.iter().any(|sl| sl.keywords.iter().any(|k| k.contains("guard_post") || k == "taunt"));
                if self.guard_posts.contains(uid) || post_set {
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
        let target = match &self.planned {
            Some((r, uids, t)) if *r == cx.round() && *uids == board_uids(cx.me) => *t,
            _ => target_arrangement(cx),
        };
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

fn board_uids(me: &Me) -> Vec<i64> {
    let mut v: Vec<i64> = me.board_units().map(|u| u.uid).collect();
    v.sort();
    v
}

impl Blue {
    /// Hill-climbs slot swaps from the heuristic arrangement, scored by simulated fights.
    fn plan_arrangement(&mut self, cx: &Ctx, sim: &mut Sim) {
        let me = cx.me;
        let uids = board_uids(me);
        if let Some((r, u, _)) = &self.planned
            && *r == cx.round()
            && *u == uids
        {
            return;
        }
        let start = target_arrangement(cx);
        self.planned = Some((cx.round(), uids.clone(), start));
        if uids.len() < 2 {
            return;
        }
        let left = sim.clock_left_ns();
        let turns = (16 - cx.round()).max(3);
        let budget = ((left - SAFETY_NS) / turns).min(self.p.turn_ns);
        if budget < 2_000_000 {
            return;
        }
        let stop_at = left - budget;
        let Some(mut ev) = eval::Evaluator::new(cx.view, sim, self.p.sim_opps, self.p.sim_seeds)
        else {
            return;
        };
        let base = me.payload().clone();
        let snaps: Vec<(i64, SnapUnit)> = base
            .board()
            .into_iter()
            .flatten()
            .map(|u| (u.uid(), u))
            .collect();
        let board_of = |t: &[Option<i64>; 7]| -> Vec<Option<SnapUnit>> {
            t.iter()
                .map(|x| {
                    x.and_then(|uid| snaps.iter().find(|(u, _)| *u == uid).map(|(_, s)| s.clone()))
                })
                .collect()
        };
        let mut best = start;
        let mut best_score = ev.score(sim, &eval::with_board(&base, &board_of(&best)));
        // Front-back swaps first, then within rows.
        let mut pairs: Vec<(usize, usize)> = Vec::new();
        for f in 0..4 {
            for b in 4..7 {
                pairs.push((f, b));
            }
        }
        for i in 0..4 {
            for j in i + 1..4 {
                pairs.push((i, j));
            }
        }
        for i in 4..7 {
            for j in i + 1..7 {
                pairs.push((i, j));
            }
        }
        for (i, j) in pairs {
            if best[i].is_none() && best[j].is_none() {
                continue;
            }
            if sim.clock_left_ns() < stop_at {
                break;
            }
            let mut cand = best;
            cand.swap(i, j);
            let sc = ev.score(sim, &eval::with_board(&base, &board_of(&cand)));
            if sc > best_score + self.p.sim_margin {
                best = cand;
                best_score = sc;
            }
        }
        self.planned = Some((cx.round(), uids, best));
    }
}

/// True when there is nothing to compare against (no board yet).
fn room_check_only(cx: &Ctx) -> bool {
    cx.me.board_count() == 0
}

impl Blue {
    /// Re-scores the best few buy candidates by their simulated effect on this board.
    fn sim_pick(
        &mut self,
        cx: &Ctx,
        sim: &mut Sim,
        cands: &mut [(usize, String, f64)],
        room: bool,
    ) -> Option<usize> {
        let left = sim.clock_left_ns();
        let turns = (16 - cx.round()).max(3);
        // Buys get up to half a turn's share.
        let budget = ((left - SAFETY_NS) / turns / 2).min(self.p.turn_ns / 2);
        if budget < 1_500_000 {
            return None;
        }
        let stop_at = left - budget;
        let mut ev = eval::Evaluator::new(cx.view, sim, self.p.sim_opps, self.p.sim_seeds)?;
        cands.sort_by(|a, b| b.2.total_cmp(&a.2));
        let k = self.p.sim_buy_k.min(cands.len());
        let base = cx.me.payload().clone();
        let board = base.board();
        let base_score = ev.score(sim, &base);
        let empty: Vec<i64> = cx.me.empty_slots();
        let worst = self.worst_board(cx).map(|w| w.0);
        let mut best = None;
        let mut bv = f64::MIN;
        for (n, (i, id, v)) in cands.iter().take(k).enumerate() {
            if n > 0 && sim.clock_left_ns() < stop_at {
                break;
            }
            let slot = if room && !empty.is_empty() {
                let back = matches!(know(id).pos, Pos::Back);
                let order: [i64; 7] = if back {
                    [5, 4, 6, 1, 2, 0, 3]
                } else {
                    [1, 2, 0, 3, 5, 4, 6]
                };
                *order.iter().find(|s| empty.contains(s)).unwrap_or(&empty[0])
            } else if let Some(w) = worst {
                w
            } else {
                continue;
            };
            let mut b = board.clone();
            b[slot as usize] = Some(SnapUnit::fresh(id, 900_000 + n as i64, false));
            let sc = ev.score(sim, &eval::with_board(&base, &b));
            let total = v + self.p.sim_buy_w * (sc - base_score);
            if total > bv {
                bv = total;
                best = Some(*i);
            }
        }
        best
    }
}

/// Units with a "When this dies" effect worth repeating (War-drummer).
const DEATH_EFFECTS: [&str; 7] = [
    "famine-caller",
    "orchard-stripper",
    "brood-mother",
    "green-recruit",
    "wheat-raider",
    "crab-apple",
    "old-stump",
];

/// How much a unit wants the back row (positive) or the front (negative).
fn backness(cx: &Ctx, u: &UnitView) -> f64 {
    let kn = know(&u.def);
    let mut b = match kn.pos {
        Pos::Back => 10.0,
        Pos::Front => -10.0,
        Pos::Any => 0.0,
    };
    let guard = if cx.p.fixes {
        cx.view
            .library()
            .get(&u.def)
            .is_some_and(|c| c.keywords.iter().any(|k| k == "taunt"))
    } else {
        u.keywords.iter().any(|k| k == "taunt")
    };
    if guard {
        b -= 20.0;
    }
    if cx.p.combos && cx.me.board_units().any(|x| x.def == "war-drummer") {
        if u.def == "war-drummer" {
            b -= 40.0;
        } else if DEATH_EFFECTS.contains(&u.def.as_str()) {
            b += 25.0;
        }
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
    let drum = |u: &UnitView| if u.def == "war-drummer" { 1000.0 } else { 0.0 };
    fr.sort_by(|a, b| {
        (b.2 + drum(b.0))
            .total_cmp(&(a.2 + drum(a.0)))
            .then(a.0.uid.cmp(&b.0.uid))
    });
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
        self.actions += 1;
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
