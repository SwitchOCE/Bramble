use league::{analyze, bench, checkcrate, ghostmatch, matchrun, refight, selfcheck};
use std::path::PathBuf;

const USAGE: &str = "usage:
  league match --red <bot> --blue <bot> --games N --seeds <file> [--clock-ms 1000] [--threads K]
               --out <dir> [--content all|standin|<folders>] [--secret <hex>] [--no-records] [--no-decisions]
               [--red-label <tag>] [--blue-label <tag>] [--debug-logs]
  league ghost-match --red <bot> --blue <bot> --field <store> --games N --seeds <file>
                     --out <dir> [--clock-ms 1000] [--threads K] [--secret <hex>] [--no-decisions]
                     [--red-label <tag>] [--blue-label <tag>] [--debug-logs]
  league selfcheck --records <dir>... [--bots flow-random|tribe] [--games N] [--threads K] [--keep <dir>]
  league check-crate <path> --name <red|blue> [--keep]
  league analyze <dir>
  league refight --match <dir> [--repo-root <dir>] [--select tribe:<name>[:<min>]]
                 --out <dir> [--threads N] [--verify]
  league bench [--content all|standin|<folders>] [--games N] [--fight-records <dir>] [--fights N]
  league bots";

fn main() {
    league_api::harness::quiet_panics();
    let args: Vec<String> = std::env::args().skip(1).collect();
    let code = match run(&args) {
        Ok(()) => 0,
        Err(e) => {
            eprintln!("league: {e}");
            if e.starts_with("usage") { 2 } else { 1 }
        }
    };
    std::process::exit(code);
}

struct Opts {
    flags: Vec<(String, String)>,
    switches: Vec<String>,
    free: Vec<String>,
}

impl Opts {
    fn parse(args: &[String], switches: &[&str]) -> Self {
        let mut out = Opts {
            flags: Vec::new(),
            switches: Vec::new(),
            free: Vec::new(),
        };
        let mut i = 0;
        while i < args.len() {
            let a = &args[i];
            if let Some(name) = a.strip_prefix("--") {
                if switches.contains(&name) {
                    out.switches.push(name.into());
                } else if i + 1 < args.len() {
                    out.flags.push((name.into(), args[i + 1].clone()));
                    i += 1;
                } else {
                    out.flags.push((name.into(), String::new()));
                }
            } else {
                out.free.push(a.clone());
            }
            i += 1;
        }
        out
    }
    fn get(&self, name: &str) -> Option<String> {
        self.flags
            .iter()
            .rev()
            .find(|(n, _)| n == name)
            .map(|(_, v)| v.clone())
    }
    fn all(&self, name: &str) -> Vec<String> {
        self.flags
            .iter()
            .filter(|(n, _)| n == name)
            .map(|(_, v)| v.clone())
            .collect()
    }
    fn need(&self, name: &str) -> Result<String, String> {
        self.get(name)
            .ok_or_else(|| format!("usage: missing --{name}\n{USAGE}"))
    }
    fn num<T: std::str::FromStr>(&self, name: &str, default: T) -> Result<T, String> {
        match self.get(name) {
            None => Ok(default),
            Some(v) => v
                .parse()
                .map_err(|_| format!("usage: --{name} {v} is not a number")),
        }
    }
    fn has(&self, name: &str) -> bool {
        self.switches.iter().any(|s| s == name)
    }
}

fn run(args: &[String]) -> Result<(), String> {
    let Some(command) = args.first() else {
        return Err(USAGE.into());
    };
    let rest = &args[1..];
    let root = league::default_root();
    match command.as_str() {
        "match" | "ghost-match" => {
            let o = Opts::parse(rest, &["no-records", "no-decisions", "debug-logs"]);
            let m = matchrun::MatchArgs {
                red: o.need("red")?,
                blue: o.need("blue")?,
                red_label: o.get("red-label"),
                blue_label: o.get("blue-label"),
                games: o.num("games", 0usize)?,
                seeds: PathBuf::from(o.need("seeds")?),
                clock_ms: o.num("clock-ms", 1000i64)?,
                threads: o.num("threads", 1usize)?,
                out: PathBuf::from(o.need("out")?),
                content: o.get("content"),
                secret: o.get("secret"),
                root: o.get("repo-root").map(PathBuf::from).unwrap_or(root),
                records: !o.has("no-records"),
                decisions: !o.has("no-decisions"),
            };
            if m.games == 0 {
                return Err(format!("usage: --games must be positive\n{USAGE}"));
            }
            let result = if command == "ghost-match" {
                ghostmatch::run_with_debug_logs(
                    &m,
                    &PathBuf::from(o.need("field")?),
                    o.has("debug-logs"),
                )?
            } else {
                matchrun::run_with_debug_logs(&m, o.has("debug-logs"))?
            };
            println!("{result:#}");
            Ok(())
        }
        "selfcheck" => {
            let o = Opts::parse(rest, &[]);
            let dirs: Vec<PathBuf> = o.all("records").into_iter().map(PathBuf::from).collect();
            if dirs.is_empty() {
                return Err(format!("usage: missing --records\n{USAGE}"));
            }
            let limit = o
                .get("games")
                .map(|g| g.parse::<usize>())
                .transpose()
                .map_err(|e| e.to_string())?;
            let keep = o.get("keep").map(PathBuf::from);
            let seats = match o.get("bots").as_deref() {
                None | Some("flow-random") => selfcheck::records_gd_seats,
                // The engine check only; TribeBot can't be a player in a match.
                Some("tribe") => selfcheck::tribe_seats,
                Some(other) => return Err(format!("usage: unknown --bots {other}\n{USAGE}")),
            };
            let r = selfcheck::run_with(
                &root,
                &dirs,
                limit,
                o.num("threads", 1usize)?,
                keep.as_deref(),
                seats,
            )?;
            for f in r.failures.iter().take(10) {
                println!("MISMATCH {f}");
            }
            println!(
                "selfcheck: {} / {} games equal to the GDScript records ({} lines, {} actions) in {:.1} s",
                r.matched, r.games, r.lines, r.acts, r.seconds
            );
            if r.matched == r.games && r.games > 0 {
                Ok(())
            } else {
                Err(format!("{} games differ", r.games - r.matched))
            }
        }
        "check-crate" => {
            let o = Opts::parse(rest, &["keep"]);
            let path = o
                .free
                .first()
                .ok_or_else(|| format!("usage: missing crate path\n{USAGE}"))?;
            let name = o.need("name")?;
            match checkcrate::check(&root, &PathBuf::from(path), &name, o.has("keep")) {
                Ok(note) => {
                    println!("check-crate: PASS {path} as {name}: {note}");
                    Ok(())
                }
                Err(problems) => {
                    for p in &problems {
                        println!("check-crate: FAIL {path}: {p}");
                    }
                    Err(format!("{} problem(s)", problems.len()))
                }
            }
        }
        "analyze" => {
            let o = Opts::parse(rest, &[]);
            let dir = o
                .free
                .first()
                .ok_or_else(|| format!("usage: missing directory\n{USAGE}"))?;
            let report = analyze::analyze(&PathBuf::from(dir))?;
            println!("{report}");
            Ok(())
        }
        "refight" => {
            let o = Opts::parse(rest, &["verify"]);
            if !o.free.is_empty()
                || o.flags.iter().any(|(name, value)| {
                    !["match", "repo-root", "select", "out", "threads"].contains(&name.as_str())
                        || value.is_empty()
                        || value.starts_with("--")
                })
            {
                return Err(USAGE.into());
            }
            let dir = PathBuf::from(o.need("match")?);
            let out = PathBuf::from(o.need("out")?);
            let root = o.get("repo-root").map(PathBuf::from).unwrap_or(root);
            let select = o.get("select").map(|rule| rule.parse()).transpose()?;
            let threads = o.num("threads", 1usize)?;
            if threads == 0 {
                return Err("usage: --threads must be positive".into());
            }
            let verify = o.has("verify");
            let report = refight::run(&dir, &root, &out, select.as_ref(), threads, verify)?;
            println!("{report}");
            if verify {
                report.verify()?;
            }
            Ok(())
        }
        "bench" => {
            let o = Opts::parse(rest, &[]);
            let report = bench::run(
                &root,
                o.get("content").as_deref(),
                o.num("games", 5usize)?,
                o.get("fight-records").map(PathBuf::from),
                o.num("fights", 200usize)?,
            )?;
            println!("{report:#}");
            Ok(())
        }
        "bots" => {
            for (name, _) in league::registry() {
                println!("{name}");
            }
            Ok(())
        }
        _ => Err(USAGE.into()),
    }
}
