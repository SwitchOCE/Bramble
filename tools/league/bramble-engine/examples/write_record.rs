//! Write a reference action stream through the Rust writer, for GDScript replay.
//! Arguments: SOURCE.jsonl OUTPUT_DIR [prefix|full]. Prefix stops at turn-1 fight_boards.
use bramble_engine::ToState;
use bramble_engine::core::{
    records::{game_record::GameRecord, record_replay::RecordReplay, record_state::RecordState},
    recruit::recruit::Recruit,
    session::game_session::GameSession,
};
use std::path::Path;
fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}
fn run() -> Result<(), String> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    let source = Path::new(args.first().ok_or("missing source record")?);
    let out = Path::new(args.get(1).ok_or("missing output directory")?);
    let full = args.get(2).is_some_and(|arg| arg == "full");
    let root = Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .expect("repository root");
    let entries = RecordReplay::read_entries(source).map_err(|e| e.message)?;
    let header = entries.get(0).ok_or("empty record")?;
    let initial = RecordReplay::rebuild_to(root, &entries, Some(0));
    if !initial.ok {
        return Err(initial.message);
    }
    let game = initial.session.expect("session");
    game.borrow_mut().record_recipe = header.get("recipe").as_dict();
    GameRecord::configure(root, out);
    for entry in entries.to_vec().into_iter().skip(1) {
        let op = entry.get("op").as_text();
        match op.as_str() {
            "start" => GameSession::start_round(&game),
            "act" => {
                let actual = GameSession::act(
                    &game,
                    entry.get("player").as_i64(),
                    &entry.get("action").as_dict(),
                );
                if actual != entry.get("result").as_text() {
                    return Err(format!("action result differs: {actual}"));
                }
            }
            "end" => GameSession::end_turn(&game, entry.get("player").as_i64()),
            "fight_boards" => {
                if full {
                    GameSession::finish_round(&game);
                } else {
                    let recruit = game.borrow().recruit.as_ref().expect("recruit").clone();
                    let alive = game.borrow().alive_players();
                    for player in alive.to_vec() {
                        Recruit::end_turn(&recruit, &player);
                    }
                    let snapshot = bramble_engine::state_dict!{"op"=>"fight_boards","turn"=>&game.borrow().round_number,"players"=>&RecordState::fight_players(&game.borrow()),"hash"=>&RecordState::state_hash(&game.borrow())}.as_dict();
                    let record = game.borrow().record.as_ref().expect("record").clone();
                    record.borrow_mut().append(&snapshot);
                    break;
                }
            }
            "finish" => {}
            _ => return Err(format!("unknown operation {op}")),
        }
    }
    let path = game
        .borrow()
        .record
        .as_ref()
        .expect("written record")
        .borrow()
        .path
        .clone();
    let written = RecordReplay::read_entries(Path::new(&path)).map_err(|e| e.message)?;
    if written.len() > entries.len() {
        return Err("too many written operations".into());
    }
    for (i, entry) in written.to_vec().iter().enumerate() {
        let expected = entries.get(i).expect("reference operation");
        if bramble_engine::util::godot_json::stringify(&entry.to_state())
            != bramble_engine::util::godot_json::stringify(&expected.to_state())
        {
            return Err(format!("written operation {i} differs"));
        }
    }
    println!(
        "PASS operations={} complete={} record={path}",
        written.len(),
        game.borrow().over
    );
    Ok(())
}
