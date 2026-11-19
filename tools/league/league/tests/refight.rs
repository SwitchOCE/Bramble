use league::matchrun::{self, MatchArgs};
use serde_json::Value;
use std::fs;
use std::path::Path;
use std::process::{Command, Output};

fn run(dir: &Path, out: &str, opts: &[&str]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_league"))
        .arg("refight")
        .arg("--match")
        .arg(dir.join("match"))
        .arg("--out")
        .arg(dir.join(out))
        .args(opts)
        .output()
        .unwrap()
}

fn log_lines(path: &Path) -> Vec<Value> {
    fs::read_to_string(path)
        .unwrap()
        .lines()
        .map(|line| serde_json::from_str(line).unwrap())
        .collect()
}

#[test]
fn refight_verifies_a_match_including_ghosts_and_rejects_a_changed_result() {
    let root = league::default_root();
    let dir = root.join(format!(".copies/refight/test-{}", std::process::id()));
    fs::create_dir_all(&dir).unwrap();
    let seeds = dir.join("seeds.txt");
    fs::write(&seeds, "11\n13\n").unwrap();
    matchrun::run(&MatchArgs {
        red: "tribe-badger".into(),
        blue: "tribe-mouse".into(),
        red_label: None,
        blue_label: None,
        games: 4,
        seeds,
        clock_ms: 1000,
        threads: 2,
        out: dir.join("match"),
        content: None,
        secret: Some("aa".into()),
        root: root.clone(),
        records: true,
        decisions: false,
    })
    .unwrap();

    let output = run(&dir, "verify", &["--verify"]);
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
    let game_log = dir.join("match/games.jsonl");
    let mut games = log_lines(&game_log);
    let expected: usize = games
        .iter()
        .flat_map(|g| g["fights"].as_array().unwrap())
        .map(|round| round["fights"].as_array().unwrap().len())
        .sum();
    let rows = log_lines(&dir.join("verify/refights.jsonl"));
    assert_eq!(rows.len(), expected);
    assert!(rows.iter().any(|f| f["players"][1] == -1));
    for row in &rows {
        assert_eq!(row["original_winner"], row["new_winner"]);
        assert_eq!(row["original_damage"], row["new_damage"]);
        assert!(row["skip"].is_null() && row["verify_mismatch"].is_null());
    }

    let selected = run(
        &dir,
        "badger",
        &["--threads", "2", "--verify", "--select", "tribe:badger"],
    );
    assert!(
        selected.status.success(),
        "{}",
        String::from_utf8_lossy(&selected.stderr)
    );
    assert!(
        String::from_utf8_lossy(&selected.stdout)
            .contains(&format!("{expected} / {expected} fights reproduced"))
    );
    let selected_rows = log_lines(&dir.join("badger/refights.jsonl"));
    assert!(!selected_rows.is_empty() && selected_rows.len() < expected);
    assert!(
        selected_rows
            .iter()
            .any(|f| f["qualifying_sides"].as_array().unwrap().len() == 2)
    );

    let result = &mut games[0]["fights"][0]["fights"][0]["result"];
    result["triggers"] = (result["triggers"].as_i64().unwrap() + 1).into();
    let mut changed = String::new();
    for game in &games {
        changed.push_str(&game.to_string());
        changed.push('\n');
    }
    fs::write(&game_log, changed).unwrap();
    let mismatch = run(&dir, "mismatch", &["--verify", "--threads", "2"]);
    assert_eq!(mismatch.status.code(), Some(1));
    assert!(String::from_utf8_lossy(&mismatch.stderr).contains("combat result triggers"));
    fs::remove_dir_all(dir).unwrap();
}
