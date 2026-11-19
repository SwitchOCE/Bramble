//! Read the same content-addressed folder as the GDScript replay store.
use super::ghost_run::{_hex, GhostRun, hash};
use crate::core::{
    mechanics::mechanic_registry::MechanicRegistry, units::unit_library::UnitLibrary,
};
use crate::{ToState, Variant};
use std::path::PathBuf;

pub struct GhostStore {
    pub directory: PathBuf,
}

impl GhostStore {
    pub fn new(directory: impl Into<PathBuf>) -> Self {
        Self {
            directory: directory.into(),
        }
    }

    pub fn fetch(
        &self,
        id: &str,
        library: Option<&UnitLibrary>,
        registry: Option<&MechanicRegistry>,
    ) -> Result<GhostRun, String> {
        let load = || {
            if !_hex(&Variant::from(id), 64) || id.bytes().any(|byte| byte.is_ascii_uppercase()) {
                return Err("invalid SHA-256 ID".into());
            }
            let path = self
                .directory
                .join("runs")
                .join(&id[..2])
                .join(format!("{id}.json"));
            let bytes = std::fs::read(&path)
                .map_err(|error| format!("cannot open {}: {error}", path.display()))?;
            if hash(&bytes) != id {
                return Err("SHA-256 mismatch".into());
            }
            GhostRun::validated(&bytes, library, registry, id.to_owned())
        };
        load().map_err(|problem| Self::_failure(id, &problem))
    }

    fn _failure(id: &str, problem: &str) -> String {
        format!("run {id}: {problem}")
    }
}

impl ToState for GhostStore {
    fn to_state(&self) -> Variant {
        crate::state_dict! {"directory"=>&self.directory.to_string_lossy().into_owned()}
    }
    fn field_names() -> &'static [&'static str] {
        &["directory"]
    }
}
