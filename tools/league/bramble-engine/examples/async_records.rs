//! Generate Rust async records for Godot replay, with SimpleBot in the only live seat.
use bramble_engine::Array;
use bramble_engine::core::{
    bots::{bot::Bot, simple_bot::SimpleBot},
    ghosts::ghost_run::{GhostRun, RunsBySeat},
    records::game_record::GameRecord,
    session::game_session::GameSession,
    util::rng::Rng,
};
use bramble_engine::game::game_content::GameContent;
use std::path::Path;

fn main() {
    if let Err(error) = run() {
        eprintln!("async_records: {error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let args: Vec<_> = std::env::args_os().skip(1).collect();
    let [store, seeds, out] = args.as_slice() else {
        return Err("usage: async_records <ghost-store> <seed-file> <output-dir>".into());
    };
    let store = Path::new(store);
    let root = Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .expect("repository root");
    let content = GameContent::load_default(root);
    let content = content.borrow();
    if !content.errors.is_empty() {
        return Err(format!("content failed to load: {:?}", content.errors));
    }

    let mut paths = Vec::new();
    for shard in std::fs::read_dir(store.join("runs")).map_err(|error| error.to_string())? {
        let shard = shard.map_err(|error| error.to_string())?.path();
        if !shard.is_dir() {
            continue;
        }
        for file in std::fs::read_dir(shard).map_err(|error| error.to_string())? {
            let file = file.map_err(|error| error.to_string())?.path();
            if file
                .extension()
                .is_some_and(|extension| extension == "json")
            {
                paths.push(file);
            }
        }
    }
    paths.sort_unstable_by(|a, b| a.file_stem().cmp(&b.file_stem()));
    if paths.len() < 7 {
        return Err("need at least seven runs".into());
    }
    let mut runs = Vec::new();
    for path in &paths {
        let id = path
            .file_stem()
            .and_then(|stem| stem.to_str())
            .ok_or("invalid run filename")?;
        runs.push(GhostRun::fetch(
            store,
            id,
            Some(&content.library.borrow()),
            Some(&content.registry.borrow()),
        )?);
    }
    let seeds = std::fs::read_to_string(seeds).map_err(|error| error.to_string())?;
    GameRecord::configure(root, Path::new(out));
    let mut games = 0;
    let mut turns = 0;
    for seed in seeds.lines() {
        let seed = seed.parse::<i64>().map_err(|error| error.to_string())?;
        for game_seed in [seed, seed.wrapping_neg()] {
            let by_seat: RunsBySeat = (1..=7)
                .map(|seat| (seat, runs[(games + seat as usize - 1) % runs.len()].clone()))
                .collect();
            let game = content.new_async_session(game_seed, by_seat, &Array::new())?;
            game.borrow_mut().keep_fight_events = false;
            let player = game.borrow().player(0);
            let mut bot = SimpleBot::new(&Rng::derive(game_seed, "bot:0"));
            while !game.borrow().over {
                GameSession::start_round(&game);
                if player.borrow().alive {
                    for _ in 0..Bot::MAX_ACTIONS {
                        if player.borrow().turn_ended {
                            break;
                        }
                        let action = bot.choose(&game, &player);
                        let result = GameSession::act(&game, 0, &action);
                        if !result.is_empty() {
                            return Err(format!("seed {game_seed}: bot action refused: {result}"));
                        }
                    }
                }
                GameSession::finish_round(&game);
                game.borrow().events.clear();
                game.borrow().fights.clear();
            }
            let game = game.borrow();
            let record = game.record.as_ref().ok_or("no written record")?.borrow();
            if !record.error.is_empty() {
                return Err(record.error.clone());
            }
            games += 1;
            turns += game.round_number;
        }
    }
    println!("async_records: wrote {games} games, {turns} turns");
    Ok(())
}
