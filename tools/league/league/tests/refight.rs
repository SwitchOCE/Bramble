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
        red: "flow".into(),
        blue: "random".into(),
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
        &["--threads", "2", "--verify", "--select", "tribe:badger:2"],
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

#[test]
fn refight_modes_reproduce_every_fight_and_write_one_line_per_observation() {
    let root = league::default_root();
    let dir = root.join(format!(".copies/refight/modes-{}", std::process::id()));
    fs::create_dir_all(&dir).unwrap();
    let seeds = dir.join("seeds.txt");
    fs::write(&seeds, "11\n13\n").unwrap();
    matchrun::run(&MatchArgs {
        red: "flow".into(),
        blue: "random".into(),
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
    let modes = [
        "--text-off",
        "--keyword-off",
        "badger_overrun,cleave,badger_fury",
        "--overrun-swings",
        "--seeds",
        "2",
    ];
    let two = run(
        &dir,
        "two",
        &[&modes[..], &["--verify", "--threads", "2"]].concat(),
    );
    assert!(
        two.status.success(),
        "{}",
        String::from_utf8_lossy(&two.stderr)
    );
    let report = String::from_utf8_lossy(&two.stdout);
    let fights = report
        .split_whitespace()
        .nth(2)
        .and_then(|n| n.parse::<usize>().ok())
        .unwrap();
    assert!(
        report.contains(&format!("{fights} / {fights} fights reproduced")),
        "{report}"
    );
    let one = run(&dir, "one", &[&modes[..], &["--threads", "1"]].concat());
    assert!(one.status.success());
    for file in [
        "text_off.jsonl",
        "keyword_off.jsonl",
        "overrun_swings.jsonl",
        "overrun_swings.tsv",
    ] {
        assert_eq!(
            fs::read(dir.join("one").join(file)).unwrap(),
            fs::read(dir.join("two").join(file)).unwrap(),
            "{file}"
        );
    }
    let rows = log_lines(&dir.join("two/text_off.jsonl"));
    assert!(!rows.is_empty());
    for row in &rows {
        assert_eq!(row["mode"], "text_off");
        assert_eq!(row["seeds"], 2);
        for field in [
            "game",
            "round",
            "stage",
            "player",
            "slot",
            "card",
            "golden",
            "tier",
            "score_recorded",
            "score_off",
            "dealt_recorded",
            "dealt_off",
            "taken_recorded",
            "taken_off",
            "result_changed",
            "own_units",
            "enemy_units",
        ] {
            assert!(!row[field].is_null(), "{field} in {row}");
        }
    }

    let capped = run(&dir, "capped", &["--text-off", "--cap", "1"]);
    assert!(capped.status.success());
    let mut groups = std::collections::BTreeSet::new();
    for row in log_lines(&dir.join("capped/text_off.jsonl")) {
        assert!(
            groups.insert((row["card"].to_string(), row["stage"].to_string())),
            "{row}"
        );
    }
    assert!(!groups.is_empty());
    let no_mode = run(&dir, "no-mode", &["--seeds", "2"]);
    assert_eq!(no_mode.status.code(), Some(2));
    fs::remove_dir_all(dir).unwrap();
}
