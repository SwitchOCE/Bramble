use serde_json::{Value, json};
use std::{fs, path::PathBuf, process::Command};

struct TestMatch(PathBuf);

impl Drop for TestMatch {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

#[test]
fn replays_gorger_sale_in_saved_record() {
    let directory =
        PathBuf::from(env!("CARGO_TARGET_TMPDIR")).join(format!("events-{}", std::process::id()));
    fs::create_dir_all(directory.parent().unwrap()).unwrap();
    fs::create_dir(&directory).unwrap();
    let directory = TestMatch(directory);
    let records = directory.0.join("records");
    fs::create_dir(&records).unwrap();

    let fixture =
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/data/smoke20-game-00013.jsonl.gz");
    let status = Command::new("gzip")
        .arg("-dc")
        .arg(fixture)
        .stdout(fs::File::create(records.join("game-00000.jsonl")).unwrap())
        .status()
        .unwrap();
    assert!(status.success());

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
        .map(|line| serde_json::from_str::<Value>(line).unwrap())
        .filter(|row| row["round"] == 8 && row["seat"] == 1)
        .collect();

    // The round-7 checkpoint has a golden Green Recruit in slot 1 and a plain
    // Gorger. The round-8 sale gives the Gorger the Recruit's golden 4/4 stats.
    let eater = json!({"card": "gorger", "uid": 57, "golden": false});
    let gain = json!({"attack": 4, "health": 4});
    let eaten = json!({
        "card": "green-recruit", "uid": 54, "golden": true, "tier": 1, "slot": 1,
        "stats": gain, "own_stats": gain
    });
    let eats: Vec<_> = rows.iter().filter(|row| row["type"] == "eat").collect();
    assert_eq!(
        eats,
        vec![&json!({
            "type": "eat", "game": 0, "round": 8, "seat": 1,
            "eater": eater, "eaten": eaten, "gain": gain, "trigger": "sale"
        })]
    );
    let sale = rows
        .iter()
        .find(|row| row["type"] == "sale" && row["unit"]["uid"] == 54)
        .expect("round 8 Green Recruit sale");
    assert_eq!(
        sale,
        &json!({
            "type": "sale", "game": 0, "round": 8, "seat": 1,
            "unit": eaten, "gold": 3, "board_since_round": 6, "rounds_on_board": 2,
            "fed": [{"type": "eat", "eater": eater, "gain": gain}]
        })
    );
}
