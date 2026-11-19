//! The bot league's match harness: the game loop, seats and seeds, the clock, logs,
//! baselines, the record self-check, the crate check and the analysis.
pub mod analyze;
pub mod baselines;
pub mod bench;
pub mod checkcrate;
pub mod game;
pub mod ghostmatch;
pub mod matchrun;
pub mod refight;
pub mod selfcheck;
pub mod watchdog;

use bramble_engine::Array;
use bramble_engine::game::game_content::{GameContent, GameContentRef};
use bramble_engine::util::godot_json;
use league_api::{Factory, harness};
use std::path::{Path, PathBuf};
use std::rc::Rc;

/// The GDScript build fingerprint pinned by proof/refresh_reference.sh.
/// GDScript replays refuse any other `rules_hash`.
pub const BUILD: &str = include_str!("../build.json");

/// The repository root (for card data), from this crate's location.
pub fn default_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..")
}

/// `None` or "all": every tribe, as the shipped game (`GameContent.load_default`).
/// "standin": the stand-in cards (`load_folders([])`). Otherwise comma-separated
/// `src/content` folder names, in order.
pub fn load_content(root: &Path, spec: Option<&str>) -> Result<GameContentRef, String> {
    check_root(root)?;
    let content = match spec {
        None | Some("all") => GameContent::load_default(root),
        Some("standin") => GameContent::load_folders(root, &Array::new()),
        Some(list) => {
            let paths: Array<String> = list
                .split(',')
                .filter(|s| !s.is_empty())
                .map(|f| format!("res://src/content/{f}"))
                .collect();
            GameContent::load_folders(root, &paths)
        }
    };
    let errors = content.borrow().errors.to_vec();
    if !errors.is_empty() {
        return Err(format!("content errors: {errors:?}"));
    }
    if spec.is_none() || spec == Some("all") {
        let tribes = content.borrow().tribe_ids().len();
        if tribes == 0 {
            return Err(format!(
                "no tribes found under {}",
                root.join("src/content").display()
            ));
        }
    }
    Ok(content)
}

/// The engine reads a missing card file as empty, as Godot does. Refuse a root with no card
/// data, so a wrong path can never play a silent empty game.
fn check_root(root: &Path) -> Result<(), String> {
    let stand_in = root.join(GameContent::STAND_IN_PATH.trim_start_matches("res://"));
    if !root.join("src/content").is_dir() || !stand_in.is_file() {
        return Err(format!(
            "no card data under {} (want src/content and {}); pass --repo-root",
            root.display(),
            stand_in.display()
        ));
    }
    Ok(())
}

/// Content from a record header's recipe paths.
pub fn load_recipe(root: &Path, paths: &[String]) -> Result<GameContentRef, String> {
    check_root(root)?;
    let paths: Array<String> = paths.iter().cloned().collect();
    let content = GameContent::load_folders(root, &paths);
    let errors = content.borrow().errors.to_vec();
    if !errors.is_empty() {
        return Err(format!("content errors: {errors:?}"));
    }
    Ok(content)
}

/// The per-thread engine objects for games on `content`.
pub fn engine_for(
    root: &Path,
    load: &dyn Fn() -> Result<GameContentRef, String>,
) -> Result<game::Engine, String> {
    let _ = root;
    let content = load()?;
    let sim_content = load()?;
    let probe = content.borrow().new_session(1, &Array::new());
    let library = Rc::new(harness::library_of_game(&probe));
    Ok(game::Engine {
        content,
        sim_content,
        library,
        build: godot_json::parse_string(BUILD.trim()),
    })
}

/// Every bot the binary can play, by name: the baselines, then the registry crate's.
pub fn registry() -> Vec<(&'static str, Factory)> {
    let mut out: Vec<(&'static str, Factory)> = vec![
        ("simple", baselines::new_simple),
        ("flow", baselines::new_flow),
        ("random", baselines::new_random),
    ];
    out.extend(league_bots::factories());
    out
}

pub const TRIBEBOT_RETIRED: &str = "TribeBot was retired as a player on 20 Nov 2026 (owner); \
     it only drives `selfcheck --bots tribe`; see docs/archive/README.md";

pub fn factory(name: &str) -> Result<Factory, String> {
    if name == "tribe" || name.starts_with("tribe-") {
        return Err(TRIBEBOT_RETIRED.into());
    }
    registry()
        .into_iter()
        .find(|(n, _)| *n == name)
        .map(|(_, f)| f)
        .ok_or_else(|| {
            let names: Vec<&str> = registry().iter().map(|(n, _)| *n).collect();
            format!("unknown bot {name}; registered: {}", names.join(", "))
        })
}

#[cfg(test)]
mod tests {
    #[test]
    fn retired_tribe_names_report_the_archive() {
        for name in ["tribe", "tribe-pigeon", "tribe-v1", "tribe-v1-mouse"] {
            assert_eq!(super::factory(name).unwrap_err(), super::TRIBEBOT_RETIRED);
        }
    }
}
