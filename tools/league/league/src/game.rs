//! One game: the turn loop of `tools/checks/records.gd` and `Bot.take_turn`, with every bot call
//! timed on its seat's CPU clock, the record written in GDScript's format, and the logs.
use crate::baselines::SimpleBot;
use crate::watchdog::Watch;
use bramble_engine::core::{
    records::record_state::RecordState,
    session::{
        game_session::{GameSession, GameSessionRef},
        matchmaking::Matchmaking,
    },
    util::rng::Rng,
};
use bramble_engine::game::game_content::GameContentRef;
use bramble_engine::util::godot_json;
use bramble_engine::{Array, Dictionary, ToState, Variant};
use league_api::harness;
use league_api::{Action, Bot, BotSetup, BotView, Library, PastFight, Sim};
use serde_json::{Value, json};
use std::cell::Cell;
use std::collections::BTreeMap;
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::rc::Rc;

/// `Bot.MAX_ACTIONS`.
pub const MAX_ACTIONS: usize = 120;

pub type Maker = Box<dyn FnOnce(&BotSetup) -> Box<dyn Bot>>;

pub struct SeatPlan {
    pub colour: &'static str,
    pub name: String,
    pub make: Maker,
    /// Seeds the Sim's own stream and the fallback bot.
    pub sim_seed: u64,
}

pub struct GamePlan {
    pub index: usize,
    pub seed: i64,
    pub swapped: bool,
    /// Red seats in the unswapped game of this seed pair.
    pub red_seats: [bool; 8],
    pub seats: Vec<SeatPlan>,
    pub clock_ns: i64,
    /// Write the decision log (every legal action at every decision).
    pub log_decisions: bool,
}

/// What one game produced. Every field but `cpu` is deterministic.
pub struct GameOut {
    pub index: usize,
    pub record: String,
    pub game: Value,
    pub cpu: Value,
    pub shops: Vec<Value>,
    pub discovers: Vec<Value>,
    pub reports: Vec<Value>,
    /// One line per decision: every legal action, with its card, and the one chosen.
    pub decisions: Vec<Value>,
    /// Placement by seat.
    pub places: Vec<i64>,
}

/// Per-thread engine objects: the real game's content and a separate copy for every Sim.
pub struct Engine {
    pub content: GameContentRef,
    pub sim_content: GameContentRef,
    pub library: Rc<Library>,
    pub build: Variant,
}

struct Seat {
    id: i64,
    colour: &'static str,
    name: String,
    bot: Option<Box<dyn Bot>>,
    fallback: Option<SimpleBot>,
    sim: Sim,
    deadline: Rc<Cell<i64>>,
    used_ns: i64,
    clock_out: Option<Value>,
    panic: Option<Value>,
    fault: Option<Value>,
    refused: i64,
    last_refusal: String,
    past: Rc<Vec<PastFight>>,
    rounds: Vec<Value>,
    last_board: Vec<Value>,
    /// Per round: (tribe counts, total stats by tribe).
    tribe_rounds: Vec<(i64, TribeCounts)>,
    golden_seen: i64,
    gold_start: Option<i64>,
    deferred_gold: i64,
    slots_seen: String,
    shop: Option<ShopLine>,
}

/// Units and total stats by tribe on one board.
type TribeCounts = BTreeMap<String, (i64, i64)>;

struct ShopLine {
    value: Value,
    expect_units: Vec<String>,
    expect_spells: Vec<String>,
}

struct Writer {
    lines: String,
}

impl Writer {
    fn put(&mut self, entry: &[(&str, Variant)]) {
        let dict = Dictionary::new();
        for (key, value) in entry {
            dict.insert(*key, value.to_state());
        }
        self.lines
            .push_str(&godot_json::stringify(&Variant::Dictionary(dict)));
        self.lines.push('\n');
    }
}

thread_local! {
    /// CPU ns spent per part of the game loop on this thread: hash, view, act, bot, stats.
    pub static PROFILE: std::cell::RefCell<[i64; 5]> = const { std::cell::RefCell::new([0; 5]) };
}

fn timed<T>(part: usize, work: impl FnOnce() -> T) -> T {
    let start = harness::thread_cpu_ns();
    let out = work();
    let spent = harness::thread_cpu_ns() - start;
    PROFILE.with(|p| p.borrow_mut()[part] += spent);
    out
}

fn hash(game: &GameSessionRef) -> Variant {
    timed(0, || RecordState::state_hash(&game.borrow()).into())
}

pub fn play(engine: &Engine, plan: GamePlan, watch: &Watch) -> GameOut {
    let game = engine
        .content
        .borrow()
        .new_session(plan.seed, &bramble_engine::Array::new());
    game.borrow_mut().keep_fight_events = false;
    // The harness writes the record itself (same lines as GameRecord), so the session must not.
    let recipe = std::mem::take(&mut game.borrow_mut().record_recipe);
    let mut rec = Writer {
        lines: String::new(),
    };
    {
        let g = game.borrow();
        let config = RecordState::fields(&*g.config.as_ref().expect("config").borrow(), &[]);
        rec.put(&[
            ("op", "header".into()),
            ("format", 2.into()),
            ("seed", g.seed_value.to_string().into()),
            ("build", engine.build.clone()),
            ("recipe", Variant::Dictionary(recipe)),
            ("config", Variant::Dictionary(config)),
            ("initial_hash", RecordState::state_hash(&g).into()),
        ]);
    }
    let mut seats: Vec<Seat> = Vec::new();
    for (id, plan_seat) in plan.seats.into_iter().enumerate() {
        let deadline = Rc::new(Cell::new(0));
        let sim = harness::sim(
            engine.sim_content.clone(),
            engine.library.clone(),
            plan_seat.sim_seed,
            deadline.clone(),
        );
        let past = Rc::new(Vec::new());
        let mut seat = Seat {
            id: id as i64,
            colour: plan_seat.colour,
            name: plan_seat.name.clone(),
            bot: None,
            fallback: None,
            sim,
            deadline,
            used_ns: 0,
            clock_out: None,
            panic: None,
            fault: None,
            refused: 0,
            last_refusal: String::new(),
            past,
            rounds: Vec::new(),
            last_board: Vec::new(),
            tribe_rounds: Vec::new(),
            golden_seen: 0,
            gold_start: None,
            deferred_gold: 0,
            slots_seen: String::new(),
            shop: None,
        };
        let setup = harness::setup(id as i64, engine.library.clone(), plan.clock_ns);
        let make = plan_seat.make;
        let label = format!(
            "{} ({}) seat {} game {}",
            plan_seat.name, plan_seat.colour, id, plan.index
        );
        let start = harness::thread_cpu_ns();
        watch.enter(&label, start);
        let made = catch_unwind(AssertUnwindSafe(|| make(&setup)));
        watch.leave();
        seat.used_ns += harness::thread_cpu_ns() - start;
        match made {
            Ok(bot) => seat.bot = Some(bot),
            Err(p) => seat.lose(
                0,
                "panic",
                json!({"round": 0, "call": "new_bot", "message": harness::panic_text(&p)}),
            ),
        }
        if seat.bot.is_some() && seat.used_ns > plan.clock_ns {
            seat.lose(
                0,
                "clock_out",
                json!({"round": 0, "call": "new_bot", "used_ms": seat.used_ns as f64 / 1e6}),
            );
        }
        seat.slots_seen = slots_key(&game, id as i64);
        seats.push(seat);
    }
    let mut ctx = Ctx {
        game: game.clone(),
        engine,
        clock_ns: plan.clock_ns,
        watch,
        index: plan.index,
        shops: Vec::new(),
        discovers: Vec::new(),
        reports: Vec::new(),
        decisions: Vec::new(),
        log_decisions: plan.log_decisions,
    };
    let round_limit = engine.library.config("round_limit").unwrap_or(50);
    let mut fight_log: Vec<Value> = Vec::new();
    while !game.borrow().over {
        for seat in &mut seats {
            seat.gold_start = None;
            // Combat card effects credit this at start_turn, alongside normal income.
            seat.deferred_gold = game.borrow().player(seat.id).borrow().gold_next_turn;
        }
        GameSession::start_round(&game);
        let round = game.borrow().round_number;
        rec.put(&[
            ("op", "start".into()),
            ("turn", round.into()),
            ("hash", hash(&game)),
        ]);
        let alive = game.borrow().alive_ids().to_vec();
        for id in alive {
            take_turn(&mut ctx, &mut seats[id as usize], &mut rec);
        }
        // Every alive player has ended its turn, so this is the state `finish_round` records.
        let payloads = harness::payloads(&game);
        rec.put(&[
            ("op", "fight_boards".into()),
            ("turn", round.into()),
            (
                "players",
                RecordState::fight_players(&game.borrow()).to_state(),
            ),
            ("hash", hash(&game)),
        ]);
        timed(4, || round_stats(&ctx, &mut seats));
        for seat in seats.iter_mut() {
            if !game.borrow().player(seat.id).borrow().alive {
                continue;
            }
            let opponent = game.borrow().opponent_of(seat.id);
            if let Some(found) = payloads
                .iter()
                .find(|p| p.id() == opponent && opponent != -2)
            {
                // Views and sandboxes keep immutable history snapshots. Copy on write
                // only when one is still held; otherwise append to the seat's owned list.
                Rc::make_mut(&mut seat.past).push(PastFight {
                    round,
                    opponent,
                    payload: found.clone(),
                });
            }
        }
        // _eliminate in finish_round can replace the ghost for the NEXT round.
        let ghost_of = game.borrow().ghost_of;
        let round_fights = GameSession::finish_round(&game);
        fight_log.push(fight_round(&game, round, &round_fights, ghost_of));
        let over = game.borrow().over;
        rec.put(&[
            ("op", "finish".into()),
            ("turn", round.into()),
            ("hash", hash(&game)),
            ("over", over.into()),
        ]);
        game.borrow().events.clear();
        game.borrow().fights.clear();
    }
    let rounds = game.borrow().round_number;
    let mut places = Vec::new();
    let mut seat_lines = Vec::new();
    let mut cpu = Vec::new();
    for seat in &seats {
        let player = game.borrow().player(seat.id);
        let player = player.borrow();
        let place = player.placement;
        let died_round = (player.eliminated_round > 0).then_some(player.eliminated_round);
        places.push(place);
        let (main, commit, pivots) = tribe_story(seat);
        seat_lines.push(json!({
            "seat": seat.id, "colour": seat.colour, "bot": seat.name, "place": place,
            "clock_out": seat.clock_out, "panic": seat.panic, "fault": seat.fault,
            "refused": seat.refused, "last_refusal": seat.last_refusal,
            "final_board": seat.last_board, "main_tribe": main, "commit_round": commit,
            "pivots": pivots, "rounds": seat.rounds, "died_round": died_round,
        }));
        cpu.push(json!({"seat": seat.id, "cpu_ms": seat.used_ns as f64 / 1e6}));
    }
    GameOut {
        index: plan.index,
        record: rec.lines,
        game: json!({
            "game": plan.index, "seed": plan.seed.to_string(), "swapped": plan.swapped,
            "layout_red_seats": (0..8).filter(|&s| plan.red_seats[s]).collect::<Vec<_>>(), "rounds": rounds, "round_limit_hit": rounds >= round_limit,
            "seats": seat_lines, "fights": fight_log,
        }),
        cpu: json!({"game": plan.index, "seats": cpu}),
        shops: ctx.shops,
        discovers: ctx.discovers,
        reports: ctx.reports,
        decisions: ctx.decisions,
        places,
    }
}

struct Ctx<'a> {
    game: GameSessionRef,
    engine: &'a Engine,
    clock_ns: i64,
    watch: &'a Watch,
    index: usize,
    shops: Vec<Value>,
    discovers: Vec<Value>,
    reports: Vec<Value>,
    decisions: Vec<Value>,
    log_decisions: bool,
}

impl Seat {
    /// The rest of this seat's game goes to SimpleBot.
    fn lose(&mut self, _round: i64, kind: &str, what: Value) {
        self.bot = None;
        let seed = self.id;
        self.fallback = Some(SimpleBot::new(Rng::new(seed)));
        match kind {
            "panic" => self.panic = Some(what),
            "fault" => self.fault = Some(what),
            _ => self.clock_out = Some(what),
        }
    }
}

enum Call {
    Choose,
    Report,
}

enum Answer {
    Index(usize),
    Report(Option<league_api::Report>),
    Lost,
}

/// One timed call into the seat's bot.
fn call(ctx: &mut Ctx, seat: &mut Seat, view: &BotView, what: Call) -> Answer {
    let Some(bot) = seat.bot.as_mut() else {
        return Answer::Lost;
    };
    let player = ctx.game.borrow().player(seat.id);
    harness::sim_begin(&mut seat.sim, &ctx.game, &player, &seat.past);
    let label = format!(
        "{} ({}) seat {} game {} round {}",
        seat.name,
        seat.colour,
        seat.id,
        ctx.index,
        view.round()
    );
    let start = harness::thread_cpu_ns();
    seat.deadline.set(start + (ctx.clock_ns - seat.used_ns));
    ctx.watch.enter(&label, start);
    let sim = &mut seat.sim;
    let result = catch_unwind(AssertUnwindSafe(|| match what {
        Call::Choose => Answer::Index(bot.choose(view, sim)),
        Call::Report => Answer::Report(bot.report(view, sim)),
    }));
    ctx.watch.leave();
    seat.used_ns += harness::thread_cpu_ns() - start;
    harness::sim_end(&mut seat.sim);
    let name = match what {
        Call::Choose => "choose",
        Call::Report => "report",
    };
    let round = view.round();
    if seat.used_ns > ctx.clock_ns {
        seat.lose(
            round,
            "clock_out",
            json!({"round": round, "call": name, "used_ms": seat.used_ns as f64 / 1e6}),
        );
        return Answer::Lost;
    }
    match result {
        Err(p) => {
            seat.lose(
                round,
                "panic",
                json!({"round": round, "call": name, "message": harness::panic_text(&p)}),
            );
            Answer::Lost
        }
        Ok(Answer::Index(i)) if i >= view.legal().len() => {
            seat.lose(
                round,
                "fault",
                json!({"round": round, "index": i, "legal": view.legal().len()}),
            );
            Answer::Lost
        }
        Ok(answer) => answer,
    }
}

fn choose(ctx: &mut Ctx, seat: &mut Seat, view: &BotView) -> usize {
    if let Answer::Index(i) = call(ctx, seat, view, Call::Choose) {
        return i;
    }
    let fallback = seat.fallback.as_mut().expect("fallback bot");
    fallback.choose(view, &mut seat.sim)
}

fn report(ctx: &mut Ctx, seat: &mut Seat, view: &BotView, kind: &str, offered: &[String]) {
    if seat.bot.is_none() {
        return;
    }
    if let Answer::Report(Some(r)) = call(ctx, seat, view, Call::Report) {
        ctx.reports.push(json!({
            "game": ctx.index, "seat": seat.id, "colour": seat.colour, "bot": seat.name,
            "round": view.round(), "kind": kind, "offered": offered, "strategy": r.strategy,
            "values": r.values.iter().map(|(id, v)| json!([id, v])).collect::<Vec<_>>(),
        }));
    }
}

fn take_turn(ctx: &mut Ctx, seat: &mut Seat, rec: &mut Writer) {
    let game = ctx.game.clone();
    let id = seat.id;
    let player = game.borrow().player(id);
    let round = game.borrow().round_number;
    let mut first = true;
    let mut last: Option<Action> = None;
    let mut ended_early = false;
    for step in 0..MAX_ACTIONS {
        if player.borrow().turn_ended || !player.borrow().alive {
            ended_early = true;
            break;
        }
        let view = timed(1, || {
            harness::view_typed(
                &game,
                id,
                &seat.past,
                &ctx.engine.library,
                ctx.clock_ns - seat.used_ns,
            )
        });
        seat.gold_start.get_or_insert(view.me().gold);
        let picking = view
            .legal()
            .iter()
            .any(|a| matches!(a, Action::Pick { .. }));
        if picking {
            report(ctx, seat, &view, "discover", &view.me().discover_options);
        } else {
            let me = view.me();
            let same = seat.shop.as_ref().is_some_and(|s| {
                s.expect_units == me.shop_units && s.expect_spells == me.shop_spells
            });
            if first || !same {
                let reason = if first {
                    "turn_start"
                } else if last == Some(Action::Refresh) {
                    "refresh"
                } else {
                    "changed"
                };
                flush_shop(ctx, seat);
                let mut offers = Vec::new();
                for (spell, row) in [(false, &me.shop_units), (true, &me.shop_spells)] {
                    for (i, card) in row.iter().enumerate() {
                        if card.is_empty() {
                            continue;
                        }
                        let buyable = view.legal().iter().any(|a| {
                            *a == Action::Buy {
                                spell,
                                index: i as i64,
                            }
                        });
                        offers.push(
                            json!({"card": card, "spell": spell, "index": i, "buyable": buyable}),
                        );
                    }
                }
                seat.shop = Some(ShopLine {
                    value: json!({
                        "game": ctx.index, "seat": id, "colour": seat.colour, "bot": seat.name,
                        "round": round, "reason": reason, "gold": me.gold, "tier": me.tier,
                        "offers": offers, "bought": [],
                    }),
                    expect_units: me.shop_units.clone(),
                    expect_spells: me.shop_spells.clone(),
                });
                let offered: Vec<String> = me
                    .shop_units
                    .iter()
                    .chain(me.shop_spells.iter())
                    .filter(|c| !c.is_empty())
                    .cloned()
                    .collect();
                report(ctx, seat, &view, "shop", &offered);
            }
            first = false;
        }
        let index = timed(3, || choose(ctx, seat, &view));
        let typed = view.legal()[index].clone();
        // The same engine enumeration emitted these fields directly. Only the chosen
        // action needs a Godot dictionary (for act and the record), in its original order.
        let action = harness::action_dict(&typed);
        let result = timed(2, || GameSession::act(&game, id, &action));
        let me = view.me();
        if ctx.log_decisions {
            ctx.decisions.push(json!({
            "game": ctx.index, "seat": id, "colour": seat.colour, "bot": seat.name,
            "by": if seat.bot.is_some() { "bot" } else { "fallback" },
            "round": round, "step": step, "gold": me.gold, "tier": me.tier,
            "board_n": me.board.iter().flatten().count(), "hand_n": me.hand.len(),
            "legal": view.legal().iter().map(|a| legal_entry(a, me)).collect::<Vec<_>>(),
            "chosen": index, "result": result.clone(),
            }));
        }
        rec.put(&[
            ("op", "act".into()),
            ("turn", round.into()),
            ("player", id.into()),
            ("action", Variant::Dictionary(action.clone())),
            ("result", result.clone().into()),
        ]);
        if let Action::Pick { index } = typed {
            ctx.discovers.push(json!({
                "game": ctx.index, "seat": id, "colour": seat.colour, "bot": seat.name,
                "round": round, "options": view.me().discover_options, "pick": index,
                "card": view.me().discover_options.get(index as usize),
            }));
        }
        if result.is_empty()
            && let (Action::Buy { spell, index }, Some(shop)) = (&typed, seat.shop.as_mut())
        {
            let row = if *spell {
                &mut shop.expect_spells
            } else {
                &mut shop.expect_units
            };
            let card = row[*index as usize].clone();
            row[*index as usize] = String::new();
            shop.value["bought"]
                .as_array_mut()
                .expect("bought list")
                .push(json!({"card": card, "spell": spell, "index": index}));
        }
        last = Some(typed);
        if !result.is_empty() {
            seat.refused += 1;
            seat.last_refusal = format!(
                "{} -> {}",
                godot_json::stringify(&Variant::Dictionary(action)),
                result
            );
            break;
        }
    }
    flush_shop(ctx, seat);
    if !ended_early {
        GameSession::end_turn(&game, id);
        rec.put(&[
            ("op", "end".into()),
            ("turn", round.into()),
            ("player", id.into()),
        ]);
    }
}

/// A legal action as a decision line shows it: the engine's fields, plus the card it uses
/// (bought, sold, played, picked, or whose ability it is) and a buy's price.
fn legal_entry(action: &Action, me: &league_api::Me) -> Value {
    let at = |row: &[String], i: i64| usize::try_from(i).ok().and_then(|i| row.get(i)).cloned();
    let unit = |u: Option<&league_api::UnitView>| u.map(|u| u.def.clone());
    match action {
        Action::Pick { index } => {
            json!({"type": "pick", "index": index, "card": at(&me.discover_options, *index)})
        }
        Action::Buy { spell, index } => {
            let (row, prices) = if *spell {
                (&me.shop_spells, &me.spell_prices)
            } else {
                (&me.shop_units, &me.unit_prices)
            };
            let price = usize::try_from(*index)
                .ok()
                .and_then(|i| prices.get(i))
                .copied();
            json!({"type": "buy", "spell": spell, "index": index, "card": at(row, *index),
                   "price": price})
        }
        Action::Sell { slot } => {
            let card = usize::try_from(*slot)
                .ok()
                .and_then(|i| me.board.get(i))
                .and_then(|u| unit(u.as_ref()));
            json!({"type": "sell", "slot": slot, "card": card})
        }
        Action::Play { hand, slot, target } => {
            let card = usize::try_from(*hand)
                .ok()
                .and_then(|i| unit(me.hand.get(i)));
            json!({"type": "play", "hand": hand, "slot": slot, "target": target, "card": card})
        }
        Action::Ability {
            uid,
            mechanic,
            target,
        } => {
            let card = unit(me.board.iter().flatten().find(|u| u.uid == *uid));
            json!({"type": "ability", "uid": uid, "mechanic": mechanic, "target": target,
                   "card": card})
        }
        Action::Move { from, to } => json!({"type": "move", "from": from, "to": to}),
        other => json!({"type": other.kind()}),
    }
}

fn flush_shop(ctx: &mut Ctx, seat: &mut Seat) {
    if let Some(shop) = seat.shop.take() {
        ctx.shops.push(shop.value);
    }
}

fn slots_key(game: &GameSessionRef, id: i64) -> String {
    let player = game.borrow().player(id);
    let state = player.borrow().slots.to_state();
    godot_json::stringify(&state)
}

/// One round's fights, as `finish_round` returned them, and every seat's health after them.
/// `a`/`b` are seat ids (-1: the ghost); `winner` is the winning seat, -1 a draw. `result` is
/// the engine's own fight result, in its JSON form.
fn fight_round(
    game: &GameSessionRef,
    round: i64,
    fights: &Array<Dictionary>,
    ghost_of: i64,
) -> Value {
    let mut lines = Vec::new();
    for fight in fights.borrow().iter() {
        let players = fight.get("players").as_array();
        let a = players.get(0).map_or(-2, |v| v.as_i64());
        let b = players.get(1).map_or(-2, |v| v.as_i64());
        let result = fight.get("result").as_dict();
        let side = result.get("winner").as_i64();
        let winner = match side {
            0 => a,
            1 => b,
            _ => -1,
        };
        let result_json: Value =
            serde_json::from_str(&godot_json::stringify(&Variant::Dictionary(result)))
                .unwrap_or(Value::Null);
        lines.push(json!({
            "a": a, "b": b, "winner": winner, "loser": fight.get("loser").as_i64(),
            "damage": fight.get("damage").as_i64(), "result": result_json,
            "ghost_of": (b == Matchmaking::GHOST && ghost_of >= 0).then_some(ghost_of),
        }));
    }
    let players: Vec<Value> = (0..8)
        .map(|id| {
            let p = game.borrow().player(id);
            let p = p.borrow();
            json!({"seat": id, "hp": p.health, "armor": p.armor, "alive": p.alive})
        })
        .collect();
    json!({"round": round, "fights": lines, "players": players})
}

/// Per-round board facts for every alive seat, after all turns and before the fights.
fn round_stats(ctx: &Ctx, seats: &mut [Seat]) {
    let game = &ctx.game;
    let round = game.borrow().round_number;
    let events = game.borrow().events.to_vec();
    for seat in seats.iter_mut() {
        let player = game.borrow().player(seat.id);
        if !player.borrow().alive {
            continue;
        }
        let triple = events
            .iter()
            .any(|e| e.get("type").as_text() == "triple" && e.get("player").as_i64() == seat.id);
        let p = player.borrow();
        let mut tribes: BTreeMap<String, (i64, i64)> = BTreeMap::new();
        let mut attack = 0;
        let mut health = 0;
        let mut board = Vec::new();
        for unit in p.board_units().to_vec() {
            let u = unit.borrow();
            let def = u.def.as_ref().expect("def").borrow();
            let (a, h) = (u.attack(), u.health());
            attack += a;
            health += h;
            board.push(json!({"card": def.id, "golden": u.golden, "slot": u.slot, "attack": a, "health": h}));
            let names = def.tribes.to_vec();
            let names: Vec<String> = if names.iter().any(|t| t == "All") {
                crate::baselines::TRIBES
                    .iter()
                    .map(|t| t.to_string())
                    .collect()
            } else {
                names
            };
            for tribe in names {
                let entry = tribes.entry(tribe).or_insert((0, 0));
                entry.0 += 1;
                entry.1 += a + h;
            }
        }
        let goldens = p
            .all_cards()
            .borrow()
            .iter()
            .filter(|u| u.borrow().golden)
            .count() as i64;
        let golden = goldens > seat.golden_seen;
        seat.golden_seen = goldens;
        let gold_left = p.gold;
        let tier = p.tier;
        let hand: Vec<String> = p
            .hand
            .borrow()
            .iter()
            .map(|u| u.borrow().def.as_ref().expect("def").borrow().id.clone())
            .collect();
        let heaps: BTreeMap<String, usize> = p
            .heaps
            .borrow()
            .iter()
            .map(|(name, heap)| (name.clone(), heap.borrow().entries.len()))
            .collect();
        let counters: Value = serde_json::from_str(&godot_json::stringify(&p.counters.to_state()))
            .expect("player counters JSON");
        let gold_from_cards = seat.deferred_gold.max(0)
            + events
                .iter()
                .filter(|e| {
                    e.get("type").as_text() == "gold"
                        && e.get("player").as_i64() == seat.id
                        && e.get("source_uid").as_i64() >= 0
                })
                .map(|e| e.get("amount").as_i64().max(0))
                .sum::<i64>();
        drop(p);
        let slots = slots_key(game, seat.id);
        let slot_buff = slots != seat.slots_seen;
        seat.slots_seen = slots;
        let counts: BTreeMap<&String, i64> = tribes.iter().map(|(k, v)| (k, v.0)).collect();
        seat.rounds.push(json!({
            "round": round, "tribes": counts, "board_attack": attack, "board_health": health, "tier": tier,
            "gold_left": gold_left, "triple": triple, "golden_gained": golden, "slot_buff": slot_buff,
            "board": board, "hand": hand, "heaps": heaps, "counters": counters,
            "gold_start": seat.gold_start, "gold_from_cards": gold_from_cards,
        }));
        seat.last_board = board;
        seat.tribe_rounds.push((round, tribes));
    }
}

/// Most units, ties to higher total stats, then the name.
fn main_of(tribes: &BTreeMap<String, (i64, i64)>) -> Option<(String, i64)> {
    tribes
        .iter()
        .max_by(|a, b| (a.1.0, a.1.1).cmp(&(b.1.0, b.1.1)).then(b.0.cmp(a.0)))
        .map(|(name, (count, _))| (name.clone(), *count))
}

fn tribe_story(seat: &Seat) -> (Option<String>, Option<i64>, Vec<Value>) {
    let Some((round, last)) = seat.tribe_rounds.last() else {
        return (None, None, Vec::new());
    };
    let _ = round;
    let main = main_of(last).map(|m| m.0);
    let commit = main.as_ref().and_then(|m| {
        seat.tribe_rounds
            .iter()
            .find(|(_, t)| t.get(m).is_some_and(|c| c.0 >= 4))
            .map(|(r, _)| *r)
    });
    let mut pivots = Vec::new();
    let mut current: Option<String> = None;
    for (r, tribes) in &seat.tribe_rounds {
        let Some((name, count)) = main_of(tribes) else {
            continue;
        };
        if count < 4 {
            continue;
        }
        match &current {
            None => current = Some(name),
            Some(cur) if *cur != name => {
                if commit.is_some_and(|c| *r > c) {
                    pivots.push(json!({"round": r, "from": cur, "to": name}));
                }
                current = Some(name);
            }
            _ => {}
        }
    }
    (main, commit, pivots)
}
