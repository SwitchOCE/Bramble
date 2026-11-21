use bramble_engine::{
    Array, Dictionary,
    content::locust::lib::locust::{GORGE, Locust},
    core::{
        bots::simple_bot::SimpleBot, records::game_record::GameRecord,
        recruit::player_state::PlayerStateRef, session::game_session::GameSession, util::rng::Rng,
    },
    game::game_content::GameContent,
};
use serde_json::{Value, json};
use std::{collections::HashMap, fs, path::PathBuf, process::Command, rc::Rc};

struct TestMatch(PathBuf);

impl Drop for TestMatch {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

fn gorger_sale(
    player: &PlayerStateRef,
    action: &Dictionary,
    round: i64,
    seat: i64,
) -> Option<Value> {
    let hand = action.get_or("hand", (-1).into()).as_i64();
    let slot = action.get_or("slot", (-1).into()).as_i64();
    let sold = if hand >= 0 {
        player.borrow().hand.get(hand as usize)?
    } else {
        player.borrow().board.get(slot as usize).flatten()?
    };
    let eater = Locust::eater(Some(player), &sold)?;
    if Rc::ptr_eq(&eater, &sold) {
        return None;
    }
    let eater = eater.borrow();
    let hook = eater
        .hooks()
        .iter_live()
        .find(|hook| hook.borrow().id == GORGE)?;
    let times = hook.borrow().params.borrow().num("times");
    let sold = sold.borrow();
    let stats = sold.stats.as_ref().unwrap().borrow();
    let def = sold.def.as_ref().unwrap().borrow();
    Some(json!({
        "type": "eat", "game": 0, "round": round, "seat": seat,
        "eater": {"card": "gorger", "uid": eater.uid, "golden": eater.golden},
        "eaten": {
            "card": def.id, "uid": sold.uid, "golden": sold.golden, "tier": def.tier,
            "slot": sold.slot, "stats": {"attack": stats.attack(), "health": stats.max_health()},
            "own_stats": {"attack": stats.own_attack(), "health": stats.own_health()},
        },
        "gain": {"attack": stats.own_attack() * times, "health": stats.own_health() * times},
        "trigger": "sale",
    }))
}

#[test]
fn replays_gorger_sales_from_board_and_hand() {
    let directory =
        PathBuf::from(env!("CARGO_TARGET_TMPDIR")).join(format!("events-{}", std::process::id()));
    fs::create_dir_all(directory.parent().unwrap()).unwrap();
    fs::create_dir(&directory).unwrap();
    let directory = TestMatch(directory);
    let records = directory.0.join("records");
    fs::create_dir(&records).unwrap();

    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../..");
    GameRecord::configure(&root, &records);
    let content = GameContent::load_folders(
        &root,
        &Array::from([
            "res://src/content/shared".into(),
            "res://src/content/locust".into(),
        ]),
    );
    let seed = 107;
    let game = content.borrow().new_session(seed, &Array::new());
    // Board sale, hand sale of a unit that never entered the board, and hand sale after board play.
    let mut expected = [None, None, None];
    let mut first_board = HashMap::new();
    let mut bot = SimpleBot::new(&Rng::derive(seed, "proof"));
    while !game.borrow().over {
        GameSession::start_round(&game);
        let round = game.borrow().round_number;
        let seats = game.borrow().alive_ids();
        for seat in seats.iter_live() {
            let player = game.borrow().player(seat);
            for _ in 0..120 {
                for unit in player.borrow().board_units().iter_live() {
                    first_board.entry(unit.borrow().uid).or_insert(round);
                }
                if player.borrow().turn_ended {
                    break;
                }
                let legal = game.borrow().legal_actions(seat);
                let sale = legal.iter_live().find_map(|action| {
                    if action.get("type").as_text() != "sell" {
                        return None;
                    }
                    let event = gorger_sale(&player, &action, round, seat)?;
                    let uid = event["eaten"]["uid"].as_i64().unwrap();
                    let first = first_board.get(&uid).copied();
                    let case = match (action.has("hand"), first) {
                        (false, _) => 0,
                        (true, None) => 1,
                        (true, Some(_)) => 2,
                    };
                    if expected[case].is_some() {
                        return None;
                    }
                    expected[case] = Some((event, first));
                    Some(action)
                });
                let action = sale.unwrap_or_else(|| bot.choose(&game, &player));
                assert_eq!(GameSession::act(&game, seat, &action), "");
            }
            if !player.borrow().turn_ended {
                GameSession::end_turn(&game, seat);
            }
        }
        GameSession::finish_round(&game);
        game.borrow().events.clear();
        game.borrow().fights.clear();
    }
    let path = game.borrow().record.as_ref().unwrap().borrow().path.clone();
    fs::rename(path, records.join("game-00000.jsonl")).unwrap();

    let replay = Command::new(env!("CARGO_BIN_EXE_bramble-events"))
        .arg(&directory.0)
        .output()
        .unwrap();
    assert!(
        replay.status.success(),
        "{}",
        String::from_utf8_lossy(&replay.stderr)
    );

    let archive = Command::new("gzip")
        .arg("-dc")
        .arg(directory.0.join("events.jsonl.gz"))
        .output()
        .unwrap();
    assert!(archive.status.success());
    let rows: Vec<Value> = std::str::from_utf8(&archive.stdout)
        .unwrap()
        .lines()
        .map(|line| serde_json::from_str(line).unwrap())
        .collect();

    for (eat, first) in
        expected.map(|event| event.expect("record contains each kind of Gorger feeding sale"))
    {
        assert!(rows.contains(&eat), "missing reconstructed eat {eat}");
        let sale = rows
            .iter()
            .find(|row| row["type"] == "sale" && row["unit"]["uid"] == eat["eaten"]["uid"])
            .expect("reconstructed sale");
        assert_eq!(sale["unit"], eat["eaten"]);
        assert_eq!(sale["round"], eat["round"]);
        assert_eq!(sale["seat"], eat["seat"]);
        assert_eq!(
            sale["fed"][0],
            json!({"type": "eat", "eater": eat["eater"], "gain": eat["gain"]})
        );
        let round = eat["round"].as_i64().unwrap();
        assert_eq!(sale["board_since_round"], json!(first));
        assert_eq!(
            sale["rounds_on_board"],
            json!(first.map_or(0, |first| round - first))
        );
    }
}
