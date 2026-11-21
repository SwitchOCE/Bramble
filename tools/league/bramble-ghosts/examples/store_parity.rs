//! Read and verify a store's index and return the Rust matchmaker's picks for a proof case file.
use bramble_engine::core::util::rng::Rng;
use bramble_ghosts::{Band, FolderStore, GhostStore, LocalMatchmaker, Matchmaker, Query};
use serde::Deserialize;
use serde_json::json;
use std::{collections::BTreeSet, fs, path::PathBuf};

#[derive(Deserialize)]
struct Case {
    rules_hash: String,
    seed: i64,
    labels: Vec<String>,
    placement: Option<[i64; 2]>,
    exclude: BTreeSet<String>,
}

fn main() {
    let [root, cases]: [PathBuf; 2] = std::env::args_os()
        .skip(1)
        .map(PathBuf::from)
        .collect::<Vec<_>>()
        .try_into()
        .expect("usage: store_parity STORE CASES.json");
    let store = FolderStore::new(root);
    let rows = store.find(&Query::default()).unwrap();
    assert_eq!(rows.len(), store.verify().unwrap());
    for row in rows {
        let run = store.fetch(&row.id).unwrap().unwrap();
        assert_eq!(row.rules_hash, run.rules_hash());
        assert_eq!(row.kind, run.source.kind);
        assert_eq!(row.label, run.source.label);
        assert_eq!(row.placement, run.placement);
        assert_eq!(row.last_turn, run.last_turn);
        assert_eq!(row.made, run.made);
        assert_eq!(row.record_sha256, run.source.record_sha256);
        assert_eq!(row.seat, run.source.seat);
        assert_eq!(row.ended, Some(run.ended));
    }
    let cases: Vec<Case> = serde_json::from_slice(&fs::read(cases).unwrap()).unwrap();
    let results: Vec<_> = cases
        .into_iter()
        .map(|case| {
            match LocalMatchmaker.pick(
                &store,
                &case.rules_hash,
                &Band {
                    labels: case.labels,
                    placement: case.placement.map(|[low, high]| low..=high),
                },
                &case.exclude,
                &mut Rng::new(case.seed),
            ) {
                Ok(ids) => json!({"ok": true, "ids": ids}),
                Err(message) => json!({"ok": false, "message": message}),
            }
        })
        .collect();
    println!("{}", serde_json::to_string(&results).unwrap());
}
