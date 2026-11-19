//! A/B matches for the blue bot.
//! `ab <A> <B> <games> <seeds> <out> [threads]`, where A and B are each `cur`, `v1`, ... (a
//! snapshot under tools/old/), `cur:key=val,key=val` (the current bot with Params overrides),
//! or a registered bot name (`tribe`, `flow`). A plays red, B blue.
use league_api::{Bot, BotSetup};
use std::path::PathBuf;
use std::sync::OnceLock;

#[path = "../../old/v1/lib.rs"]
#[allow(dead_code, unused)]
mod v1;

#[path = "../../old/s1/lib.rs"]
#[allow(dead_code, unused)]
mod s1;

static SA: OnceLock<s1::Params> = OnceLock::new();
static SB: OnceLock<s1::Params> = OnceLock::new();

fn s1_a(seed: u64, s: &BotSetup) -> Box<dyn Bot> {
    s1::new_bot_with(seed, s, SA.get().unwrap().clone())
}
fn s1_b(seed: u64, s: &BotSetup) -> Box<dyn Bot> {
    s1::new_bot_with(seed, s, SB.get().unwrap().clone())
}

fn s1_params(spec: &str) -> Result<s1::Params, String> {
    let mut p = s1::Params::default();
    if let Some((_, rest)) = spec.split_once(':') {
        for kv in rest.split(',').filter(|x| !x.is_empty()) {
            let (k, v) = kv.split_once('=').ok_or(format!("bad {kv}"))?;
            let v: f64 = v.parse().map_err(|e| format!("{kv}: {e}"))?;
            if !p.set(k, v) {
                return Err(format!("unknown param {k}"));
            }
        }
    }
    Ok(p)
}

#[path = "../../old/s2/lib.rs"]
#[allow(dead_code, unused)]
mod s2;

static S2A: OnceLock<s2::Params> = OnceLock::new();
static S2B: OnceLock<s2::Params> = OnceLock::new();

fn s2_a(seed: u64, s: &BotSetup) -> Box<dyn Bot> {
    s2::new_bot_with(seed, s, S2A.get().unwrap().clone())
}
fn s2_b(seed: u64, s: &BotSetup) -> Box<dyn Bot> {
    s2::new_bot_with(seed, s, S2B.get().unwrap().clone())
}

fn s2_params(spec: &str) -> Result<s2::Params, String> {
    let mut p = s2::Params::default();
    if let Some((_, rest)) = spec.split_once(':') {
        for kv in rest.split(',').filter(|x| !x.is_empty()) {
            let (k, v) = kv.split_once('=').ok_or(format!("bad {kv}"))?;
            let v: f64 = v.parse().map_err(|e| format!("{kv}: {e}"))?;
            if !p.set(k, v) {
                return Err(format!("unknown param {k}"));
            }
        }
    }
    Ok(p)
}

#[path = "../../old/s3/lib.rs"]
#[allow(dead_code, unused)]
mod s3;

static S3A: OnceLock<s3::Params> = OnceLock::new();
static S3B: OnceLock<s3::Params> = OnceLock::new();

fn s3_a(seed: u64, s: &BotSetup) -> Box<dyn Bot> {
    s3::new_bot_with(seed, s, S3A.get().unwrap().clone())
}
fn s3_b(seed: u64, s: &BotSetup) -> Box<dyn Bot> {
    s3::new_bot_with(seed, s, S3B.get().unwrap().clone())
}

fn s3_params(spec: &str) -> Result<s3::Params, String> {
    let mut p = s3::Params::default();
    if let Some((_, rest)) = spec.split_once(':') {
        for kv in rest.split(',').filter(|x| !x.is_empty()) {
            let (k, v) = kv.split_once('=').ok_or(format!("bad {kv}"))?;
            let v: f64 = v.parse().map_err(|e| format!("{kv}: {e}"))?;
            if !p.set(k, v) {
                return Err(format!("unknown param {k}"));
            }
        }
    }
    Ok(p)
}

#[path = "../../old/s4/lib.rs"]
#[allow(dead_code, unused)]
mod s4;

static S4A: OnceLock<s4::Params> = OnceLock::new();
static S4B: OnceLock<s4::Params> = OnceLock::new();

fn s4_a(seed: u64, s: &BotSetup) -> Box<dyn Bot> {
    s4::new_bot_with(seed, s, S4A.get().unwrap().clone())
}
fn s4_b(seed: u64, s: &BotSetup) -> Box<dyn Bot> {
    s4::new_bot_with(seed, s, S4B.get().unwrap().clone())
}

fn s4_params(spec: &str) -> Result<s4::Params, String> {
    let mut p = s4::Params::default();
    if let Some((_, rest)) = spec.split_once(':') {
        for kv in rest.split(',').filter(|x| !x.is_empty()) {
            let (k, v) = kv.split_once('=').ok_or(format!("bad {kv}"))?;
            let v: f64 = v.parse().map_err(|e| format!("{kv}: {e}"))?;
            if !p.set(k, v) {
                return Err(format!("unknown param {k}"));
            }
        }
    }
    Ok(p)
}

static PA: OnceLock<blue::Params> = OnceLock::new();
static PB: OnceLock<blue::Params> = OnceLock::new();

fn cur_a(seed: u64, s: &BotSetup) -> Box<dyn Bot> {
    blue::new_bot_with(seed, s, PA.get().unwrap().clone())
}
fn cur_b(seed: u64, s: &BotSetup) -> Box<dyn Bot> {
    blue::new_bot_with(seed, s, PB.get().unwrap().clone())
}

fn params(spec: &str) -> Result<blue::Params, String> {
    let mut p = blue::Params::default();
    if let Some((_, rest)) = spec.split_once(':') {
        for kv in rest.split(',').filter(|x| !x.is_empty()) {
            let (k, v) = kv.split_once('=').ok_or(format!("bad {kv}"))?;
            let v: f64 = v.parse().map_err(|e| format!("{kv}: {e}"))?;
            if !p.set(k, v) {
                return Err(format!("unknown param {k}"));
            }
        }
    }
    Ok(p)
}

fn factory(spec: &str, a: bool) -> Result<Option<league_api::Factory>, String> {
    let name = spec.split(':').next().unwrap();
    Ok(match name {
        "cur" => {
            let p = params(spec)?;
            if a {
                PA.set(p).unwrap();
                Some(cur_a)
            } else {
                PB.set(p).unwrap();
                Some(cur_b)
            }
        }
        "v1" => Some(v1::new_bot),
        "s1" => {
            let p = s1_params(spec)?;
            if a {
                SA.set(p).unwrap();
                Some(s1_a)
            } else {
                SB.set(p).unwrap();
                Some(s1_b)
            }
        }
        "s2" => {
            let p = s2_params(spec)?;
            if a {
                S2A.set(p).unwrap();
                Some(s2_a)
            } else {
                S2B.set(p).unwrap();
                Some(s2_b)
            }
        }
        "s3" => {
            let p = s3_params(spec)?;
            if a {
                S3A.set(p).unwrap();
                Some(s3_a)
            } else {
                S3B.set(p).unwrap();
                Some(s3_b)
            }
        }
        "s4" => {
            let p = s4_params(spec)?;
            if a {
                S4A.set(p).unwrap();
                Some(s4_a)
            } else {
                S4B.set(p).unwrap();
                Some(s4_b)
            }
        }
        other => Some(league::factory(other)?),
    })
}

fn main() -> Result<(), String> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.len() < 5 {
        return Err("usage: ab <A> <B> <games> <seeds> <out> [threads]".into());
    }
    let threads = args.get(5).map_or(2, |t| t.parse().unwrap());
    let fa = factory(&args[0], true)?;
    let fb = factory(&args[1], false)?;
    let margs = league::matchrun::MatchArgs {
        red: args[0].clone(),
        blue: args[1].clone(),
        red_label: None,
        blue_label: None,
        games: args[2].parse().map_err(|e| format!("games: {e}"))?,
        seeds: PathBuf::from(&args[3]),
        clock_ms: 1000,
        threads,
        out: PathBuf::from(&args[4]),
        content: None,
        secret: Some("blue-ab".into()),
        root: league::default_root(),
        records: false,
        decisions: false,
    };
    let summary = league::matchrun::run_factories(&margs, fa.unwrap(), fb.unwrap())?;
    println!("{summary}");
    Ok(())
}

