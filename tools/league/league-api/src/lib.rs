//! The crate a league bot depends on. It holds only what a bot may use: the `Bot` trait, the
//! read-only `BotView` (owned copies of what a player may know) and the `Sim` lookahead handle.
//! A bot never touches the live game: it gets a `&BotView` and a `&mut Sim`, and returns an
//! index into `view.legal()`.
//!
//! A bot crate exposes `pub fn new_bot(seed: u64, setup: &BotSetup) -> Box<dyn Bot>`.
//!
//! # What a bot can't reach (checked by these doc tests)
//!
//! The view's fields are private; a bot reads them through methods and gets shared references:
//! ```compile_fail
//! fn peek(view: &league_api::BotView) -> i64 { view.round }
//! ```
//! A bot can't change its view:
//! ```compile_fail
//! fn edit(view: &league_api::BotView) { view.me().gold = 99; }
//! ```
//! A bot can't make a `Sim` (so it can't point one at a game), nor reach inside one:
//! ```compile_fail
//! fn make() -> league_api::Sim { league_api::Sim { ctx: None } }
//! ```
//! ```compile_fail
//! fn inside(sim: &league_api::Sim) { let _ = &sim.content; }
//! ```
//! A payload's engine data is private:
//! ```compile_fail
//! fn raw(p: &league_api::Payload) { let _ = &p.raw; }
//! ```
//! A bot crate can't name the engine: it isn't a dependency of the bot (`check-crate` allows only
//! `league-api`), and `league-api` re-exports nothing of it but the plain `Rng`. Nothing in this
//! crate's public API outside `harness` returns an engine object, and `harness` functions need
//! engine objects to call (and `check-crate` rejects any bot that names `harness`).
//! What does compile is reading copies:
//! ```
//! fn read(view: &league_api::BotView) -> i64 { view.me().gold + view.round() }
//! ```
#![deny(unsafe_code)]

mod action;
mod clock;
mod copy;
mod sim;
mod view;

pub use action::Action;
pub use bramble_engine::core::util::rng::Rng;
pub use sim::{FightOutcome, Sandbox, Sim};
pub use view::{
    BotView, CardInfo, HeapView, Library, Me, PastFight, Payload, PlayerSummary, SlotView,
    SnapUnit, StandingView, UnitView,
};

use std::rc::Rc;

/// A league bot. A fresh one is made for every seat of every game.
pub trait Bot {
    /// The next action, as an index into `view.legal()`.
    fn choose(&mut self, view: &BotView, sim: &mut Sim) -> usize;
    /// Optional: the bot's value for every card on offer, and its strategy name. Called at each
    /// new shop and each Discover choice, on the bot's clock.
    fn report(&mut self, _view: &BotView, _sim: &mut Sim) -> Option<Report> {
        None
    }
}

/// What `report` gives: a value for each card on offer (by card id) and a strategy name.
/// Values are on the bot's own scale.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct Report {
    pub strategy: String,
    pub values: Vec<(String, f64)>,
}

/// A bot crate's constructor.
pub type Factory = fn(u64, &BotSetup) -> Box<dyn Bot>;

/// What a bot knows before its first turn.
pub struct BotSetup {
    player_id: i64,
    library: Rc<Library>,
    clock_ns: i64,
}

impl BotSetup {
    /// The seat this bot plays (its player id, 0..7).
    pub fn player_id(&self) -> i64 {
        self.player_id
    }
    pub fn library(&self) -> &Library {
        &self.library
    }
    /// This seat's CPU budget for the whole game, in ns.
    pub fn clock_ns(&self) -> i64 {
        self.clock_ns
    }
}

/// The harness's side: building views, sims and setups from engine objects. Bots have no use
/// for it (it needs engine objects a bot can't obtain), and `check-crate` rejects any bot that
/// names it.
#[doc(hidden)]
pub mod harness {
    use super::*;
    use bramble_engine::Dictionary;
    use bramble_engine::core::{
        recruit::player_state::PlayerStateRef, session::game_session::GameSessionRef,
    };
    use bramble_engine::game::game_content::GameContentRef;
    use std::cell::{Cell, RefCell};

    pub use crate::clock::{clock_ns, this_thread_clock, thread_cpu_ns};
    pub use crate::copy::{
        deep, deep_dict, fight_payload, full_player, restore_full, restore_payload,
        restore_payload_for,
    };

    pub fn library_of_game(game: &GameSessionRef) -> Library {
        view::library_of_game(game)
    }
    pub fn setup(player_id: i64, library: Rc<Library>, clock_ns: i64) -> BotSetup {
        BotSetup {
            player_id,
            library,
            clock_ns,
        }
    }
    pub fn sim(
        content: GameContentRef,
        library: Rc<Library>,
        seed: u64,
        deadline: Rc<Cell<i64>>,
    ) -> Sim {
        Sim::new(content, library, seed, deadline)
    }
    pub struct Built {
        pub view: BotView,
        pub legal: Vec<Dictionary>,
    }
    /// The view of `player_id` now, with the legal actions as the engine gives them.
    pub fn view(
        game: &GameSessionRef,
        player_id: i64,
        past: &Rc<Vec<PastFight>>,
        library: &Rc<Library>,
        clock_left_ns: i64,
    ) -> Built {
        let (legal, typed) = view::legal_of(game, player_id);
        let view = build_view(game, player_id, past, library, clock_left_ns, typed);
        Built { view, legal }
    }
    /// The same owned view without allocating a dictionary for every legal action.
    /// Materialize only the selected action with action_dict_for when playing/recording it.
    pub fn view_typed(
        game: &GameSessionRef,
        player_id: i64,
        past: &Rc<Vec<PastFight>>,
        library: &Rc<Library>,
        clock_left_ns: i64,
    ) -> BotView {
        let typed = view::typed_legal_of(game, player_id);
        build_view(game, player_id, past, library, clock_left_ns, typed)
    }
    fn build_view(
        game: &GameSessionRef,
        player_id: i64,
        past: &Rc<Vec<PastFight>>,
        library: &Rc<Library>,
        clock_left_ns: i64,
        legal: Vec<Action>,
    ) -> BotView {
        let player = game.borrow().player(player_id);
        BotView {
            round: game.borrow().round_number,
            me: view::me_of(game, &player),
            players: view::summaries_of(game),
            opponent: game.borrow().opponent_of(player_id),
            past: past.clone(),
            library: library.clone(),
            legal,
            clock_left_ns,
        }
    }
    /// Lets the Sim see the live player for the length of one bot call (for `sandbox`).
    pub fn sim_begin(
        sim: &mut Sim,
        game: &GameSessionRef,
        me: &PlayerStateRef,
        past: &Rc<Vec<PastFight>>,
    ) {
        let g = game.borrow();
        let id = me.borrow().id;
        sim.begin(sim::CallContext {
            round: g.round_number,
            me: me.clone(),
            players: view::summaries_of(game),
            opponent: g.opponent_of(id),
            past: past.clone(),
            unit_odds: g.unit_odds.clone(),
            spell_odds: g.spell_odds.clone(),
        });
    }
    pub fn sim_end(sim: &mut Sim) {
        sim.end();
    }
    /// Every fight payload of the round, as `RecordState.fight_players` gives them.
    pub fn payloads(game: &GameSessionRef) -> Vec<Payload> {
        view::payload_list(game)
    }
    pub fn payload_raw(payload: &Payload) -> Dictionary {
        payload.raw().clone()
    }
    pub fn action_dict(action: &Action) -> Dictionary {
        action.to_dict()
    }
    pub fn action_dict_for(game: &GameSessionRef, player_id: i64, action: &Action) -> Dictionary {
        action.to_dict_for(game, player_id)
    }
    pub fn action_of(raw: &Dictionary) -> Action {
        Action::from_dict(raw)
    }
    pub fn run_fight(
        content: &GameContentRef,
        round: i64,
        a: &Payload,
        b: &Payload,
        seed: i64,
    ) -> Result<FightOutcome, String> {
        sim::run_fight(content, round, a, b, seed)
    }

    thread_local! {
        static LAST_PANIC: RefCell<String> = const { RefCell::new(String::new()) };
    }
    /// Replaces the panic hook with one that keeps the message (and its location) for the
    /// harness to log, instead of printing it.
    pub fn quiet_panics() {
        std::panic::set_hook(Box::new(|info| {
            let text = match info.payload().downcast_ref::<&str>() {
                Some(s) => (*s).to_owned(),
                None => info
                    .payload()
                    .downcast_ref::<String>()
                    .cloned()
                    .unwrap_or_default(),
            };
            let place = info
                .location()
                .map(|l| format!(" at {}:{}", l.file(), l.line()))
                .unwrap_or_default();
            LAST_PANIC.with(|last| *last.borrow_mut() = format!("{text}{place}"));
        }));
    }
    /// The text of a caught panic.
    pub fn panic_text(_panic: &Box<dyn std::any::Any + Send>) -> String {
        let kept = LAST_PANIC.with(|last| std::mem::take(&mut *last.borrow_mut()));
        if !kept.is_empty() {
            return kept;
        }
        match _panic.downcast_ref::<&str>() {
            Some(s) => (*s).to_owned(),
            None => _panic
                .downcast_ref::<String>()
                .cloned()
                .unwrap_or_else(|| "panic".into()),
        }
    }
}
