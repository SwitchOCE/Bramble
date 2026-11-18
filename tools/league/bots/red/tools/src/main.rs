//! The red team's tools. A starting point: plays the red bot against FlowBot through the harness.
//! `cargo run --offline --locked --release -p red-tools -- <games> <seeds-file> <out-dir>`
use std::path::PathBuf;

fn main() -> Result<(), String> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let [games, seeds, out] = args.as_slice() else {
        return Err("usage: red-tools <games> <seeds-file> <out-dir>".into());
    };
    let summary = league::matchrun::run(&league::matchrun::MatchArgs {
        red: "red".into(),
        blue: "flow".into(),
        games: games.parse().map_err(|e| format!("games: {e}"))?,
        seeds: PathBuf::from(seeds),
        clock_ms: 1000,
        threads: 2,
        out: PathBuf::from(out),
        content: None,
        secret: None,
        root: league::default_root(),
        records: true,
    })?;
    println!("{summary}");
    Ok(())
}
