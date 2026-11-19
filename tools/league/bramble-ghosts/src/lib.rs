//! Immutable ghost runs, match record cutting and local matchmaking.

mod cut;
mod matchmaking;
mod run;
mod store;

pub use cut::{CutOptions, CutReport, cut_match};
pub use matchmaking::{Band, LocalMatchmaker, Matchmaker};
pub use run::{Act, Ended, RUN_FORMAT, Run, RunSource, RunTurn, SourceKind};
pub use store::{FolderStore, GhostStore, Query, RunInfo};

use sha2::{Digest, Sha256};
use std::{fmt::Display, path::Path};

fn sha256(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}

fn is_hex(value: &str, len: usize) -> bool {
    value.len() == len
        && value
            .bytes()
            .all(|c| matches!(c, b'0'..=b'9' | b'a'..=b'f'))
}

fn at<T>(path: &Path, result: Result<T, impl Display>) -> Result<T, String> {
    result.map_err(|error| format!("{}: {error}", path.display()))
}
