//! The blue team's tools. A starting point: plays the blue bot against FlowBot through the harness.
//! To play two versions of your own bot, keep a copy of the old one as a module here (for
//! example `#[path = "../old/lib.rs"] mod old;`) and call
//! `league::matchrun::run_factories(&args, blue::new_bot, old::new_bot)`.
//! `cargo run --offline --locked --release -p blue-tools -- <games> <seeds-file> <out-dir>`
use std::path::PathBuf;

fn main() -> Result<(), String> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let [games, seeds, out] = args.as_slice() else {
        return Err("usage: blue-tools <games> <seeds-file> <out-dir>".into());
    };
    let summary = league::matchrun::run(&league::matchrun::MatchArgs {
        red: "blue".into(),
        blue: "flow".into(),
        red_label: None,
        blue_label: None,
        games: games.parse().map_err(|e| format!("games: {e}"))?,
        seeds: PathBuf::from(seeds),
        clock_ms: 1000,
        threads: 2,
        out: PathBuf::from(out),
        content: None,
        secret: None,
        root: league::default_root(),
        records: true,
        // Every legal action at every decision, and the pick (about 40 MB a 1,000 games).
        decisions: true,
    })?;
    println!("{summary}");
    Ok(())
}
