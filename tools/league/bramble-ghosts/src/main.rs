use bramble_ghosts::{CutOptions, FolderStore, cut_match};
use std::{
    collections::BTreeMap,
    path::{Path, PathBuf},
    process::ExitCode,
};

const USAGE: &str = "\
Usage:
  bramble-ghosts cut --match DIR --store DIR --made TIME [--ghost-store DIR] [--repo-root DIR] [--include-unfinished]
  bramble-ghosts verify --store DIR
  bramble-ghosts verify --run FILE
  bramble-ghosts index --store DIR";

fn main() -> ExitCode {
    let args: Vec<_> = std::env::args().skip(1).collect();
    match run(&args) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("bramble-ghosts: {error}");
            ExitCode::FAILURE
        }
    }
}

fn run(args: &[String]) -> Result<(), String> {
    let Some((command, args)) = args.split_first() else {
        return Err(USAGE.into());
    };
    if matches!(command.as_str(), "--help" | "-h")
        || matches!(args, [arg] if arg == "--help" || arg == "-h")
    {
        println!("{USAGE}");
        return Ok(());
    }
    let allowed = match command.as_str() {
        "cut" => &[
            "--match",
            "--store",
            "--ghost-store",
            "--made",
            "--repo-root",
            "--include-unfinished",
        ][..],
        "verify" => &["--store", "--run"][..],
        "index" => &["--store"][..],
        _ => return Err(format!("unknown command {command:?}\n{USAGE}")),
    };
    let mut options = BTreeMap::new();
    let mut args = args.iter().map(String::as_str);
    while let Some(flag) = args.next() {
        if !allowed.contains(&flag) || options.contains_key(flag) {
            return Err(format!("unexpected option {flag:?}\n{USAGE}"));
        }
        let value = if flag == "--include-unfinished" {
            ""
        } else {
            args.next()
                .filter(|value| !value.is_empty() && !value.starts_with("--"))
                .ok_or_else(|| format!("missing value for {flag}\n{USAGE}"))?
        };
        options.insert(flag, value);
    }
    let need = |flag| {
        options
            .get(flag)
            .copied()
            .ok_or_else(|| format!("missing {flag}\n{USAGE}"))
    };
    match command.as_str() {
        "cut" => {
            let repo_root = options.get("--repo-root").map_or_else(
                || Path::new(env!("CARGO_MANIFEST_DIR")).join("../../.."),
                PathBuf::from,
            );
            let store = FolderStore::new(need("--store")?);
            let report = cut_match(
                &CutOptions {
                    match_dir: Path::new(need("--match")?),
                    repo_root: &repo_root,
                    ghost_store: options.get("--ghost-store").map(Path::new),
                    made: need("--made")?,
                    include_unfinished: options.contains_key("--include-unfinished"),
                },
                &store,
            )?;
            println!(
                "cut {} records into {} runs; skipped {} unfinished",
                report.records,
                report.run_ids.len(),
                report.skipped_unfinished
            );
        }
        "verify" => {
            let count = match (options.get("--store"), options.get("--run")) {
                (Some(root), None) => FolderStore::new(*root).verify()?,
                (None, Some(run)) => {
                    FolderStore::verify_file(Path::new(run))?;
                    1
                }
                _ => return Err(format!("choose --store or --run\n{USAGE}")),
            };
            println!("verified {count} runs");
        }
        "index" => {
            let count = FolderStore::new(need("--store")?).rebuild_index()?;
            println!("indexed {count} runs");
        }
        _ => unreachable!(),
    }
    Ok(())
}
