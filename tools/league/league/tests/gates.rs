//! The harness gates that run as tests: sandbox refreshes don't predict real ones, a bot that
//! runs past its clock gets a clock-out and the game finishes, panics and bad indices fall back
//! to SimpleBot, a view is a copy (the game can't change it, it can't change the game), and a
//! match is byte-identical at any thread count. Stand-in content, so they run before tribes.
use bramble_engine::core::{
    records::record_state::RecordState, session::game_session::GameSession,
};
use bramble_engine::{Array, Dictionary, ToState};
use league::matchrun::{self, MatchArgs};
use league_api::{Action, harness};
use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use std::cell::Cell;
use std::path::{Path, PathBuf};
use std::rc::Rc;

fn root() -> PathBuf {
    league::default_root()
}

fn scratch(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("league-test-{name}-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

fn refresh(game: &bramble_engine::core::session::game_session::GameSessionRef, id: i64) -> String {
    let action = Dictionary::new();
    action.insert("type", "refresh".into());
    GameSession::act(game, id, &action)
}

#[test]
fn sandbox_refresh_is_not_the_real_next_refresh_and_writes_nothing_back() {
    let root = root();
    let engine =
        league::engine_for(&root, &|| league::load_content(&root, Some("standin"))).unwrap();
    let (mut trials, mut same, mut compared) = (0, 0, 0);
    for seed in 1..=60i64 {
        let game = engine.content.borrow().new_session(seed, &Array::new());
        game.borrow_mut().keep_fight_events = false;
        for round in 1..=4 {
            GameSession::start_round(&game);
            for id in 0..8i64 {
                let player = game.borrow().player(id);
                player.borrow_mut().gold = 50; // enough to refresh in both
                let deadline = Rc::new(Cell::new(i64::MAX / 4));
                let mut sim = harness::sim(
                    engine.sim_content.clone(),
                    engine.library.clone(),
                    (seed * 100 + id) as u64,
                    deadline,
                );
                harness::sim_begin(&mut sim, &game, &player, &Rc::new(Vec::new()));
                let before = RecordState::state_hash(&game.borrow());
                let mut sandbox = sim.sandbox().unwrap();
                assert_eq!(sandbox.act(&Action::Refresh), "");
                let guess = sandbox.view().unwrap().me().shop_units.clone();
                sandbox.act(&Action::Buy {
                    spell: false,
                    index: 0,
                });
                sandbox.end_turn();
                harness::sim_end(&mut sim);
                assert_eq!(
                    before,
                    RecordState::state_hash(&game.borrow()),
                    "the sandbox changed the game"
                );
                assert_eq!(refresh(&game, id), "");
                let real = player.borrow().shop_units.to_vec();
                trials += 1;
                compared += real.len();
                if guess == real {
                    same += 1;
                }
                let _ = round;
            }
            for id in 0..8 {
                GameSession::end_turn(&game, id);
            }
            GameSession::finish_round(&game);
        }
    }
    println!(
        "sandbox refresh equal to the real one in {same} of {trials} trials ({compared} shop slots)"
    );
    assert!(trials >= 1000);
    // Equal shops by chance happen only with tiny pools; with stand-ins at tiers 1-3 they are rare.
    assert!(
        same * 50 < trials,
        "{same} of {trials} sandbox refreshes equalled the real ones"
    );
}

fn play(
    name: &str,
    red: &str,
    blue: &str,
    games: usize,
    clock_ms: i64,
    threads: usize,
    secret: &str,
) -> PathBuf {
    let out = scratch(name);
    let seeds = out.join("seeds.txt");
    std::fs::write(&seeds, "11\n11\n13\n14\n").unwrap();
    let args = MatchArgs {
        red: red.into(),
        blue: blue.into(),
        red_label: Some("red-m1".into()),
        blue_label: None,
        games,
        seeds,
        clock_ms,
        threads,
        out: out.join("run"),
        content: Some("standin".into()),
        secret: Some(secret.into()),
        root: root(),
        records: true,
        decisions: true,
    };
    matchrun::run(&args).unwrap();
    out.join("run")
}

fn games(dir: &Path) -> Vec<Value> {
    std::fs::read_to_string(dir.join("games.jsonl"))
        .unwrap()
        .lines()
        .map(|l| serde_json::from_str(l).unwrap())
        .collect()
}

fn seats<'a>(games: &'a [Value], colour: &str) -> Vec<&'a Value> {
    games
        .iter()
        .flat_map(|g| g["seats"].as_array().unwrap())
        .filter(|s| s["colour"] == colour)
        .collect()
}

#[test]
fn busy_bot_gets_a_clock_out_and_the_game_finishes() {
    let dir = play("busy", "test-busy", "flow", 2, 40, 1, "aa");
    let g = games(&dir);
    assert_eq!(g.len(), 2);
    for game in &g {
        assert!(game["rounds"].as_i64().unwrap() >= 3);
        let places: Vec<i64> = game["seats"]
            .as_array()
            .unwrap()
            .iter()
            .map(|s| s["place"].as_i64().unwrap())
            .collect();
        assert!(places.iter().all(|p| (1..=8).contains(p)), "{places:?}");
    }
    for seat in seats(&g, "red") {
        let out = &seat["clock_out"];
        assert!(!out.is_null(), "red seat without a clock-out: {seat}");
        assert_eq!(out["round"], 3);
    }
    for seat in seats(&g, "blue") {
        assert!(seat["clock_out"].is_null());
    }
    league::analyze::analyze(&dir).unwrap();
    let analysis: Value =
        serde_json::from_str(&std::fs::read_to_string(dir.join("analysis.json")).unwrap()).unwrap();
    assert_eq!(analysis["health"]["by_colour"]["red"]["clock_outs"], 8);
    assert_eq!(analysis["health"]["by_colour"]["blue"]["clock_outs"], 0);
}

#[test]
fn panics_and_bad_indices_fall_back_to_simplebot() {
    let dir = play("faults", "test-panic", "test-fault", 2, 1000, 1, "bb");
    let g = games(&dir);
    for seat in seats(&g, "red") {
        let panic = seat["panic"]["message"].as_str().unwrap();
        assert!(panic.contains("planted panic in round 3"), "{panic}");
    }
    for seat in seats(&g, "blue") {
        assert_eq!(seat["fault"]["round"], 2);
    }
    for game in &g {
        assert!(
            game["seats"]
                .as_array()
                .unwrap()
                .iter()
                .all(|s| s["refused"] == 0)
        );
    }
}

#[test]
fn a_match_is_byte_identical_at_any_thread_count() {
    let one = play("threads1", "random", "example-clean", 6, 1000, 1, "cc");
    let three = play("threads3", "random", "example-clean", 6, 1000, 3, "cc");
    let mut files: Vec<String> = [
        "games.jsonl",
        "shops.jsonl.gz",
        "library.json",
        "discovers.jsonl",
        "reports.jsonl",
        "decisions.jsonl.gz",
        "summary.json",
    ]
    .map(String::from)
    .to_vec();
    for i in 0..6 {
        files.push(format!("records/game-{i:05}.jsonl"));
    }
    for f in files {
        let normalize = |dir: &Path| {
            let bytes = std::fs::read(dir.join(&f)).unwrap();
            if f == "summary.json" {
                let mut v: Value = serde_json::from_slice(&bytes).unwrap();
                // The runtime checkout may change between runs; it is provenance only.
                assert!(v["git_sha"].is_null() || v["git_sha"].is_string());
                v.as_object_mut().unwrap().remove("git_sha");
                serde_json::to_vec(&v).unwrap()
            } else {
                bytes
            }
        };
        let a = normalize(&one);
        let b = normalize(&three);
        assert!(a == b, "{f} differs between 1 and 3 threads");
        assert!(!a.is_empty() || f == "discovers.jsonl", "{f} is empty");
    }
    let summary: Value =
        serde_json::from_slice(&std::fs::read(one.join("summary.json")).unwrap()).unwrap();
    assert_eq!(summary["schema"], 1);
    assert_eq!(summary["complete"], true);
    assert_eq!(summary["red_label"], "red-m1");
    assert_eq!(summary["blue_label"], "example-clean");
    assert_eq!(
        summary["rules_hash"],
        serde_json::from_str::<Value>(league::BUILD).unwrap()["rules_hash"]
    );
    assert_eq!(
        summary["seeds_sha256"],
        format!(
            "{:x}",
            Sha256::digest(std::fs::read(one.parent().unwrap().join("seeds.txt")).unwrap())
        )
    );
    let engine =
        league::engine_for(&root(), &|| league::load_content(&root(), Some("standin"))).unwrap();
    let library: Vec<Value> =
        serde_json::from_slice(&std::fs::read(one.join("library.json")).unwrap()).unwrap();
    assert_eq!(library.len(), engine.library.cards().len());
    for c in &library {
        let original = engine.library.get(c["id"].as_str().unwrap()).unwrap();
        assert_eq!(
            *c,
            json!({"id": original.id, "name": original.name, "tribes": original.tribes,
            "tier": original.tier, "attack": original.attack, "health": original.health,
            "spell": original.spell, "token": original.token})
        );
    }
    assert!(
        library
            .windows(2)
            .all(|w| w[0]["id"].as_str() < w[1]["id"].as_str())
    );
    league::analyze::analyze(&one).unwrap();
    let analysis: Value =
        serde_json::from_slice(&std::fs::read(one.join("analysis.json")).unwrap()).unwrap();
    assert_eq!(
        analysis["seed_pairs"], 3,
        "repeated seed text must not merge distinct pairs"
    );
    // The decision log has one line per record `act`, in order, with the chosen action's
    // fields and every legal option.
    let text = std::process::Command::new("gzip")
        .args(["-dc"])
        .arg(one.join("decisions.jsonl.gz"))
        .output()
        .unwrap();
    assert!(text.status.success());
    let decisions: Vec<serde_json::Value> = String::from_utf8(text.stdout)
        .unwrap()
        .lines()
        .map(|l| serde_json::from_str(l).unwrap())
        .collect();
    verify_logged_states(&one, Some("standin"), &decisions);
    let mut acts = Vec::new();
    for i in 0..6 {
        let rec = std::fs::read_to_string(one.join(format!("records/game-{i:05}.jsonl"))).unwrap();
        for l in rec.lines() {
            let v: serde_json::Value = serde_json::from_str(l).unwrap();
            if v["op"] == "act" {
                acts.push((i, v));
            }
        }
    }
    assert_eq!(decisions.len(), acts.len());
    for (d, (game, act)) in decisions.iter().zip(&acts) {
        assert_eq!(d["game"], *game);
        assert_eq!(d["seat"], act["player"]);
        assert_eq!(d["round"], act["turn"]);
        let chosen = &d["legal"][d["chosen"].as_u64().unwrap() as usize];
        for (key, value) in act["action"].as_object().unwrap() {
            assert_eq!(&chosen[key], value, "decision field {key}");
        }
        if chosen["type"] == "buy" || chosen["type"] == "pick" {
            assert!(chosen["card"].is_string(), "a buy or pick names its card");
        }
    }
    // A different secret changes the bots' seeds (RandomBot plays differently) but not the game seeds.
    let other = play("secret", "random", "example-clean", 2, 1000, 1, "dd");
    let a = games(&one);
    let b = games(&other);
    assert_eq!(a[0]["seed"], b[0]["seed"]);
    assert_ne!(
        std::fs::read(one.join("records/game-00000.jsonl")).unwrap(),
        std::fs::read(other.join("records/game-00000.jsonl")).unwrap()
    );
    // Colours swap on the second game of each seed; 4 seats are red.
    let c0: Vec<&str> = a[0]["seats"]
        .as_array()
        .unwrap()
        .iter()
        .map(|s| s["colour"].as_str().unwrap())
        .collect();
    let c1: Vec<&str> = a[1]["seats"]
        .as_array()
        .unwrap()
        .iter()
        .map(|s| s["colour"].as_str().unwrap())
        .collect();
    for s in 0..8 {
        assert_ne!(c0[s], c1[s]);
    }
    assert_eq!(c0.iter().filter(|c| **c == "red").count(), 4);
    assert_eq!(a[0]["layout_red_seats"].as_array().unwrap().len(), 4);
}

#[test]
fn red_seats_are_shuffled_by_the_secret() {
    use league::matchrun::red_seats;
    let mut layouts = std::collections::BTreeSet::new();
    let mut red_count = [0usize; 8];
    for pair in 0..2000 {
        let red = red_seats("some secret", pair);
        assert_eq!(red.iter().filter(|r| **r).count(), 4);
        for s in 0..8 {
            red_count[s] += usize::from(red[s]);
        }
        layouts.insert(red);
    }
    // All 70 four-seat layouts turn up, each seat red about half the time.
    assert_eq!(layouts.len(), 70);
    for count in red_count {
        assert!((900..1100).contains(&count), "{red_count:?}");
    }
    assert_ne!(red_seats("one", 0), red_seats("two", 0));
    // Parity no longer gives teammates away: some layouts put both colours on even seats.
    assert!(layouts.iter().any(|r| r[0] != r[2]));
}

#[test]
fn a_view_is_a_copy() {
    let root = root();
    let engine =
        league::engine_for(&root, &|| league::load_content(&root, Some("standin"))).unwrap();
    let game = engine.content.borrow().new_session(5, &Array::new());
    GameSession::start_round(&game);
    let past = Rc::new(Vec::new());
    let built = harness::view(&game, 0, &past, &engine.library, 1);
    let before = built.view.me().payload().to_json();
    let gold = built.view.me().gold;
    // Play every action the view offered to buy; the view must not change.
    let buy = built
        .legal
        .iter()
        .position(|a| a.get("type").as_text() == "buy")
        .unwrap();
    assert_eq!(GameSession::act(&game, 0, &built.legal[buy]), "");
    let play_card = harness::view(&game, 0, &past, &engine.library, 1).legal;
    let play = play_card
        .iter()
        .position(|a| a.get("type").as_text() == "play")
        .unwrap();
    assert_eq!(GameSession::act(&game, 0, &play_card[play]), "");
    assert_eq!(built.view.me().payload().to_json(), before);
    assert_eq!(built.view.me().gold, gold);
    assert!(game.borrow().player(0).borrow().gold < gold);
    // A bot's edits to its own payload copy reach nothing.
    let hash = RecordState::state_hash(&game.borrow());
    let mut copy = built.view.me().payload().clone();
    copy.set_tier(6);
    copy.set_board(0, Some(league_api::SnapUnit::fresh("t1_plain", 999, true)));
    assert_eq!(hash, RecordState::state_hash(&game.borrow()));
    assert_eq!(built.view.me().payload().to_json(), before);
}

#[test]
fn records_replay_in_the_rust_engine() {
    let dir = play("replay", "flow", "random", 2, 1000, 1, "ee");
    for i in 0..2 {
        let path = dir.join(format!("records/game-{i:05}.jsonl"));
        let result =
            bramble_engine::core::records::record_replay::RecordReplay::read(&root(), &path);
        assert!(result.ok, "{}: {}", path.display(), result.message);
        assert!(result.complete);
    }
}

#[test]
fn selfcheck_matches_stand_in_records_when_present() {
    let dir = Path::new("/home/alex/league/records/standin");
    if !dir.exists() {
        eprintln!("skipped: no stand-in records");
        return;
    }
    let report = league::selfcheck::run(&root(), &[dir.to_owned()], Some(3), 1, None).unwrap();
    assert_eq!(report.matched, 3, "{:?}", report.failures);
}

/// Replay the records and compare each logged fact with the state at its documented time.
fn verify_logged_states(dir: &Path, content: Option<&str>, decisions: &[Value]) {
    use bramble_engine::util::godot_json;
    let content = league::load_content(&root(), content).unwrap();
    for logged in games(dir) {
        let index = logged["game"].as_u64().unwrap();
        let seed = logged["seed"].as_str().unwrap().parse().unwrap();
        let game = content.borrow().new_session(seed, &Array::new());
        game.borrow_mut().record_recipe.clear();
        game.borrow_mut().keep_fight_events = false;
        let mut decision = decisions.iter().filter(|d| d["game"] == index);
        let mut first_gold = [None; 8];
        let mut ghost_of = -1;
        let record =
            std::fs::read_to_string(dir.join(format!("records/game-{index:05}.jsonl"))).unwrap();
        for line in record.lines() {
            let v: Value = serde_json::from_str(line).unwrap();
            let round = v["turn"].as_u64().unwrap_or(0) as usize;
            match v["op"].as_str().unwrap() {
                "start" => {
                    first_gold.fill(None);
                    GameSession::start_round(&game);
                }
                "act" => {
                    let id = v["player"].as_i64().unwrap();
                    let player = game.borrow().player(id);
                    let d = decision.next().unwrap();
                    let p = player.borrow();
                    first_gold[id as usize].get_or_insert(p.gold);
                    assert_eq!(d["board_n"], p.board_units().len());
                    assert_eq!(d["hand_n"], p.hand.len());
                    drop(p);
                    let action = godot_json::parse_string(&v["action"].to_string()).as_dict();
                    assert_eq!(
                        GameSession::act(&game, id, &action),
                        v["result"].as_str().unwrap()
                    );
                }
                "end" => GameSession::end_turn(&game, v["player"].as_i64().unwrap()),
                "fight_boards" => {
                    ghost_of = game.borrow().ghost_of;
                    for seat in logged["seats"].as_array().unwrap() {
                        let id = seat["seat"].as_i64().unwrap();
                        let player = game.borrow().player(id);
                        let p = player.borrow();
                        if !p.alive {
                            continue;
                        }
                        let r = &seat["rounds"][round - 1];
                        let board: Vec<Value> = p.board_units().borrow().iter().map(|u| {
                            let u = u.borrow();
                            json!({"card": u.def.as_ref().unwrap().borrow().id, "golden": u.golden,
                                "slot": u.slot, "attack": u.attack(), "health": u.health()})
                        }).collect();
                        assert_eq!(r["board"], json!(board));
                        assert_eq!(
                            r["board_attack"],
                            board
                                .iter()
                                .map(|u| u["attack"].as_i64().unwrap())
                                .sum::<i64>()
                        );
                        assert_eq!(
                            r["board_health"],
                            board
                                .iter()
                                .map(|u| u["health"].as_i64().unwrap())
                                .sum::<i64>()
                        );
                        assert!(
                            r.get("attack").is_none()
                                && r.get("health").is_none()
                                && r.get("golden").is_none()
                        );
                        assert!(r["golden_gained"].is_boolean());
                        let hand: Vec<String> = p
                            .hand
                            .borrow()
                            .iter()
                            .map(|u| u.borrow().def.as_ref().unwrap().borrow().id.clone())
                            .collect();
                        assert_eq!(r["hand"], json!(hand));
                        let counters: Value =
                            serde_json::from_str(&godot_json::stringify(&p.counters.to_state()))
                                .unwrap();
                        assert_eq!(r["counters"], counters);
                        let mut heaps = json!({});
                        for (name, heap) in p.heaps.borrow().iter() {
                            heaps[name] = json!(heap.borrow().entries.len());
                        }
                        assert_eq!(r["heaps"], heaps);
                        assert_eq!(r["gold_left"], p.gold);
                        assert_eq!(r["gold_start"], json!(first_gold[id as usize]));
                    }
                }
                "finish" => {
                    GameSession::finish_round(&game);
                    let f = &logged["fights"][round - 1];
                    assert!(f.get("health").is_none());
                    for id in 0..8 {
                        let player = game.borrow().player(id);
                        let p = player.borrow();
                        assert_eq!(
                            f["players"][id as usize],
                            json!({"seat": id, "hp": p.health, "armor": p.armor, "alive": p.alive})
                        );
                    }
                    for seat in logged["seats"].as_array().unwrap() {
                        let Some(stats) = seat["rounds"]
                            .as_array()
                            .unwrap()
                            .iter()
                            .find(|r| r["round"] == round)
                        else {
                            continue;
                        };
                        let id = seat["seat"].as_i64().unwrap();
                        let mut earned = game.borrow().player(id).borrow().gold_next_turn.max(0);
                        for event in game.borrow().events.borrow().iter() {
                            if event.get("type").as_text() == "gold"
                                && event.get("player").as_i64() == id
                                && event.get("source_uid").as_i64() >= 0
                            {
                                earned += event.get("amount").as_i64().max(0);
                            }
                        }
                        assert_eq!(stats["gold_from_cards"], earned);
                    }
                    for fight in f["fights"].as_array().unwrap() {
                        let expected = (fight["b"] == -1 && ghost_of >= 0).then_some(ghost_of);
                        assert_eq!(fight["ghost_of"], json!(expected));
                    }
                    game.borrow().events.clear();
                    game.borrow().fights.clear();
                }
                _ => {}
            }
        }
        assert!(decision.next().is_none());
        for seat in logged["seats"].as_array().unwrap() {
            let p = game.borrow().player(seat["seat"].as_i64().unwrap());
            let died = p.borrow().eliminated_round;
            assert_eq!(seat["died_round"], json!((died > 0).then_some(died)));
            assert_eq!(
                seat["final_board"],
                seat["rounds"].as_array().unwrap().last().unwrap()["board"]
            );
        }
    }
}

#[test]
fn tribe_logs_match_replayed_states_and_failed_reruns_have_no_manifest() {
    let dir = scratch("tribe-logs");
    let seeds = dir.join("seeds.txt");
    std::fs::write(
        &seeds,
        "# hash the exact bytes, including comments\n11\n12\n",
    )
    .unwrap();
    let mut args = MatchArgs {
        red: "tribe".into(),
        blue: "tribe".into(),
        red_label: None,
        blue_label: None,
        games: 4,
        seeds,
        clock_ms: 1000,
        threads: 1,
        out: dir.join("run"),
        content: None,
        secret: Some("abc".into()),
        root: root(),
        records: true,
        decisions: true,
    };
    let result = matchrun::run(&args).unwrap();
    assert_eq!(result["summary"]["red_label"], "tribe");
    let text = std::process::Command::new("gzip")
        .arg("-dc")
        .arg(args.out.join("decisions.jsonl.gz"))
        .output()
        .unwrap();
    assert!(text.status.success());
    let decisions: Vec<Value> = String::from_utf8(text.stdout)
        .unwrap()
        .lines()
        .map(|s| serde_json::from_str(s).unwrap())
        .collect();
    verify_logged_states(&args.out, None, &decisions);
    let logs = games(&args.out);
    let rounds: Vec<&Value> = logs
        .iter()
        .flat_map(|g| g["seats"].as_array().unwrap())
        .flat_map(|s| s["rounds"].as_array().unwrap())
        .collect();
    assert!(
        rounds
            .iter()
            .any(|r| r["gold_from_cards"].as_i64().unwrap() > 0)
    );
    assert!(
        rounds
            .iter()
            .any(|r| !r["heaps"].as_object().unwrap().is_empty())
    );
    assert!(
        rounds
            .iter()
            .any(|r| !r["counters"].as_object().unwrap().is_empty())
    );
    args.games = 5;
    assert!(matchrun::run(&args).unwrap_err().contains("need 3 seeds"));
    assert!(!args.out.join("summary.json").exists());
}
