//! Repeatable recruit sandbox timings on a restored late-game board.
//! Run: cargo run --release --offline --locked -p league-api --example recruit_bench
//!      -- /home/alex/league/proof/late-cases.jsonl 5000
use bramble_engine::Array;
use bramble_engine::core::session::game_session::GameSession;
use bramble_engine::game::game_content::GameContent;
use bramble_engine::util::godot_json;
use league_api::{Action, harness};
use std::cell::Cell;
use std::hint::black_box;
use std::io::{BufRead, BufReader};
use std::path::Path;
use std::rc::Rc;

fn timed(label: &str, n: usize, mut run: impl FnMut()) {
    let start = harness::thread_cpu_ns();
    for _ in 0..n {
        run();
    }
    println!(
        "{label}_us_per_call={:.3} calls={n}",
        (harness::thread_cpu_ns() - start) as f64 / 1000.0 / n as f64
    );
}

fn main() {
    let args: Vec<_> = std::env::args().collect();
    let path = args.get(1).expect("late-cases.jsonl path");
    let n = args.get(2).map_or(5000, |s| s.parse().expect("iterations"));
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
    let content = GameContent::load_default(&root);
    let line = BufReader::new(std::fs::File::open(path).expect("cases"))
        .lines()
        .next()
        .expect("first case")
        .expect("case line");
    let case = godot_json::parse_string(&line).as_dict();
    let game = content.borrow().new_session(42, &Array::new());
    game.borrow_mut().round_number = case.get("round").as_i64() - 1;
    game.borrow_mut().keep_fight_events = false;
    game.borrow_mut().record_recipe.clear();
    GameSession::start_round(&game);
    let raw = case.get("a").as_dict();
    harness::restore_payload(&mut game.borrow_mut(), &raw);
    let id = raw.get("id").as_i64();
    let player = game.borrow().player(id);
    player.borrow_mut().gold = 100;
    let from = player
        .borrow()
        .board_units()
        .get(0)
        .expect("board unit")
        .borrow()
        .slot;
    let to = (from + 1) % 7;
    let past = Rc::new(Vec::new());
    let library = Rc::new(harness::library_of_game(&game));
    let mut sim = harness::sim(content, library, 123, Rc::new(Cell::new(i64::MAX)));
    harness::sim_begin(&mut sim, &game, &player, &past);
    let mut sandbox = sim.sandbox().expect("sandbox");
    timed("legal", n, || {
        black_box(sandbox.legal());
    });
    let mut reverse = false;
    timed("act_move", n, || {
        let (from, to) = if reverse { (to, from) } else { (from, to) };
        assert!(sandbox.act(&Action::Move { from, to }).is_empty());
        reverse = !reverse;
    });
    timed("view", n / 5, || {
        black_box(sandbox.view().expect("view"));
    });
    timed("legal_and_act_move", n, || {
        black_box(sandbox.legal());
        let (from, to) = if reverse { (to, from) } else { (from, to) };
        assert!(sandbox.act(&Action::Move { from, to }).is_empty());
        reverse = !reverse;
    });
}
