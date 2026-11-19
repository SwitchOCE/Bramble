use bramble_engine::core::{
    records::game_record::GameRecord, session::game_session::GameSession, util::rng::Rng,
};
use bramble_engine::{Array, game::game_content::GameContent};
use bramble_ghosts::{
    Band, CutOptions, Ended, FolderStore, GhostStore, LocalMatchmaker, Matchmaker, Query,
    RUN_FORMAT, Run, RunSource, RunTurn, SourceKind, cut_match,
};
use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use std::{
    collections::{BTreeMap, BTreeSet},
    fs,
    path::{Path, PathBuf},
    sync::atomic::{AtomicUsize, Ordering},
};

struct Scratch(PathBuf);

impl Scratch {
    fn new() -> Self {
        static NEXT: AtomicUsize = AtomicUsize::new(0);
        loop {
            let path = std::env::temp_dir().join(format!(
                "bramble-ghosts-test-{}-{}",
                std::process::id(),
                NEXT.fetch_add(1, Ordering::Relaxed)
            ));
            match fs::create_dir(&path) {
                Ok(()) => return Self(path),
                Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => continue,
                Err(e) => panic!("{}: {e}", path.display()),
            }
        }
    }
}

impl Drop for Scratch {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

fn run() -> Run {
    Run {
        format: RUN_FORMAT,
        rules: json!({"rules_hash": "a".repeat(64), "version": "0.0.1", "revision": "workspace", "engine": "Godot"}),
        patch: String::new(),
        content: vec!["mouse".into()],
        tribes: Vec::new(),
        source: RunSource {
            kind: SourceKind::Bot,
            label: "red".into(),
            player: "red".into(),
            rating: None,
            record_sha256: "b".repeat(64),
            record_mode: "live".into(),
            game_seed: "101".into(),
            seat: 3,
        },
        made: "2026-11-19T11:00:00Z".into(),
        placement: 2,
        last_turn: 1,
        ended: Ended::Eliminated,
        cards: BTreeMap::new(),
        turns: vec![RunTurn {
            turn: 1,
            tier: 1,
            health: 40,
            armor: 0,
            gold: 2,
            acts: Vec::new(),
            payload: json!({"id": 3, "tier": 1, "board": [null], "hand": [], "slots": [],
                "counters": {}, "heaps": {}, "standing": []}),
        }],
    }
}

fn run_path(root: &Path, id: &str) -> PathBuf {
    root.join("runs").join(&id[..2]).join(format!("{id}.json"))
}

#[test]
fn add_is_idempotent_and_fetch_refuses_tampering() {
    let scratch = Scratch::new();
    let store = FolderStore::new(&scratch.0);
    let bytes = run().to_bytes().unwrap();
    let id = store.add(&bytes).unwrap();
    assert_eq!(id, format!("{:x}", Sha256::digest(&bytes)));
    assert_eq!(store.add(&bytes).unwrap(), id);
    assert_eq!(store.find(&Query::default()).unwrap().len(), 1);
    assert_eq!(
        store.fetch(&id).unwrap().unwrap().to_bytes().unwrap(),
        bytes
    );
    assert!(store.fetch(&"0".repeat(64)).unwrap().is_none());

    fs::remove_file(scratch.0.join("index.jsonl")).unwrap();
    assert_eq!(store.rebuild_index().unwrap(), 1);
    let path = run_path(&scratch.0, &id);
    fs::write(&path, [&bytes[..], b"\n"].concat()).unwrap();
    assert!(store.fetch(&id).unwrap_err().contains("hash mismatch"));
    assert!(store.verify().unwrap_err().contains("hash mismatch"));
    assert!(store.add(&bytes).unwrap_err().contains("hash mismatch"));
}

#[test]
fn writer_and_reader_refuse_a_gap_even_with_the_correct_id() {
    let scratch = Scratch::new();
    let store = FolderStore::new(&scratch.0);
    let mut run = run();
    let mut third = run.turns[0].clone();
    third.turn = 3;
    run.last_turn = 3;
    run.turns.push(third);
    assert!(run.to_bytes().unwrap_err().contains("turn gap"));
    let bytes = serde_json::to_vec(&run).unwrap();
    assert!(store.add(&bytes).unwrap_err().contains("turn gap"));
    let id = format!("{:x}", Sha256::digest(&bytes));
    let path = run_path(&scratch.0, &id);
    fs::create_dir_all(path.parent().unwrap()).unwrap();
    fs::write(path, bytes).unwrap();
    assert!(store.fetch(&id).unwrap_err().contains("turn gap"));
    assert!(store.rebuild_index().unwrap_err().contains("turn gap"));
}

#[test]
fn matchmaker_draws_distinct_ids_within_the_band() {
    let scratch = Scratch::new();
    let store = FolderStore::new(&scratch.0);
    let mut run = run();
    let rules_hash = run.rules_hash().to_owned();
    let eligible: BTreeSet<_> = (0..8)
        .map(|i| {
            run.source.game_seed = i.to_string();
            store.add(&run.to_bytes().unwrap()).unwrap()
        })
        .collect();
    let mut other = run.clone();
    other.source.label = "blue".into();
    store.add(&other.to_bytes().unwrap()).unwrap();
    let mut other = run.clone();
    other.placement = 1;
    other.source.kind = SourceKind::Player;
    store.add(&other.to_bytes().unwrap()).unwrap();
    let mut other = run.clone();
    other.rules["rules_hash"] = json!("c".repeat(64));
    store.add(&other.to_bytes().unwrap()).unwrap();

    assert_eq!(
        store
            .find(&Query {
                kinds: vec![SourceKind::Player],
                ..Query::default()
            })
            .unwrap()
            .len(),
        1
    );
    let band = Band {
        labels: vec!["red".into()],
        placement: Some(2..=3),
    };
    let mut exclude = BTreeSet::new();
    let pick = |seed, exclude: &BTreeSet<String>| {
        LocalMatchmaker.pick(&store, &rules_hash, &band, exclude, &mut Rng::new(seed))
    };
    let first = pick(47, &exclude).unwrap();
    assert_eq!(first, pick(47, &exclude).unwrap());
    store.rebuild_index().unwrap();
    assert_eq!(first, pick(47, &exclude).unwrap());
    assert_ne!(first, pick(48, &exclude).unwrap());
    assert_eq!(first.iter().collect::<BTreeSet<_>>().len(), 7);
    assert!(first.iter().all(|id| eligible.contains(id)));
    exclude.insert(first[0].clone());
    let remaining = pick(47, &exclude).unwrap();
    assert!(!remaining.contains(&first[0]));
    exclude.insert(remaining[0].clone());
    assert_eq!(
        pick(47, &exclude).unwrap_err(),
        "need 7 eligible ghost runs, found 6"
    );
}

#[test]
fn cutter_keeps_payloads_actions_and_pre_fight_economy() {
    let scratch = Scratch::new();
    let records = scratch.0.join("records");
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
    GameRecord::configure(&root, &records);
    let content = GameContent::load_folders(&root, &Array::new());
    let game = content.borrow().new_session(101, &Array::new());
    game.borrow()
        .config
        .as_ref()
        .unwrap()
        .borrow_mut()
        .round_limit = 2;
    let mut economy = BTreeMap::new();
    for turn in 1..=2 {
        GameSession::start_round(&game);
        let actions = game.borrow().legal_actions(0);
        let refresh = actions
            .to_vec()
            .into_iter()
            .find(|act| act.get("type").as_text() == "refresh")
            .unwrap();
        assert_eq!(GameSession::act(&game, 0, &refresh), "");
        for seat in 0..8 {
            GameSession::end_turn(&game, seat);
            let player = game.borrow().player(seat);
            let player = player.borrow();
            economy.insert((seat, turn), (player.health, player.armor, player.gold));
        }
        GameSession::finish_round(&game);
    }
    let record_path = game.borrow().record.as_ref().unwrap().borrow().path.clone();
    drop(game);
    let path = records.join("game-00000.jsonl");
    fs::rename(record_path, &path).unwrap();
    let game_row = json!({"game": 0, "seed": "101", "seats": (0..8).map(|seat|
        json!({"seat": seat, "bot": "proof", "label": "proof-band"})).collect::<Vec<_>>()});
    fs::write(scratch.0.join("games.jsonl"), format!("{game_row}\n")).unwrap();
    let store = FolderStore::new(scratch.0.join("store"));
    let options = CutOptions {
        match_dir: &scratch.0,
        repo_root: &root,
        made: "2026-11-19T11:00:00Z",
        include_unfinished: false,
    };
    let report = cut_match(&options, &store).unwrap();
    assert_eq!(report.run_ids.len(), 8);
    let source = fs::read_to_string(&path).unwrap();
    let entries: Vec<Value> = source
        .lines()
        .map(|line| serde_json::from_str(line).unwrap())
        .collect();
    let fights: Vec<_> = entries
        .iter()
        .filter(|line| line["op"] == "fight_boards")
        .collect();
    for (seat, id) in report.run_ids.iter().enumerate() {
        let run = store.fetch(id).unwrap().unwrap();
        assert_eq!(run.source.label, "proof-band");
        assert_eq!(run.ended, Ended::RoundLimit);
        for turn in &run.turns {
            assert_eq!(turn.payload, fights[turn.turn - 1]["players"][seat]);
            assert_eq!(
                (turn.health, turn.armor, turn.gold),
                economy[&(seat as i64, turn.turn)]
            );
            if seat == 0 {
                assert_eq!(turn.acts.len(), 1);
                assert_eq!(turn.acts[0].action["type"], "refresh");
                assert!(turn.acts[0].result.is_empty());
            } else {
                assert!(turn.acts.is_empty());
            }
        }
    }

    let unfinished = source
        .lines()
        .take_while(|line| !line.contains("\"over\":true"))
        .collect::<Vec<_>>()
        .join("\n");
    fs::write(&path, unfinished).unwrap();
    assert_eq!(cut_match(&options, &store).unwrap().skipped_unfinished, 1);
    let options = CutOptions {
        include_unfinished: true,
        ..options
    };
    let report = cut_match(&options, &store).unwrap();
    assert_eq!(report.run_ids.len(), 8);
    assert!(
        report
            .run_ids
            .iter()
            .all(|id| store.fetch(id).unwrap().unwrap().ended == Ended::Unfinished)
    );

    let gap = entries
        .iter()
        .filter(|line| line["op"] != "fight_boards" || line["turn"] != 1)
        .map(Value::to_string)
        .collect::<Vec<_>>()
        .join("\n");
    fs::write(&path, gap).unwrap();
    let error = cut_match(&options, &store).unwrap_err();
    assert!(error.contains("finish without fight boards"), "{error}");
    assert_eq!(store.verify().unwrap(), 16);
}
