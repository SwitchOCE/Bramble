//! Lookahead on the real engine, on things the bot may know.
use crate::view::{self, BotView, Library, PastFight, Payload, PlayerSummary};
use crate::{action::Action, clock, copy};
use bramble_engine::core::{
    recruit::player_state::PlayerStateRef,
    session::game_session::{GameSession, GameSessionRef},
    util::rng::Rng,
};
use bramble_engine::game::game_content::GameContentRef;
use bramble_engine::{Array, Dictionary, Variant};
use std::collections::{BTreeMap, HashSet};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::{cell::Cell, rc::Rc};

/// The result of one lookahead fight.
#[derive(Clone, Debug)]
pub struct FightOutcome {
    /// 0: side a won, 1: side b won, -1: a tie.
    pub winner: i64,
    /// The losing player id as the fight saw it, or -2 for a tie.
    pub loser: i64,
    /// Damage the loser takes, before armor.
    pub damage: i64,
    /// Why the fight stopped (`board_empty`, `no_attacks`, `attack_limit`, `trigger_limit`).
    pub reason: String,
    /// Recruit-board uids of each side's units that survived.
    pub survivors: [Vec<i64>; 2],
    /// Each side as a payload after the fight and its `after_fight` hooks (permanent buffs,
    /// counters, heaps). The uids are the fight's own (see `Sim::fight`).
    pub after: [Payload; 2],
}

pub(crate) struct CallContext {
    pub round: i64,
    pub me: PlayerStateRef,
    pub players: Vec<PlayerSummary>,
    pub opponent: i64,
    pub past: Rc<Vec<PastFight>>,
}

/// The bot's lookahead handle. One per seat per game; it shares nothing with other seats.
pub struct Sim {
    content: GameContentRef,
    library: Rc<Library>,
    rng: Rng,
    deadline: Rc<Cell<i64>>,
    ctx: Option<CallContext>,
}

impl Sim {
    pub(crate) fn new(
        content: GameContentRef,
        library: Rc<Library>,
        seed: u64,
        deadline: Rc<Cell<i64>>,
    ) -> Self {
        let rng = Rng::new((seed ^ (seed >> 32)) as i64);
        Self {
            content,
            library,
            rng,
            deadline,
            ctx: None,
        }
    }
    pub(crate) fn begin(&mut self, ctx: CallContext) {
        self.ctx = Some(ctx);
    }
    pub(crate) fn end(&mut self) {
        self.ctx = None;
    }

    /// CPU time left on this seat's clock, read now, in ns.
    pub fn clock_left_ns(&self) -> i64 {
        self.deadline.get() - clock::thread_cpu_ns()
    }

    /// A number from the Sim's own random stream (seeded from the bot's seed), for seeds.
    pub fn next_seed(&mut self) -> i64 {
        let high = self.rng.next_u32();
        let low = self.rng.next_u32();
        (high << 31) ^ low
    }

    fn round(&self) -> i64 {
        self.ctx.as_ref().map_or(1, |c| c.round)
    }

    /// One fight of `a` against `b` on the real engine, run as FORMAT.md's runner does: a fresh
    /// session seeded with `seed`, the round set to the current round, both payloads restored,
    /// `GameSession._fight` once. Seat ids outside 0..7 (ghosts) or equal on both sides are
    /// remapped; if the two payloads share a uid, all uids are renumbered a board, a hand,
    /// b board, b hand. An invalid payload gives `Err`, never a panic.
    pub fn fight(&mut self, a: &Payload, b: &Payload, seed: i64) -> Result<FightOutcome, String> {
        run_fight(&self.content, self.round(), a, b, seed)
    }

    /// A recruit-phase sandbox: a copy of the bot's own player now; the others as their last
    /// fight payloads (health, armor, tier and alive as shown); an estimated pool (starting
    /// copies minus the copies this bot can see); shop and Discover draws from a session seeded
    /// from this Sim's own stream. Nothing is written back to the game.
    pub fn sandbox(&mut self) -> Result<Sandbox, String> {
        let Some(ctx) = &self.ctx else {
            return Err("no game in progress".into());
        };
        let me = copy::full_player(&ctx.me.borrow());
        let (round, players, opponent, past) = (
            ctx.round,
            ctx.players.clone(),
            ctx.opponent,
            ctx.past.clone(),
        );
        let seed = self.next_seed();
        let origin = Rc::new(Origin {
            seed,
            round,
            me,
            players,
            opponent,
            past,
        });
        Sandbox::build(
            self.content.clone(),
            self.library.clone(),
            self.deadline.clone(),
            origin,
        )
    }
}

struct Origin {
    seed: i64,
    round: i64,
    me: Dictionary,
    players: Vec<PlayerSummary>,
    opponent: i64,
    past: Rc<Vec<PastFight>>,
}

/// A private recruit phase. `act` plays an action on the copy; nothing reaches the real game.
pub struct Sandbox {
    content: GameContentRef,
    library: Rc<Library>,
    deadline: Rc<Cell<i64>>,
    origin: Rc<Origin>,
    game: GameSessionRef,
    me: i64,
    actions: Vec<Action>,
    broken: Option<String>,
}

fn guard<T>(work: impl FnOnce() -> T) -> Result<T, String> {
    catch_unwind(AssertUnwindSafe(work)).map_err(|panic| crate::harness::panic_text(&panic))
}

impl Sandbox {
    fn build(
        content: GameContentRef,
        library: Rc<Library>,
        deadline: Rc<Cell<i64>>,
        origin: Rc<Origin>,
    ) -> Result<Self, String> {
        let game = guard(|| build_session(&content, &origin))?;
        let me = origin.me.get("id").as_i64();
        Ok(Self {
            content,
            library,
            deadline,
            origin,
            game,
            me,
            actions: Vec::new(),
            broken: None,
        })
    }

    /// The legal actions for the sandbox player now.
    pub fn legal(&self) -> Vec<Action> {
        if self.broken.is_some() {
            return Vec::new();
        }
        guard(|| view::typed_legal_of(&self.game, self.me)).unwrap_or_default()
    }

    /// Plays `action`; returns the engine's refusal text, "" when accepted.
    pub fn act(&mut self, action: &Action) -> String {
        if let Some(problem) = &self.broken {
            return problem.clone();
        }
        let dict = action.to_dict();
        match guard(|| GameSession::act(&self.game, self.me, &dict)) {
            Ok(result) => {
                self.actions.push(action.clone());
                result
            }
            Err(problem) => {
                let text = format!("sandbox broken: {problem}");
                self.broken = Some(text.clone());
                text
            }
        }
    }

    /// Ends the sandbox player's turn (End of Turn effects run).
    pub fn end_turn(&mut self) {
        if self.broken.is_some() {
            return;
        }
        let action = Action::EndTurn;
        self.act(&action);
    }

    /// A BotView of the sandbox player.
    pub fn view(&self) -> Result<BotView, String> {
        if let Some(problem) = &self.broken {
            return Err(problem.clone());
        }
        guard(|| {
            let player = self.game.borrow().player(self.me);
            BotView {
                round: self.origin.round,
                me: view::me_of(&self.game, &player),
                players: self.origin.players.clone(),
                opponent: self.origin.opponent,
                past: self.origin.past.clone(),
                library: self.library.clone(),
                legal: view::typed_legal_of(&self.game, self.me),
                clock_left_ns: self.deadline.get() - clock::thread_cpu_ns(),
            }
        })
    }

    /// The sandbox player as a fight payload now.
    pub fn payload(&self) -> Result<Payload, String> {
        if let Some(problem) = &self.broken {
            return Err(problem.clone());
        }
        let player = self.game.borrow().player(self.me);
        let raw = copy::fight_payload(&player.borrow());
        Ok(Payload::from_raw(raw))
    }

    /// The sandbox player's board now against `opponent`, as `Sim::fight`.
    pub fn fight_vs(&self, opponent: &Payload, seed: i64) -> Result<FightOutcome, String> {
        let mine = self.payload()?;
        run_fight(&self.content, self.origin.round, &mine, opponent, seed)
    }

    /// An independent copy of this sandbox in its current state (same draws to come).
    pub fn fork(&self) -> Result<Sandbox, String> {
        if let Some(problem) = &self.broken {
            return Err(problem.clone());
        }
        let mut copy = Sandbox::build(
            self.content.clone(),
            self.library.clone(),
            self.deadline.clone(),
            self.origin.clone(),
        )?;
        for action in &self.actions {
            copy.act(action);
        }
        Ok(copy)
    }
}

fn build_session(content: &GameContentRef, origin: &Origin) -> GameSessionRef {
    let game = content.borrow().new_session(origin.seed, &Array::new());
    let me_id = origin.me.get("id").as_i64();
    {
        let mut g = game.borrow_mut();
        g.keep_fight_events = false;
        g.round_number = origin.round;
        copy::restore_full(&mut g, &copy::deep_dict(&origin.me));
    }
    // Copies this player can see, by card id.
    let mut seen: BTreeMap<String, i64> = BTreeMap::new();
    let mut add = |id: String, n: i64| *seen.entry(id).or_insert(0) += n;
    for key in ["board", "hand"] {
        for unit in origin.me.get(key).as_array().to_vec() {
            if let Variant::Dictionary(unit) = unit {
                add(unit.get("def").as_text(), unit.get("pool_copies").as_i64());
            }
        }
    }
    for key in ["shop_units", "shop_spells", "discover_options"] {
        for id in origin.me.get(key).as_array().to_vec() {
            let id = id.as_text();
            if !id.is_empty() {
                add(id, 1);
            }
        }
    }
    for summary in &origin.players {
        if summary.id == me_id {
            continue;
        }
        let player = game.borrow().player(summary.id);
        {
            let mut p = player.borrow_mut();
            p.health = summary.health;
            p.armor = summary.armor;
            p.tier = summary.tier;
            p.alive = summary.alive;
            p.placement = summary.placement;
            p.turn_ended = true;
        }
        if let Some(last) = origin.past.iter().rev().find(|f| f.opponent == summary.id) {
            let raw = copy::deep_dict(last.payload.raw());
            for key in ["board", "hand"] {
                for unit in raw.get(key).as_array().to_vec() {
                    if let Variant::Dictionary(unit) = unit {
                        add(unit.get("def").as_text(), unit.get("pool_copies").as_i64());
                    }
                }
            }
            raw.insert("tier", summary.tier.into());
            copy::restore_payload(&mut game.borrow_mut(), &raw);
        }
    }
    {
        let g = game.borrow();
        for pool in [g.units.as_ref(), g.spells.as_ref()].into_iter().flatten() {
            let pool = pool.borrow();
            let start = pool._start.borrow().clone();
            let mut copies = pool._copies.borrow_mut();
            for (id, count) in start {
                let left = (count - seen.get(&id).copied().unwrap_or(0)).max(0);
                copies.insert(id, left);
            }
        }
    }
    if origin.opponent >= 0 {
        let pair = Variant::array(vec![me_id.into(), origin.opponent.into()]);
        game.borrow_mut().pairings = Array::from(vec![pair]);
    }
    // The recruit's random streams are created on first use from this session's seed.
    game
}

pub(crate) fn run_fight(
    content: &GameContentRef,
    round: i64,
    a: &Payload,
    b: &Payload,
    seed: i64,
) -> Result<FightOutcome, String> {
    guard(|| fight_inner(content, round, a, b, seed))?
}

fn fight_inner(
    content: &GameContentRef,
    round: i64,
    a: &Payload,
    b: &Payload,
    seed: i64,
) -> Result<FightOutcome, String> {
    let a_raw = copy::deep_dict(a.raw());
    let b_raw = copy::deep_dict(b.raw());
    for (side, raw) in [("a", &a_raw), ("b", &b_raw)] {
        if raw.get("board").as_array().len() != 7 || raw.get("slots").as_array().len() != 7 {
            return Err(format!("{side}: expected 7 board positions and 7 slots"));
        }
        if raw.get("hand").as_array().len() > 7 {
            return Err(format!("{side}: more than 7 hand cards"));
        }
    }
    let mut a_id = a_raw.get("id").as_i64();
    if !(0..8).contains(&a_id) {
        a_id = 0;
    }
    let mut b_id = b_raw.get("id").as_i64();
    if !(0..8).contains(&b_id) || b_id == a_id {
        b_id = (a_id + 1) % 8;
    }
    a_raw.insert("id", a_id.into());
    b_raw.insert("id", b_id.into());
    let uids = |raw: &Dictionary| -> Vec<i64> {
        let mut out = Vec::new();
        for key in ["board", "hand"] {
            for unit in raw.get(key).as_array().to_vec() {
                if let Variant::Dictionary(unit) = unit {
                    out.push(unit.get("uid").as_i64());
                }
            }
        }
        out
    };
    let mut seen = HashSet::new();
    let clash = uids(&a_raw)
        .into_iter()
        .chain(uids(&b_raw))
        .any(|uid| uid <= 0 || !seen.insert(uid));
    if clash {
        let mut next = 1;
        for raw in [&a_raw, &b_raw] {
            for key in ["board", "hand"] {
                for unit in raw.get(key).as_array().to_vec() {
                    if let Variant::Dictionary(unit) = unit {
                        unit.insert("uid", next.into());
                        next += 1;
                    }
                }
            }
        }
    }
    let game = content.borrow().new_session(seed, &Array::new());
    {
        let mut g = game.borrow_mut();
        g.keep_fight_events = false;
        g.round_number = round.max(1);
        copy::restore_payload(&mut g, &a_raw);
        copy::restore_payload(&mut g, &b_raw);
        let pair = Variant::array(vec![a_id.into(), b_id.into()]);
        g.pairings = Array::from(vec![pair]);
    }
    let fight = GameSession::_fight(&game, a_id, b_id);
    let result = fight.get("result").as_dict();
    let survivors = result.get("survivor_recruit_uids").as_array();
    let side = |i: usize| -> Vec<i64> {
        survivors
            .get(i)
            .unwrap_or_default()
            .as_array()
            .borrow()
            .iter()
            .map(Variant::as_i64)
            .collect()
    };
    let after = |id: i64| {
        let player = game.borrow().player(id);
        Payload::from_raw(copy::fight_payload(&player.borrow()))
    };
    Ok(FightOutcome {
        winner: result.get("winner").as_i64(),
        loser: fight.get("loser").as_i64(),
        damage: fight.get("damage").as_i64(),
        reason: result.get("reason").as_text(),
        survivors: [side(0), side(1)],
        after: [after(a_id), after(b_id)],
    })
}
