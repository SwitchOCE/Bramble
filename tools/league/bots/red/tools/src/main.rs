//! The red team's tools.
//! `red-tools pit <A> <B> <games> <seeds-file> <out-dir> [clock_ms]`
//! A and B: a registered bot name (flow, tribe, simple, ...), or `red` / `red:key=val,key=val`
//! for the red bot with changed params.
use league_api::{Bot, BotSetup};
use red::Params;
use std::path::PathBuf;
use std::sync::OnceLock;
#[path = "../old/v1.rs"]
#[allow(dead_code)]
mod v1;
#[path = "../old/v2.rs"]
#[allow(dead_code)]
mod v2;
#[path = "../old/s1/src/lib.rs"]
#[allow(dead_code)]
mod s1;

static A: OnceLock<Params> = OnceLock::new();
static B: OnceLock<Params> = OnceLock::new();
static TA: OnceLock<Option<String>> = OnceLock::new();
static TB: OnceLock<Option<String>> = OnceLock::new();

fn make(seed: u64, setup: &BotSetup, p: &Params, t: &Option<String>) -> Box<dyn Bot> {
    let mut bot = red::new_red(seed, setup, p.clone());
    if let Some(text) = t {
        bot.set_table(red::parse_table_text(text));
    }
    Box::new(bot)
}
fn fa(seed: u64, setup: &BotSetup) -> Box<dyn Bot> {
    make(seed, setup, A.get().unwrap(), TA.get().unwrap())
}
fn fb(seed: u64, setup: &BotSetup) -> Box<dyn Bot> {
    make(seed, setup, B.get().unwrap(), TB.get().unwrap())
}

/// `red[:k=v,...]`; a `table=<path>` entry loads another cards.tsv.
fn parse(spec: &str) -> Result<Option<(Params, Option<String>)>, String> {
    let Some(rest) = spec.strip_prefix("red") else {
        return Ok(None);
    };
    let mut p = Params::default();
    let mut table = None;
    let rest = rest.trim_start_matches(':');
    for kv in rest.split(',').filter(|s| !s.is_empty()) {
        let (k, v) = kv.split_once('=').ok_or(format!("bad {kv}"))?;
        if k == "table" {
            table = Some(std::fs::read_to_string(v).map_err(|e| format!("{v}: {e}"))?);
        } else {
            p.set(k, v)?;
        }
    }
    Ok(Some((p, table)))
}

fn main() -> Result<(), String> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.first().map(String::as_str) != Some("pit") || args.len() < 6 {
        return Err("usage: red-tools pit <A> <B> <games> <seeds> <out> [clock_ms] [threads]".into());
    }
    let (a, b) = (&args[1], &args[2]);
    let fac_a: league_api::Factory = match parse(a)? {
        Some((p, t)) => {
            A.set(p).unwrap();
            TA.set(t).unwrap();
            fa
        }
        None if a == "v1" => v1::new_bot,
        None if a == "v2" => v2::new_bot,
        None if a == "s1" => s1::new_bot,
        None => league::factory(a)?,
    };
    let fac_b: league_api::Factory = match parse(b)? {
        Some((p, t)) => {
            B.set(p).unwrap();
            TB.set(t).unwrap();
            fb
        }
        None if b == "v1" => v1::new_bot,
        None if b == "v2" => v2::new_bot,
        None if b == "s1" => s1::new_bot,
        None => league::factory(b)?,
    };
    let clock_ms = args.get(6).map_or(Ok(1000), |s| s.parse()).map_err(|e| format!("{e}"))?;
    let threads = args.get(7).map_or(Ok(2), |s| s.parse()).map_err(|e| format!("{e}"))?;
    let summary = league::matchrun::run_factories(
        &league::matchrun::MatchArgs {
            red: a.clone(),
            blue: b.clone(),
            red_label: None,
            blue_label: None,
            games: args[3].parse().map_err(|e| format!("games: {e}"))?,
            seeds: PathBuf::from(&args[4]),
            clock_ms,
            threads,
            out: PathBuf::from(&args[5]),
            content: None,
            secret: Some("redpit".into()),
            root: league::default_root(),
            records: false,
            decisions: false,
        },
        fac_a,
        fac_b,
    )?;
    println!(
        "A {} {:.3}  B {} {:.3}  gap {:+.3}",
        a,
        summary["red_avg_place"].as_f64().unwrap_or(0.0),
        b,
        summary["blue_avg_place"].as_f64().unwrap_or(0.0),
        summary["gap_red_minus_blue"].as_f64().unwrap_or(0.0)
    );
    Ok(())
}
